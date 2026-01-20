import 'package:equatable/equatable.dart';

/// Driver entity with extended information
class Driver extends Equatable {
  final String id;
  final String userId;
  final String status; // pending, approved, rejected, suspended
  final bool isOnline;
  final bool isAvailable;
  final String? vehicleType;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehiclePlate;
  final int? vehicleYear;
  final double rating;
  final int totalRides;
  final int totalEarnings;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationUpdate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Driver({
    required this.id,
    required this.userId,
    required this.status,
    this.isOnline = false,
    this.isAvailable = true,
    this.vehicleType,
    this.vehicleModel,
    this.vehicleColor,
    this.vehiclePlate,
    this.vehicleYear,
    this.rating = 0.0,
    this.totalRides = 0,
    this.totalEarnings = 0,
    this.licenseNumber,
    this.licenseExpiry,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';

  bool get canAcceptRides => isApproved && isOnline && isAvailable;

  @override
  List<Object?> get props => [id, userId, status, isOnline, isAvailable];
}
