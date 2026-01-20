import 'package:flutter/material.dart';
import '../../domain/entities/app_notification.dart';

/// Notifications list page
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Text('Mark all as read'),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear all'),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  // TODO: Mark all as read
                  break;
                case 'clear_all':
                  // TODO: Clear all notifications
                  break;
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 10, // TODO: Replace with actual notifications
        itemBuilder: (context, index) {
          return _buildNotificationItem(
            context,
            AppNotification(
              id: 'notif_$index',
              userId: 'user_1',
              title: _getNotificationTitle(index),
              body: _getNotificationBody(index),
              type: _getNotificationType(index),
              isRead: index > 2,
              createdAt: DateTime.now().subtract(Duration(hours: index)),
            ),
          );
        },
      ),
    );
  }

  String _getNotificationTitle(int index) {
    final titles = [
      'Ride Completed',
      '50% OFF on your next ride!',
      'Payment Received',
      'New Driver Available',
      'Ride Cancelled',
      'Welcome to Ridooo!',
      'Rate Your Driver',
      'Weekly Summary',
      'Account Verified',
      'Special Offer',
    ];
    return titles[index % titles.length];
  }

  String _getNotificationBody(int index) {
    final bodies = [
      'Your ride from Gulberg to Model Town has been completed.',
      'Use code SAVE50 to get 50% off on your next ride.',
      'Rs. 350 has been added to your wallet.',
      'Drivers are now available in your area.',
      'Your ride was cancelled. No charges applied.',
      'Welcome! Start booking rides with Ridooo.',
      'How was your ride with Ahmed? Rate now!',
      'You completed 5 rides this week. View summary.',
      'Your documents have been verified successfully.',
      'Book 3 rides this week and get 1 free!',
    ];
    return bodies[index % bodies.length];
  }

  String _getNotificationType(int index) {
    final types = [
      NotificationType.ride,
      NotificationType.promo,
      NotificationType.payment,
      NotificationType.system,
    ];
    return types[index % types.length];
  }

  Widget _buildNotificationItem(BuildContext context, AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        // TODO: Delete notification
      },
      child: Container(
        color: notification.isRead ? null : Colors.blue.shade50,
        child: ListTile(
          onTap: () {
            // TODO: Handle notification tap (navigate to relevant page)
          },
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(notification.type),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(notification.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          isThreeLine: true,
          trailing: !notification.isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case NotificationType.ride:
        return Icons.directions_car;
      case NotificationType.promo:
        return Icons.local_offer;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.system:
      default:
        return Icons.info;
    }
  }

  Color _getIconBackgroundColor(String type) {
    switch (type) {
      case NotificationType.ride:
        return Colors.blue;
      case NotificationType.promo:
        return Colors.orange;
      case NotificationType.payment:
        return Colors.green;
      case NotificationType.system:
      default:
        return Colors.purple;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
