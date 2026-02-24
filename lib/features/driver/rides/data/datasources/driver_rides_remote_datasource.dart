import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../user/booking/data/models/ride_model.dart';
import '../../../../user/booking/data/models/driver_offer_model.dart';

abstract class DriverRidesRemoteDataSource {
  /// Get nearby available ride requests
  Future<List<RideModel>> getNearbyRideRequests({
    required double driverLat,
    required double driverLng,
    required int radiusKm,
  });

  /// Create an offer for a ride
  Future<DriverOfferModel> createOffer({
    required String rideId,
    required String driverId,
    required String driverName,
    String? driverPhone,
    String? driverPhoto,
    required double driverRating,
    required int driverTotalRides,
    required String vehicleModel,
    String? vehicleColor,
    required String vehiclePlate,
    required double offeredPrice,
    int? estimatedArrivalMin,
    String? message,
  });

  /// Get driver's active offer
  Future<DriverOfferModel?> getActiveOffer(String driverId);

  /// Cancel an offer
  Future<void> cancelOffer(String offerId);

  /// Update driver location
  Future<void> updateLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    double? accuracy,
    required bool isOnline,
  });

  /// Get driver's online status
  Future<bool> getOnlineStatus(String driverId);

  /// Mark driver as arrived at pickup
  Future<RideModel> markArrivedAtPickup({
    required String rideId,
    required String driverId,
  });

  /// Cancel ride (by driver)
  Future<RideModel> cancelRide({
    required String rideId,
    required String driverId,
    String? reason,
  });

  /// Get driver's active ride
  Future<RideModel?> getActiveRide(String driverId);

  /// Get ride by ID
  Future<RideModel> getRideById(String rideId);

  /// Verify OTP and start the trip
  Future<RideModel> verifyOtpAndStartTrip({
    required String rideId,
    required String otp,
  });

  /// Start the trip (simplified, no OTP)
  Future<RideModel> startTrip({required String rideId});

  /// Complete the trip
  Future<RideModel> completeTrip({required String rideId});
}

class DriverRidesRemoteDataSourceImpl implements DriverRidesRemoteDataSource {
  final SupabaseClient supabase;

  DriverRidesRemoteDataSourceImpl({required this.supabase});

  @override
  Future<List<RideModel>> getNearbyRideRequests({
    required double driverLat,
    required double driverLng,
    required int radiusKm,
  }) async {
    try {
      // Get rides that are in 'searching' status
      final response = await supabase
          .from(ApiConstants.ridesTable)
          .select()
          .eq('status', 'searching')
          .order('created_at', ascending: false)
          .limit(20);

      // Get unique user IDs and fetch user info in batch
      final ridesList = (response as List).cast<Map<String, dynamic>>();
      final userIds = ridesList
          .map((r) => r['user_id'] as String)
          .toSet()
          .toList();
      
      Map<String, Map<String, dynamic>> usersMap = {};
      if (userIds.isNotEmpty) {
        final usersResponse = await supabase
            .from('users')
            .select('id, name, phone_number, profile_image')
            .inFilter('id', userIds);
        
        for (final user in (usersResponse as List).cast<Map<String, dynamic>>()) {
          usersMap[user['id'] as String] = user;
        }
      }
      
      // Merge user data into rides
      final ridesWithUsers = ridesList.map((ride) {
        final userId = ride['user_id'] as String;
        final userData = usersMap[userId];
        return <String, dynamic>{
          ...ride,
          'user': userData,
        };
      }).toList();

      final rides = ridesWithUsers.map((json) => RideModel.fromJson(json)).toList();

      // Filter by distance (simple approach - could use PostGIS functions for better performance)
      final nearbyRides =
          rides.where((ride) {
            final distance = _calculateDistance(
              driverLat,
              driverLng,
              ride.pickupLatitude,
              ride.pickupLongitude,
            );
            return distance <= radiusKm;
          }).toList();

      return nearbyRides;
    } catch (e) {
      throw ServerException('Failed to fetch nearby rides: $e');
    }
  }

  @override
  Future<DriverOfferModel> createOffer({
    required String rideId,
    required String driverId,
    required String driverName,
    String? driverPhone,
    String? driverPhoto,
    required double driverRating,
    required int driverTotalRides,
    required String vehicleModel,
    String? vehicleColor,
    required String vehiclePlate,
    required double offeredPrice,
    int? estimatedArrivalMin,
    String? message,
  }) async {
    try {
      final offerData = DriverOfferModel.toCreateJson(
        rideId: rideId,
        driverId: driverId,
        driverName: driverName,
        driverPhone: driverPhone,
        driverPhoto: driverPhoto,
        driverRating: driverRating,
        driverTotalRides: driverTotalRides,
        vehicleModel: vehicleModel,
        vehicleColor: vehicleColor,
        vehiclePlate: vehiclePlate,
        offeredPrice: offeredPrice,
        estimatedArrivalMin: estimatedArrivalMin,
        message: message,
      );

      final response =
          await supabase
              .from(ApiConstants.driverOffersTable)
              .insert(offerData)
              .select()
              .single();

      return DriverOfferModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw ServerException('You have already sent an offer for this ride');
      }
      throw ServerException('Failed to create offer: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to create offer: $e');
    }
  }

  @override
  Future<DriverOfferModel?> getActiveOffer(String driverId) async {
    try {
      // Get the most recent offer that is either pending or accepted
      final response =
          await supabase
              .from(ApiConstants.driverOffersTable)
              .select()
              .eq('driver_id', driverId)
              .inFilter('status', ['pending', 'accepted'])
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (response == null) return null;

      return DriverOfferModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch active offer: $e');
    }
  }

  @override
  Future<void> cancelOffer(String offerId) async {
    try {
      await supabase
          .from(ApiConstants.driverOffersTable)
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', offerId)
          .eq('status', 'pending');
    } catch (e) {
      throw ServerException('Failed to cancel offer: $e');
    }
  }

  @override
  Future<void> updateLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    double? accuracy,
    required bool isOnline,
  }) async {
    try {
      final locationData = {
        'driver_id': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'accuracy': accuracy,
        'is_online': isOnline,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Use upsert with onConflict to handle existing records
      await supabase
          .from(ApiConstants.driverLocationsTable)
          .upsert(locationData, onConflict: 'driver_id');
    } catch (e) {
      throw ServerException('Failed to update location: $e');
    }
  }

  @override
  Future<bool> getOnlineStatus(String driverId) async {
    try {
      final response =
          await supabase
              .from(ApiConstants.driverLocationsTable)
              .select('is_online')
              .eq('driver_id', driverId)
              .maybeSingle();

      if (response == null) return false;

      return response['is_online'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<RideModel> markArrivedAtPickup({
    required String rideId,
    required String driverId,
  }) async {
    try {
      // Generate a 4-digit OTP
      final otp = (1000 + Random().nextInt(9000)).toString();

      final response =
          await supabase
              .from(ApiConstants.ridesTable)
              .update({
                'status': 'arrived',
                'otp': otp,
                'arrived_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', rideId)
              .eq('driver_id', driverId)
              .eq('status', 'accepted')
              .select()
              .single();

      return RideModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to mark arrival: $e');
    }
  }

  @override
  Future<RideModel> cancelRide({
    required String rideId,
    required String driverId,
    String? reason,
  }) async {
    try {
      final response =
          await supabase
              .from(ApiConstants.ridesTable)
              .update({
                'status': 'cancelled',
                'cancellation_reason': reason ?? 'Cancelled by driver',
                'cancelled_by': 'driver',
                'cancelled_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', rideId)
              .eq('driver_id', driverId)
              .inFilter('status', ['accepted', 'arrived'])
              .select()
              .single();

      return RideModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to cancel ride: $e');
    }
  }

  @override
  Future<RideModel?> getActiveRide(String driverId) async {
    try {
      final response =
          await supabase
              .from(ApiConstants.ridesTable)
              .select()
              .eq('driver_id', driverId)
              .inFilter('status', ['accepted', 'arrived', 'in_progress'])
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (response == null) return null;

      // Fetch user info separately
      final userId = response['user_id'] as String;
      final userResponse = await supabase
          .from('users')
          .select('id, name, phone_number, profile_image')
          .eq('id', userId)
          .maybeSingle();
      
      final rideWithUser = {
        ...response,
        'user': userResponse,
      };

      return RideModel.fromJson(rideWithUser);
    } catch (e) {
      throw ServerException('Failed to get active ride: $e');
    }
  }

  @override
  Future<RideModel> getRideById(String rideId) async {
    try {
      final response =
          await supabase
              .from(ApiConstants.ridesTable)
              .select()
              .eq('id', rideId)
              .single();

      // Fetch user info separately
      final userId = response['user_id'] as String;
      final userResponse = await supabase
          .from('users')
          .select('id, name, phone_number, profile_image')
          .eq('id', userId)
          .maybeSingle();
      
      final rideWithUser = {
        ...response,
        'user': userResponse,
      };

      return RideModel.fromJson(rideWithUser);
    } catch (e) {
      throw ServerException('Failed to get ride: $e');
    }
  }

  @override
  Future<RideModel> verifyOtpAndStartTrip({
    required String rideId,
    required String otp,
  }) async {
    try {
      // Verify OTP matches
      final rideCheck =
          await supabase
              .from(ApiConstants.ridesTable)
              .select('otp')
              .eq('id', rideId)
              .single();

      if (rideCheck['otp'] != otp) {
        throw ServerException('Invalid OTP');
      }

      // Update ride status to in_progress
      final response =
          await supabase
              .from(ApiConstants.ridesTable)
              .update({
                'status': 'in_progress',
                'started_at': DateTime.now().toIso8601String(),
              })
              .eq('id', rideId)
              .select()
              .single();

      // Fetch user info separately
      final userId = response['user_id'] as String;
      final userResponse = await supabase
          .from('users')
          .select('id, name, phone_number, profile_image')
          .eq('id', userId)
          .maybeSingle();
      
      final rideWithUser = {
        ...response,
        'user': userResponse,
      };

      return RideModel.fromJson(rideWithUser);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to start trip: $e');
    }
  }

  @override
  Future<RideModel> startTrip({required String rideId}) async {
    try {
      // Update ride status to in_progress
      final response =
          await supabase
              .from(ApiConstants.ridesTable)
              .update({
                'status': 'in_progress',
                'started_at': DateTime.now().toIso8601String(),
              })
              .eq('id', rideId)
              .select()
              .single();

      // Fetch user info separately
      final userId = response['user_id'] as String;
      final userResponse = await supabase
          .from('users')
          .select('id, name, phone_number, profile_image')
          .eq('id', userId)
          .maybeSingle();
      
      final rideWithUser = {
        ...response,
        'user': userResponse,
      };

      return RideModel.fromJson(rideWithUser);
    } catch (e) {
      throw ServerException('Failed to start trip: $e');
    }
  }

  @override
  Future<RideModel> completeTrip({required String rideId}) async {
    try {
      // Get the accepted offer's price for this ride
      final offerResponse = await supabase
          .from('driver_offers')
          .select('offered_price')
          .eq('ride_id', rideId)
          .eq('status', 'accepted')
          .maybeSingle();
      
      final finalFare = offerResponse?['offered_price'] as num?;
      
      // Update ride status to completed with final fare
      final updateData = <String, dynamic>{
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      };
      
      if (finalFare != null) {
        updateData['final_fare'] = finalFare;
        updateData['actual_fare'] = finalFare;
      }
      
      final response =
          await supabase
              .from(ApiConstants.ridesTable)
              .update(updateData)
              .eq('id', rideId)
              .select()
              .single();

      // Fetch user info separately
      final userId = response['user_id'] as String;
      final userResponse = await supabase
          .from('users')
          .select('id, name, phone_number, profile_image')
          .eq('id', userId)
          .maybeSingle();
      
      final rideWithUser = {
        ...response,
        'user': userResponse,
      };

      return RideModel.fromJson(rideWithUser);
    } catch (e) {
      throw ServerException('Failed to complete trip: $e');
    }
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.14159265359 / 180);
  }
}
