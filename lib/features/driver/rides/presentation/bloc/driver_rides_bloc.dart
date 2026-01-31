import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/services/realtime_service.dart';
import '../../domain/repositories/driver_rides_repository.dart';
import '../../../../user/booking/data/models/ride_model.dart';
import '../../../../user/booking/data/models/driver_offer_model.dart';
import '../../../../user/booking/domain/entities/ride.dart';
import '../../../../user/booking/domain/entities/driver_offer.dart';
import 'driver_rides_event.dart';
import 'driver_rides_state.dart';

class DriverRidesBloc extends Bloc<DriverRidesEvent, DriverRidesState> {
  final DriverRidesRepository repository;
  final RealtimeService realtimeService;
  final String driverId;
  final String driverName;
  final String? driverPhone;
  final String? driverPhoto;
  final double driverRating;
  final int driverTotalRides;
  final String vehicleModel;
  final String? vehicleColor;
  final String vehiclePlate;

  RealtimeChannel? _ridesChannel;
  RealtimeChannel? _offersChannel;
  StreamSubscription? _offerSubscription;
  
  // Store current driver location for refresh
  double _currentLat = 0;
  double _currentLng = 0;

  DriverRidesBloc({
    required this.repository,
    required this.realtimeService,
    required this.driverId,
    required this.driverName,
    this.driverPhone,
    this.driverPhoto,
    required this.driverRating,
    required this.driverTotalRides,
    required this.vehicleModel,
    this.vehicleColor,
    required this.vehiclePlate,
  }) : super(const DriverRidesInitial()) {
    on<LoadNearbyRideRequests>(_onLoadNearbyRideRequests);
    on<CreateRideOffer>(_onCreateRideOffer);
    on<CancelRideOffer>(_onCancelRideOffer);
    on<UpdateDriverLocation>(_onUpdateDriverLocation);
    on<ToggleOnlineStatus>(_onToggleOnlineStatus);
    on<LoadActiveOffer>(_onLoadActiveOffer);
    on<ListenToNewRides>(_onListenToNewRides);
    on<ListenToOfferStatus>(_onListenToOfferStatus);
    on<NewRideReceived>(_onNewRideReceived);
    on<RideRemoved>(_onRideRemoved);
    on<OfferStatusChanged>(_onOfferStatusChanged);
    on<RefreshRides>(_onRefreshRides);
    on<StopListening>(_onStopListening);
    on<MarkArrivedAtPickup>(_onMarkArrivedAtPickup);
    on<CancelActiveRide>(_onCancelActiveRide);
    on<LoadActiveRide>(_onLoadActiveRide);
    on<ActiveRideUpdated>(_onActiveRideUpdated);
    on<VerifyOtpAndStartTrip>(_onVerifyOtpAndStartTrip);
  }

  Future<void> _onLoadNearbyRideRequests(
    LoadNearbyRideRequests event,
    Emitter<DriverRidesState> emit,
  ) async {
    emit(const DriverRidesLoading());
    
    // Store location for future refreshes
    _currentLat = event.latitude;
    _currentLng = event.longitude;

    final result = await repository.getNearbyRideRequests(
      driverLat: event.latitude,
      driverLng: event.longitude,
      radiusKm: event.radiusKm,
    );

    final onlineResult = await repository.getOnlineStatus(driverId);
    final isOnline = onlineResult.fold((l) => false, (r) => r);

    final activeOfferResult = await repository.getActiveOffer(driverId);
    final activeOffer = activeOfferResult.fold((l) => null, (r) => r);

    result.fold(
      (failure) => emit(DriverRidesError(failure.message)),
      (rides) => emit(NearbyRidesLoaded(
        rides: rides,
        isOnline: isOnline,
        activeOffer: activeOffer,
      )),
    );
  }
  
  Future<void> _onRefreshRides(
    RefreshRides event,
    Emitter<DriverRidesState> emit,
  ) async {
    // Don't show loading, just update in background
    _currentLat = event.latitude;
    _currentLng = event.longitude;

    final result = await repository.getNearbyRideRequests(
      driverLat: event.latitude,
      driverLng: event.longitude,
      radiusKm: 10,
    );

    final activeOfferResult = await repository.getActiveOffer(driverId);
    final activeOffer = activeOfferResult.fold((l) => null, (r) => r);

    result.fold(
      (failure) {}, // Silent fail for refresh
      (rides) {
        if (state is NearbyRidesLoaded) {
          emit(NearbyRidesLoaded(
            rides: rides,
            isOnline: (state as NearbyRidesLoaded).isOnline,
            activeOffer: activeOffer,
          ));
        }
      },
    );
  }

  Future<void> _onCreateRideOffer(
    CreateRideOffer event,
    Emitter<DriverRidesState> emit,
  ) async {
    final currentState = state;
    emit(const DriverRidesLoading());

    final result = await repository.createOffer(
      rideId: event.rideId,
      driverId: driverId,
      driverName: driverName,
      driverPhone: driverPhone,
      driverPhoto: driverPhoto,
      driverRating: driverRating,
      driverTotalRides: driverTotalRides,
      vehicleModel: vehicleModel,
      vehicleColor: vehicleColor,
      vehiclePlate: vehiclePlate,
      offeredPrice: event.offeredPrice,
      estimatedArrivalMin: event.estimatedArrivalMin,
      message: event.message,
    );

    result.fold(
      (failure) {
        emit(DriverRidesError(failure.message));
        // Return to previous state after showing error
        if (currentState is NearbyRidesLoaded) {
          emit(currentState);
        }
      },
      (offer) => emit(OfferCreated(offer: offer)),
    );
  }

  Future<void> _onCancelRideOffer(
    CancelRideOffer event,
    Emitter<DriverRidesState> emit,
  ) async {
    final result = await repository.cancelOffer(event.offerId);

    result.fold(
      (failure) => emit(DriverRidesError(failure.message)),
      (_) => emit(const OfferCancelled()),
    );
  }

  Future<void> _onUpdateDriverLocation(
    UpdateDriverLocation event,
    Emitter<DriverRidesState> emit,
  ) async {
    final result = await repository.updateLocation(
      driverId: driverId,
      latitude: event.latitude,
      longitude: event.longitude,
      heading: event.heading,
      speed: event.speed,
      accuracy: event.accuracy,
      isOnline: event.isOnline,
    );

    result.fold(
      (failure) => emit(DriverRidesError(failure.message)),
      (_) => emit(LocationUpdated(isOnline: event.isOnline)),
    );
  }

  Future<void> _onToggleOnlineStatus(
    ToggleOnlineStatus event,
    Emitter<DriverRidesState> emit,
  ) async {
    // This will be called with current location
    // For now, just emit status change
    emit(OnlineStatusChanged(
      isOnline: event.goOnline,
      message: event.goOnline ? 'You are now online' : 'You are now offline',
    ));
  }

  Future<void> _onLoadActiveOffer(
    LoadActiveOffer event,
    Emitter<DriverRidesState> emit,
  ) async {
    final result = await repository.getActiveOffer(driverId);

    // Don't emit anything if no active offer, just for background check
    result.fold(
      (failure) => null,
      (offer) {
        if (offer != null && state is NearbyRidesLoaded) {
          final currentState = state as NearbyRidesLoaded;
          emit(currentState.copyWith(activeOffer: offer));
        }
      },
    );
  }

  Future<void> _onListenToNewRides(
    ListenToNewRides event,
    Emitter<DriverRidesState> emit,
  ) async {
    // Unsubscribe from previous channel if exists
    await _ridesChannel?.unsubscribe();
    
    // Subscribe to searching rides with better handling
    _ridesChannel = realtimeService.subscribeToSearchingRides(
      onRideAdded: (payload) {
        final ride = RideModel.fromJson(payload);
        add(NewRideReceived(ride));
      },
      onRideRemoved: (payload) {
        final rideId = payload['id'] as String?;
        if (rideId != null) {
          add(RideRemoved(rideId));
        }
      },
    );

    emit(const ListeningToRealtime());
  }

  Future<void> _onListenToOfferStatus(
    ListenToOfferStatus event,
    Emitter<DriverRidesState> emit,
  ) async {
    // Subscribe to driver's own offers via realtime
    _offersChannel = realtimeService.subscribeToDriverOfferUpdates(
      driverId: driverId,
      onUpdate: (payload) {
        debugPrint('🔔 Driver received offer update: $payload');
        final offer = DriverOfferModel.fromJson(payload);
        debugPrint('🔔 Offer status: ${offer.status}');
        add(OfferStatusChanged(offer));
      },
    );
    
    // Also start polling as a fallback (every 3 seconds)
    _startOfferPolling();
  }
  
  Timer? _offerPollingTimer;
  String? _lastActiveOfferId;
  
  void _startOfferPolling() {
    _offerPollingTimer?.cancel();
    _offerPollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollForOfferUpdates(),
    );
  }
  
  Future<void> _pollForOfferUpdates() async {
    try {
      final result = await repository.getActiveOffer(driverId);
      result.fold(
        (failure) {}, // Ignore failures in polling
        (offer) {
          if (offer != null && offer.status == 'accepted') {
            // Only trigger if this is a new acceptance
            if (_lastActiveOfferId != offer.id || _lastActiveOfferId == null) {
              _lastActiveOfferId = offer.id;
              debugPrint('📊 Polling found accepted offer: ${offer.id}');
              add(OfferStatusChanged(offer));
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Polling error: $e');
    }
  }
  
  void _stopOfferPolling() {
    _offerPollingTimer?.cancel();
    _offerPollingTimer = null;
  }

  void _onNewRideReceived(
    NewRideReceived event,
    Emitter<DriverRidesState> emit,
  ) {
    if (state is NearbyRidesLoaded) {
      final currentState = state as NearbyRidesLoaded;
      final updatedRides = List<Ride>.from(currentState.rides);
      
      // Check if ride already exists
      final existingIndex = updatedRides.indexWhere((r) => r.id == event.ride.id);
      if (existingIndex == -1) {
        // Add new ride at the beginning
        updatedRides.insert(0, event.ride);
        emit(currentState.copyWith(rides: updatedRides));
      }
    } else {
      // If not in loaded state, initialize with the new ride
      emit(NearbyRidesLoaded(
        rides: [event.ride],
        isOnline: true,
        activeOffer: null,
      ));
    }
  }
  
  void _onRideRemoved(
    RideRemoved event,
    Emitter<DriverRidesState> emit,
  ) {
    if (state is NearbyRidesLoaded) {
      final currentState = state as NearbyRidesLoaded;
      final updatedRides = currentState.rides
          .where((r) => r.id != event.rideId)
          .toList();
      
      // Check if active offer was for this ride
      final shouldClearOffer = currentState.activeOffer?.rideId == event.rideId;
      
      emit(currentState.copyWith(
        rides: updatedRides,
        clearActiveOffer: shouldClearOffer,
      ));
    }
  }
  
  String? _handledAcceptedOfferId;

  Future<void> _onOfferStatusChanged(
    OfferStatusChanged event,
    Emitter<DriverRidesState> emit,
  ) async {
    final offer = event.offer;
    debugPrint('🚀 _onOfferStatusChanged: status=${offer.status}, offerId=${offer.id}');

    if (offer.status == 'accepted') {
      // Prevent duplicate handling
      if (_handledAcceptedOfferId == offer.id) {
        debugPrint('⏭️ Offer ${offer.id} already handled, skipping');
        return;
      }
      _handledAcceptedOfferId = offer.id;
      
      // Stop polling once accepted
      _stopOfferPolling();
      debugPrint('🚀 Offer accepted! Loading ride details...');
      
      // Load complete ride details first before navigating
      final result = await repository.getRideById(offer.rideId);
      result.fold(
        (failure) {
          debugPrint('❌ Failed to load ride: ${failure.message}');
          // If we can't load ride details, emit with minimal info
          emit(OfferAccepted(
            offer: offer,
            ride: Ride(
              id: offer.rideId,
              userId: '',
              vehicleType: '',
              status: 'accepted',
              pickupLatitude: 0,
              pickupLongitude: 0,
              pickupAddress: '',
              dropoffLatitude: 0,
              dropoffLongitude: 0,
              dropoffAddress: '',
              estimatedFare: offer.offeredPrice,
              distanceKm: 0,
              estimatedDurationMinutes: 0,
              paymentMethod: 'cash',
              paymentStatus: 'pending',
              createdAt: DateTime.now(),
            ),
          ));
        },
        (ride) {
          debugPrint('✅ Ride loaded: ${ride.id}, pickup: ${ride.pickupAddress}');
          // Emit with complete ride details
          emit(OfferAccepted(
            offer: offer,
            ride: ride.copyWith(
              driverId: driverId,
              status: 'accepted',
              offeredPrice: offer.offeredPrice,
            ),
          ));
        },
      );
    } else if (offer.status == 'rejected') {
      emit(OfferRejected(offerId: offer.id));
    } else if (offer.status == 'expired') {
      emit(OfferExpired(offerId: offer.id));
    }
  }

  void _onStopListening(
    StopListening event,
    Emitter<DriverRidesState> emit,
  ) {
    _ridesChannel?.unsubscribe();
    _offersChannel?.unsubscribe();
    _offerSubscription?.cancel();
    _stopOfferPolling();

    _ridesChannel = null;
    _offersChannel = null;
    _offerSubscription = null;
  }

  Future<void> _onMarkArrivedAtPickup(
    MarkArrivedAtPickup event,
    Emitter<DriverRidesState> emit,
  ) async {
    final result = await repository.markArrivedAtPickup(
      rideId: event.rideId,
      driverId: driverId,
    );

    result.fold(
      (failure) => emit(DriverRidesError(failure.message)),
      (ride) {
        if (state is ActiveRideState) {
          emit(ArrivedAtPickup(
            ride: ride,
            offer: (state as ActiveRideState).offer,
          ));
        }
      },
    );
  }

  Future<void> _onCancelActiveRide(
    CancelActiveRide event,
    Emitter<DriverRidesState> emit,
  ) async {
    final result = await repository.cancelRide(
      rideId: event.rideId,
      driverId: driverId,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(DriverRidesError(failure.message)),
      (_) => emit(const ActiveRideCancelled()),
    );
  }

  Future<void> _onLoadActiveRide(
    LoadActiveRide event,
    Emitter<DriverRidesState> emit,
  ) async {
    final result = await repository.getActiveRide(driverId);

    result.fold(
      (failure) => emit(DriverRidesError(failure.message)),
      (ride) {
        if (ride != null) {
          // Also get the accepted offer
          _loadActiveOfferForRide(ride);
        }
      },
    );
  }
  
  Future<void> _loadActiveOfferForRide(Ride ride) async {
    final offerResult = await repository.getActiveOffer(driverId);
    offerResult.fold(
      (failure) {},
      (offer) {
        if (offer != null && offer.status == 'accepted') {
          add(ActiveRideUpdated(ride));
        }
      },
    );
  }

  void _onActiveRideUpdated(
    ActiveRideUpdated event,
    Emitter<DriverRidesState> emit,
  ) {
    if (state is OfferAccepted) {
      final currentState = state as OfferAccepted;
      emit(ActiveRideState(
        ride: event.ride,
        offer: currentState.offer,
        driverLatitude: _currentLat,
        driverLongitude: _currentLng,
      ));
    } else if (state is ActiveRideState) {
      emit((state as ActiveRideState).copyWith(ride: event.ride));
    }
  }

  Future<void> _onVerifyOtpAndStartTrip(
    VerifyOtpAndStartTrip event,
    Emitter<DriverRidesState> emit,
  ) async {
    final result = await repository.verifyOtpAndStartTrip(
      rideId: event.rideId,
      otp: event.otp,
    );

    result.fold(
      (failure) => emit(DriverRidesError(failure.message)),
      (ride) {
        if (state is ActiveRideState) {
          emit((state as ActiveRideState).copyWith(ride: ride));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _ridesChannel?.unsubscribe();
    _offersChannel?.unsubscribe();
    _offerSubscription?.cancel();
    _stopOfferPolling();
    return super.close();
  }
}
