import 'package:equatable/equatable.dart';

enum UserRole { user, driver }

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImage;
  final UserRole role;
  final String? licenseNumber; // For drivers
  final String? vehicleModel; // For drivers
  final String? vehiclePlate; // For drivers

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImage,
    required this.role,
    this.licenseNumber,
    this.vehicleModel,
    this.vehiclePlate,
  });

  bool get isDriver => role == UserRole.driver;

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phoneNumber,
        profileImage,
        role,
        licenseNumber,
        vehicleModel,
        vehiclePlate,
      ];
}
