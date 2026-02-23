import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api_constants.dart';

/// Service for handling ratings operations with Supabase
class RatingService {
  final SupabaseClient _supabase;

  RatingService({required SupabaseClient supabaseClient})
      : _supabase = supabaseClient;

  /// Submit a rating for a driver after a ride
  Future<Map<String, dynamic>> submitRating({
    required String rideId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    String? comment,
    List<String>? tags,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.ratingsTable)
          .insert({
            'ride_id': rideId,
            'reviewer_id': reviewerId,
            'reviewee_id': revieweeId,
            'rating': rating,
            'comment': comment,
            'tags': tags,
          })
          .select()
          .single();

      // Update driver's average rating (handled by database trigger)
      // But we can also update it manually for immediate effect
      await _updateDriverAverageRating(revieweeId);

      return response;
    } catch (e) {
      print('Error submitting rating: $e');
      rethrow;
    }
  }

  /// Get driver's rating statistics
  Future<Map<String, dynamic>> getDriverRatingStats(String driverId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.ratingsTable)
          .select()
          .eq('reviewee_id', driverId);

      final ratings = response as List;
      
      if (ratings.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_ratings': 0,
          'rating_distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      // Calculate statistics
      double totalRating = 0;
      final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      
      for (final r in ratings) {
        final rating = r['rating'] as int;
        totalRating += rating;
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }

      return {
        'average_rating': totalRating / ratings.length,
        'total_ratings': ratings.length,
        'rating_distribution': distribution,
      };
    } catch (e) {
      print('Error getting driver rating stats: $e');
      rethrow;
    }
  }

  /// Get ratings for a specific driver
  Future<List<Map<String, dynamic>>> getDriverRatings(
    String driverId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from(ApiConstants.ratingsTable)
          .select('''
            *,
            reviewer:users!ratings_reviewer_id_fkey(name, profile_image)
          ''')
          .eq('reviewee_id', driverId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting driver ratings: $e');
      rethrow;
    }
  }

  /// Check if user has already rated a ride
  Future<bool> hasUserRatedRide(String rideId, String reviewerId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.ratingsTable)
          .select('id')
          .eq('ride_id', rideId)
          .eq('reviewer_id', reviewerId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking if user rated ride: $e');
      return false;
    }
  }

  /// Get rating for a specific ride
  Future<Map<String, dynamic>?> getRideRating(String rideId, String reviewerId) async {
    try {
      final response = await _supabase
          .from(ApiConstants.ratingsTable)
          .select()
          .eq('ride_id', rideId)
          .eq('reviewer_id', reviewerId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting ride rating: $e');
      return null;
    }
  }

  /// Update driver's average rating in the drivers table
  Future<void> _updateDriverAverageRating(String driverId) async {
    try {
      // Calculate new average from all ratings
      final stats = await getDriverRatingStats(driverId);
      final averageRating = stats['average_rating'] as double;
      final totalRatings = stats['total_ratings'] as int;

      // Update driver's rating
      await _supabase
          .from(ApiConstants.driversTable)
          .update({
            'rating': averageRating,
            'total_rides': totalRatings, // This might not be accurate, just for demo
          })
          .eq('id', driverId);
    } catch (e) {
      print('Error updating driver average rating: $e');
      // Don't throw - this is a secondary operation
    }
  }
}
