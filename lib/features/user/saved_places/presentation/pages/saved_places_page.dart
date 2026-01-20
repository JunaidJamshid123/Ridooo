import 'package:flutter/material.dart';

/// Saved places page for users
class SavedPlacesPage extends StatelessWidget {
  const SavedPlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO: Implement saved places with BLoC
    // - Home location (editable)
    // - Work location (editable)
    // - Other saved places list
    // - Add new place button

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Places'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          // Home
          _SavedPlaceTile(
            icon: Icons.home,
            title: 'Home',
            subtitle: 'Add home address',
            onTap: () {
              // TODO: Navigate to add/edit place
            },
          ),
          const Divider(),

          // Work
          _SavedPlaceTile(
            icon: Icons.work,
            title: 'Work',
            subtitle: 'Add work address',
            onTap: () {
              // TODO: Navigate to add/edit place
            },
          ),
          const Divider(),

          // Other places header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Other Places',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // TODO: List of other saved places

          // Add place button
          ListTile(
            leading: const Icon(Icons.add_location),
            title: const Text('Add New Place'),
            onTap: () {
              // TODO: Navigate to add place
            },
          ),
        ],
      ),
    );
  }
}

class _SavedPlaceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SavedPlaceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
