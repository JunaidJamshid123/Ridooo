import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
        
        conversationsMap[rideId] = ChatConversation(
          id: rideId,
          passengerId: passengerId,
          rideId: rideId,
          passengerName: 'Passenger', // Will be updated below
          passengerImage: null,
          lastMessage: 'Start a conversation',
          timestamp: DateTime.parse(rideData['created_at'] as String),
          unreadCount: 0,
          isOnline: true,
        );
      }
      
      // Batch fetch user info for all passengers
      if (userIds.isNotEmpty) {
        final usersResponse = await _supabase
            .from('users')
            .select('id, name, profile_image')
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
            final photo = userData['profile_image'] as String?;
            
            final existing = conversationsMap[rideId]!;
            conversationsMap[rideId] = ChatConversation(
              id: existing.id,
              passengerId: existing.passengerId,
              rideId: existing.rideId,
              passengerName: name.isNotEmpty ? name : 'Passenger',
              passengerImage: photo,
              lastMessage: existing.lastMessage,
              timestamp: existing.timestamp,
              unreadCount: existing.unreadCount,
              isOnline: existing.isOnline,
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
            lastMessage: lastMsg?['content'] as String? ?? 'Start a conversation',
            timestamp: lastMsg != null
                ? DateTime.parse(lastMsg['created_at'] as String)
                : conversation.timestamp,
            unreadCount: unreadCounts[rideId] ?? 0,
            isOnline: true,
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadConversations,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildChatItem(conversation);
                    },
                  ),
                ),
    );
  }

  Widget _buildChatItem(ChatConversation conversation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreenPage(
                  recipientId: conversation.passengerId ?? '',
                  recipientName: conversation.passengerName,
                  recipientImage: conversation.passengerImage,
                  rideId: conversation.rideId,
                  isOnline: conversation.isOnline,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Passenger Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        conversation.passengerName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    if (conversation.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(conversation.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: conversation.unreadCount > 0
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.grey.shade600,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
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
                                color: conversation.unreadCount > 0
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.grey.shade600,
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A1A1A),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${conversation.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your passengers',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
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
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final bool isOnline;

  ChatConversation({
    required this.id,
    this.passengerId,
    this.rideId,
    required this.passengerName,
    this.passengerImage,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isOnline,
  });
}
