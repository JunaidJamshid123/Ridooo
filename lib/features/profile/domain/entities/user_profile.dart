import 'package:equatable/equatable.dart';

/// User profile entity
class UserProfile extends Equatable {
  final String id;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? profilePhotoUrl;
  final String role; // user, driver, admin
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    this.email,
    this.phone,
    this.fullName,
    this.profilePhotoUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDriver => role == 'driver';
  bool get isUser => role == 'user';
  bool get isAdmin => role == 'admin';

  String get displayName => fullName ?? phone ?? email ?? 'User';
  
  String get initials {
    if (fullName != null && fullName!.isNotEmpty) {
      final parts = fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return '?';
  }

  @override
  List<Object?> get props => [id, email, phone, fullName, role];
}

/// Driver profile with additional driver-specific fields
class DriverProfile extends UserProfile {
  final String? cnic;
  final String? licenseNumber;
  final String vehicleType; // car, bike, rickshaw
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? vehicleColor;
  final double rating;
  final int totalRides;
  final bool isVerified;
  final bool isOnline;
  final double? currentLatitude;
  final double? currentLongitude;

  const DriverProfile({
    required super.id,
    super.email,
    super.phone,
    super.fullName,
    super.profilePhotoUrl,
    required super.role,
    required super.createdAt,
    required super.updatedAt,
    this.cnic,
    this.licenseNumber,
    required this.vehicleType,
    this.vehiclePlate,
    this.vehicleModel,
    this.vehicleColor,
    required this.rating,
    required this.totalRides,
    required this.isVerified,
    required this.isOnline,
    this.currentLatitude,
    this.currentLongitude,
  });

  String get vehicleInfo {
    final parts = <String>[];
    if (vehicleModel != null) parts.add(vehicleModel!);
    if (vehicleColor != null) parts.add(vehicleColor!);
    if (vehiclePlate != null) parts.add(vehiclePlate!);
    return parts.join(' • ');
  }

  @override
  List<Object?> get props => [
    ...super.props,
    cnic,
    licenseNumber,
    vehicleType,
    vehiclePlate,
    isVerified,
    isOnline,
  ];
}
