import 'package:flutter/material.dart';

/// Page showing a single ride request with details for driver to accept/decline
class RideRequestPage extends StatelessWidget {
  final String requestId;

  const RideRequestPage({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO: Implement ride request details
    // - User info (name, rating)
    // - Pickup and dropoff on map
    // - Distance and ETA to pickup
    // - Trip distance and estimated time
    // - User's offered price
    // - Counter-offer input
    // - Accept/Decline buttons

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Request'),
      ),
      body: const Center(
        child: Text('Ride Request Page - TODO'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Accept ride request
                  },
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
