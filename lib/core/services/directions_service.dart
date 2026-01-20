import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class DirectionsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static String get _apiKey => EnvConfig.googleMapsApiKey;

  /// Get directions between two points
  /// Returns polyline points for drawing route on map
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    TravelMode travelMode = TravelMode.driving,
    bool optimizeRoute = false,
  }) async {
    try {
      final String url = '$_baseUrl?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=${travelMode.name}'
          '${optimizeRoute ? '&alternatives=true' : ''}'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          // If alternatives requested and available, return the shortest route
          if (optimizeRoute && data['routes'] != null && (data['routes'] as List).length > 1) {
            final routes = (data['routes'] as List).map((r) => DirectionsResult.fromJsonRoute(r)).toList();
            routes.sort((a, b) {
              final aDistance = int.tryParse(a.distanceValue ?? '0') ?? 0;
              final bDistance = int.tryParse(b.distanceValue ?? '0') ?? 0;
              return aDistance.compareTo(bDistance);
            });
            return routes.first;
          }
          return DirectionsResult.fromJson(data);
        } else {
          print('Directions API error: ${data['status']}');
          return null;
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  /// Get multiple route alternatives
  Future<List<DirectionsResult>> getAlternativeRoutes({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final String url = '$_baseUrl?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&alternatives=true'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List routes = data['routes'] as List;
          return routes.map((route) {
            return DirectionsResult.fromRoute(route);
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting alternative routes: $e');
      return [];
    }
  }
}

enum TravelMode {
  driving,
  walking,
  bicycling,
  transit,
}

class DirectionsResult {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final String distanceValue; // in meters
  final String durationValue; // in seconds
  final LatLng startLocation;
  final LatLng endLocation;
  final String summary;

  DirectionsResult({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
    required this.startLocation,
    required this.endLocation,
    required this.summary,
  });

  factory DirectionsResult.fromJson(Map<String, dynamic> json) {
    final route = json['routes'][0];
    return DirectionsResult.fromJsonRoute(route);
  }

  factory DirectionsResult.fromJsonRoute(Map<String, dynamic> route) {
    final leg = route['legs'][0];
    final polylinePoints = _decodePolyline(route['overview_polyline']['points']);

    return DirectionsResult(
      polylinePoints: polylinePoints,
      distance: leg['distance']['text'],
      duration: leg['duration']['text'],
      distanceValue: leg['distance']['value'].toString(),
      durationValue: leg['duration']['value'].toString(),
      startLocation: LatLng(
        leg['start_location']['lat'],
        leg['start_location']['lng'],
      ),
      endLocation: LatLng(
        leg['end_location']['lat'],
        leg['end_location']['lng'],
      ),
      summary: route['summary'] ?? 'Recommended route',
    );
  }

  factory DirectionsResult.fromRoute(Map<String, dynamic> route) {
    return DirectionsResult.fromJsonRoute(route);
  }

  /// Decode Google's encoded polyline
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Calculate estimated fare based on distance (simple example)
  double calculateFare({
    double baseFare = 2.50,
    double perKmRate = 1.50,
    double perMinuteRate = 0.25,
  }) {
    final distanceKm = double.parse(distanceValue) / 1000;
    final durationMin = double.parse(durationValue) / 60;
    
    return baseFare + (distanceKm * perKmRate) + (durationMin * perMinuteRate);
  }
}
