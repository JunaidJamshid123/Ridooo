import '../../domain/entities/driver_offer.dart';

/// Driver offer model for JSON serialization
class DriverOfferModel extends DriverOffer {
  const DriverOfferModel({
    required super.id,
    required super.rideId,
    required super.driverId,
    required super.driverName,
    super.driverPhone,
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
    return DriverOfferModel(
      id: json['id'] as String,
      rideId: json['ride_id'] as String,
      driverId: json['driver_id'] as String,
      driverName: json['driver_name'] as String? ?? 'Unknown',
      driverPhone: json['driver_phone'] as String?,
      driverPhoto: json['driver_photo'] as String?,
      driverRating: (json['driver_rating'] as num?)?.toDouble() ?? 5.0,
      driverTotalRides: json['driver_total_rides'] as int? ?? 0,
      vehicleModel: json['vehicle_model'] as String? ?? 'Unknown',
      vehicleColor: json['vehicle_color'] as String? ?? 'Unknown',
      vehiclePlate: json['vehicle_plate'] as String? ?? 'Unknown',
      offeredPrice: (json['offered_price'] as num).toDouble(),
      etaMinutes: json['estimated_arrival_min'] as int?,
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
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_photo': driverPhoto,
      'driver_rating': driverRating,
      'driver_total_rides': driverTotalRides,
      'vehicle_model': vehicleModel,
      'vehicle_color': vehicleColor,
      'vehicle_plate': vehiclePlate,
      'offered_price': offeredPrice,
      'estimated_arrival_min': etaMinutes,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  /// Create a new offer (driver side) - includes denormalized driver data
  static Map<String, dynamic> toCreateJson({
    required String rideId,
    required String driverId,
    required String driverName,
    String? driverPhone,
    String? driverPhoto,
    required double driverRating,
    required int driverTotalRides,
    required String vehicleModel,
    String? vehicleColor,
    required String vehiclePlate,
    required double offeredPrice,
    int? estimatedArrivalMin,
    String? message,
  }) {
    return {
      'ride_id': rideId,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'driver_photo': driverPhoto,
      'driver_rating': driverRating,
      'driver_total_rides': driverTotalRides,
      'vehicle_model': vehicleModel,
      'vehicle_color': vehicleColor,
      'vehicle_plate': vehiclePlate,
      'offered_price': offeredPrice,
      'estimated_arrival_min': estimatedArrivalMin,
      'message': message,
      'status': 'pending',
    };
  }
}
