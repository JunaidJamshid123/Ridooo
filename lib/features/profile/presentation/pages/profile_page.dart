import 'package:flutter/material.dart';

/// User profile page showing account info and options
class ProfilePage extends StatelessWidget {
  final bool isDriver;

  const ProfilePage({
    super.key,
    this.isDriver = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to settings
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            
            // Profile menu items
            _buildMenuSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile photo
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green.shade100,
                child: Text(
                  'JD',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // TODO: Change profile photo
                    },
                    icon: const Icon(Icons.camera_alt, size: 16),
                    color: Colors.white,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name and email
          const Text(
            'John Doe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+92 300 1234567',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Edit profile button
          OutlinedButton(
            onPressed: () {
              // TODO: Navigate to edit profile
            },
            child: const Text('Edit Profile'),
          ),
          
          // Driver rating (only for drivers)
          if (isDriver) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                const Text(
                  '4.8',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(150 rides)',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        if (!isDriver)
          _buildMenuItem(
            icon: Icons.bookmark,
            title: 'Saved Places',
            onTap: () {
              // TODO: Navigate to saved places
            },
          ),
        if (isDriver)
          _buildMenuItem(
            icon: Icons.description,
            title: 'Documents',
            onTap: () {
              // TODO: Navigate to documents
            },
          ),
        _buildMenuItem(
          icon: Icons.history,
          title: 'Ride History',
          onTap: () {
            // TODO: Navigate to ride history
          },
        ),
        if (!isDriver)
          _buildMenuItem(
            icon: Icons.account_balance_wallet,
            title: 'Payment Methods',
            onTap: () {
              // TODO: Navigate to payment methods
            },
          ),
        _buildMenuItem(
          icon: Icons.notifications,
          title: 'Notifications',
          onTap: () {
            // TODO: Navigate to notifications
          },
        ),
        _buildMenuItem(
          icon: Icons.help,
          title: 'Help & Support',
          onTap: () {
            // TODO: Navigate to support
          },
        ),
        _buildMenuItem(
          icon: Icons.info,
          title: 'About',
          onTap: () {
            // TODO: Navigate to about
          },
        ),
        const Divider(),
        _buildMenuItem(
          icon: Icons.logout,
          title: 'Log Out',
          iconColor: Colors.red,
          titleColor: Colors.red,
          onTap: () {
            // TODO: Show logout confirmation
            _showLogoutDialog(context);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    String? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade700),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      trailing: trailing != null
          ? Text(
              trailing,
              style: TextStyle(color: Colors.grey.shade600),
            )
          : Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Perform logout
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
