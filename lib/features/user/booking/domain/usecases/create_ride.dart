import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/ride.dart';
import '../repositories/booking_repository.dart';

/// Use case to create a new ride
class CreateRide {
  final BookingRepository repository;

  CreateRide(this.repository);

  Future<Either<Failure, Ride>> call(CreateRideParams params) {
    return repository.createRide(
      pickupLat: params.pickupLat,
      pickupLng: params.pickupLng,
      pickupAddress: params.pickupAddress,
      dropoffLat: params.dropoffLat,
      dropoffLng: params.dropoffLng,
      dropoffAddress: params.dropoffAddress,
      vehicleType: params.vehicleType,
      estimatedFare: params.estimatedFare,
      offeredPrice: params.offeredPrice,
      distanceKm: params.distanceKm,
      estimatedDurationMinutes: params.estimatedDurationMinutes,
      paymentMethod: params.paymentMethod,
    );
  }
}

class CreateRideParams {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final String vehicleType;
  final double estimatedFare;
  final double? offeredPrice;
  final double distanceKm;
  final int estimatedDurationMinutes;
  final String paymentMethod;

  CreateRideParams({
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.vehicleType,
    required this.estimatedFare,
    this.offeredPrice,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.paymentMethod,
  });
}
