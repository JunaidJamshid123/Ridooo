import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../user/booking/domain/entities/ride.dart';
import '../../../../user/booking/domain/entities/driver_offer.dart';

abstract class DriverRidesRepository {
  /// Get nearby ride requests that are searching for drivers
  Future<Either<Failure, List<Ride>>> getNearbyRideRequests({
    required double driverLat,
    required double driverLng,
    int radiusKm = 10,
  });

  /// Create an offer/bid for a ride
  Future<Either<Failure, DriverOffer>> createOffer({
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

  /// Get driver's current active offer
  Future<Either<Failure, DriverOffer?>> getActiveOffer(String driverId);

  /// Cancel a pending offer
  Future<Either<Failure, void>> cancelOffer(String offerId);

  /// Update driver's current location
  Future<Either<Failure, void>> updateLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    double? accuracy,
    required bool isOnline,
  });

  /// Get driver's online status
  Future<Either<Failure, bool>> getOnlineStatus(String driverId);

  /// Mark driver as arrived at pickup
  Future<Either<Failure, Ride>> markArrivedAtPickup({
    required String rideId,
    required String driverId,
  });

  /// Cancel ride (by driver)
  Future<Either<Failure, Ride>> cancelRide({
    required String rideId,
    required String driverId,
    String? reason,
  });

  /// Get driver's active ride
  Future<Either<Failure, Ride?>> getActiveRide(String driverId);

  /// Get ride details by ID
  Future<Either<Failure, Ride>> getRideById(String rideId);

  /// Verify OTP and start the trip
  Future<Either<Failure, Ride>> verifyOtpAndStartTrip({
    required String rideId,
    required String otp,
  });
}
