import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../user/chat/presentation/pages/chat_screen_page.dart';

/// Driver chat list page showing all driver conversations - Dynamic with Supabase
class DriverChatListPage extends StatefulWidget {
  const DriverChatListPage({super.key});

  @override
  State<DriverChatListPage> createState() => _DriverChatListPageState();
}

class _DriverChatListPageState extends State<DriverChatListPage>
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
      final driverId = _supabase.auth.currentUser?.id;
      if (driverId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Optimized: Single query with JOIN to get accepted offers with ride info
      final offersResponse = await _supabase
          .from('driver_offers')
          .select('''
            ride_id, 
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
          .eq('driver_id', driverId)
          .eq('status', 'accepted')
          .order('created_at', ascending: false)
          .limit(50);

      final Map<String, ChatConversation> conversationsMap = {};
      final List<String> rideIds = [];
      final List<String> userIds = [];
      final Map<String, String> rideToUserMap = {};
      final Map<String, Map<String, dynamic>> rideDataMap = {};
      
      // First pass: collect ride and user IDs
      for (final offer in offersResponse as List) {
        final rideData = offer['ride'];
        if (rideData == null) continue;
        
        final rideId = rideData['id'] as String;
        
        // Skip if already processed
        if (conversationsMap.containsKey(rideId)) continue;
        
        // Only show active/recent rides
        final rideStatus = rideData['status'] as String;
        if (!['accepted', 'arrived', 'in_progress', 'completed'].contains(rideStatus)) continue;
        
        final passengerId = rideData['user_id'] as String;
        
        rideIds.add(rideId);
        if (!userIds.contains(passengerId)) {
          userIds.add(passengerId);
        }
        rideToUserMap[rideId] = passengerId;
        rideDataMap[rideId] = rideData;
        
        conversationsMap[rideId] = ChatConversation(
          id: rideId,
          passengerId: passengerId,
          rideId: rideId,
          passengerName: 'Passenger', // Will be updated below
          passengerImage: null,
          passengerPhone: null,
          lastMessage: 'Start a conversation',
          timestamp: DateTime.parse(rideData['created_at'] as String),
          unreadCount: 0,
          isOnline: true,
          rideStatus: rideStatus,
          pickupAddress: rideData['pickup_address'] as String?,
          dropoffAddress: rideData['dropoff_address'] as String?,
        );
      }
      
      // Batch fetch user info for all passengers
      if (userIds.isNotEmpty) {
        final usersResponse = await _supabase
            .from('users')
            .select('id, name, phone_number, profile_image')
            .inFilter('id', userIds);
        
        final Map<String, Map<String, dynamic>> usersMap = {};
        for (final user in usersResponse as List) {
          usersMap[user['id'] as String] = user;
        }
        
        // Update conversations with user info
        for (final rideId in conversationsMap.keys) {
          final passengerId = rideToUserMap[rideId];
          if (passengerId == null) continue;
          
          final userData = usersMap[passengerId];
          if (userData != null) {
            final name = userData['name'] as String? ?? 'Passenger';
            final phone = userData['phone_number'] as String?;
            final photo = userData['profile_image'] as String?;
            
            final existing = conversationsMap[rideId]!;
            conversationsMap[rideId] = ChatConversation(
              id: existing.id,
              passengerId: existing.passengerId,
              rideId: existing.rideId,
              passengerName: name.isNotEmpty ? name : 'Passenger',
              passengerImage: photo,
              passengerPhone: phone,
              lastMessage: existing.lastMessage,
              timestamp: existing.timestamp,
              unreadCount: existing.unreadCount,
              isOnline: existing.isOnline,
              rideStatus: existing.rideStatus,
              pickupAddress: existing.pickupAddress,
              dropoffAddress: existing.dropoffAddress,
            );
          }
        }
      }
      
      // Batch fetch: Get last messages and unread counts for all rides at once
      if (rideIds.isNotEmpty) {
        // Get all messages for these rides in one query
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
          
          // Count unread messages for this driver
          if (msg['receiver_id'] == driverId && msg['is_read'] == false) {
            unreadCounts[rideId] = (unreadCounts[rideId] ?? 0) + 1;
          }
        }
        
        // Update conversations with message data
        for (final rideId in conversationsMap.keys) {
          final conversation = conversationsMap[rideId]!;
          final lastMsg = lastMessages[rideId];
          
          conversationsMap[rideId] = ChatConversation(
            id: conversation.id,
            passengerId: conversation.passengerId,
            rideId: conversation.rideId,
            passengerName: conversation.passengerName,
            passengerImage: conversation.passengerImage,
            passengerPhone: conversation.passengerPhone,
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
    final driverId = _supabase.auth.currentUser?.id;
    if (driverId == null) return;

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
                recipientId: conversation.passengerId ?? '',
                recipientName: conversation.passengerName,
                recipientImage: conversation.passengerImage,
                recipientPhone: conversation.passengerPhone,
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
                    backgroundImage: conversation.passengerImage != null
                        ? NetworkImage(conversation.passengerImage!)
                        : null,
                    child: conversation.passengerImage == null
                        ? Text(
                            conversation.passengerName.isNotEmpty
                                ? conversation.passengerName[0].toUpperCase()
                                : 'P',
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
                            conversation.passengerName,
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
        return 'At Pickup';
      case 'accepted':
        return 'En Route';
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
              'Messages from passengers will appear here',
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
  final String? passengerId;
  final String? rideId;
  final String passengerName;
  final String? passengerImage;
  final String? passengerPhone;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final bool isOnline;
  final String? rideStatus;
  final String? pickupAddress;
  final String? dropoffAddress;

  ChatConversation({
    required this.id,
    this.passengerId,
    this.rideId,
    required this.passengerName,
    this.passengerImage,
    this.passengerPhone,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isOnline,
    this.rideStatus,
    this.pickupAddress,
    this.dropoffAddress,
  });
}
