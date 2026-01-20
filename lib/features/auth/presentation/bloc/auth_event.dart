import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  
  const LoginEvent({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String phoneNumber;
  final UserRole role;
  final String? licenseNumber;
  final String? vehicleModel;
  final String? vehiclePlate;
  
  const RegisterEvent({
    required this.name,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.role,
    this.licenseNumber,
    this.vehicleModel,
    this.vehiclePlate,
  });
  
  @override
  List<Object?> get props => [
        name,
        email,
        password,
        phoneNumber,
        role,
        licenseNumber,
        vehicleModel,
        vehiclePlate,
      ];
}

class LogoutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}
