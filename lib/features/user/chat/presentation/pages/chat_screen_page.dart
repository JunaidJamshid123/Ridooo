import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';

/// Individual chat screen with a driver - Connected to Supabase
class ChatScreenPage extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientImage;
  final bool isOnline;
  final String? rideId; // Optional: link to specific ride

  const ChatScreenPage({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientImage,
    this.isOnline = false,
    this.rideId,
  });

  @override
  State<ChatScreenPage> createState() => _ChatScreenPageState();
}

class _ChatScreenPageState extends State<ChatScreenPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  StreamSubscription? _messageSubscription;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
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
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }
  
  void _subscribeToMessages() {
    if (_currentUserId == null) return;
    
    // Subscribe to new messages
    _supabase
        .channel('chat_${_currentUserId}_${widget.recipientId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final newMessage = payload.newRecord;
            // Check if this message is for this conversation
            final senderId = newMessage['sender_id'];
            final receiverId = newMessage['receiver_id'];
            final messageId = newMessage['id'] as String;
            
            if ((senderId == _currentUserId && receiverId == widget.recipientId) ||
                (senderId == widget.recipientId && receiverId == _currentUserId)) {
              // Check for ride_id filter
              if (widget.rideId != null && newMessage['ride_id'] != widget.rideId) {
                return;
              }
              
              // Avoid duplicates - check if message already exists (from optimistic update)
              final existingIndex = _messages.indexWhere((m) => 
                  m.id == messageId || 
                  (m.text == newMessage['content'] as String && 
                   m.isFromUser && 
                   senderId == _currentUserId &&
                   m.timestamp.difference(DateTime.parse(newMessage['created_at'] as String)).inSeconds.abs() < 5)
              );
              
              if (existingIndex == -1) {
                // New message from recipient
                setState(() {
                  _messages.add(ChatMessage(
                    id: messageId,
                    text: newMessage['content'] as String,
                    isFromUser: newMessage['sender_id'] == _currentUserId,
                    timestamp: DateTime.parse(newMessage['created_at'] as String),
                  ));
                });
                _scrollToBottom();
              } else if (_messages[existingIndex].id != messageId) {
                // Update the optimistic message with the real ID
                setState(() {
                  _messages[existingIndex] = ChatMessage(
                    id: messageId,
                    text: newMessage['content'] as String,
                    isFromUser: newMessage['sender_id'] == _currentUserId,
                    timestamp: DateTime.parse(newMessage['created_at'] as String),
                  );
                });
              }
            }
          },
        )
        .subscribe();
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    _messageController.clear();
    
    // Optimistically add message
    final tempMessage = ChatMessage(
      id: DateTime.now().toString(),
      text: text,
      isFromUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      // Insert message to Supabase
      await _supabase.from('chat_messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': widget.recipientId,
        'content': text,
        'ride_id': widget.rideId,
        'message_type': 'text',
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: widget.recipientImage != null 
                      ? NetworkImage(widget.recipientImage!)
                      : null,
                  child: widget.recipientImage == null ? Text(
                    widget.recipientName.isNotEmpty ? widget.recipientName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ) : null,
                ),
                if (widget.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
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
                    widget.recipientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isOnline ? Colors.green : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
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
                                      .abs() >
                                  30;

                          return Column(
                            children: [
                              if (showTimestamp) _buildTimestamp(message.timestamp),
                              _buildMessageBubble(message),
                            ],
                          );
                        },
                      ),
          ),

          // Message Input
          _buildMessageInput(),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          timeText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            message.isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isFromUser) const SizedBox(width: 40),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.isFromUser
                    ? const Color(0xFF1A1A1A)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isFromUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isFromUser ? 4 : 16),
                ),
                border: message.isFromUser
                    ? null
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: message.isFromUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isFromUser
                          ? Colors.white70
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isFromUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Attach file coming soon')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 22),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chat Message Model
class ChatMessage {
  final String id;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
  });
}
