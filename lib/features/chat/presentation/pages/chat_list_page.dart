import 'package:flutter/material.dart';
import '../../domain/entities/chat_message.dart';

/// Chat list page showing all conversations
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Search conversations
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 5, // TODO: Replace with actual conversations
        itemBuilder: (context, index) => _buildConversationItem(
          context,
          Conversation(
            id: 'conv_$index',
            rideId: 'ride_$index',
            userId: 'user_$index',
            driverId: 'driver_$index',
            lastMessage: index == 0 
                ? 'I\'m at the pickup location' 
                : 'Thanks for the ride!',
            lastMessageAt: DateTime.now().subtract(Duration(hours: index)),
            unreadCount: index == 0 ? 2 : 0,
            createdAt: DateTime.now().subtract(Duration(days: index)),
            otherUserName: 'User ${index + 1}',
            otherUserPhoto: null,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationItem(BuildContext context, Conversation conversation) {
    return ListTile(
      onTap: () {
        // TODO: Navigate to chat room
        // context.push('/chat/${conversation.id}');
      },
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade100,
        child: conversation.otherUserPhoto != null
            ? ClipOval(
                child: Image.network(
                  conversation.otherUserPhoto!,
                  fit: BoxFit.cover,
                ),
              )
            : Text(
                conversation.otherUserName?.substring(0, 1).toUpperCase() ?? '?',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.otherUserName ?? 'Unknown User',
              style: TextStyle(
                fontWeight: conversation.hasUnread 
                    ? FontWeight.bold 
                    : FontWeight.normal,
              ),
            ),
          ),
          if (conversation.lastMessageAt != null)
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: TextStyle(
                fontSize: 12,
                color: conversation.hasUnread 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage ?? 'No messages yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: conversation.hasUnread 
                    ? Colors.black87 
                    : Colors.grey.shade600,
                fontWeight: conversation.hasUnread 
                    ? FontWeight.w500 
                    : FontWeight.normal,
              ),
            ),
          ),
          if (conversation.hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
