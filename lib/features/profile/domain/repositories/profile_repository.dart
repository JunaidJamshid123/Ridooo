import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_profile.dart';

/// Profile repository interface
abstract class ProfileRepository {
  /// Get current user profile
  Future<Either<Failure, UserProfile>> getProfile();

  /// Get user profile by ID
  Future<Either<Failure, UserProfile>> getProfileById(String userId);

  /// Update user profile
  Future<Either<Failure, UserProfile>> updateProfile({
    String? fullName,
    String? email,
    String? phone,
  });

  /// Update profile photo
  Future<Either<Failure, String>> updateProfilePhoto(String imagePath);

  /// Delete profile photo
  Future<Either<Failure, void>> deleteProfilePhoto();

  /// Get driver profile
  Future<Either<Failure, DriverProfile>> getDriverProfile();

  /// Update driver profile
  Future<Either<Failure, DriverProfile>> updateDriverProfile({
    String? fullName,
    String? email,
    String? vehicleModel,
    String? vehicleColor,
    String? vehiclePlate,
  });

  /// Delete account
  Future<Either<Failure, void>> deleteAccount();

  /// Check if email is already in use
  Future<Either<Failure, bool>> isEmailInUse(String email);

  /// Check if phone is already in use
  Future<Either<Failure, bool>> isPhoneInUse(String phone);
}
