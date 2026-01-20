import 'package:flutter/material.dart';

/// Help & Support page
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick actions
          _buildQuickActions(context),
          const SizedBox(height: 24),
          
          // FAQ section
          _buildSectionHeader('Frequently Asked Questions'),
          const SizedBox(height: 12),
          _buildFAQItem(
            context,
            question: 'How do I book a ride?',
            answer: 'Open the app, enter your pickup and destination locations, select your vehicle type, and tap "Confirm Ride" to book.',
          ),
          _buildFAQItem(
            context,
            question: 'What payment methods are accepted?',
            answer: 'We accept cash, JazzCash, EasyPaisa, and credit/debit cards. You can manage your payment methods in the Payment section.',
          ),
          _buildFAQItem(
            context,
            question: 'How do I cancel a ride?',
            answer: 'You can cancel a ride before the driver arrives by tapping "Cancel Ride" on the ride tracking screen. Note that cancellation fees may apply.',
          ),
          _buildFAQItem(
            context,
            question: 'What if I left something in the vehicle?',
            answer: 'Go to your ride history, select the ride, and tap "I lost something". This will help you contact the driver directly.',
          ),
          _buildFAQItem(
            context,
            question: 'How do I report an issue with a driver?',
            answer: 'After your ride, go to your ride history, select the ride, and tap "Report Issue". You can describe the problem and our support team will help.',
          ),
          
          const SizedBox(height: 24),
          
          // My tickets section
          _buildSectionHeader('My Support Tickets'),
          const SizedBox(height: 12),
          _buildTicketItem(
            context,
            subject: 'Payment not received',
            status: 'in_progress',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          _buildTicketItem(
            context,
            subject: 'Driver behavior complaint',
            status: 'resolved',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          
          const SizedBox(height: 24),
          
          // Contact section
          _buildSectionHeader('Contact Us'),
          const SizedBox(height: 12),
          _buildContactItem(
            context,
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'support@ridooo.com',
            onTap: () {
              // TODO: Open email client
            },
          ),
          _buildContactItem(
            context,
            icon: Icons.phone,
            title: 'Phone Support',
            subtitle: '+92 42 1234567',
            onTap: () {
              // TODO: Open phone dialer
            },
          ),
          _buildContactItem(
            context,
            icon: Icons.chat,
            title: 'Live Chat',
            subtitle: 'Chat with our support team',
            onTap: () {
              // TODO: Open live chat
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create ticket page
        },
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.directions_car,
            label: 'Ride Issue',
            onTap: () {
              // TODO: Create ride issue ticket
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.payment,
            label: 'Payment',
            onTap: () {
              // TODO: Create payment ticket
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.person,
            label: 'Account',
            onTap: () {
              // TODO: Create account ticket
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketItem(
    BuildContext context, {
    required String subject,
    required String status,
    required DateTime createdAt,
  }) {
    Color statusColor;
    String statusText;

    switch (status) {
      case 'open':
        statusColor = Colors.blue;
        statusText = 'Open';
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusText = 'In Progress';
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusText = 'Resolved';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Closed';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          // TODO: Navigate to ticket details
        },
        title: Text(subject),
        subtitle: Text(
          'Created ${_formatDate(createdAt)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
