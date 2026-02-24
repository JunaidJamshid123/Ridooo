import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
          lastMessage: 'Start a conversation',
          timestamp: DateTime.parse(rideData['created_at'] as String),
          unreadCount: 0,
          isOnline: true,
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
                  recipientId: conversation.driverId ?? '',
                  recipientName: conversation.driverName,
                  recipientImage: conversation.driverImage,
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
                // Driver Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        conversation.driverName[0].toUpperCase(),
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
                              conversation.driverName,
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
            'Start a conversation with your driver',
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
  final String? driverId;
  final String? rideId;
  final String driverName;
  final String? driverImage;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final bool isOnline;

  ChatConversation({
    required this.id,
    this.driverId,
    this.rideId,
    required this.driverName,
    this.driverImage,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isOnline,
  });
}

