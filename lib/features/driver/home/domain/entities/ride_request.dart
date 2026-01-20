import 'package:equatable/equatable.dart';

/// Ride request entity (from user to drivers)
class RideRequest extends Equatable {
  final String id;
  final String rideId;
  final String userId;
  final String userName;
  final String? userPhoto;
  final double userRating;
  final String vehicleType;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffAddress;
  final double distanceKm;
  final int estimatedDurationMinutes;
  final double estimatedFare;
  final double? offeredPrice;
  final String paymentMethod;
  final double distanceToPickup; // Distance from driver to pickup
  final int etaToPickup; // ETA to pickup in minutes
  final DateTime createdAt;
  final DateTime expiresAt;

  const RideRequest({
    required this.id,
    required this.rideId,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.userRating,
    required this.vehicleType,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.estimatedFare,
    this.offeredPrice,
    required this.paymentMethod,
    required this.distanceToPickup,
    required this.etaToPickup,
    required this.createdAt,
    required this.expiresAt,
  });

  double get displayPrice => offeredPrice ?? estimatedFare;
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [id, rideId, userId];
}
