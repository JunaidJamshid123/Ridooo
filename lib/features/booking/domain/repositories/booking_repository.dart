import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ride.dart';

abstract class BookingRepository {
  Future<Either<Failure, Ride>> createRide({
    required String pickupLocation,
    required String dropoffLocation,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required String vehicleType,
  });
  
  Future<Either<Failure, List<Ride>>> getUserRides(String userId);
  
  Future<Either<Failure, Ride>> getRideById(String rideId);
  
  Future<Either<Failure, void>> cancelRide(String rideId);
}
