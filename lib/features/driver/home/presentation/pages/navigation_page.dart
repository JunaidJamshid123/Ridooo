import 'package:flutter/material.dart';

/// Navigation page for driver to navigate to pickup/dropoff
class DriverNavigationPage extends StatefulWidget {
  final String rideId;
  final bool isPickup; // true = navigating to pickup, false = to dropoff

  const DriverNavigationPage({
    super.key,
    required this.rideId,
    this.isPickup = true,
  });

  @override
  State<DriverNavigationPage> createState() => _DriverNavigationPageState();
}

class _DriverNavigationPageState extends State<DriverNavigationPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO: Implement turn-by-turn navigation
    // - Full screen Google Map
    // - Route overlay
    // - Current location tracking
    // - Distance and ETA to destination
    // - User/Pickup info card
    // - Call/Chat buttons
    // - Arrive/Start Ride button (at pickup)
    // - Complete Ride button (at dropoff)

    return Scaffold(
      body: Stack(
        children: [
          // TODO: Full screen map with navigation
          Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Text('Navigation Map Placeholder'),
            ),
          ),

          // Top bar with back button and destination
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isPickup ? 'Pickup Location' : 'Dropoff Location',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Text(
                          'Loading address...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  // TODO: ETA display
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('--', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('min'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom action panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User info row
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Name',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('★ 4.8'),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () {
                          // TODO: Call user
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat),
                        onPressed: () {
                          // TODO: Chat with user
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Handle action (arrive/start/complete)
                      },
                      child: Text(
                        widget.isPickup ? 'ARRIVED AT PICKUP' : 'COMPLETE RIDE',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
