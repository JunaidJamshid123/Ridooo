import 'package:equatable/equatable.dart';

class Ride extends Equatable {
  final String id;
  final String driverId;
  final String userId;
  final String pickupLocation;
  final String dropoffLocation;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String vehicleType;
  final double fare;
  final String status; // pending, accepted, in_progress, completed, cancelled
  final DateTime createdAt;

  const Ride({
    required this.id,
    required this.driverId,
    required this.userId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.vehicleType,
    required this.fare,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        driverId,
        userId,
        pickupLocation,
        dropoffLocation,
        pickupLatitude,
        pickupLongitude,
        dropoffLatitude,
        dropoffLongitude,
        vehicleType,
        fare,
        status,
        createdAt,
      ];
}
