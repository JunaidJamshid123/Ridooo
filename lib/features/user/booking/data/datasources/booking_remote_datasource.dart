import '../models/ride_model.dart';
import '../models/driver_offer_model.dart';

/// Remote data source interface for booking operations
abstract class BookingRemoteDataSource {
  /// Create a new ride
  Future<RideModel> createRide(Map<String, dynamic> rideData);

  /// Get ride by ID
  Future<RideModel> getRideById(String rideId);

  /// Get user's active ride
  Future<RideModel?> getActiveRide(String userId);

  /// Get user's ride history
  Future<List<RideModel>> getRideHistory({
    required String userId,
    int page = 1,
    int limit = 20,
  });

  /// Get driver offers for a ride
  Future<List<DriverOfferModel>> getDriverOffers(String rideId);

  /// Accept a driver offer
  Future<RideModel> acceptDriverOffer({
    required String rideId,
    required String offerId,
  });

  /// Cancel a ride
  Future<RideModel> cancelRide({
    required String rideId,
    required String userId,
    String? reason,
  });

  /// Rate a ride
  Future<void> rateRide({
    required String rideId,
    required String driverId,
    required String userId,
    required int rating,
    String? review,
  });

  /// Apply promo code
  Future<double> applyPromoCode({
    required String rideId,
    required String promoCode,
    required String userId,
  });

  /// Subscribe to ride updates
  Stream<RideModel> watchRide(String rideId);

  /// Subscribe to driver offers
  Stream<DriverOfferModel> watchDriverOffers(String rideId);

  /// Subscribe to driver location
  Stream<Map<String, double>> watchDriverLocation(String driverId);
}
