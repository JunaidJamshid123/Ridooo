import '../../domain/entities/driver_offer.dart';

/// Driver offer model for JSON serialization
class DriverOfferModel extends DriverOffer {
  const DriverOfferModel({
    required super.id,
    required super.rideId,
    required super.driverId,
    required super.driverName,
    super.driverPhoto,
    required super.driverRating,
    required super.driverTotalRides,
    required super.vehicleModel,
    required super.vehicleColor,
    required super.vehiclePlate,
    required super.offeredPrice,
    super.etaMinutes,
    required super.status,
    super.message,
    required super.createdAt,
    required super.expiresAt,
  });

  factory DriverOfferModel.fromJson(Map<String, dynamic> json) {
    // Handle nested driver and vehicle data
    final driver = json['driver'] as Map<String, dynamic>?;
    final user = driver?['user'] as Map<String, dynamic>?;

    return DriverOfferModel(
      id: json['id'] as String,
      rideId: json['ride_id'] as String,
      driverId: json['driver_id'] as String,
      driverName: user?['full_name'] as String? ?? 'Unknown',
      driverPhoto: user?['profile_photo'] as String?,
      driverRating: (driver?['rating'] as num?)?.toDouble() ?? 0.0,
      driverTotalRides: driver?['total_rides'] as int? ?? 0,
      vehicleModel: driver?['vehicle_model'] as String? ?? 'Unknown',
      vehicleColor: driver?['vehicle_color'] as String? ?? 'Unknown',
      vehiclePlate: driver?['vehicle_plate'] as String? ?? 'Unknown',
      offeredPrice: (json['offered_price'] as num).toDouble(),
      etaMinutes: json['eta_minutes'] as int?,
      status: json['status'] as String,
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'driver_id': driverId,
      'offered_price': offeredPrice,
      'eta_minutes': etaMinutes,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  /// Create a new offer (driver side)
  Map<String, dynamic> toCreateJson() {
    return {
      'ride_id': rideId,
      'driver_id': driverId,
      'offered_price': offeredPrice,
      'eta_minutes': etaMinutes,
      'status': 'pending',
      'message': message,
    };
  }
}
