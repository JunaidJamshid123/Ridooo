import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ride.dart';
import '../repositories/booking_repository.dart';

class CreateRideUseCase {
  final BookingRepository repository;

  CreateRideUseCase(this.repository);

  Future<Either<Failure, Ride>> call({
    required String pickupLocation,
    required String dropoffLocation,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String vehicleType,
  }) async {
    return await repository.createRide(
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      dropoffLatitude: dropoffLatitude,
      dropoffLongitude: dropoffLongitude,
      vehicleType: vehicleType,
    );
  }
}
