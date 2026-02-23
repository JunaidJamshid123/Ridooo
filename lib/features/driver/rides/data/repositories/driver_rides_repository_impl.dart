import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../../core/errors/exceptions.dart';
import '../../../../user/booking/domain/entities/ride.dart';
import '../../../../user/booking/domain/entities/driver_offer.dart';
import '../../domain/repositories/driver_rides_repository.dart';
import '../datasources/driver_rides_remote_datasource.dart';

class DriverRidesRepositoryImpl implements DriverRidesRepository {
  final DriverRidesRemoteDataSource remoteDataSource;

  DriverRidesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Ride>>> getNearbyRideRequests({
    required double driverLat,
    required double driverLng,
    int radiusKm = 10,
  }) async {
    try {
      final rides = await remoteDataSource.getNearbyRideRequests(
        driverLat: driverLat,
        driverLng: driverLng,
        radiusKm: radiusKm,
      );
      return Right(rides);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final offer = await remoteDataSource.createOffer(
        rideId: rideId,
        driverId: driverId,
        driverName: driverName,
        driverPhone: driverPhone,
        driverPhoto: driverPhoto,
        driverRating: driverRating,
        driverTotalRides: driverTotalRides,
        vehicleModel: vehicleModel,
        vehicleColor: vehicleColor,
        vehiclePlate: vehiclePlate,
        offeredPrice: offeredPrice,
        estimatedArrivalMin: estimatedArrivalMin,
        message: message,
      );
      return Right(offer);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DriverOffer?>> getActiveOffer(String driverId) async {
    try {
      final offer = await remoteDataSource.getActiveOffer(driverId);
      return Right(offer);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOffer(String offerId) async {
    try {
      await remoteDataSource.cancelOffer(offerId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    double? accuracy,
    required bool isOnline,
  }) async {
    try {
      await remoteDataSource.updateLocation(
        driverId: driverId,
        latitude: latitude,
        longitude: longitude,
        heading: heading,
        speed: speed,
        accuracy: accuracy,
        isOnline: isOnline,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> getOnlineStatus(String driverId) async {
    try {
      final status = await remoteDataSource.getOnlineStatus(driverId);
      return Right(status);
    } catch (e) {
      return Right(false);
    }
  }

  @override
  Future<Either<Failure, Ride>> markArrivedAtPickup({
    required String rideId,
    required String driverId,
  }) async {
    try {
      final ride = await remoteDataSource.markArrivedAtPickup(
        rideId: rideId,
        driverId: driverId,
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
    required String driverId,
    String? reason,
  }) async {
    try {
      final ride = await remoteDataSource.cancelRide(
        rideId: rideId,
        driverId: driverId,
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
  Future<Either<Failure, Ride?>> getActiveRide(String driverId) async {
    try {
      final ride = await remoteDataSource.getActiveRide(driverId);
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
  Future<Either<Failure, Ride>> verifyOtpAndStartTrip({
    required String rideId,
    required String otp,
  }) async {
    try {
      final ride = await remoteDataSource.verifyOtpAndStartTrip(
        rideId: rideId,
        otp: otp,
      );
      return Right(ride);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ride>> startTrip({required String rideId}) async {
    try {
      final ride = await remoteDataSource.startTrip(rideId: rideId);
      return Right(ride);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ride>> completeTrip({required String rideId}) async {
    try {
      final ride = await remoteDataSource.completeTrip(rideId: rideId);
      return Right(ride);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
