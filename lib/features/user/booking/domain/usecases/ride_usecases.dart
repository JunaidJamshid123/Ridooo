import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/ride.dart';
import '../repositories/booking_repository.dart';

/// Use case to accept a driver's offer
class AcceptDriverOffer {
  final BookingRepository repository;

  AcceptDriverOffer(this.repository);

  Future<Either<Failure, Ride>> call({
    required String rideId,
    required String offerId,
  }) {
    return repository.acceptDriverOffer(
      rideId: rideId,
      offerId: offerId,
    );
  }
}

/// Use case to cancel a ride
class CancelRide {
  final BookingRepository repository;

  CancelRide(this.repository);

  Future<Either<Failure, Ride>> call({
    required String rideId,
    String? reason,
  }) {
    return repository.cancelRide(
      rideId: rideId,
      reason: reason,
    );
  }
}

/// Use case to rate a completed ride
class RateRide {
  final BookingRepository repository;

  RateRide(this.repository);

  Future<Either<Failure, void>> call({
    required String rideId,
    required int rating,
    String? review,
  }) {
    return repository.rateRide(
      rideId: rideId,
      rating: rating,
      review: review,
    );
  }
}

/// Use case to get ride history
class GetRideHistory {
  final BookingRepository repository;

  GetRideHistory(this.repository);

  Future<Either<Failure, List<Ride>>> call({
    int page = 1,
    int limit = 20,
  }) {
    return repository.getRideHistory(page: page, limit: limit);
  }
}

/// Use case to get active ride
class GetActiveRide {
  final BookingRepository repository;

  GetActiveRide(this.repository);

  Future<Either<Failure, Ride?>> call() {
    return repository.getActiveRide();
  }
}
