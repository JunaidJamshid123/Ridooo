import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Simple and clean activity feed for users
class UserActivityPage extends StatefulWidget {
  const UserActivityPage({super.key});

  @override
  State<UserActivityPage> createState() => _UserActivityPageState();
}

class _UserActivityPageState extends State<UserActivityPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Mock activity data - TODO: Replace with actual data from backend
  final List<Activity> _activities = [
    Activity(
      type: ActivityType.login,
      title: 'Logged in',
      description: 'You logged into your account',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      icon: Icons.login,
      iconColor: Colors.blue,
    ),
    Activity(
      type: ActivityType.rideBooked,
      title: 'Ride booked',
      description: 'Gulberg III → Model Town',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      icon: Icons.directions_car,
      iconColor: Colors.green,
      amount: 350.0,
    ),
    Activity(
      type: ActivityType.payment,
      title: 'Payment successful',
      description: 'Ride payment completed',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      icon: Icons.payment,
      iconColor: Colors.purple,
      amount: -350.0,
    ),
    Activity(
      type: ActivityType.rideCompleted,
      title: 'Ride completed',
      description: 'DHA Phase 5 → Airport',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      icon: Icons.check_circle,
      iconColor: Colors.green,
      amount: 450.0,
    ),
    Activity(
      type: ActivityType.walletRecharge,
      title: 'Wallet recharged',
      description: 'Added money to wallet',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      icon: Icons.account_balance_wallet,
      iconColor: Colors.orange,
      amount: 1000.0,
    ),
    Activity(
      type: ActivityType.rideCancelled,
      title: 'Ride cancelled',
      description: 'You cancelled a ride',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      icon: Icons.cancel,
      iconColor: Colors.red,
    ),
    Activity(
      type: ActivityType.profileUpdated,
      title: 'Profile updated',
      description: 'You updated your profile picture',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      icon: Icons.person,
      iconColor: Colors.blue,
    ),
    Activity(
      type: ActivityType.rideBooked,
      title: 'Ride booked',
      description: 'Johar Town → Liberty Market',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      icon: Icons.directions_car,
      iconColor: Colors.green,
      amount: 280.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Activity',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              // TODO: Filter activities
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh activities
          await Future.delayed(const Duration(seconds: 1));
        },
        child: _activities.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  final activity = _activities[index];
                  final showDate = index == 0 ||
                      !_isSameDay(
                        activity.timestamp,
                        _activities[index - 1].timestamp,
                      );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDate) _buildDateHeader(activity.timestamp),
                      _buildActivityItem(activity),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    String dateText;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);

    if (activityDate == today) {
      dateText = 'Today';
    } else if (activityDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMMM dd, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        dateText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildActivityItem(Activity activity) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Show activity details
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: activity.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    activity.icon,
                    color: activity.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(activity.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Amount (if applicable)
                if (activity.amount != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: activity.amount! > 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${activity.amount! > 0 ? '+' : ''}Rs. ${activity.amount!.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: activity.amount! > 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
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
              Icons.history,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No activities yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent activities will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('hh:mm a').format(dateTime);
    }
  }
}

// Activity model
class Activity {
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;
  final Color iconColor;
  final double? amount;

  Activity({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
    this.amount,
  });
}

// Activity types
enum ActivityType {
  login,
  rideBooked,
  rideCompleted,
  rideCancelled,
  payment,
  walletRecharge,
  profileUpdated,
  passwordChanged,
  savedPlace,
}
