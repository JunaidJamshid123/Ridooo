import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../rides/presentation/bloc/driver_rides_bloc.dart';
import '../../../rides/presentation/bloc/driver_rides_event.dart';
import '../../../rides/presentation/bloc/driver_rides_state.dart';
import '../../../rides/presentation/widgets/create_offer_bottom_sheet.dart';
import '../../../rides/presentation/pages/active_ride_page.dart';
import '../../../../user/booking/domain/entities/ride.dart';

/// Driver home page with Google Maps and online/offline toggle
class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  GoogleMapController? _mapController;
  bool _isOnline = false;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  Timer? _locationTimer;
  
  // Real ride requests from BLoC
  List<Ride> _nearbyRides = [];
  
  // Legacy mock data (for backwards compatibility)
  final List<Map<String, dynamic>> _nearbyRequests = [
    {
      'id': '1',
      'userName': 'Sarah Johnson',
      'rating': 4.8,
      'pickup': 'Downtown Plaza',
      'destination': 'Airport',
      'distance': '2.3 km',
      'fare': 24.50,
      'lat': 37.7849,
      'lng': -122.4094,
    },
    {
      'id': '2',
      'userName': 'Mike Chen',
      'rating': 4.9,
      'pickup': 'Central Station',
      'destination': 'Business District',
      'distance': '1.1 km',
      'fare': 16.50,
      'lat': 37.7899,
      'lng': -122.4012,
    },
  ];

  // Default location (San Francisco)
  static const LatLng _defaultLocation = LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initializeBloc();
  }

  void _initializeBloc() {
    // Start listening to new rides and offer status updates
    try {
      context.read<DriverRidesBloc>().add(const ListenToNewRides());
      context.read<DriverRidesBloc>().add(const ListenToOfferStatus());
    } catch (e) {
      // BLoC not available, will use mock data
      debugPrint('DriverRidesBloc not available: $e');
    }
  }

  void _loadNearbyRides() {
    if (_currentPosition == null) return;
    
    try {
      context.read<DriverRidesBloc>().add(LoadNearbyRideRequests(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: 10,
      ));
    } catch (e) {
      debugPrint('Could not load nearby rides: $e');
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _updateMarkers();
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );

      // Update location every 10 seconds when online
      if (_isOnline) {
        _startLocationUpdates();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isOnline) {
        _getCurrentLocation();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateMarkers() {
    _markers.clear();

    // Add driver's current location
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }

    // Add nearby ride requests from BLoC or mock data
    if (_isOnline) {
      // Use real rides if available
      if (_nearbyRides.isNotEmpty) {
        for (var ride in _nearbyRides) {
          _markers.add(
            Marker(
              markerId: MarkerId(ride.id),
              position: LatLng(ride.pickupLatitude, ride.pickupLongitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: 'Ride Request',
                snippet: '${ride.pickupAddress.split(',').first} → ${ride.dropoffAddress.split(',').first}',
              ),
              onTap: () => _showRideRequestDetails(ride),
            ),
          );
        }
      } else {
        // Fallback to mock data
        for (var request in _nearbyRequests) {
          _markers.add(
            Marker(
              markerId: MarkerId(request['id']),
              position: LatLng(request['lat'], request['lng']),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: request['userName'],
                snippet: '${request['pickup']} → ${request['destination']}',
              ),
              onTap: () => _showRequestDetails(request),
            ),
          );
        }
      }
    }

    setState(() {});
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });

    // Update BLoC status
    try {
      context.read<DriverRidesBloc>().add(ToggleOnlineStatus(_isOnline));
      
      if (_isOnline && _currentPosition != null) {
        context.read<DriverRidesBloc>().add(UpdateDriverLocation(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          isOnline: true,
        ));
        _loadNearbyRides();
      }
    } catch (e) {
      debugPrint('Could not update BLoC status: $e');
    }

    if (_isOnline) {
      _startLocationUpdates();
      _updateMarkers();
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('You are now online and accepting rides'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      _locationTimer?.cancel();
      _updateMarkers();
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.pause_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('You are now offline'),
            ],
          ),
          backgroundColor: AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  /// Show details for a real ride request from BLoC
  void _showRideRequestDetails(Ride ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_taxi, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ride.vehicleType.toUpperCase()} Ride',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.straighten, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${ride.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '~${ride.estimatedDurationMinutes} min',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₨${ride.estimatedFare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trip_origin, size: 16, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ride.pickupAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const SizedBox(width: 7),
                      Container(
                        width: 2,
                        height: 20,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ride.dropoffAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showCreateOfferSheet(ride);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Make an Offer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Show create offer bottom sheet
  void _showCreateOfferSheet(Ride ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateOfferBottomSheet(ride: ride),
    );
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['userName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
                          const SizedBox(width: 4),
                          Text(
                            '${request['rating']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            request['distance'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trip_origin, size: 16, color: AppColors.success),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          request['pickup'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          request['destination'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Estimated Fare',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '\$${request['fare'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to offer page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Make an Offer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverRidesBloc, DriverRidesState>(
      listener: (context, state) {
        if (state is NearbyRidesLoaded) {
          setState(() {
            _nearbyRides = state.rides;
            _isOnline = state.isOnline;
          });
          _updateMarkers();
        } else if (state is NewRideAvailable) {
          // A new ride request came in via real-time
          setState(() {
            _nearbyRides = [..._nearbyRides, state.ride];
          });
          _updateMarkers();
          
          // Show notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.local_taxi, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('New ride request: ${state.ride.pickupAddress.split(',').first}'),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () => _showRideRequestDetails(state.ride),
              ),
            ),
          );
        } else if (state is OfferCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offer sent successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is OfferAccepted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Your offer was accepted! Starting navigation...'),
              backgroundColor: AppColors.success,
            ),
          );
          // Navigate to active ride screen
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
        } else if (state is OfferRejected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offer was declined by the user'),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (state is DriverRidesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Google Map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : _defaultLocation,
                zoom: 14.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _updateMarkers();
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),

            // Top info bar
            SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isOnline ? AppColors.success : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _isOnline ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                      if (_isOnline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_search,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_nearbyRequests.length} nearby',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Column(
                children: [
                  // My location button
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(right: 16, bottom: 16),
                      child: FloatingActionButton(
                        onPressed: _getCurrentLocation,
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // Online/Offline toggle
                  Container(
                    margin: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleOnlineStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isOnline ? AppColors.error : AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: (_isOnline ? AppColors.error : AppColors.success)
                            .withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isOnline ? Icons.pause_circle : Icons.play_circle,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isOnline ? 'Go Offline' : 'Go Online',
                            style: const TextStyle(
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
          ),
        ],
      ),
      ), // Close BlocListener child (Scaffold)
    ); // Close BlocListener
  }
}
