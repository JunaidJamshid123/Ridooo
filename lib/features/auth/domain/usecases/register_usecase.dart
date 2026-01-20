import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required UserRole role,
    String? licenseNumber,
    String? vehicleModel,
    String? vehiclePlate,
  }) async {
    return await repository.register(
      name: name,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      role: role,
      licenseNumber: licenseNumber,
      vehicleModel: vehicleModel,
      vehiclePlate: vehiclePlate,
    );
  }
}
