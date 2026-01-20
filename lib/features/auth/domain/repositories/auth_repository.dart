import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });
  
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
    String? licenseNumber,
    String? vehicleModel,
    String? vehiclePlate,
  });
  
  Future<Either<Failure, void>> logout();
  
  Future<Either<Failure, User?>> getCurrentUser();
}
