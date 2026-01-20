import 'package:equatable/equatable.dart';

/// Ride entity representing a ride booking
class Ride extends Equatable {
  final String id;
  final String userId;
  final String? driverId;
  final String vehicleType;
  final String status;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffAddress;
  final double estimatedFare;
  final double? actualFare;
  final double? offeredPrice;
  final double distanceKm;
  final int estimatedDurationMinutes;
  final String? otp;
  final String? cancellationReason;
  final String? cancelledBy;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  const Ride({
    required this.id,
    required this.userId,
    this.driverId,
    required this.vehicleType,
    required this.status,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffAddress,
    required this.estimatedFare,
    this.actualFare,
    this.offeredPrice,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    this.otp,
    this.cancellationReason,
    this.cancelledBy,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });

  bool get isActive =>
      status == 'pending' ||
      status == 'searching' ||
      status == 'accepted' ||
      status == 'arrived' ||
      status == 'in_progress';

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  @override
  List<Object?> get props => [id, status, driverId];
}
