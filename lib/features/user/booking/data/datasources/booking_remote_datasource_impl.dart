import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../../core/constants/api_constants.dart';
import '../models/ride_model.dart';
import '../models/driver_offer_model.dart';
import 'booking_remote_datasource.dart';

/// Supabase implementation of BookingRemoteDataSource
class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final SupabaseClient supabaseClient;

  BookingRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<RideModel> createRide(Map<String, dynamic> rideData) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.ridesTable)
          .insert(rideData)
          .select()
          .single();

      return RideModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RideModel> getRideById(String rideId) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.ridesTable)
          .select()
          .eq('id', rideId)
          .single();

      return RideModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RideModel?> getActiveRide(String userId) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.ridesTable)
          .select()
          .eq('user_id', userId)
          .inFilter('status', ['searching', 'accepted', 'driver_arrived', 'in_progress'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return RideModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<RideModel>> getRideHistory({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final from = (page - 1) * limit;
      final to = from + limit - 1;

      final response = await supabaseClient
          .from(ApiConstants.ridesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(from, to);

      return (response as List)
          .map((json) => RideModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<DriverOfferModel>> getDriverOffers(String rideId) async {
    try {
      final response = await supabaseClient
          .from(ApiConstants.driverOffersTable)
          .select()
          .eq('ride_id', rideId)
          .order('offered_price', ascending: true);

      debugPrint('📦 Raw offers response: $response');
      
      final offers = (response as List)
          .map((json) {
            debugPrint('📋 Parsing offer: driver_name=${json['driver_name']}, driver_phone=${json['driver_phone']}, driver_photo=${json['driver_photo']}');
            return DriverOfferModel.fromJson(json);
          })
          .toList();
      
      return offers;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RideModel> acceptDriverOffer({
    required String rideId,
    required String offerId,
  }) async {
    try {
      // Get the offer to extract driver info
      final offerResponse = await supabaseClient
          .from(ApiConstants.driverOffersTable)
          .select()
          .eq('id', offerId)
          .single();

      final offer = DriverOfferModel.fromJson(offerResponse);

      // Update the ride with driver info and status
      final rideResponse = await supabaseClient
          .from(ApiConstants.ridesTable)
          .update({
            'driver_id': offer.driverId,
            'status': 'accepted',
            'offered_price': offer.offeredPrice,
            'accepted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', rideId)
          .select()
          .single();

      // Update the offer status to accepted
      await supabaseClient
          .from(ApiConstants.driverOffersTable)
          .update({'status': 'accepted'})
          .eq('id', offerId);

      // Reject all other offers for this ride
      await supabaseClient
          .from(ApiConstants.driverOffersTable)
          .update({'status': 'rejected'})
          .eq('ride_id', rideId)
          .neq('id', offerId);

      return RideModel.fromJson(rideResponse);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> rejectDriverOffer({
    required String rideId,
    required String offerId,
  }) async {
    try {
      await supabaseClient
          .from(ApiConstants.driverOffersTable)
          .update({'status': 'rejected'})
          .eq('id', offerId)
          .eq('ride_id', rideId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RideModel> cancelRide({
    required String rideId,
    required String userId,
    String? reason,
  }) async {
    try {
      final updateData = {
        'status': 'cancelled',
        if (reason != null) 'cancellation_reason': reason,
      };

      final response = await supabaseClient
          .from(ApiConstants.ridesTable)
          .update(updateData)
          .eq('id', rideId)
          .eq('user_id', userId)
          .select()
          .single();

      return RideModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> rateRide({
    required String rideId,
    required String driverId,
    required String userId,
    required int rating,
    String? review,
  }) async {
    try {
      // Insert rating into ratings table
      await supabaseClient.from(ApiConstants.ratingsTable).insert({
        'ride_id': rideId,
        'driver_id': driverId,
        'user_id': userId,
        'rating': rating,
        'review': review,
        'rater_type': 'user',
      });

      // Update driver's average rating
      await supabaseClient.rpc('update_driver_rating', params: {
        'driver_id_param': driverId,
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<double> applyPromoCode({
    required String rideId,
    required String promoCode,
    required String userId,
  }) async {
    try {
      final result = await supabaseClient.rpc('apply_promo_code', params: {
        'ride_id_param': rideId,
        'promo_code_param': promoCode,
        'user_id_param': userId,
      });

      return (result as num).toDouble();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<RideModel> watchRide(String rideId) {
    return supabaseClient
        .from(ApiConstants.ridesTable)
        .stream(primaryKey: ['id'])
        .eq('id', rideId)
        .map((data) => RideModel.fromJson(data.first));
  }

  @override
  Stream<DriverOfferModel> watchDriverOffers(String rideId) {
    return supabaseClient
        .from(ApiConstants.driverOffersTable)
        .stream(primaryKey: ['id'])
        .eq('ride_id', rideId)
        .map((data) => data.map((json) => DriverOfferModel.fromJson(json)))
        .expand((offers) => offers);
  }

  @override
  Stream<Map<String, double>> watchDriverLocation(String driverId) {
    return supabaseClient
        .from(ApiConstants.driverLocationsTable)
        .stream(primaryKey: ['driver_id'])
        .eq('driver_id', driverId)
        .map((data) {
          if (data.isEmpty) return <String, double>{};
          final location = data.first;
          return {
            'latitude': location['latitude'] as double,
            'longitude': location['longitude'] as double,
          };
        });
  }
}
