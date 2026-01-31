import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/ride.dart';
import '../entities/driver_offer.dart';

/// Repository interface for booking/ride operations
abstract class BookingRepository {
  /// Create a new ride request
  Future<Either<Failure, Ride>> createRide({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String vehicleType,
    required double estimatedFare,
    double? offeredPrice,
    required double distanceKm,
    required int estimatedDurationMinutes,
    required String paymentMethod,
  });

  /// Get ride by ID
  Future<Either<Failure, Ride>> getRideById(String rideId);

  /// Get user's active ride (if any)
  Future<Either<Failure, Ride?>> getActiveRide();

  /// Get user's ride history
  Future<Either<Failure, List<Ride>>> getRideHistory({
    int page = 1,
    int limit = 20,
  });

  /// Get driver offers for a ride
  Future<Either<Failure, List<DriverOffer>>> getDriverOffers(String rideId);

  /// Accept a driver offer
  Future<Either<Failure, Ride>> acceptDriverOffer({
    required String rideId,
    required String offerId,
  });

  /// Reject a driver offer
  Future<Either<Failure, void>> rejectDriverOffer({
    required String rideId,
    required String offerId,
  });

  /// Cancel a ride
  Future<Either<Failure, Ride>> cancelRide({
    required String rideId,
    String? reason,
  });

  /// Rate a completed ride
  Future<Either<Failure, void>> rateRide({
    required String rideId,
    required int rating,
    String? review,
  });

  /// Apply promo code to ride
  Future<Either<Failure, double>> applyPromoCode({
    required String rideId,
    required String promoCode,
  });

  /// Stream of ride updates
  Stream<Ride> watchRide(String rideId);

  /// Stream of driver offers for a ride
  Stream<DriverOffer> watchDriverOffers(String rideId);

  /// Stream of driver location during ride
  Stream<Map<String, double>> watchDriverLocation(String driverId);
}
