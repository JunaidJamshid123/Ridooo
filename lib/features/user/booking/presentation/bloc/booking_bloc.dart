import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/driver_offer.dart';
import '../../domain/usecases/create_ride.dart';
import '../../domain/usecases/ride_usecases.dart';

// ==================== EVENTS ====================

abstract class BookingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CreateRideRequested extends BookingEvent {
  final CreateRideParams params;

  CreateRideRequested(this.params);

  @override
  List<Object?> get props => [params];
}

class CancelRideRequested extends BookingEvent {
  final String rideId;
  final String? reason;

  CancelRideRequested({required this.rideId, this.reason});

  @override
  List<Object?> get props => [rideId, reason];
}

class AcceptOfferRequested extends BookingEvent {
  final String rideId;
  final String offerId;

  AcceptOfferRequested({required this.rideId, required this.offerId});

  @override
  List<Object?> get props => [rideId, offerId];
}

class RideUpdated extends BookingEvent {
  final Ride ride;

  RideUpdated(this.ride);

  @override
  List<Object?> get props => [ride];
}

class DriverOfferReceived extends BookingEvent {
  final DriverOffer offer;

  DriverOfferReceived(this.offer);

  @override
  List<Object?> get props => [offer];
}

class DriverLocationUpdated extends BookingEvent {
  final double latitude;
  final double longitude;

  DriverLocationUpdated({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

class LoadActiveRide extends BookingEvent {}

class ResetBooking extends BookingEvent {}

// ==================== STATES ====================

abstract class BookingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class RideCreated extends BookingState {
  final Ride ride;

  RideCreated(this.ride);

  @override
  List<Object?> get props => [ride];
}

class SearchingForDrivers extends BookingState {
  final Ride ride;
  final List<DriverOffer> offers;
  final int viewingCount;

  SearchingForDrivers({
    required this.ride,
    this.offers = const [],
    this.viewingCount = 0,
  });

  @override
  List<Object?> get props => [ride, offers, viewingCount];

  SearchingForDrivers copyWith({
    Ride? ride,
    List<DriverOffer>? offers,
    int? viewingCount,
  }) {
    return SearchingForDrivers(
      ride: ride ?? this.ride,
      offers: offers ?? this.offers,
      viewingCount: viewingCount ?? this.viewingCount,
    );
  }
}

class RideAccepted extends BookingState {
  final Ride ride;
  final double? driverLatitude;
  final double? driverLongitude;

  RideAccepted({
    required this.ride,
    this.driverLatitude,
    this.driverLongitude,
  });

  @override
  List<Object?> get props => [ride, driverLatitude, driverLongitude];

  RideAccepted copyWith({
    Ride? ride,
    double? driverLatitude,
    double? driverLongitude,
  }) {
    return RideAccepted(
      ride: ride ?? this.ride,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
    );
  }
}

class DriverArrived extends BookingState {
  final Ride ride;

  DriverArrived(this.ride);

  @override
  List<Object?> get props => [ride];
}

class RideInProgress extends BookingState {
  final Ride ride;
  final double? driverLatitude;
  final double? driverLongitude;

  RideInProgress({
    required this.ride,
    this.driverLatitude,
    this.driverLongitude,
  });

  @override
  List<Object?> get props => [ride, driverLatitude, driverLongitude];
}

class RideCompleted extends BookingState {
  final Ride ride;

  RideCompleted(this.ride);

  @override
  List<Object?> get props => [ride];
}

class RideCancelled extends BookingState {
  final Ride ride;

  RideCancelled(this.ride);

  @override
  List<Object?> get props => [ride];
}

class BookingError extends BookingState {
  final String message;

  BookingError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final CreateRide createRideUseCase;
  final CancelRide cancelRideUseCase;
  final AcceptDriverOffer acceptOfferUseCase;
  final GetActiveRide getActiveRideUseCase;

  BookingBloc({
    required this.createRideUseCase,
    required this.cancelRideUseCase,
    required this.acceptOfferUseCase,
    required this.getActiveRideUseCase,
  }) : super(BookingInitial()) {
    on<CreateRideRequested>(_onCreateRide);
    on<CancelRideRequested>(_onCancelRide);
    on<AcceptOfferRequested>(_onAcceptOffer);
    on<RideUpdated>(_onRideUpdated);
    on<DriverOfferReceived>(_onDriverOfferReceived);
    on<DriverLocationUpdated>(_onDriverLocationUpdated);
    on<LoadActiveRide>(_onLoadActiveRide);
    on<ResetBooking>(_onResetBooking);
  }

  Future<void> _onCreateRide(
    CreateRideRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());

    final result = await createRideUseCase(event.params);

    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (ride) {
        emit(RideCreated(ride));
        emit(SearchingForDrivers(ride: ride));
        // TODO: Start listening to ride updates and driver offers
      },
    );
  }

  Future<void> _onCancelRide(
    CancelRideRequested event,
    Emitter<BookingState> emit,
  ) async {
    final result = await cancelRideUseCase(
      rideId: event.rideId,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (ride) => emit(RideCancelled(ride)),
    );
  }

  Future<void> _onAcceptOffer(
    AcceptOfferRequested event,
    Emitter<BookingState> emit,
  ) async {
    final result = await acceptOfferUseCase(
      rideId: event.rideId,
      offerId: event.offerId,
    );

    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (ride) => emit(RideAccepted(ride: ride)),
    );
  }

  void _onRideUpdated(
    RideUpdated event,
    Emitter<BookingState> emit,
  ) {
    final ride = event.ride;

    switch (ride.status) {
      case 'searching':
        if (state is SearchingForDrivers) {
          emit((state as SearchingForDrivers).copyWith(ride: ride));
        } else {
          emit(SearchingForDrivers(ride: ride));
        }
        break;
      case 'accepted':
        if (state is RideAccepted) {
          emit((state as RideAccepted).copyWith(ride: ride));
        } else {
          emit(RideAccepted(ride: ride));
        }
        break;
      case 'arrived':
        emit(DriverArrived(ride));
        break;
      case 'in_progress':
        emit(RideInProgress(ride: ride));
        break;
      case 'completed':
        emit(RideCompleted(ride));
        break;
      case 'cancelled':
        emit(RideCancelled(ride));
        break;
    }
  }

  void _onDriverOfferReceived(
    DriverOfferReceived event,
    Emitter<BookingState> emit,
  ) {
    if (state is SearchingForDrivers) {
      final currentState = state as SearchingForDrivers;
      final updatedOffers = [...currentState.offers, event.offer];
      emit(currentState.copyWith(offers: updatedOffers));
    }
  }

  void _onDriverLocationUpdated(
    DriverLocationUpdated event,
    Emitter<BookingState> emit,
  ) {
    if (state is RideAccepted) {
      emit((state as RideAccepted).copyWith(
        driverLatitude: event.latitude,
        driverLongitude: event.longitude,
      ));
    } else if (state is RideInProgress) {
      emit(RideInProgress(
        ride: (state as RideInProgress).ride,
        driverLatitude: event.latitude,
        driverLongitude: event.longitude,
      ));
    }
  }

  Future<void> _onLoadActiveRide(
    LoadActiveRide event,
    Emitter<BookingState> emit,
  ) async {
    final result = await getActiveRideUseCase();

    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (ride) {
        if (ride != null) {
          add(RideUpdated(ride));
        }
      },
    );
  }

  void _onResetBooking(
    ResetBooking event,
    Emitter<BookingState> emit,
  ) {
    emit(BookingInitial());
  }
}
