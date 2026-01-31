import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../user/booking/domain/entities/ride.dart';
import '../../../../user/booking/domain/entities/driver_offer.dart';
import '../bloc/driver_rides_bloc.dart';
import '../bloc/driver_rides_event.dart';
import '../bloc/driver_rides_state.dart';

/// Enhanced Active Ride Page for Driver - Phase 2: Driver En Route to Pickup
class DriverActiveRidePage extends StatefulWidget {
  final Ride ride;
  final DriverOffer offer;

  const DriverActiveRidePage({
    super.key,
    required this.ride,
    required this.offer,
  });

  @override
  State<DriverActiveRidePage> createState() => _DriverActiveRidePageState();
}

class _DriverActiveRidePageState extends State<DriverActiveRidePage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _locationUpdateTimer;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};

  int _etaMinutes = 0;
  double _distanceToPickup = 0;
  bool _isNavigating = false;
  bool _showTripDetails = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Ride stages for driver
  final List<_DriverStage> _driverStages = [
    _DriverStage('Offer Accepted', Icons.check_circle, true),
    _DriverStage('En Route', Icons.navigation, true),
    _DriverStage('Arrived', Icons.location_on, false),
    _DriverStage('Trip Started', Icons.play_arrow, false),
    _DriverStage('Completed', Icons.flag, false),
  ];

  @override
  void initState() {
    super.initState();
    _etaMinutes = widget.offer.etaMinutes ?? 5;

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    _initializeLocation();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _locationUpdateTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _updateMarkers();
        _calculateDistance();
      });

      _moveToFitBounds();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _startLocationUpdates() {
    // Stream position updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((position) {
      setState(() {
        _currentPosition = position;
        _updateMarkers();
        _calculateDistance();
      });
    });

    // Update driver location in database every 5 seconds
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _sendLocationUpdate(),
    );
  }

  void _sendLocationUpdate() {
    if (_currentPosition == null) return;

    context.read<DriverRidesBloc>().add(
          UpdateDriverLocation(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            heading: _currentPosition!.heading,
            speed: _currentPosition!.speed,
            accuracy: _currentPosition!.accuracy,
            isOnline: true,
          ),
        );
  }

  void _calculateDistance() {
    if (_currentPosition == null) return;

    final distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.ride.pickupLatitude,
      widget.ride.pickupLongitude,
    );

    setState(() {
      _distanceToPickup = distanceInMeters / 1000; // Convert to km
      // Rough ETA calculation: assuming average speed of 30 km/h
      _etaMinutes = (_distanceToPickup / 0.5).ceil(); // 0.5 km per minute
      if (_etaMinutes < 1) _etaMinutes = 1;
    });
  }

  void _updateMarkers() {
    _markers = {
      // Driver's current location with rotation
      if (_currentPosition != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
          rotation: _currentPosition!.heading,
          anchor: const Offset(0.5, 0.5),
        ),
      // Pickup location
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          widget.ride.pickupLatitude,
          widget.ride.pickupLongitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup - ${widget.ride.userName ?? 'Passenger'}',
          snippet: widget.ride.pickupAddress,
        ),
      ),
      // Dropoff location (shown faded)
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(
          widget.ride.dropoffLatitude,
          widget.ride.dropoffLongitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        alpha: 0.5,
        infoWindow: InfoWindow(
          title: 'Dropoff',
          snippet: widget.ride.dropoffAddress,
        ),
      ),
    };

    // Pulsing circle around pickup
    _circles = {
      Circle(
        circleId: const CircleId('pickup_pulse'),
        center:
            LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
        radius: 30 + (_pulseAnimation.value * 70),
        fillColor:
            AppColors.success.withOpacity(0.15 * (1 - _pulseAnimation.value)),
        strokeColor:
            AppColors.success.withOpacity(0.4 * (1 - _pulseAnimation.value)),
        strokeWidth: 2,
      ),
    };

    // Draw route polyline
    if (_currentPosition != null) {
      _polylines = {
        // Route to pickup
        Polyline(
          polylineId: const PolylineId('route_to_pickup'),
          points: _createCurvedRoute(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
          ),
          color: AppColors.primary,
          width: 5,
          patterns: [PatternItem.dash(15), PatternItem.gap(8)],
        ),
        // Route from pickup to dropoff (faded)
        Polyline(
          polylineId: const PolylineId('pickup_to_dropoff'),
          points: [
            LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
            LatLng(widget.ride.dropoffLatitude, widget.ride.dropoffLongitude),
          ],
          color: Colors.grey.withOpacity(0.4),
          width: 3,
          patterns: [PatternItem.dot, PatternItem.gap(10)],
        ),
      };
    }
  }

  List<LatLng> _createCurvedRoute(LatLng start, LatLng end) {
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    final offset = (end.latitude - start.latitude).abs() * 0.1;

    return [
      start,
      LatLng(midLat + offset, midLng),
      end,
    ];
  }

  void _moveToFitBounds() {
    if (_mapController == null || _currentPosition == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(_currentPosition!.latitude, widget.ride.pickupLatitude),
        math.min(_currentPosition!.longitude, widget.ride.pickupLongitude),
      ),
      northeast: LatLng(
        math.max(_currentPosition!.latitude, widget.ride.pickupLatitude),
        math.max(_currentPosition!.longitude, widget.ride.pickupLongitude),
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 120),
    );
  }

  Future<void> _openGoogleMapsNavigation() async {
    HapticFeedback.mediumImpact();
    final url =
        'google.navigation:q=${widget.ride.pickupLatitude},${widget.ride.pickupLongitude}&mode=d';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      setState(() => _isNavigating = true);
    } else {
      // Fallback to web URL
      final webUrl =
          'https://www.google.com/maps/dir/?api=1&destination=${widget.ride.pickupLatitude},${widget.ride.pickupLongitude}&travelmode=driving';
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callUser() async {
    HapticFeedback.lightImpact();
    final userPhone = widget.ride.userPhone;
    if (userPhone == null || userPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('User phone number not available'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final uri = Uri.parse('tel:$userPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _messageUser() async {
    HapticFeedback.lightImpact();
    final userPhone = widget.ride.userPhone;
    if (userPhone == null || userPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('User phone number not available'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final uri = Uri.parse('sms:$userPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _markAsArrived() {
    HapticFeedback.heavyImpact();
    context.read<DriverRidesBloc>().add(
          MarkArrivedAtPickup(rideId: widget.ride.id),
        );

    setState(() {
      _driverStages[2].isCompleted = true;
    });

    // Show OTP input dialog
    _showOtpInputDialog();
  }

  void _showOtpInputDialog() {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 28),
            ),
            const SizedBox(width: 12),
            const Text("You've Arrived!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ask ${widget.ride.userName ?? 'the passenger'} for the OTP to start the trip.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 12,
              ),
              decoration: InputDecoration(
                hintText: '----',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  letterSpacing: 12,
                ),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final otp = otpController.text;
              if (otp.length == 4) {
                Navigator.pop(context);
                context.read<DriverRidesBloc>().add(
                      VerifyOtpAndStartTrip(
                        rideId: widget.ride.id,
                        otp: otp,
                      ),
                    );
                setState(() {
                  _driverStages[3].isCompleted = true;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('START TRIP'),
          ),
        ],
      ),
    );
  }

  void _cancelRide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 12),
            Text('Cancel Ride?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this ride? This may affect your rating and acceptance score.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO, KEEP RIDE'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DriverRidesBloc>().add(
                    CancelActiveRide(
                        rideId: widget.ride.id, reason: 'Driver cancelled'),
                  );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );
  }

  String _getDistanceString() {
    if (_distanceToPickup >= 1) {
      return '${_distanceToPickup.toStringAsFixed(1)} km';
    } else {
      return '${(_distanceToPickup * 1000).toStringAsFixed(0)} m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canMarkArrived = _distanceToPickup < 0.2; // Within 200m

    return Scaffold(
      body: Stack(
        children: [
          // Map with animated markers
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              _updateMarkers();
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    widget.ride.pickupLatitude,
                    widget.ride.pickupLongitude,
                  ),
                  zoom: 14,
                ),
                markers: _markers,
                polylines: _polylines,
                circles: _circles,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  controller.setMapStyle(_mapStyle);
                  _moveToFitBounds();
                },
              );
            },
          ),

          // Top bar with back button and status
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildCircularButton(
                    icon: Icons.close,
                    onPressed: _cancelRide,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusPill(),
                  ),
                  const SizedBox(width: 12),
                  _buildCircularButton(
                    icon: Icons.my_location,
                    onPressed: _moveToFitBounds,
                  ),
                ],
              ),
            ),
          ),

          // Quick stats overlay
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: _buildQuickStats(),
          ),

          // Bottom Panel with slide animation
          SlideTransition(
            position: _slideAnimation,
            child: DraggableScrollableSheet(
              initialChildSize: 0.40,
              minChildSize: 0.22,
              maxChildSize: 0.72,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Progress indicator
                        _buildProgressIndicator(),

                        const Divider(height: 24),

                        // User Info Card
                        _buildUserInfoCard(),

                        const Divider(height: 24),

                        // Pickup Location Card
                        _buildPickupLocationCard(),

                        // Trip Details (expandable)
                        _buildTripDetails(),

                        const SizedBox(height: 16),

                        // Action Buttons
                        _buildActionButtons(),

                        const SizedBox(height: 12),

                        // Arrived Button
                        _buildArrivedButton(canMarkArrived),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 48,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: size * 0.45),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation,
                color: AppColors.success, size: 16),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'En Route to Pickup',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatItem(
            icon: Icons.access_time,
            value: '$_etaMinutes',
            unit: 'min',
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _buildStatItem(
            icon: Icons.straighten,
            value: _distanceToPickup >= 1
                ? _distanceToPickup.toStringAsFixed(1)
                : (_distanceToPickup * 1000).toStringAsFixed(0),
            unit: _distanceToPickup >= 1 ? 'km' : 'm',
            color: AppColors.info,
          ),
          const SizedBox(height: 8),
          _buildStatItem(
            icon: Icons.attach_money,
            value: widget.offer.offeredPrice.toStringAsFixed(0),
            unit: '₨',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          unit == '₨' ? '$unit$value' : '$value $unit',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_driverStages.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stageIndex = index ~/ 2;
            final isCompleted = _driverStages[stageIndex].isCompleted;
            return Expanded(
              child: Container(
                height: 3,
                color: isCompleted ? AppColors.success : Colors.grey.shade300,
              ),
            );
          } else {
            final stageIndex = index ~/ 2;
            final stage = _driverStages[stageIndex];
            return Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: stage.isCompleted
                    ? AppColors.success
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                stage.icon,
                color: Colors.white,
                size: 14,
              ),
            );
          }
        }),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // User Photo
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: widget.ride.userPhoto != null
                      ? NetworkImage(widget.ride.userPhoto!)
                      : null,
                  child: widget.ride.userPhoto == null
                      ? const Icon(Icons.person, size: 28, color: Colors.grey)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // User Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ride.userName ?? 'Passenger',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Passenger',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          _buildActionIconButton(
            icon: Icons.message,
            color: AppColors.info,
            onTap: _messageUser,
          ),
          const SizedBox(width: 8),
          _buildActionIconButton(
            icon: Icons.phone,
            color: AppColors.success,
            onTap: _callUser,
          ),
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildPickupLocationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.trip_origin,
                color: AppColors.success, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Pickup Location',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getDistanceString(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.ride.pickupAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetails() {
    return ExpansionTile(
      title: const Text(
        'Trip Details',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 20),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      initiallyExpanded: _showTripDetails,
      onExpansionChanged: (expanded) =>
          setState(() => _showTripDetails = expanded),
      children: [
        // Dropoff
        _buildLocationRow(
          icon: Icons.location_on,
          iconColor: AppColors.error,
          label: 'Dropoff',
          address: widget.ride.dropoffAddress,
        ),
        const SizedBox(height: 16),
        // Trip stats
        Row(
          children: [
            Expanded(
              child: _buildInfoChip(
                icon: Icons.straighten,
                label:
                    '${widget.ride.distanceKm.toStringAsFixed(1)} km',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoChip(
                icon: Icons.access_time,
                label: '${widget.ride.estimatedDurationMinutes} min',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Earnings breakdown
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Earnings',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '₨${widget.offer.offeredPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Call Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _callUser,
              icon: const Icon(Icons.phone),
              label: const Text('Call'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Navigate Button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _openGoogleMapsNavigation,
              icon: const Icon(Icons.navigation, color: Colors.white),
              label: Text(
                _isNavigating ? 'Continue Nav' : 'Navigate',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivedButton(bool canMarkArrived) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canMarkArrived ? _markAsArrived : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                canMarkArrived ? AppColors.success : Colors.grey.shade300,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: canMarkArrived ? 4 : 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                canMarkArrived ? Icons.check_circle : Icons.location_on,
                color: canMarkArrived ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                canMarkArrived
                    ? "I'VE ARRIVED"
                    : "Get closer (${_getDistanceString()} away)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: canMarkArrived ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom map style
  static const String _mapStyle = '''
[
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  }
]
''';
}

class _DriverStage {
  final String name;
  final IconData icon;
  bool isCompleted;

  _DriverStage(this.name, this.icon, this.isCompleted);
}
