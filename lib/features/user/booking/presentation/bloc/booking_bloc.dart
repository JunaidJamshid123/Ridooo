import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/services/realtime_service.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/driver_offer.dart' as entities;
import '../../domain/usecases/create_ride.dart';
import '../../domain/usecases/ride_usecases.dart' as usecases;
import '../../domain/repositories/booking_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final entities.DriverOffer offer;

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

class LoadRideOffers extends BookingEvent {
  final String rideId;

  LoadRideOffers({required this.rideId});

  @override
  List<Object?> get props => [rideId];
}

class ListenToRideOffers extends BookingEvent {
  final String rideId;

  ListenToRideOffers({required this.rideId});

  @override
  List<Object?> get props => [rideId];
}

class AcceptDriverOffer extends BookingEvent {
  final String rideId;
  final String offerId;

  AcceptDriverOffer({required this.rideId, required this.offerId});

  @override
  List<Object?> get props => [rideId, offerId];
}

class RejectDriverOffer extends BookingEvent {
  final String rideId;
  final String offerId;

  RejectDriverOffer({required this.rideId, required this.offerId});

  @override
  List<Object?> get props => [rideId, offerId];
}

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
  final List<entities.DriverOffer> offers;
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
    List<entities.DriverOffer>? offers,
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

class OffersLoading extends BookingState {}

class OffersLoaded extends BookingState {
  final List<entities.DriverOffer> offers;

  OffersLoaded(this.offers);

  @override
  List<Object?> get props => [offers];
}

class OfferAcceptedSuccessfully extends BookingState {
  final Ride ride;

  OfferAcceptedSuccessfully(this.ride);

  @override
  List<Object?> get props => [ride];
}

class OfferRejectedSuccessfully extends BookingState {}

class BookingError extends BookingState {
  final String message;

  BookingError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final CreateRide createRideUseCase;
  final usecases.CancelRide cancelRideUseCase;
  final usecases.AcceptDriverOffer acceptOfferUseCase;
  final usecases.GetActiveRide getActiveRideUseCase;
  final BookingRepository repository;
  final RealtimeService realtimeService;

  RealtimeChannel? _offersChannel;

  BookingBloc({
    required this.createRideUseCase,
    required this.cancelRideUseCase,
    required this.acceptOfferUseCase,
    required this.getActiveRideUseCase,
    required this.repository,
    required this.realtimeService,
  }) : super(BookingInitial()) {
    on<CreateRideRequested>(_onCreateRide);
    on<CancelRideRequested>(_onCancelRide);
    on<AcceptOfferRequested>(_onAcceptOffer);
    on<RideUpdated>(_onRideUpdated);
    on<DriverOfferReceived>(_onDriverOfferReceived);
    on<DriverLocationUpdated>(_onDriverLocationUpdated);
    on<LoadActiveRide>(_onLoadActiveRide);
    on<LoadRideOffers>(_onLoadRideOffers);
    on<ListenToRideOffers>(_onListenToRideOffers);
    on<AcceptDriverOffer>(_onAcceptDriverOffer);
    on<RejectDriverOffer>(_onRejectDriverOffer);
    on<ResetBooking>(_onResetBooking);
  }

  @override
  Future<void> close() {
    _offersChannel?.unsubscribe();
    return super.close();
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
        // Start listening to driver offers for this ride
        add(ListenToRideOffers(rideId: ride.id));
        // Load any existing offers
        add(LoadRideOffers(rideId: ride.id));
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
    _offersChannel?.unsubscribe();
    _offersChannel = null;
    emit(BookingInitial());
  }

  Future<void> _onLoadRideOffers(
    LoadRideOffers event,
    Emitter<BookingState> emit,
  ) async {
    // Don't emit loading if already searching
    if (state is! SearchingForDrivers) {
      emit(OffersLoading());
    }

    final result = await repository.getDriverOffers(event.rideId);

    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (offers) {
        if (state is SearchingForDrivers) {
          // Update the SearchingForDrivers state with offers
          emit((state as SearchingForDrivers).copyWith(offers: offers));
        } else {
          emit(OffersLoaded(offers));
        }
      },
    );
  }

  Future<void> _onListenToRideOffers(
    ListenToRideOffers event,
    Emitter<BookingState> emit,
  ) async {
    // Unsubscribe from previous channel if exists
    await _offersChannel?.unsubscribe();

    _offersChannel = realtimeService.subscribeToDriverOffers(
      rideId: event.rideId,
      onNewOffer: (payload) async {
        // Convert payload to DriverOffer
        try {
          // Reload all offers when a new one arrives
          final result = await repository.getDriverOffers(event.rideId);
          result.fold(
            (failure) {
              // Log error but don't emit error state for realtime updates
            },
            (offers) {
              // Emit updated offers list to SearchingForDrivers state
              if (state is SearchingForDrivers) {
                final currentState = state as SearchingForDrivers;
                add(RideUpdated(currentState.ride)); // Re-trigger state
                // Update offers through event
                for (final offer in offers) {
                  if (!currentState.offers.any((o) => o.id == offer.id)) {
                    add(DriverOfferReceived(offer));
                  }
                }
              }
            },
          );
        } catch (e) {
          // Silently fail for realtime errors
        }
      },
    );
  }

  Future<void> _onAcceptDriverOffer(
    AcceptDriverOffer event,
    Emitter<BookingState> emit,
  ) async {
    final result = await repository.acceptDriverOffer(
      rideId: event.rideId,
      offerId: event.offerId,
    );

    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (ride) => emit(OfferAcceptedSuccessfully(ride)),
    );
  }

  Future<void> _onRejectDriverOffer(
    RejectDriverOffer event,
    Emitter<BookingState> emit,
  ) async {
    final result = await repository.rejectDriverOffer(
      rideId: event.rideId,
      offerId: event.offerId,
    );

    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (_) async {
        emit(OfferRejectedSuccessfully());
        // Reload offers to update the list
        final offersResult = await repository.getDriverOffers(event.rideId);
        offersResult.fold(
          (failure) => emit(BookingError(failure.message)),
          (offers) => emit(OffersLoaded(offers)),
        );
      },
    );
  }
}
