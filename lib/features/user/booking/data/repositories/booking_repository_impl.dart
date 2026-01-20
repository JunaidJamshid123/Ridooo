import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/driver_offer.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';

/// Implementation of BookingRepository
class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;
  final String userId; // Current user ID from auth

  BookingRepositoryImpl({
    required this.remoteDataSource,
    required this.userId,
  });

  @override
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
  }) async {
    try {
      final rideData = {
        'user_id': userId,
        'vehicle_type': vehicleType,
        'status': 'searching',
        'pickup_latitude': pickupLat,
        'pickup_longitude': pickupLng,
        'pickup_address': pickupAddress,
        'dropoff_latitude': dropoffLat,
        'dropoff_longitude': dropoffLng,
        'dropoff_address': dropoffAddress,
        'estimated_fare': estimatedFare,
        'offered_price': offeredPrice,
        'distance_km': distanceKm,
        'estimated_duration_minutes': estimatedDurationMinutes,
        'payment_method': paymentMethod,
        'payment_status': 'pending',
      };

      final ride = await remoteDataSource.createRide(rideData);
      return Right(ride);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ride>> getRideById(String rideId) async {
    try {
      final ride = await remoteDataSource.getRideById(rideId);
      return Right(ride);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ride?>> getActiveRide() async {
    try {
      final ride = await remoteDataSource.getActiveRide(userId);
      return Right(ride);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Ride>>> getRideHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final rides = await remoteDataSource.getRideHistory(
        userId: userId,
        page: page,
        limit: limit,
      );
      return Right(rides);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DriverOffer>>> getDriverOffers(String rideId) async {
    try {
      final offers = await remoteDataSource.getDriverOffers(rideId);
      return Right(offers);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ride>> acceptDriverOffer({
    required String rideId,
    required String offerId,
  }) async {
    try {
      final ride = await remoteDataSource.acceptDriverOffer(
        rideId: rideId,
        offerId: offerId,
      );
      return Right(ride);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ride>> cancelRide({
    required String rideId,
    String? reason,
  }) async {
    try {
      final ride = await remoteDataSource.cancelRide(
        rideId: rideId,
        userId: userId,
        reason: reason,
      );
      return Right(ride);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rateRide({
    required String rideId,
    required int rating,
    String? review,
  }) async {
    try {
      // Need to get driver ID from ride first
      final ride = await remoteDataSource.getRideById(rideId);
      if (ride.driverId == null) {
        return const Left(ServerFailure('Cannot rate: no driver assigned'));
      }

      await remoteDataSource.rateRide(
        rideId: rideId,
        driverId: ride.driverId!,
        userId: userId,
        rating: rating,
        review: review,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> applyPromoCode({
    required String rideId,
    required String promoCode,
  }) async {
    try {
      final discount = await remoteDataSource.applyPromoCode(
        rideId: rideId,
        promoCode: promoCode,
        userId: userId,
      );
      return Right(discount);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Ride> watchRide(String rideId) {
    return remoteDataSource.watchRide(rideId);
  }

  @override
  Stream<DriverOffer> watchDriverOffers(String rideId) {
    return remoteDataSource.watchDriverOffers(rideId);
  }

  @override
  Stream<Map<String, double>> watchDriverLocation(String driverId) {
    return remoteDataSource.watchDriverLocation(driverId);
  }
}
