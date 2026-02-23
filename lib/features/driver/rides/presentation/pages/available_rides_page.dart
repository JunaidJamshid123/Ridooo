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
      appBar: AppBar(
        title: const Text('Available Rides'),
        actions: [
          // Online/Offline Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isOnline ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _isOnline,
                  onChanged: (_) => _toggleOnlineStatus(),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
      body: BlocConsumer<DriverRidesBloc, DriverRidesState>(
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.orange.shade50,
                      child: Row(
                        children: [
                          const Icon(Icons.pending, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You have a pending offer for ₨${state.activeOffer!.offeredPrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
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
    );
  }

  Widget _buildOfflineView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'You are offline',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Go online to start receiving ride requests',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              onPressed: _toggleOnlineStatus,
              text: 'Go Online',
              backgroundColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No rides available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'New ride requests will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              onPressed: _loadNearbyRides,
              text: 'Refresh',
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
