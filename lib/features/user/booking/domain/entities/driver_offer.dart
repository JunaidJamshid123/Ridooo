import 'package:equatable/equatable.dart';

/// Driver offer entity for InDrive-style bidding
class DriverOffer extends Equatable {
  final String id;
  final String rideId;
  final String driverId;
  final String driverName;
  final String? driverPhoto;
  final double driverRating;
  final int driverTotalRides;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlate;
  final double offeredPrice;
  final int? etaMinutes;
  final String status; // pending, accepted, rejected, expired, cancelled
  final String? message;
  final DateTime createdAt;
  final DateTime expiresAt;

  const DriverOffer({
    required this.id,
    required this.rideId,
    required this.driverId,
    required this.driverName,
    this.driverPhoto,
    required this.driverRating,
    required this.driverTotalRides,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlate,
    required this.offeredPrice,
    this.etaMinutes,
    required this.status,
    this.message,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isPending => status == 'pending';
  bool get isExpired => DateTime.now().isAfter(expiresAt) || status == 'expired';

  @override
  List<Object?> get props => [id, rideId, driverId, status];
}
