import 'package:equatable/equatable.dart';
import '../../../../user/booking/domain/entities/ride.dart';
import '../../../../user/booking/domain/entities/driver_offer.dart';

/// States for Driver Rides BLoC
abstract class DriverRidesState extends Equatable {
  const DriverRidesState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DriverRidesInitial extends DriverRidesState {
  const DriverRidesInitial();
}

/// Loading state
class DriverRidesLoading extends DriverRidesState {
  const DriverRidesLoading();
}

/// Nearby rides loaded successfully
class NearbyRidesLoaded extends DriverRidesState {
  final List<Ride> rides;
  final bool isOnline;
  final DriverOffer? activeOffer;

  const NearbyRidesLoaded({
    required this.rides,
    required this.isOnline,
    this.activeOffer,
  });

  @override
  List<Object?> get props => [rides, isOnline, activeOffer];

  NearbyRidesLoaded copyWith({
    List<Ride>? rides,
    bool? isOnline,
    DriverOffer? activeOffer,
    bool clearActiveOffer = false,
  }) {
    return NearbyRidesLoaded(
      rides: rides ?? this.rides,
      isOnline: isOnline ?? this.isOnline,
      activeOffer: clearActiveOffer ? null : (activeOffer ?? this.activeOffer),
    );
  }
}

/// New ride request available (real-time notification)
class NewRideAvailable extends DriverRidesState {
  final Ride ride;
  final String message;

  const NewRideAvailable({
    required this.ride,
    this.message = 'New ride request available!',
  });

  @override
  List<Object?> get props => [ride, message];
}

/// Offer created successfully
class OfferCreated extends DriverRidesState {
  final DriverOffer offer;
  final String message;

  const OfferCreated({
    required this.offer,
    this.message = 'Offer sent successfully!',
  });

  @override
  List<Object?> get props => [offer, message];
}

/// Offer accepted by user
class OfferAccepted extends DriverRidesState {
  final DriverOffer offer;
  final Ride ride;
  final String message;

  const OfferAccepted({
    required this.offer,
    required this.ride,
    this.message = 'Your offer was accepted!',
  });

  @override
  List<Object?> get props => [offer, ride, message];
}

/// Offer rejected by user
class OfferRejected extends DriverRidesState {
  final String offerId;
  final String message;

  const OfferRejected({
    required this.offerId,
    this.message = 'Your offer was rejected',
  });

  @override
  List<Object?> get props => [offerId, message];
}

/// Offer cancelled
class OfferCancelled extends DriverRidesState {
  final String message;

  const OfferCancelled({
    this.message = 'Offer cancelled successfully',
  });

  @override
  List<Object?> get props => [message];
}

/// Offer expired
class OfferExpired extends DriverRidesState {
  final String offerId;
  final String message;

  const OfferExpired({
    required this.offerId,
    this.message = 'Your offer has expired',
  });

  @override
  List<Object?> get props => [offerId, message];
}

/// Location updated
class LocationUpdated extends DriverRidesState {
  final bool isOnline;
  final String message;

  const LocationUpdated({
    required this.isOnline,
    this.message = 'Location updated',
  });

  @override
  List<Object?> get props => [isOnline, message];
}

/// Online status changed
class OnlineStatusChanged extends DriverRidesState {
  final bool isOnline;
  final String message;

  const OnlineStatusChanged({
    required this.isOnline,
    required this.message,
  });

  @override
  List<Object?> get props => [isOnline, message];
}

/// Listening to real-time updates
class ListeningToRealtime extends DriverRidesState {
  final String message;

  const ListeningToRealtime({
    this.message = 'Listening for new rides...',
  });

  @override
  List<Object?> get props => [message];
}

/// Error state
class DriverRidesError extends DriverRidesState {
  final String message;

  const DriverRidesError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Driver has an active ride (en route to pickup)
class ActiveRideState extends DriverRidesState {
  final Ride ride;
  final DriverOffer offer;
  final double? driverLatitude;
  final double? driverLongitude;

  const ActiveRideState({
    required this.ride,
    required this.offer,
    this.driverLatitude,
    this.driverLongitude,
  });

  @override
  List<Object?> get props => [ride, offer, driverLatitude, driverLongitude];

  ActiveRideState copyWith({
    Ride? ride,
    DriverOffer? offer,
    double? driverLatitude,
    double? driverLongitude,
  }) {
    return ActiveRideState(
      ride: ride ?? this.ride,
      offer: offer ?? this.offer,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
    );
  }
}

/// Driver arrived at pickup location
class ArrivedAtPickup extends DriverRidesState {
  final Ride ride;
  final DriverOffer offer;
  final String message;

  const ArrivedAtPickup({
    required this.ride,
    required this.offer,
    this.message = 'You have arrived at the pickup location',
  });

  @override
  List<Object?> get props => [ride, offer, message];
}

/// Active ride cancelled
class ActiveRideCancelled extends DriverRidesState {
  final String message;

  const ActiveRideCancelled({
    this.message = 'Ride has been cancelled',
  });

  @override
  List<Object?> get props => [message];
}
