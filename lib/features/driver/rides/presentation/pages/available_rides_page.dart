import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/widgets/custom_button.dart';
import '../../../../user/booking/domain/entities/ride.dart';
import '../bloc/driver_rides_bloc.dart';
import '../bloc/driver_rides_event.dart';
import '../bloc/driver_rides_state.dart';
import '../widgets/ride_request_card.dart';
import '../widgets/create_offer_bottom_sheet.dart';
import 'active_ride_page.dart';

class AvailableRidesPage extends StatefulWidget {
  const AvailableRidesPage({super.key});

  @override
  State<AvailableRidesPage> createState() => _AvailableRidesPageState();
}

class _AvailableRidesPageState extends State<AvailableRidesPage> {
  bool _isOnline = false;
  Timer? _refreshTimer;
  StreamSubscription<Position>? _positionStream;
  
  // Real GPS location
  double _currentLat = 31.5204;
  double _currentLng = 74.3587;
  bool _locationLoaded = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    // Start listening for new rides
    context.read<DriverRidesBloc>().add(const ListenToNewRides());
    context.read<DriverRidesBloc>().add(const ListenToOfferStatus());
  }

  Future<void> _initLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions permanently denied');
        _loadNearbyRides(); // Use default location
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _locationLoaded = true;
      });
      
      _loadNearbyRides();
      
      // Start continuous location updates
      _startLocationUpdates();
    } catch (e) {
      debugPrint('Error getting location: $e');
      _loadNearbyRides(); // Use default location
    }
  }

  void _startLocationUpdates() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      ),
    ).listen((Position position) {
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });
      
      // Update driver location in Supabase if online
      if (_isOnline) {
        context.read<DriverRidesBloc>().add(UpdateDriverLocation(
          latitude: _currentLat,
          longitude: _currentLng,
          isOnline: true,
        ));
      }
    });
  }
  
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_isOnline && mounted) {
        context.read<DriverRidesBloc>().add(RefreshRides(
          latitude: _currentLat,
          longitude: _currentLng,
        ));
      }
    });
  }

  void _loadNearbyRides() {
    context.read<DriverRidesBloc>().add(LoadNearbyRideRequests(
      latitude: _currentLat,
      longitude: _currentLng,
      radiusKm: 15,
    ));
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });
    context.read<DriverRidesBloc>().add(ToggleOnlineStatus(_isOnline));
    
    if (_isOnline) {
      // Update location when going online
      context.read<DriverRidesBloc>().add(UpdateDriverLocation(
        latitude: _currentLat,
        longitude: _currentLng,
        isOnline: true,
      ));
      _loadNearbyRides();
      _startAutoRefresh();
    } else {
      // Stop refresh when offline
      _refreshTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void _showCreateOfferSheet(Ride ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateOfferBottomSheet(ride: ride),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Modern header with online toggle
            _buildHeader(),
            // Content
            Expanded(
              child: BlocConsumer<DriverRidesBloc, DriverRidesState>(
                listener: (context, state) {
                  if (state is DriverRidesError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is OfferCreated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context); // Close bottom sheet
                  } else if (state is OfferAccepted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    // Navigate to active ride screen with bloc
                    final bloc = context.read<DriverRidesBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: bloc,
                          child: DriverActiveRidePage(
                            ride: state.ride,
                            offer: state.offer,
                          ),
                        ),
                      ),
                    );
                  } else if (state is ActiveRideState) {
                    // Also navigate if we already have active ride state
                    final bloc = context.read<DriverRidesBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: bloc,
                          child: DriverActiveRidePage(
                            ride: state.ride,
                            offer: state.offer,
                          ),
                        ),
                      ),
                    );
                  } else if (state is OfferRejected || state is OfferExpired) {
                    final message = state is OfferRejected
                        ? (state as OfferRejected).message
                        : (state as OfferExpired).message;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    _loadNearbyRides();
                  } else if (state is OnlineStatusChanged) {
                    setState(() {
                      _isOnline = state.isOnline;
                    });
                  } else if (state is NearbyRidesLoaded) {
                    // Update online status from state
                    if (state.isOnline != _isOnline) {
                      setState(() {
                        _isOnline = state.isOnline;
                      });
                    }
                  }
                },
                builder: (context, state) {
                  if (!_isOnline) {
                    return _buildOfflineView();
                  }

                  if (state is DriverRidesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is NearbyRidesLoaded) {
                    if (state.rides.isEmpty) {
                      return _buildEmptyView();
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _loadNearbyRides(),
                      child: Column(
                        children: [
                          if (state.activeOffer != null)
                            _buildActiveOfferBanner(state.activeOffer!),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.rides.length,
                              itemBuilder: (context, index) {
                                final ride = state.rides[index];
                                final hasActiveOffer = state.activeOffer?.rideId == ride.id;
                                
                                return RideRequestCard(
                                  ride: ride,
                                  hasActiveOffer: hasActiveOffer,
                                  onSendOffer: () => _showCreateOfferSheet(ride),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Available Rides',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _locationLoaded ? 'Location updated' : 'Getting location...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Online toggle
          GestureDetector(
            onTap: _toggleOnlineStatus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isOnline
                      ? [const Color(0xFF2ED573), const Color(0xFF7BED9F)]
                      : [Colors.grey.shade300, Colors.grey.shade400],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: _isOnline
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2ED573).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isOnline ? Colors.white : Colors.grey.shade600,
                      shape: BoxShape.circle,
                      boxShadow: _isOnline
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: _isOnline ? Colors.white : Colors.grey.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOfferBanner(dynamic activeOffer) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA726).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pending_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pending Offer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rs. ${activeOffer.offeredPrice.toStringAsFixed(0)} - Waiting for response',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.timer_rounded, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildOfflineView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 70,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'You\'re Offline',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Go online to start receiving ride requests from passengers nearby',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: _toggleOnlineStatus,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ED573), Color(0xFF7BED9F)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2ED573).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Go Online',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 70,
                color: Color(0xFF667EEA),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Rides Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'re looking for rides near you. New requests will appear here automatically.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: _loadNearbyRides,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF667EEA), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Color(0xFF667EEA), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        color: Color(0xFF667EEA),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
