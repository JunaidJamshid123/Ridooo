import 'package:equatable/equatable.dart';
import '../../../../user/booking/domain/entities/ride.dart';
import '../../../../user/booking/domain/entities/driver_offer.dart';

/// Events for Driver Rides BLoC
abstract class DriverRidesEvent extends Equatable {
  const DriverRidesEvent();

  @override
  List<Object?> get props => [];
}

/// Load nearby ride requests
class LoadNearbyRideRequests extends DriverRidesEvent {
  final double latitude;
  final double longitude;
  final int radiusKm;

  const LoadNearbyRideRequests({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10,
  });

  @override
  List<Object?> get props => [latitude, longitude, radiusKm];
}

/// Create an offer for a ride
class CreateRideOffer extends DriverRidesEvent {
  final String rideId;
  final double offeredPrice;
  final int? estimatedArrivalMin;
  final String? message;

  const CreateRideOffer({
    required this.rideId,
    required this.offeredPrice,
    this.estimatedArrivalMin,
    this.message,
  });

  @override
  List<Object?> get props => [rideId, offeredPrice, estimatedArrivalMin, message];
}

/// Cancel a pending offer
class CancelRideOffer extends DriverRidesEvent {
  final String offerId;

  const CancelRideOffer(this.offerId);

  @override
  List<Object?> get props => [offerId];
}

/// Update driver location
class UpdateDriverLocation extends DriverRidesEvent {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final bool isOnline;

  const UpdateDriverLocation({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.accuracy,
    required this.isOnline,
  });

  @override
  List<Object?> get props => [latitude, longitude, heading, speed, accuracy, isOnline];
}

/// Toggle online status
class ToggleOnlineStatus extends DriverRidesEvent {
  final bool goOnline;

  const ToggleOnlineStatus(this.goOnline);

  @override
  List<Object?> get props => [goOnline];
}

/// Load active offer
class LoadActiveOffer extends DriverRidesEvent {
  const LoadActiveOffer();
}

/// Listen to new rides (real-time)
class ListenToNewRides extends DriverRidesEvent {
  const ListenToNewRides();
}

/// Listen to offer status changes (real-time)
class ListenToOfferStatus extends DriverRidesEvent {
  const ListenToOfferStatus();
}

/// New ride received (real-time callback)
class NewRideReceived extends DriverRidesEvent {
  final Ride ride;

  const NewRideReceived(this.ride);

  @override
  List<Object?> get props => [ride];
}

/// Ride removed (accepted/cancelled by user)
class RideRemoved extends DriverRidesEvent {
  final String rideId;

  const RideRemoved(this.rideId);

  @override
  List<Object?> get props => [rideId];
}

/// Offer status changed (real-time callback)
class OfferStatusChanged extends DriverRidesEvent {
  final DriverOffer offer;

  const OfferStatusChanged(this.offer);

  @override
  List<Object?> get props => [offer];
}

/// Refresh rides list
class RefreshRides extends DriverRidesEvent {
  final double latitude;
  final double longitude;

  const RefreshRides({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Stop listening to real-time updates
class StopListening extends DriverRidesEvent {
  const StopListening();
}

/// Mark driver as arrived at pickup location
class MarkArrivedAtPickup extends DriverRidesEvent {
  final String rideId;

  const MarkArrivedAtPickup({required this.rideId});

  @override
  List<Object?> get props => [rideId];
}

/// Cancel active ride (by driver)
class CancelActiveRide extends DriverRidesEvent {
  final String rideId;
  final String? reason;

  const CancelActiveRide({required this.rideId, this.reason});

  @override
  List<Object?> get props => [rideId, reason];
}

/// Load active ride (for driver)
class LoadActiveRide extends DriverRidesEvent {
  const LoadActiveRide();
}

/// Active ride updated (realtime)
class ActiveRideUpdated extends DriverRidesEvent {
  final Ride ride;

  const ActiveRideUpdated(this.ride);

  @override
  List<Object?> get props => [ride];
}

/// Verify OTP and start the trip
class VerifyOtpAndStartTrip extends DriverRidesEvent {
  final String rideId;
  final String otp;

  const VerifyOtpAndStartTrip({
    required this.rideId,
    required this.otp,
  });

  @override
  List<Object?> get props => [rideId, otp];
}
