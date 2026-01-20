import '../../domain/entities/ride.dart';

/// Ride model for JSON serialization
class RideModel extends Ride {
  const RideModel({
    required super.id,
    required super.userId,
    super.driverId,
    required super.vehicleType,
    required super.status,
    required super.pickupLatitude,
    required super.pickupLongitude,
    required super.pickupAddress,
    required super.dropoffLatitude,
    required super.dropoffLongitude,
    required super.dropoffAddress,
    required super.estimatedFare,
    super.actualFare,
    super.offeredPrice,
    required super.distanceKm,
    required super.estimatedDurationMinutes,
    super.otp,
    super.cancellationReason,
    super.cancelledBy,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.createdAt,
    super.acceptedAt,
    super.arrivedAt,
    super.startedAt,
    super.completedAt,
    super.cancelledAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      driverId: json['driver_id'] as String?,
      vehicleType: json['vehicle_type'] as String,
      status: json['status'] as String,
      pickupLatitude: (json['pickup_latitude'] as num).toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num).toDouble(),
      pickupAddress: json['pickup_address'] as String,
      dropoffLatitude: (json['dropoff_latitude'] as num).toDouble(),
      dropoffLongitude: (json['dropoff_longitude'] as num).toDouble(),
      dropoffAddress: json['dropoff_address'] as String,
      estimatedFare: (json['estimated_fare'] as num).toDouble(),
      actualFare: json['actual_fare'] != null
          ? (json['actual_fare'] as num).toDouble()
          : null,
      offeredPrice: json['offered_price'] != null
          ? (json['offered_price'] as num).toDouble()
          : null,
      distanceKm: (json['distance_km'] as num).toDouble(),
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int,
      otp: json['otp'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      arrivedAt: json['arrived_at'] != null
          ? DateTime.parse(json['arrived_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'driver_id': driverId,
      'vehicle_type': vehicleType,
      'status': status,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'pickup_address': pickupAddress,
      'dropoff_latitude': dropoffLatitude,
      'dropoff_longitude': dropoffLongitude,
      'dropoff_address': dropoffAddress,
      'estimated_fare': estimatedFare,
      'actual_fare': actualFare,
      'offered_price': offeredPrice,
      'distance_km': distanceKm,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'otp': otp,
      'cancellation_reason': cancellationReason,
      'cancelled_by': cancelledBy,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'arrived_at': arrivedAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }

  /// Create a new ride request (without id and timestamps)
  Map<String, dynamic> toCreateJson() {
    return {
      'user_id': userId,
      'vehicle_type': vehicleType,
      'status': 'searching',
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'pickup_address': pickupAddress,
      'dropoff_latitude': dropoffLatitude,
      'dropoff_longitude': dropoffLongitude,
      'dropoff_address': dropoffAddress,
      'estimated_fare': estimatedFare,
      'offered_price': offeredPrice,
      'distance_km': distanceKm,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'payment_method': paymentMethod,
      'payment_status': 'pending',
    };
  }
}
