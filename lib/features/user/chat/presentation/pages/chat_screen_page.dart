import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';

/// Individual chat screen with a driver/passenger - Connected to Supabase
/// Supports both driver and passenger views with ride context
class ChatScreenPage extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientImage;
  final String? recipientPhone;
  final bool isOnline;
  final String? rideId;
  final String? rideStatus;
  final String? pickupAddress;
  final String? dropoffAddress;

  const ChatScreenPage({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientImage,
    this.recipientPhone,
    this.isOnline = false,
    this.rideId,
    this.rideStatus,
    this.pickupAddress,
    this.dropoffAddress,
  });

  @override
  State<ChatScreenPage> createState() => _ChatScreenPageState();
}

class _ChatScreenPageState extends State<ChatScreenPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  RealtimeChannel? _channel;
  Timer? _pollingTimer;
  String? _currentUserId;
  
  // Recipient info (can be loaded from DB if not provided)
  late String _recipientName;
  String? _recipientImage;
  String? _recipientPhone;
  bool _recipientOnline = false;
  
  // Quick reply suggestions
  final List<String> _quickReplies = [
    "I'm on my way",
    "Be there in 5 mins",
    "Running a bit late",
    "I've arrived",
    "Where are you?",
    "Thank you!",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUserId = _supabase.auth.currentUser?.id;
    
    // Initialize recipient info
    _recipientName = widget.recipientName.isNotEmpty 
        ? widget.recipientName 
        : 'User';
    _recipientImage = widget.recipientImage;
    _recipientPhone = widget.recipientPhone;
    _recipientOnline = widget.isOnline;
    
    // Load recipient info if name is generic
    if (_recipientName == 'User' || _recipientName == 'Passenger' || _recipientName == 'Driver') {
      _loadRecipientInfo();
    }
    
    _loadMessages();
    _subscribeToMessages();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _channel?.unsubscribe();
    _pollingTimer?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadMessages();
    }
  }
  
  /// Load recipient info from database
  Future<void> _loadRecipientInfo() async {
    if (widget.recipientId.isEmpty) return;
    
    try {
      // Try to get user info from users table
      final userResponse = await _supabase
          .from('users')
          .select('id, name, phone_number, profile_image')
          .eq('id', widget.recipientId)
          .maybeSingle();
      
      if (userResponse != null && mounted) {
        final name = userResponse['name'] as String?;
        if (name != null && name.isNotEmpty) {
          setState(() {
            _recipientName = name;
            _recipientPhone = userResponse['phone_number'] as String?;
            _recipientImage = userResponse['profile_image'] as String?;
          });
          return;
        }
      }
      
      // Fallback: Try drivers table
      final driverResponse = await _supabase
          .from('drivers')
          .select('id, name, phone_number, profile_image')
          .eq('user_id', widget.recipientId)
          .maybeSingle();
      
      if (driverResponse != null && mounted) {
        final name = driverResponse['name'] as String?;
        if (name != null && name.isNotEmpty) {
          setState(() {
            _recipientName = name;
            _recipientPhone = driverResponse['phone_number'] as String?;
            _recipientImage = driverResponse['profile_image'] as String?;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading recipient info: $e');
    }
  }
  
  /// Start periodic polling as fallback for realtime
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollNewMessages();
    });
  }
  
  /// Poll for new messages (fallback mechanism)
  Future<void> _pollNewMessages() async {
    if (_currentUserId == null || !mounted) return;
    
    try {
      var query = _supabase
          .from('chat_messages')
          .select()
          .or('and(sender_id.eq.$_currentUserId,receiver_id.eq.${widget.recipientId}),and(sender_id.eq.${widget.recipientId},receiver_id.eq.$_currentUserId)');
      
      if (widget.rideId != null) {
        query = query.eq('ride_id', widget.rideId!);
      }
      
      final response = await query
          .order('created_at', ascending: true)
          .limit(100);
      
      final newMessages = (response as List).map((json) => ChatMessage(
        id: json['id'] as String,
        text: json['content'] as String,
        isFromUser: json['sender_id'] == _currentUserId,
        timestamp: DateTime.parse(json['created_at'] as String),
      )).toList();
      
      // Only update if there are new messages
      if (newMessages.length != _messages.length) {
        setState(() {
          _messages = newMessages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error polling messages: $e');
    }
  }
  
  Future<void> _loadMessages() async {
    if (_currentUserId == null) return;
    
    try {
      // Get messages between current user and recipient for this ride
      var query = _supabase
          .from('chat_messages')
          .select()
          .or('and(sender_id.eq.$_currentUserId,receiver_id.eq.${widget.recipientId}),and(sender_id.eq.${widget.recipientId},receiver_id.eq.$_currentUserId)');
      
      // Filter by ride_id if provided
      if (widget.rideId != null) {
        query = query.eq('ride_id', widget.rideId!);
      }
      
      final response = await query
          .order('created_at', ascending: true)
          .limit(100);
      
      setState(() {
        _messages = (response as List).map((json) => ChatMessage(
          id: json['id'] as String,
          text: json['content'] as String,
          isFromUser: json['sender_id'] == _currentUserId,
          timestamp: DateTime.parse(json['created_at'] as String),
        )).toList();
        _isLoading = false;
      });
      
      _scrollToBottom();
      
      // Mark messages as read
      _markMessagesAsRead();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _markMessagesAsRead() async {
    if (_currentUserId == null || widget.rideId == null) return;
    
    try {
      await _supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('ride_id', widget.rideId!)
          .eq('receiver_id', _currentUserId!)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }
  
  void _subscribeToMessages() {
    if (_currentUserId == null) return;
    
    // Create a unique channel name for this conversation
    final channelName = widget.rideId != null 
        ? 'chat_ride_${widget.rideId}'
        : 'chat_${_currentUserId}_${widget.recipientId}';
    
    _channel = _supabase.channel(channelName);
    
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chat_messages',
      callback: (payload) {
        final newMessage = payload.newRecord;
        if (newMessage.isEmpty) return;
        
        // Check if this message is for this conversation
        final senderId = newMessage['sender_id'];
        final receiverId = newMessage['receiver_id'];
        final messageId = newMessage['id'] as String;
        final messageRideId = newMessage['ride_id'];
        
        // Skip if ride_id doesn't match (when filtered by ride)
        if (widget.rideId != null && messageRideId != widget.rideId) {
          return;
        }
        
        // Check if message belongs to this conversation
        if (!((senderId == _currentUserId && receiverId == widget.recipientId) ||
              (senderId == widget.recipientId && receiverId == _currentUserId))) {
          return;
        }
        
        // Check if message already exists
        final existingIndex = _messages.indexWhere((m) => m.id == messageId);
        
        if (existingIndex == -1) {
          // New message from other user
          setState(() {
            _messages.add(ChatMessage(
              id: messageId,
              text: newMessage['content'] as String? ?? '',
              isFromUser: senderId == _currentUserId,
              timestamp: DateTime.parse(newMessage['created_at'] as String),
            ));
          });
          _scrollToBottom();
          
          // Mark as read if from other user
          if (senderId != _currentUserId) {
            _markMessagesAsRead();
          }
        }
      },
    ).subscribe();
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickReply]) async {
    final text = (quickReply ?? _messageController.text).trim();
    if (text.isEmpty || _currentUserId == null || _isSending) return;

    if (quickReply == null) {
      _messageController.clear();
    }
    
    setState(() => _isSending = true);
    HapticFeedback.lightImpact();
    
    // Optimistically add message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = ChatMessage(
      id: tempId,
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    
    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      // Insert message to Supabase
      final response = await _supabase.from('chat_messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': widget.recipientId,
        'content': text,
        'ride_id': widget.rideId,
        'message_type': 'text',
        'is_read': false,
      }).select().single();
      
      // Update the temp message with real data
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: response['id'] as String,
              text: text,
              isFromUser: true,
              timestamp: DateTime.parse(response['created_at'] as String),
              status: MessageStatus.sent,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      // Mark message as failed
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: tempId,
              text: text,
              isFromUser: true,
              timestamp: DateTime.now(),
              status: MessageStatus.failed,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send message'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _sendMessage(text),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  
  Future<void> _makePhoneCall() async {
    final phone = _recipientPhone ?? widget.recipientPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Ride info banner (if ride context exists)
          if (widget.rideId != null && (widget.pickupAddress != null || widget.dropoffAddress != null))
            _buildRideInfoBanner(),
          
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading messages...'),
                      ],
                    ),
                  )
                : _messages.isEmpty
                    ? _buildEmptyChat()
                    : _buildMessagesList(),
          ),

          // Quick replies (when no messages or for convenience)
          if (_messages.length < 3) _buildQuickReplies(),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () => _showRecipientInfo(),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFF0F2F5),
                  backgroundImage: _recipientImage != null 
                      ? NetworkImage(_recipientImage!)
                      : null,
                  child: _recipientImage == null 
                      ? Text(
                          _recipientName.isNotEmpty ? _recipientName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                if (_recipientOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _recipientName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _recipientOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: _recipientOnline ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Color(0xFF4CAF50)),
          onPressed: _makePhoneCall,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A1A)),
          onSelected: (value) {
            switch (value) {
              case 'info':
                _showRecipientInfo();
                break;
              case 'clear':
                _confirmClearChat();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 20),
                  SizedBox(width: 12),
                  Text('View Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Clear Chat', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildRideInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.pickupAddress != null)
            Row(
              children: [
                const Icon(Icons.trip_origin, size: 14, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.pickupAddress!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5F6368),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (widget.pickupAddress != null && widget.dropoffAddress != null)
            const SizedBox(height: 8),
          if (widget.dropoffAddress != null)
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Color(0xFFEA4335)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.dropoffAddress!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5F6368),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F2F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Start a conversation',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Send a message to get started',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showTimestamp = index == 0 ||
            _messages[index - 1]
                    .timestamp
                    .difference(message.timestamp)
                    .inMinutes
                    .abs() > 30;
        
        // Check if this is the first message from a different sender
        final showAvatar = !message.isFromUser && 
            (index == 0 || _messages[index - 1].isFromUser);

        return Column(
          children: [
            if (showTimestamp) _buildTimestamp(message.timestamp),
            _buildMessageBubble(message, showAvatar: showAvatar),
          ],
        );
      },
    );
  }
  
  Widget _buildQuickReplies() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _quickReplies.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _sendMessage(reply),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Text(
                      reply,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5F6368),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showRecipientInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFF0F2F5),
              backgroundImage: _recipientImage != null 
                  ? NetworkImage(_recipientImage!)
                  : null,
              child: _recipientImage == null 
                  ? Text(
                      _recipientName.isNotEmpty ? _recipientName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              _recipientName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (_recipientPhone != null) ...[
              const SizedBox(height: 4),
              Text(
                _recipientPhone!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.phone,
                  label: 'Call',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _makePhoneCall();
                  },
                ),
                _buildActionButton(
                  icon: Icons.message,
                  label: 'Message',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _focusNode.requestFocus();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5F6368),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat?'),
        content: const Text('This will delete all messages in this conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _messages.clear());
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(DateTime timestamp) {
    String timeText;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      timeText = 'Today';
    } else if (messageDate == yesterday) {
      timeText = 'Yesterday';
    } else {
      timeText = DateFormat('MMM dd, yyyy').format(timestamp);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            timeText,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5F6368),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, {bool showAvatar = false}) {
    final isOutgoing = message.isFromUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for incoming messages
          if (!isOutgoing) ...[
            if (showAvatar)
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFF0F2F5),
                backgroundImage: _recipientImage != null 
                    ? NetworkImage(_recipientImage!)
                    : null,
                child: _recipientImage == null 
                    ? Text(
                        _recipientName.isNotEmpty ? _recipientName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 6),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOutgoing
                    ? AppColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
                  bottomRight: Radius.circular(isOutgoing ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isOutgoing ? Colors.white : const Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: isOutgoing ? Colors.white70 : const Color(0xFF9E9E9E),
                        ),
                      ),
                      if (isOutgoing) ...[
                        const SizedBox(width: 4),
                        _buildMessageStatusIcon(message.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isOutgoing) const SizedBox(width: 6),
        ],
      ),
    );
  }
  
  Widget _buildMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 14, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: Colors.redAccent);
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EAED))),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSending ? null : () => _sendMessage(),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _isSending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Message status enum
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

// Chat Message Model
class ChatMessage {
  final String id;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });
}
