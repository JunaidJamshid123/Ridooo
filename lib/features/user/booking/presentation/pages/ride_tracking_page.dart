import 'package:flutter/material.dart';

/// Page for tracking active ride with driver on map
class RideTrackingPage extends StatefulWidget {
  final String rideId;

  const RideTrackingPage({super.key, required this.rideId});

  @override
  State<RideTrackingPage> createState() => _RideTrackingPageState();
}

class _RideTrackingPageState extends State<RideTrackingPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: Implement ride tracking UI
    // - Google Map with driver marker
    // - Route polyline
    // - Driver info card
    // - ETA display
    // - Cancel button (if applicable)
    // - SOS button
    // - Chat button
    // - OTP display (when driver arrives)

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Ride'),
      ),
      body: const Center(
        child: Text('Ride Tracking Page - TODO'),
      ),
    );
  }
}
