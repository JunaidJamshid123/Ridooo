import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/driver.dart';
import '../entities/ride_request.dart';

/// Repository interface for driver operations
abstract class DriverRepository {
  /// Get driver profile
  Future<Either<Failure, Driver>> getDriverProfile();

  /// Update driver online status
  Future<Either<Failure, Driver>> setOnlineStatus(bool isOnline);

  /// Update driver location
  Future<Either<Failure, void>> updateLocation({
    required double latitude,
    required double longitude,
  });

  /// Get nearby ride requests
  Future<Either<Failure, List<RideRequest>>> getNearbyRideRequests();

  /// Make an offer on a ride request
  Future<Either<Failure, void>> makeOffer({
    required String rideId,
    required double offeredPrice,
    int? etaMinutes,
    String? message,
  });

  /// Cancel an offer
  Future<Either<Failure, void>> cancelOffer(String offerId);

  /// Get current active ride (accepted)
  Future<Either<Failure, Map<String, dynamic>?>> getActiveRide();

  /// Update ride status (arrived, started, completed)
  Future<Either<Failure, void>> updateRideStatus({
    required String rideId,
    required String status,
  });

  /// Verify OTP and start ride
  Future<Either<Failure, bool>> verifyOtpAndStartRide({
    required String rideId,
    required String otp,
  });

  /// Complete ride
  Future<Either<Failure, void>> completeRide({
    required String rideId,
    required double actualFare,
  });

  /// Stream of ride requests
  Stream<RideRequest> watchRideRequests();

  /// Stream of current ride updates
  Stream<Map<String, dynamic>> watchActiveRide(String rideId);
}
