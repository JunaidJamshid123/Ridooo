import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utility functions for home page
class HomePageUtils {
  /// Calculate distance between two coordinates in meters
  static double calculateDistance(LatLng pos1, LatLng pos2) {
    const double earthRadius = 6371000; // meters
    final lat1 = pos1.latitude * Math.pi / 180;
    final lat2 = pos2.latitude * Math.pi / 180;
    final dLat = (pos2.latitude - pos1.latitude) * Math.pi / 180;
    final dLon = (pos2.longitude - pos1.longitude) * Math.pi / 180;

    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1) *
            Math.cos(lat2) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);
    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Get screen position for a location (simple approximation)
  static Offset getScreenPosition(LatLng location, Size screenSize) {
    return Offset(screenSize.width / 2, screenSize.height / 2.5);
  }

  /// Create bounds from two locations
  static LatLngBounds createBounds(LatLng pos1, LatLng pos2) {
    return LatLngBounds(
      southwest: LatLng(
        pos1.latitude < pos2.latitude ? pos1.latitude : pos2.latitude,
        pos1.longitude < pos2.longitude ? pos1.longitude : pos2.longitude,
      ),
      northeast: LatLng(
        pos1.latitude > pos2.latitude ? pos1.latitude : pos2.latitude,
        pos1.longitude > pos2.longitude ? pos1.longitude : pos2.longitude,
      ),
    );
  }
}
