import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class PlacesService {
  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _geocodingBaseUrl = 'https://maps.googleapis.com/maps/api/geocode';
  static String get _apiKey => EnvConfig.googleMapsApiKey;

  /// Search for places with autocomplete
  Future<List<PlacePrediction>> getPlacePredictions({
    required String input,
    LatLng? location,
    int radius = 50000, // 50km
  }) async {
    try {
      String url = '$_placesBaseUrl/autocomplete/json?'
          'input=${Uri.encodeComponent(input)}'
          '&key=$_apiKey';

      if (location != null) {
        url += '&location=${location.latitude},${location.longitude}'
            '&radius=$radius';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List predictions = data['predictions'];
          return predictions.map((p) => PlacePrediction.fromJson(p)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting place predictions: $e');
      return [];
    }
  }

  /// Get place details including coordinates
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final String url = '$_placesBaseUrl/details/json?'
          'place_id=$placeId'
          '&fields=name,formatted_address,geometry,types'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  /// Reverse geocoding - Get address from coordinates
  Future<String?> getAddressFromCoordinates(LatLng location) async {
    try {
      final String url = '$_geocodingBaseUrl/json?'
          'latlng=${location.latitude},${location.longitude}'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
      return null;
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }

  /// Forward geocoding - Get coordinates from address
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      final String url = '$_geocodingBaseUrl/json?'
          'address=${Uri.encodeComponent(address)}'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      return null;
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }

  /// Search for nearby places (e.g., nearby drivers, parking, etc.)
  Future<List<NearbyPlace>> searchNearbyPlaces({
    required LatLng location,
    required String type,
    int radius = 1000, // 1km
  }) async {
    try {
      final String url = '$_placesBaseUrl/nearbysearch/json?'
          'location=${location.latitude},${location.longitude}'
          '&radius=$radius'
          '&type=$type'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List results = data['results'];
          return results.map((p) => NearbyPlace.fromJson(p)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching nearby places: $e');
      return [];
    }
  }
}

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'],
      description: json['description'],
      mainText: json['structured_formatting']['main_text'],
      secondaryText: json['structured_formatting']['secondary_text'] ?? '',
    );
  }
}

class PlaceDetails {
  final String name;
  final String formattedAddress;
  final LatLng location;
  final List<String> types;

  PlaceDetails({
    required this.name,
    required this.formattedAddress,
    required this.location,
    required this.types,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']['location'];
    return PlaceDetails(
      name: json['name'] ?? '',
      formattedAddress: json['formatted_address'] ?? '',
      location: LatLng(geometry['lat'], geometry['lng']),
      types: List<String>.from(json['types'] ?? []),
    );
  }
}

class NearbyPlace {
  final String placeId;
  final String name;
  final LatLng location;
  final double? rating;
  final String vicinity;

  NearbyPlace({
    required this.placeId,
    required this.name,
    required this.location,
    this.rating,
    required this.vicinity,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']['location'];
    return NearbyPlace(
      placeId: json['place_id'],
      name: json['name'],
      location: LatLng(geometry['lat'], geometry['lng']),
      rating: json['rating']?.toDouble(),
      vicinity: json['vicinity'] ?? '',
    );
  }
}
