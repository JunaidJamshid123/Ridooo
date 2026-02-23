import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/directions_service.dart';
import '../../../../core/services/places_service.dart';
import '../../../user/booking/presentation/bloc/booking_bloc.dart';
import '../../../user/booking/domain/entities/ride.dart';
import '../../../user/booking/domain/entities/driver_offer.dart';
import '../../../user/booking/domain/usecases/create_ride.dart';
import '../../../user/booking/presentation/pages/user_ride_tracking_page.dart';
import '../widgets/location_search_dialog.dart';
import '../widgets/ripple_painter.dart';
import '../widgets/driver_offer_card.dart';
import '../widgets/bottom_sheets.dart';
import '../utils/home_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  bool _isLoadingLocation = true;
  String _selectedRideType = 'Standard';
  final LocationService _locationService = LocationService();
  final DirectionsService _directionsService = DirectionsService();
  final PlacesService _placesService = PlacesService();

  String _currentAddress = 'Detecting location...';
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Pickup and Destination
  PlaceDetails? _pickupLocation;
  PlaceDetails? _destinationLocation;
  DirectionsResult? _currentRoute;
  bool _isCalculatingRoute = false;

  // Stream subscription
  StreamSubscription<LatLng>? _locationSubscription;

  // UI State
  bool _showRideOptions = false;
  bool _isSearchingDriver = false;
  double _searchAnimationProgress = 0.0;
  int _driversViewing = 0;
  final TextEditingController _customPriceController = TextEditingController();
  bool _useCustomPrice = false;
  double? _customPrice;

  // Real-time ride and offers
  Ride? _currentRide;
  List<DriverOffer> _realDriverOffers = [];
  DriverOffer? _lastAcceptedOffer;
  
  // Legacy driver offers (for backwards compatibility during transition)
  List<Map<String, dynamic>> _driverOffers = [];
  Timer? _offerTimer;
  int _currentOfferTimeLeft = 10;

  // Animation controller for ripple effect
  AnimationController? _rippleController;

  final List<Map<String, dynamic>> _rideTypes = [
    {
      'name': 'Economy',
      'price': 12.50,
      'time': '5 min',
      'icon': Icons.directions_car,
      'capacity': '4',
    },
    {
      'name': 'Standard',
      'price': 18.00,
      'time': '3 min',
      'icon': Icons.local_taxi,
      'capacity': '4',
    },
    {
      'name': 'Premium',
      'price': 28.50,
      'time': '8 min',
      'icon': Icons.airport_shuttle,
      'capacity': '4',
    },
    {
      'name': 'XL',
      'price': 35.00,
      'time': '10 min',
      'icon': Icons.commute,
      'capacity': '6',
    },
  ];

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await _getCurrentLocation();
    await _locationService.startLocationTracking();

    _locationSubscription = _locationService.locationStream.listen((
      LatLng newLocation,
    ) {
      // Only update if significant change and not in ride options mode
      if (mounted && !_showRideOptions && !_isSearchingDriver) {
        final distance = HomePageUtils.calculateDistance(_currentPosition, newLocation);
        if (distance > 50) {
          // Only update if moved more than 50 meters to reduce rebuilds
          if (mounted) {
            setState(() {
              _currentPosition = newLocation;
              _updateCurrentLocationMarker(newLocation);
            });
          }
        }
      }
    });

    // Get address for current location
    _updateCurrentAddress();
  }



  Future<void> _updateCurrentAddress() async {
    final address = await _placesService.getAddressFromCoordinates(
      _currentPosition,
    );
    if (address != null) {
      setState(() {
        _currentAddress = address;
      });
    }
  }

  void _updateCurrentLocationMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      };
    });
  }

  Future<void> _calculateRoute() async {
    if (_pickupLocation == null || _destinationLocation == null) return;

    setState(() {
      _isCalculatingRoute = true;
    });

    // Get optimized route with alternatives
    final route = await _directionsService.getDirections(
      origin: _pickupLocation!.location,
      destination: _destinationLocation!.location,
      optimizeRoute: true,
    );

    if (route != null) {
      setState(() {
        _currentRoute = route;
        _isCalculatingRoute = false;
        _showRideOptions = true;

        // Update markers - InDrive Style
        _markers = {
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupLocation!.location,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: '🟢 Pickup',
              snippet: _pickupLocation!.name,
            ),
            anchor: const Offset(0.5, 0.5),
          ),
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationLocation!.location,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: '📍 Destination',
              snippet: _destinationLocation!.name,
            ),
            anchor: const Offset(0.5, 0.5),
          ),
        };

        // Draw route polyline - Enhanced Design
        _polylines = {
          // Background shadow line for depth
          Polyline(
            polylineId: const PolylineId('route_shadow'),
            points: route.polylinePoints,
            color: Colors.black.withOpacity(0.15),
            width: 10,
            geodesic: true,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            zIndex: 0,
          ),
          // Background white line for contrast
          Polyline(
            polylineId: const PolylineId('route_bg'),
            points: route.polylinePoints,
            color: Colors.white,
            width: 8,
            geodesic: true,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            zIndex: 1,
          ),
          // Main route line with primary color
          Polyline(
            polylineId: const PolylineId('route_main'),
            points: route.polylinePoints,
            color: AppColors.primary,
            width: 6,
            geodesic: true,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
            zIndex: 2,
          ),
        };
      });

      // Adjust camera to show entire route
      _fitRouteBounds();
    } else {
      setState(() {
        _isCalculatingRoute = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not calculate route')),
        );
      }
    }
  }

  void _fitRouteBounds() {
    if (_pickupLocation == null || _destinationLocation == null) return;

    final bounds = HomePageUtils.createBounds(
      _pickupLocation!.location,
      _destinationLocation!.location,
    );

    // Smooth camera animation with padding
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 120),
    );
  }

  void _clearRoute() {
    HapticFeedback.lightImpact();
    setState(() {
      _pickupLocation = null;
      _destinationLocation = null;
      _currentRoute = null;
      _polylines.clear();
      _showRideOptions = false;
      _isSearchingDriver = false;
      _useCustomPrice = false;
      _customPrice = null;
      _customPriceController.clear();
      _driverOffers.clear();
      _driversViewing = 0;
      _updateCurrentLocationMarker(_currentPosition);
    });

    // Smooth zoom back to current location
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 15,
          tilt: 0,
        ),
      ),
    );
  }

  /// Create a real ride request using BookingBloc
  Future<void> _searchForDriver() async {
    if (_pickupLocation == null || _destinationLocation == null || _currentRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and destination')),
      );
      return;
    }

    setState(() {
      _isSearchingDriver = true;
      _searchAnimationProgress = 0.0;
      _driversViewing = 0;
      _driverOffers.clear();
      _realDriverOffers.clear();
    });

    // Calculate fare
    final fare = _currentRoute?.calculateFare() ?? 0.0;
    final selectedRide = _rideTypes.firstWhere(
      (r) => r['name'] == _selectedRideType,
    );
    final calculatedPrice = (fare * (selectedRide['price'] / 18.0));
    final finalPrice = _useCustomPrice && _customPrice != null 
        ? _customPrice! 
        : calculatedPrice;

    // Map ride type name to vehicle type
    String vehicleType;
    switch (_selectedRideType) {
      case 'Economy':
        vehicleType = 'economy';
        break;
      case 'Standard':
        vehicleType = 'standard';
        break;
      case 'Premium':
        vehicleType = 'premium';
        break;
      case 'XL':
        vehicleType = 'xl';
        break;
      default:
        vehicleType = 'standard';
    }

    // Create ride request using BLoC
    context.read<BookingBloc>().add(
      CreateRideRequested(
        CreateRideParams(
          pickupLat: _pickupLocation!.location.latitude,
          pickupLng: _pickupLocation!.location.longitude,
          pickupAddress: _pickupLocation!.formattedAddress,
          dropoffLat: _destinationLocation!.location.latitude,
          dropoffLng: _destinationLocation!.location.longitude,
          dropoffAddress: _destinationLocation!.formattedAddress,
          vehicleType: vehicleType,
          estimatedFare: calculatedPrice,
          offeredPrice: _useCustomPrice ? _customPrice : null,
          distanceKm: (double.tryParse(_currentRoute!.distanceValue) ?? 0) / 1000.0,
          estimatedDurationMinutes: ((double.tryParse(_currentRoute!.durationValue) ?? 0) / 60).round(),
          paymentMethod: 'cash', // Default to cash, can be changed
        ),
      ),
    );
  }

  /// Legacy method for simulating offers (kept for fallback)
  void _simulateDriverSearch() async {
    // Simulate drivers viewing the request
    for (int i = 0; i <= 10; i++) {
      if (!_isSearchingDriver) break;
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && _isSearchingDriver) {
        setState(() {
          _searchAnimationProgress = i / 10;
          if (_driversViewing < 8) {
            _driversViewing += 1;
          }
        });
      }
    }

    // Generate driver offers (InDrive style)
    if (mounted && _isSearchingDriver) {
      _generateDriverOffers();
    }
  }

  void _generateDriverOffers() {
    final baseFare = _currentRoute?.calculateFare() ?? 0.0;
    final selectedRide = _rideTypes.firstWhere(
      (r) => r['name'] == _selectedRideType,
    );
    final basePrice = (baseFare * (selectedRide['price'] / 18.0));

    // Simulate multiple driver offers coming in
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || !_isSearchingDriver || _driverOffers.length >= 4) {
        timer.cancel();
        return;
      }

      final driverNames = ['John D.', 'Sarah M.', 'Mike R.', 'Lisa K.', 'Tom B.'];
      final carModels = ['Toyota Camry', 'Honda Accord', 'Nissan Altima', 'Ford Fusion'];
      
      final offer = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'driverName': driverNames[_driverOffers.length % driverNames.length],
        'carModel': carModels[_driverOffers.length % carModels.length],
        'rating': 4.5 + (_driverOffers.length * 0.1),
        'price': basePrice + ((_driverOffers.length - 1) * 2.5), // Varied pricing
        'eta': '${3 + _driverOffers.length} min',
        'timeLeft': 15,
      };

      setState(() {
        _driverOffers.add(offer);
      });

      _startOfferTimer(_driverOffers.length - 1);
    });
  }

  void _startOfferTimer(int offerIndex) {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || offerIndex >= _driverOffers.length) {
        timer.cancel();
        return;
      }

      setState(() {
        _driverOffers[offerIndex]['timeLeft'] -= 1;
      });

      if (_driverOffers[offerIndex]['timeLeft'] <= 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _driverOffers.removeAt(offerIndex);
          });
        }
      }
    });
  }

  void _acceptDriverOffer(Map<String, dynamic> offer) {
    // Check if this is a real offer with backend integration
    if (offer.containsKey('realOffer') && _currentRide != null) {
      final realOffer = offer['realOffer'] as DriverOffer;
      
      // Store the accepted offer for navigation
      _lastAcceptedOffer = realOffer;
      
      // Accept the offer using BLoC
      context.read<BookingBloc>().add(
        AcceptDriverOffer(
          rideId: _currentRide!.id,
          offerId: realOffer.id,
        ),
      );
    } else {
      // Legacy behavior for simulated offers
      setState(() {
        _isSearchingDriver = false;
        _driverOffers.clear();
      });
      _showDriverFoundDialog(offer['price']);
    }
  }

  void _declineDriverOffer(int index) {
    final offer = _driverOffers[index];
    
    // Check if this is a real offer
    if (offer.containsKey('realOffer') && _currentRide != null) {
      final realOffer = offer['realOffer'] as DriverOffer;
      
      // Reject the offer using BLoC
      context.read<BookingBloc>().add(
        RejectDriverOffer(
          rideId: _currentRide!.id,
          offerId: realOffer.id,
        ),
      );
    }
    
    setState(() {
      _driverOffers.removeAt(index);
    });
  }

  void _showDriverFoundDialog(double price) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            contentPadding: const EdgeInsets.all(28),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withOpacity(0.15),
                        AppColors.success.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Driver Found!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_selectedRideType • \$${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 17,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _currentRoute?.distance ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLocationSearch({required bool isPickup}) async {
    final result = await showModalBottomSheet<PlaceDetails>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: LocationSearchDialog(
            title: isPickup ? 'Select Pickup Location' : 'Select Destination',
            currentLocation: _currentPosition,
            onLocationSelected: (place) {
              Navigator.of(context).pop(place);
            },
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        if (isPickup) {
          _pickupLocation = result;
        } else {
          _destinationLocation = result;
        }
      });

      // Auto-calculate route if both locations are set
      if (_pickupLocation != null && _destinationLocation != null) {
        await _calculateRoute();
      }
    }
  }

  void _useCurrentLocationAsPickup() async {
    final address = await _placesService.getAddressFromCoordinates(
      _currentPosition,
    );

    setState(() {
      _pickupLocation = PlaceDetails(
        name: 'Current Location',
        formattedAddress: address ?? _currentAddress,
        location: _currentPosition,
        types: [],
      );
    });

    if (_destinationLocation != null) {
      await _calculateRoute();
    }
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      };
    });
  }

  Future<void> _getCurrentLocation() async {
    HapticFeedback.selectionClick();
    try {
      final location = await _locationService.getCurrentLocation();

      if (location != null) {
        setState(() {
          _currentPosition = location;
          _isLoadingLocation = false;
          _currentAddress = 'Location detected';
          _updateMarker(location);
        });

        // Smooth camera movement to current location
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentPosition,
              zoom: 16,
              tilt: 0,
            ),
          ),
        );
      } else {
        setState(() {
          _isLoadingLocation = false;
          _currentAddress = 'Location permission denied';
        });

        // Show dialog to enable location
        if (mounted) {
          _showLocationPermissionDialog();
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _currentAddress = 'Error getting location';
      });
      print('Error getting location: $e');
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Location Required',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Please enable location services to find nearby drivers and show your current location on the map.',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (!_isLoadingLocation) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15),
      );
    }
  }

  Offset _getScreenPosition(LatLng location) {
    return HomePageUtils.getScreenPosition(location, MediaQuery.of(context).size);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _customPriceController.dispose();
    _rippleController?.dispose();
    _offerTimer?.cancel();
    _mapController?.dispose();
    _locationService.stopLocationTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is RideCreated) {
          // Ride created successfully, start listening for offers
          _currentRide = state.ride;
          context.read<BookingBloc>().add(
            ListenToRideOffers(rideId: state.ride.id),
          );
          context.read<BookingBloc>().add(
            LoadRideOffers(rideId: state.ride.id),
          );
          
          // Update UI to show searching
          setState(() {
            _searchAnimationProgress = 0.5;
            _driversViewing = 1;
          });
        } else if (state is SearchingForDrivers) {
          // Update with real offers
          setState(() {
            _realDriverOffers = state.offers;
            _driversViewing = state.viewingCount > 0 ? state.viewingCount : _driversViewing;
            
            // Convert real offers to legacy format for UI compatibility
            _driverOffers = state.offers.map((offer) => {
              'id': offer.id,
              'driverName': offer.driverName,
              'carModel': offer.vehicleModel,
              'rating': offer.driverRating,
              'price': offer.offeredPrice,
              'eta': '${offer.estimatedArrivalMin ?? 5} min',
              'timeLeft': offer.expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 300),
              'realOffer': offer,
            }).toList();
          });
        } else if (state is OffersLoaded) {
          // Update with loaded offers
          setState(() {
            _realDriverOffers = state.offers;
            
            // Convert to legacy format
            _driverOffers = state.offers.map((offer) => {
              'id': offer.id,
              'driverName': offer.driverName,
              'carModel': offer.vehicleModel,
              'rating': offer.driverRating,
              'price': offer.offeredPrice,
              'eta': '${offer.estimatedArrivalMin ?? 5} min',
              'timeLeft': offer.expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 300),
              'realOffer': offer,
            }).toList();
          });
          
          if (state.offers.isNotEmpty) {
            setState(() {
              _searchAnimationProgress = 1.0;
            });
          }
        } else if (state is OfferAcceptedSuccessfully) {
          // Navigate to ride tracking
          setState(() {
            _isSearchingDriver = false;
            _driverOffers.clear();
            _realDriverOffers.clear();
          });
          
          // Navigate to ride tracking page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserRideTrackingPage(
                ride: state.ride,
                acceptedOffer: _lastAcceptedOffer,
              ),
            ),
          );
        } else if (state is BookingError) {
          setState(() {
            _isSearchingDriver = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Stack(
          children: [
            // Google Map - Enhanced Configuration
            Positioned.fill(
              child: RepaintBoundary(
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 15.5,
                    tilt: 0,
                  ),
                  myLocationEnabled: !_showRideOptions && !_isSearchingDriver,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: false,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  buildingsEnabled: true,
                  indoorViewEnabled: false,
                  trafficEnabled: false,
                  liteModeEnabled: false,
                  markers: _markers,
                  polylines: _polylines,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 80,
                    bottom: _showRideOptions ? 450 : 350,
                  ),
                  minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
                ),
              ),
            ),

            // Ripple Animation on Map (InDrive style)
            if (_isSearchingDriver && _pickupLocation != null)
              Positioned.fill(
              child: AnimatedBuilder(
                animation: _rippleController!,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RipplePainter(
                      animation: _rippleController!,
                      center: _getScreenPosition(_pickupLocation!.location),
                      color: const Color(0xFF1A1A1A),
                    ),
                  );
                },
              ),
            ),

          // Drivers Viewing Overlay - Enhanced Design
          if (_isSearchingDriver && _driversViewing > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 20,
              right: 20,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(
                    begin: 0.0,
                    end: _driversViewing > 0 ? 1.0 : 0.0,
                  ),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    final clampedValue = value.clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: 0.8 + (clampedValue * 0.2),
                      child: Opacity(
                        opacity: clampedValue,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.remove_red_eye_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$_driversViewing drivers viewing',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    'Searching for best match',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Driver Offers - InDrive Style
          if (_driverOffers.isNotEmpty)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 200,
              left: 12,
              right: 12,
              top: MediaQuery.of(context).padding.top + 100,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _driverOffers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final offer = entry.value;
                      return DriverOfferCard(
                      offer: offer,
                      index: index,
                      onAccept: () => _acceptDriverOffer(offer),
                      onDecline: () => _declineDriverOffer(index),
                    );
                    }).toList(),
                  ),
                ),
              ),
            ),

          // Clear Route Button - Enhanced Design
          if (_showRideOptions)
            Positioned(
              left: 20,
              top: MediaQuery.of(context).padding.top + 20,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _clearRoute,
                    borderRadius: BorderRadius.circular(16),
                    splashColor: AppColors.primary.withOpacity(0.1),
                    highlightColor: AppColors.primary.withOpacity(0.05),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // My Location Button - Enhanced Design
          Positioned(
            right: 20,
            top: MediaQuery.of(context).padding.top + 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _getCurrentLocation,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: AppColors.primary.withOpacity(0.1),
                  highlightColor: AppColors.primary.withOpacity(0.05),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Sheet - Enhanced Design
          DraggableScrollableSheet(
            key: ValueKey('sheet_${_showRideOptions}_${_isSearchingDriver}'),
            initialChildSize: _isSearchingDriver ? 0.22 : (_showRideOptions ? 0.52 : 0.36),
            minChildSize: 0.22,
            maxChildSize: 0.90,
            snap: true,
            snapSizes: _isSearchingDriver 
                ? const [0.22] 
                : (_showRideOptions ? const [0.36, 0.52, 0.90] : const [0.36, 0.90]),
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 32,
                      offset: const Offset(0, -8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child:
                    _isSearchingDriver
                        ? _buildSearchingDriverSheet(scrollController)
                        : _showRideOptions
                        ? _buildRideOptionsSheet(scrollController)
                        : LocationSelectionSheet(
                            scrollController: scrollController,
                            pickupLocation: _pickupLocation,
                            destinationLocation: _destinationLocation,
                            currentAddress: _currentAddress,
                            onPickupTap: () => _openLocationSearch(isPickup: true),
                            onDestinationTap: () => _openLocationSearch(isPickup: false),
                            onUseCurrentLocation: _useCurrentLocationAsPickup,
                            onClearPickup: () {
                              setState(() {
                                _pickupLocation = null;
                                _clearRoute();
                              });
                            },
                            onClearDestination: () {
                              setState(() {
                                _destinationLocation = null;
                                _clearRoute();
                              });
                            },
                          ),
              );
            },
          ),

          // Loading Indicator - Enhanced Design
          if (_isCalculatingRoute)
            AnimatedOpacity(
              opacity: _isCalculatingRoute ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.7, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 32,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: CircularProgressIndicator(
                                  strokeWidth: 5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Finding best route...',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Calculating optimal path',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideOptionsSheet(ScrollController scrollController) {
    final fare = _currentRoute?.calculateFare() ?? 0.0;
    final selectedRide = _rideTypes.firstWhere(
      (r) => r['name'] == _selectedRideType,
    );
    final calculatedPrice = (fare * (selectedRide['price'] / 18.0));
    final displayPrice =
        _useCustomPrice && _customPrice != null
            ? _customPrice!
            : calculatedPrice;

    return RideOptionsSheet(
      scrollController: scrollController,
      currentRoute: _currentRoute,
      rideTypes: _rideTypes,
      selectedRideType: _selectedRideType,
      useCustomPrice: _useCustomPrice,
      customPrice: _customPrice,
      customPriceController: _customPriceController,
      onRideTypeSelected: (rideType) {
        setState(() {
          _selectedRideType = rideType;
          _useCustomPrice = false;
          _customPrice = null;
          _customPriceController.clear();
        });
      },
      onCustomPriceToggle: (value) {
        setState(() {
          _useCustomPrice = value;
          if (!_useCustomPrice) {
            _customPrice = null;
            _customPriceController.clear();
          }
        });
      },
      onCustomPriceChanged: (value) {
        final fare = _currentRoute?.calculateFare() ?? 0.0;
        final minimumFare = fare * 0.8;
        final price = double.tryParse(value);
        setState(() {
          if (price != null && price >= minimumFare) {
            _customPrice = price;
          } else {
            _customPrice = null;
          }
        });
      },
      onSearchDriver: _searchForDriver,
    );
  }

  Widget _buildSearchingDriverSheet(ScrollController scrollController) {
    final selectedRide = _rideTypes.firstWhere(
      (r) => r['name'] == _selectedRideType,
    );
    final fare = _currentRoute?.calculateFare() ?? 0.0;
    final calculatedPrice = (fare * (selectedRide['price'] / 18.0));
    final displayPrice =
        _useCustomPrice && _customPrice != null
            ? _customPrice!
            : calculatedPrice;

    return SearchingDriverSheet(
      scrollController: scrollController,
      selectedRideType: _selectedRideType,
      displayPrice: displayPrice,
      onCancel: () {
        setState(() {
          _isSearchingDriver = false;
          _driverOffers.clear();
          _driversViewing = 0;
        });
      },
    );
  }
}
