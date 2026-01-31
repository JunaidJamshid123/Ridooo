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
  
  // User info (denormalized for driver display)
  final String? userName;
  final String? userPhone;
  final String? userPhoto;

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
    this.userName,
    this.userPhone,
    this.userPhoto,
  });

  bool get isActive =>
      status == 'pending' ||
      status == 'searching' ||
      status == 'accepted' ||
      status == 'arrived' ||
      status == 'in_progress';

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String? get pickupLocationName => pickupAddress;
  String? get dropoffLocationName => dropoffAddress;

  Ride copyWith({
    String? id,
    String? userId,
    String? driverId,
    String? vehicleType,
    String? status,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupAddress,
    double? dropoffLatitude,
    double? dropoffLongitude,
    String? dropoffAddress,
    double? estimatedFare,
    double? actualFare,
    double? offeredPrice,
    double? distanceKm,
    int? estimatedDurationMinutes,
    String? otp,
    String? cancellationReason,
    String? cancelledBy,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? arrivedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? userName,
    String? userPhone,
    String? userPhoto,
  }) {
    return Ride(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      vehicleType: vehicleType ?? this.vehicleType,
      status: status ?? this.status,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
      dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      actualFare: actualFare ?? this.actualFare,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      otp: otp ?? this.otp,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userPhoto: userPhoto ?? this.userPhoto,
    );
  }

  @override
  List<Object?> get props => [id, status, driverId];
}
