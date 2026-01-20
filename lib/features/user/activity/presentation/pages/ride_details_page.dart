import 'package:flutter/material.dart';

/// Ride details page showing full information about a specific ride
class RideDetailsPage extends StatelessWidget {
  final String rideId;

  const RideDetailsPage({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement ride details UI
    // - Static map with route
    // - Driver info (with rating)
    // - Pickup and dropoff addresses
    // - Date and time
    // - Distance and duration
    // - Payment details
    // - Actions: Re-book, Report issue, Get receipt

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              // TODO: Show/download receipt
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Ride Details Page - TODO'),
      ),
    );
  }
}
