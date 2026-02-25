import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import 'chat_screen_page.dart';

/// User chat list page showing all conversations with drivers - Dynamic with Supabase
class UserChatListPage extends StatefulWidget {
  const UserChatListPage({super.key});

  @override
  State<UserChatListPage> createState() => _UserChatListPageState();
}

class _UserChatListPageState extends State<UserChatListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _supabase = Supabase.instance.client;
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Best approach: Get accepted driver_offers with ride info (driver_name is denormalized in offers)
      final offersResponse = await _supabase
          .from('driver_offers')
          .select('''
            ride_id, 
            driver_id,
            driver_name,
            driver_phone,
            driver_photo,
            created_at,
            ride:ride_id(
              id, 
              user_id, 
              status, 
              pickup_address, 
              dropoff_address, 
              created_at
            )
          ''')
          .eq('status', 'accepted')
          .order('created_at', ascending: false)
          .limit(50);

      final Map<String, ChatConversation> conversationsMap = {};
      final List<String> rideIds = [];
      
      // First pass: collect data from the join query
      for (final offer in offersResponse as List) {
        final rideData = offer['ride'];
        if (rideData == null) continue;
        
        // Check if this ride belongs to current user
        final rideUserId = rideData['user_id'] as String?;
        if (rideUserId != userId) continue;
        
        final rideId = rideData['id'] as String;
        
        // Skip if already processed
        if (conversationsMap.containsKey(rideId)) continue;
        
        // Only show active/recent rides
        final rideStatus = rideData['status'] as String;
        if (!['accepted', 'arrived', 'in_progress', 'completed'].contains(rideStatus)) continue;
        
        final driverId = offer['driver_id'] as String;
        
        // Get driver info from offer (denormalized)
        String driverName = offer['driver_name'] as String? ?? '';
        String? driverPhoto = offer['driver_photo'] as String?;
        String? driverPhone = offer['driver_phone'] as String?;
        
        // If name still empty, use a friendly fallback
        if (driverName.isEmpty) {
          driverName = 'Driver';
        }
        
        rideIds.add(rideId);
        
        conversationsMap[rideId] = ChatConversation(
          id: rideId,
          driverId: driverId,
          rideId: rideId,
          driverName: driverName,
          driverImage: driverPhoto,
          driverPhone: driverPhone,
          lastMessage: 'Start a conversation',
          timestamp: DateTime.parse(rideData['created_at'] as String),
          unreadCount: 0,
          isOnline: true,
          rideStatus: rideStatus,
          pickupAddress: rideData['pickup_address'] as String?,
          dropoffAddress: rideData['dropoff_address'] as String?,
        );
      }
      
      // Batch fetch: Get all messages for these rides at once
      if (rideIds.isNotEmpty) {
        final allMessages = await _supabase
            .from('chat_messages')
            .select('ride_id, content, created_at, receiver_id, is_read')
            .inFilter('ride_id', rideIds)
            .order('created_at', ascending: false);
        
        // Process messages: find last message and unread count per ride
        final Map<String, Map<String, dynamic>> lastMessages = {};
        final Map<String, int> unreadCounts = {};
        
        for (final msg in allMessages as List) {
          final rideId = msg['ride_id'] as String;
          
          // Track last message per ride
          if (!lastMessages.containsKey(rideId)) {
            lastMessages[rideId] = msg;
          }
          
          // Count unread messages for this user
          if (msg['receiver_id'] == userId && msg['is_read'] == false) {
            unreadCounts[rideId] = (unreadCounts[rideId] ?? 0) + 1;
          }
        }
        
        // Update conversations with message data
        for (final rideId in conversationsMap.keys) {
          final conversation = conversationsMap[rideId]!;
          final lastMsg = lastMessages[rideId];
          
          conversationsMap[rideId] = ChatConversation(
            id: conversation.id,
            driverId: conversation.driverId,
            rideId: conversation.rideId,
            driverName: conversation.driverName,
            driverImage: conversation.driverImage,
            driverPhone: conversation.driverPhone,
            lastMessage: lastMsg?['content'] as String? ?? 'Start a conversation',
            timestamp: lastMsg != null
                ? DateTime.parse(lastMsg['created_at'] as String)
                : conversation.timestamp,
            unreadCount: unreadCounts[rideId] ?? 0,
            isOnline: true,
            rideStatus: conversation.rideStatus,
            pickupAddress: conversation.pickupAddress,
            dropoffAddress: conversation.dropoffAddress,
          );
        }
      }

      // Sort by timestamp (most recent first)
      final conversations = conversationsMap.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToMessages() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _subscription = _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          _loadConversations();
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: false,
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              setState(() => _isRefreshing = true);
              await _loadConversations();
              setState(() => _isRefreshing = false);
            },
            icon: _isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh, color: Color(0xFF5F6368)),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildChatItem(conversation);
                    },
                  ),
                ),
    );
  }

  Widget _buildChatItem(ChatConversation conversation) {
    final hasUnread = conversation.unreadCount > 0;
    
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreenPage(
                recipientId: conversation.driverId ?? '',
                recipientName: conversation.driverName,
                recipientImage: conversation.driverImage,
                recipientPhone: conversation.driverPhone,
                rideId: conversation.rideId,
                isOnline: conversation.isOnline,
                rideStatus: conversation.rideStatus,
                pickupAddress: conversation.pickupAddress,
                dropoffAddress: conversation.dropoffAddress,
              ),
            ),
          ).then((_) => _loadConversations());
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFF0F2F5),
                    backgroundImage: conversation.driverImage != null
                        ? NetworkImage(conversation.driverImage!)
                        : null,
                    child: conversation.driverImage == null
                        ? Text(
                            conversation.driverName.isNotEmpty
                                ? conversation.driverName[0].toUpperCase()
                                : 'D',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  if (conversation.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
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
              
              // Chat Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.driverName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                              color: const Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTimestamp(conversation.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread ? AppColors.primary : const Color(0xFF9E9E9E),
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: hasUnread ? const Color(0xFF1A1A1A) : const Color(0xFF9E9E9E),
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (conversation.rideStatus != null) ...[
                      const SizedBox(height: 6),
                      _buildStatusChip(conversation.rideStatus!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _getRideStatusColor(status).withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _getRideStatusText(status),
        style: TextStyle(
          fontSize: 11,
          color: _getRideStatusColor(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Color _getRideStatusColor(String status) {
    switch (status) {
      case 'in_progress':
        return Colors.blue;
      case 'arrived':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  String _getRideStatusText(String status) {
    switch (status) {
      case 'in_progress':
        return 'Trip in Progress';
      case 'arrived':
        return 'Driver Arrived';
      case 'accepted':
        return 'Driver En Route';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  Widget _buildEmptyState() {
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
              'No messages yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Messages from drivers will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9E9E9E),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      return DateFormat('EEE').format(timestamp);
    } else {
      return DateFormat('dd/MM/yy').format(timestamp);
    }
  }
}

// Chat Conversation Model
class ChatConversation {
  final String id;
  final String? driverId;
  final String? rideId;
  final String driverName;
  final String? driverImage;
  final String? driverPhone;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final bool isOnline;
  final String? rideStatus;
  final String? pickupAddress;
  final String? dropoffAddress;

  ChatConversation({
    required this.id,
    this.driverId,
    this.rideId,
    required this.driverName,
    this.driverImage,
    this.driverPhone,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isOnline,
    this.rideStatus,
    this.pickupAddress,
    this.dropoffAddress,
  });
}

