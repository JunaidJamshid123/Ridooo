import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/services/realtime_service.dart';
import '../../../../../core/services/directions_service.dart';
import '../../../../../injection_container.dart' as di;
import '../../../chat/presentation/pages/chat_screen_page.dart';
import '../../domain/entities/ride.dart';
import '../../domain/entities/driver_offer.dart';
import '../bloc/booking_bloc.dart';
import 'ride_summary_page.dart';

/// Enhanced Ride Tracking Page for User - Phase 2: Driver En Route to Pickup
class UserRideTrackingPage extends StatefulWidget {
  final Ride ride;
  final DriverOffer? acceptedOffer;

  const UserRideTrackingPage({
    super.key,
    required this.ride,
    this.acceptedOffer,
  });

  @override
  State<UserRideTrackingPage> createState() => _UserRideTrackingPageState();
}

class _UserRideTrackingPageState extends State<UserRideTrackingPage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  StreamSubscription? _driverLocationSubscription;
  Timer? _etaCountdownTimer;
  Timer? _pulseTimer;
  Timer? _routeUpdateTimer;
  Timer? _rideStatusPollTimer;  // Fallback polling for ride status

  // Directions service for real routes
  final DirectionsService _directionsService = DirectionsService();
  final _supabase = Supabase.instance.client;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};

  double? _driverLatitude;
  double? _driverLongitude;
  double? _driverHeading;
  int _etaMinutes = 5;
  int _etaSeconds = 0;
  double _distanceToPickup = 0;
  double _pulseRadius = 0;

  // Route points for accurate road display
  List<LatLng>? _driverToPickupRoute;
  List<LatLng>? _pickupToDropoffRoute;
  bool _isLoadingRoute = false;

  late Ride _currentRide;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _showTripDetails = false;

  // Ride stages
  final List<_RideStage> _rideStages = [
    _RideStage('Ride Confirmed', Icons.check_circle, true),
    _RideStage('Driver En Route', Icons.directions_car, true),
    _RideStage('Driver Arrived', Icons.location_on, false),
    _RideStage('Trip Started', Icons.play_arrow, false),
    _RideStage('Trip Completed', Icons.flag, false),
  ];

  @override
  void initState() {
    super.initState();
    _currentRide = widget.ride;
    _etaMinutes = widget.acceptedOffer?.etaMinutes ?? 5;

    // Initialize animations
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    _updateMarkers();
    _subscribeToDriverLocation();
    _subscribeToRideUpdates();
    _startEtaCountdown();
    _startRideStatusPolling();  // Fallback polling
    _loadRoutes(); // Load accurate road routes
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _etaCountdownTimer?.cancel();
    _pulseTimer?.cancel();
    _routeUpdateTimer?.cancel();
    _rideStatusPollTimer?.cancel();
    _pulseAnimationController.dispose();
    _slideController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Start polling ride status as fallback
  void _startRideStatusPolling() {
    _rideStatusPollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollRideStatus());
  }

  /// Poll ride status from Supabase
  Future<void> _pollRideStatus() async {
    try {
      final response = await _supabase
          .from('rides')
          .select('status, otp')
          .eq('id', _currentRide.id)
          .single();

      final status = response['status'] as String?;
      final otp = response['otp'] as String?;

      if (!mounted) return;

      // Only process if status changed
      if (status != _currentRide.status) {
        if (status == 'arrived') {
          setState(() {
            _currentRide = _currentRide.copyWith(status: 'arrived', otp: otp);
            _rideStages[2].isCompleted = true;
          });
          _showDriverArrivedDialog();
          HapticFeedback.heavyImpact();
        } else if (status == 'in_progress') {
          setState(() {
            _currentRide = _currentRide.copyWith(status: 'in_progress');
            _rideStages[3].isCompleted = true;
          });
          HapticFeedback.mediumImpact();
        } else if (status == 'completed') {
          _rideStatusPollTimer?.cancel();  // Stop polling
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RideSummaryPage(
                ride: _currentRide.copyWith(status: 'completed'),
                offer: widget.acceptedOffer,
              ),
            ),
          );
        } else if (status == 'cancelled') {
          _rideStatusPollTimer?.cancel();  // Stop polling
          _showRideCancelledDialog();
        }
      }
    } catch (e) {
      debugPrint('Error polling ride status: $e');
    }
  }

  /// Load accurate routes from Google Directions API
  Future<void> _loadRoutes() async {
    setState(() => _isLoadingRoute = true);

    try {
      // Load pickup to dropoff route
      final pickupToDropoff = await _directionsService.getDirections(
        origin: LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
        destination: LatLng(
          widget.ride.dropoffLatitude,
          widget.ride.dropoffLongitude,
        ),
        optimizeRoute: true,
      );

      if (pickupToDropoff != null) {
        _pickupToDropoffRoute = pickupToDropoff.polylinePoints;
      }

      // Load driver to pickup route if driver location is available
      if (_driverLatitude != null && _driverLongitude != null) {
        await _loadDriverToPickupRoute();
      }
    } catch (e) {
      debugPrint('Error loading routes: $e');
    }

    if (mounted) {
      setState(() {
        _isLoadingRoute = false;
        _updateMarkers();
      });
      _fitBounds();
    }
  }

  /// Load route from driver to pickup location
  Future<void> _loadDriverToPickupRoute() async {
    if (_driverLatitude == null || _driverLongitude == null) return;

    try {
      final driverToPickup = await _directionsService.getDirections(
        origin: LatLng(_driverLatitude!, _driverLongitude!),
        destination: LatLng(
          widget.ride.pickupLatitude,
          widget.ride.pickupLongitude,
        ),
        optimizeRoute: true,
      );

      if (driverToPickup != null && mounted) {
        setState(() {
          _driverToPickupRoute = driverToPickup.polylinePoints;
          // Update ETA from real directions
          final etaSeconds = int.tryParse(driverToPickup.durationValue) ?? 0;
          _etaMinutes = (etaSeconds / 60).ceil();
          if (_etaMinutes < 1) _etaMinutes = 1;
          _etaSeconds = etaSeconds;

          // Update distance
          final distanceMeters =
              double.tryParse(driverToPickup.distanceValue) ?? 0;
          _distanceToPickup = distanceMeters / 1000;
        });
      }
    } catch (e) {
      debugPrint('Error loading driver to pickup route: $e');
    }
  }

  void _startEtaCountdown() {
    _etaSeconds = _etaMinutes * 60;
    _etaCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_etaSeconds > 0) {
        setState(() {
          _etaSeconds--;
          _etaMinutes = (_etaSeconds / 60).ceil();
        });
      }
    });
  }

  void _subscribeToDriverLocation() {
    if (_currentRide.driverId == null) return;

    final realtimeService = di.sl<RealtimeService>();

    // Set up periodic route updates (every 30 seconds)
    _routeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_driverLatitude != null && _driverLongitude != null) {
        _loadDriverToPickupRoute();
      }
    });

    realtimeService.subscribeToDriverLocation(
      driverId: _currentRide.driverId!,
      onUpdate: (payload) {
        final lat = (payload['latitude'] as num?)?.toDouble();
        final lng = (payload['longitude'] as num?)?.toDouble();
        final heading = (payload['heading'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          final bool isFirstUpdate = _driverLatitude == null;

          setState(() {
            _driverLatitude = lat;
            _driverLongitude = lng;
            _driverHeading = heading;
            _updateMarkers();
            _calculateETA();
          });

          // Load route on first driver location update
          if (isFirstUpdate) {
            _loadDriverToPickupRoute();
          }

          // Smoothly animate camera to show driver
          _animateCameraToDriver();
        }
      },
    );
  }

  void _animateCameraToDriver() {
    if (_mapController == null ||
        _driverLatitude == null ||
        _driverLongitude == null)
      return;

    _fitBounds();
  }

  void _subscribeToRideUpdates() {
    final realtimeService = di.sl<RealtimeService>();

    realtimeService.subscribeToRideUpdates(
      rideId: _currentRide.id,
      onUpdate: (payload) {
        final status = payload['status'] as String?;

        if (status == 'arrived') {
          setState(() {
            _currentRide = _currentRide.copyWith(
              status: 'arrived',
              otp: payload['otp'] as String?,
            );
            _rideStages[2].isCompleted = true;
          });
          _showDriverArrivedDialog();
          HapticFeedback.heavyImpact();
        } else if (status == 'in_progress') {
          setState(() {
            _currentRide = _currentRide.copyWith(status: 'in_progress');
            _rideStages[3].isCompleted = true;
          });
          HapticFeedback.mediumImpact();
        } else if (status == 'completed') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RideSummaryPage(
                ride: _currentRide.copyWith(status: 'completed'),
                offer: widget.acceptedOffer,
              ),
            ),
          );
        } else if (status == 'cancelled') {
          _showRideCancelledDialog();
        }
      },
    );
  }

  void _calculateETA() {
    if (_driverLatitude == null || _driverLongitude == null) return;

    const double earthRadius = 6371;
    final dLat = _toRadians(widget.ride.pickupLatitude - _driverLatitude!);
    final dLng = _toRadians(widget.ride.pickupLongitude - _driverLongitude!);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(_driverLatitude!)) *
            math.cos(_toRadians(widget.ride.pickupLatitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;

    setState(() {
      _distanceToPickup = distance;
      _etaMinutes = (distance / 0.5).ceil();
      if (_etaMinutes < 1) _etaMinutes = 1;
      _etaSeconds = _etaMinutes * 60;
    });
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  void _updateMarkers() {
    _markers = {
      // Driver's location with custom car marker
      if (_driverLatitude != null && _driverLongitude != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(_driverLatitude!, _driverLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          rotation: _driverHeading ?? 0,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: widget.acceptedOffer?.driverName ?? 'Your Driver',
            snippet:
                '${widget.acceptedOffer?.vehicleModel ?? ''} • $_etaMinutes min away',
          ),
        ),
      // Pickup location (user's location) with pulse effect
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          widget.ride.pickupLatitude,
          widget.ride.pickupLongitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Your Pickup',
          snippet: widget.ride.pickupAddress,
        ),
      ),
      // Dropoff location
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(
          widget.ride.dropoffLatitude,
          widget.ride.dropoffLongitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        alpha: 0.6,
        infoWindow: InfoWindow(
          title: 'Your Destination',
          snippet: widget.ride.dropoffAddress,
        ),
      ),
    };

    // Pulsing circle around pickup
    _circles = {
      Circle(
        circleId: const CircleId('pickup_pulse'),
        center: LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
        radius: 50 + (_pulseAnimation.value * 100),
        fillColor: AppColors.success.withOpacity(
          0.1 * (1 - _pulseAnimation.value),
        ),
        strokeColor: AppColors.success.withOpacity(
          0.3 * (1 - _pulseAnimation.value),
        ),
        strokeWidth: 2,
      ),
    };

    // Draw routes using real road data from Directions API
    _polylines = {};

    // Draw driver to pickup route (if available)
    if (_driverToPickupRoute != null && _driverToPickupRoute!.isNotEmpty) {
      // Shadow line for depth
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('driver_to_pickup_shadow'),
          points: _driverToPickupRoute!,
          color: Colors.black.withOpacity(0.15),
          width: 10,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          zIndex: 0,
        ),
      );
      // White background
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('driver_to_pickup_bg'),
          points: _driverToPickupRoute!,
          color: Colors.white,
          width: 7,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          zIndex: 1,
        ),
      );
      // Main route line (animated dashed)
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('driver_to_pickup_main'),
          points: _driverToPickupRoute!,
          color: AppColors.primary,
          width: 5,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          zIndex: 2,
        ),
      );
    } else if (_driverLatitude != null && _driverLongitude != null) {
      // Fallback to simple line if route not loaded yet
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('driver_to_pickup_simple'),
          points: [
            LatLng(_driverLatitude!, _driverLongitude!),
            LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
          ],
          color: AppColors.primary,
          width: 4,
          patterns: [PatternItem.dash(15), PatternItem.gap(8)],
        ),
      );
    }

    // Draw pickup to dropoff route (preview, faded)
    if (_pickupToDropoffRoute != null && _pickupToDropoffRoute!.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('pickup_to_dropoff'),
          points: _pickupToDropoffRoute!,
          color: Colors.grey.withOpacity(0.4),
          width: 4,
          geodesic: true,
          patterns: [PatternItem.dot, PatternItem.gap(8)],
          zIndex: 0,
        ),
      );
    } else {
      // Fallback simple line
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('pickup_to_dropoff_simple'),
          points: [
            LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
            LatLng(widget.ride.dropoffLatitude, widget.ride.dropoffLongitude),
          ],
          color: Colors.grey.withOpacity(0.4),
          width: 3,
          patterns: [PatternItem.dot, PatternItem.gap(10)],
        ),
      );
    }
  }

  List<LatLng> _createCurvedRoute(LatLng start, LatLng end) {
    // Create a slight curve for better visual
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    final offset = (end.latitude - start.latitude).abs() * 0.1;

    return [start, LatLng(midLat + offset, midLng), end];
  }

  void _fitBounds() {
    if (_mapController == null) return;

    // Calculate bounds including all points
    final points = <LatLng>[
      LatLng(widget.ride.pickupLatitude, widget.ride.pickupLongitude),
      LatLng(widget.ride.dropoffLatitude, widget.ride.dropoffLongitude),
    ];

    if (_driverLatitude != null && _driverLongitude != null) {
      points.add(LatLng(_driverLatitude!, _driverLongitude!));
    }

    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 120));
  }

  void _showDriverArrivedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Driver Arrived!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your driver has arrived at the pickup location.',
                  textAlign: TextAlign.center,
                ),
                if (_currentRide.otp != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Share this OTP with your driver to start the trip:',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Text(
                      _currentRide.otp!,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('GOT IT'),
              ),
            ],
          ),
    );
  }

  void _showRideCancelledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.cancel, color: AppColors.error, size: 32),
                SizedBox(width: 12),
                Text('Ride Cancelled'),
              ],
            ),
            content: const Text(
              'Unfortunately, this ride has been cancelled. We apologize for the inconvenience.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _callDriver() async {
    HapticFeedback.lightImpact();
    final driverPhone = widget.acceptedOffer?.driverPhone;
    if (driverPhone == null || driverPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Driver phone number not available'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final uri = Uri.parse('tel:$driverPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _messageDriver() async {
    HapticFeedback.lightImpact();
    
    // Open in-app chat with driver
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreenPage(
          recipientId: widget.acceptedOffer?.driverId ?? '',
          recipientName: widget.acceptedOffer?.driverName ?? 'Driver',
          recipientImage: widget.acceptedOffer?.driverPhoto,
          recipientPhone: widget.acceptedOffer?.driverPhone,
          rideId: widget.ride.id,
          rideStatus: widget.ride.status,
          pickupAddress: widget.ride.pickupAddress,
          dropoffAddress: widget.ride.dropoffAddress,
          isOnline: true,
        ),
      ),
    );
  }

  Future<void> _shareRide() async {
    HapticFeedback.lightImpact();
    final driverName = widget.acceptedOffer?.driverName ?? 'Driver';
    final vehicleInfo =
        '${widget.acceptedOffer?.vehicleModel ?? ''} ${widget.acceptedOffer?.vehiclePlate ?? ''}';
    final shareText = '''
🚗 I'm on my way!

Driver: $driverName
Vehicle: $vehicleInfo
From: ${widget.ride.pickupAddress}
To: ${widget.ride.dropoffAddress}
ETA: $_etaMinutes minutes

Track my ride on Ridooo App!
    ''';

    await Share.share(shareText, subject: 'My Ride Details');
  }

  void _cancelRide() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Cancel Ride?'),
            content: const Text(
              'Are you sure you want to cancel this ride? Cancellation charges may apply.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('NO, KEEP RIDE'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<BookingBloc>().add(
                    CancelRideRequested(
                      rideId: _currentRide.id,
                      reason: 'User cancelled',
                    ),
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

  @override
  Widget build(BuildContext context) {
    final isArrived = _currentRide.status == 'arrived';
    final isInProgress = _currentRide.status == 'in_progress';

    return Scaffold(
      body: Stack(
        children: [
          // Map
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              _updateMarkers(); // Update circles with animation
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    widget.ride.pickupLatitude,
                    widget.ride.pickupLongitude,
                  ),
                  zoom: 15,
                ),
                markers: _markers,
                polylines: _polylines,
                circles: _circles,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Set custom map style for cleaner look
                  controller.setMapStyle(_mapStyle);
                },
              );
            },
          ),

          // Top Status Bar with animation
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Back button
                  _buildCircularButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  // Status pill
                  Expanded(child: _buildStatusPill(isArrived, isInProgress)),
                  const SizedBox(width: 12),
                  // Share button
                  _buildCircularButton(
                    icon: Icons.share,
                    onPressed: _shareRide,
                  ),
                ],
              ),
            ),
          ),

          // Recenter button
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.45,
            child: _buildCircularButton(
              icon: Icons.my_location,
              onPressed: _fitBounds,
              size: 44,
            ),
          ),

          // SOS Button
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 80,
            child: _buildSosButton(),
          ),

          // Bottom Panel with slide animation
          SlideTransition(
            position: _slideAnimation,
            child: DraggableScrollableSheet(
              initialChildSize: 0.42,
              minChildSize: 0.25,
              maxChildSize: 0.75,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
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

                        // Ride progress indicator
                        _buildRideProgressIndicator(),

                        const Divider(height: 24),

                        // Driver Info Card
                        _buildDriverInfoCard(),

                        const Divider(height: 24),

                        // Vehicle Info
                        _buildVehicleInfo(),

                        // Trip details (expandable)
                        _buildTripDetails(),

                        // OTP Display (when driver arrived)
                        if (isArrived && _currentRide.otp != null)
                          _buildOtpDisplay(),

                        const SizedBox(height: 16),

                        // Action Buttons
                        _buildActionButtons(),

                        // Cancel Button
                        if (!isArrived && !isInProgress)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            child: TextButton(
                              onPressed: _cancelRide,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text('Cancel Ride'),
                            ),
                          )
                        else
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
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: size * 0.45),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildStatusPill(bool isArrived, bool isInProgress) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isArrived) {
      statusColor = AppColors.success;
      statusText = 'Driver Arrived';
      statusIcon = Icons.location_on;
    } else if (isInProgress) {
      statusColor = AppColors.info;
      statusText = 'Trip in Progress';
      statusIcon = Icons.directions_car;
    } else {
      statusColor = Colors.orange;
      statusText = 'Driver En Route';
      statusIcon = Icons.navigation;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              statusText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isArrived && !isInProgress) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_etaMinutes min',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSosButton() {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        // TODO: Implement SOS functionality
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.emergency, color: Colors.white),
                SizedBox(width: 8),
                Text('Emergency services will be contacted'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, color: Colors.white, size: 20),
            Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_rideStages.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Line between stages
            final stageIndex = index ~/ 2;
            final isCompleted = _rideStages[stageIndex].isCompleted;
            return Expanded(
              child: Container(
                height: 3,
                color: isCompleted ? AppColors.success : Colors.grey.shade300,
              ),
            );
          } else {
            // Stage icon
            final stageIndex = index ~/ 2;
            final stage = _rideStages[stageIndex];
            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color:
                    stage.isCompleted
                        ? AppColors.success
                        : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(stage.icon, color: Colors.white, size: 16),
            );
          }
        }),
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Driver Photo with status indicator
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 3),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      widget.acceptedOffer?.driverPhoto != null
                          ? NetworkImage(widget.acceptedOffer!.driverPhoto!)
                          : null,
                  child:
                      widget.acceptedOffer?.driverPhoto == null
                          ? const Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.grey,
                          )
                          : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Driver Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.acceptedOffer?.driverName ?? 'Your Driver',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            widget.acceptedOffer?.driverRating.toStringAsFixed(
                                  1,
                                ) ??
                                '4.5',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.acceptedOffer?.driverTotalRides ?? 0} rides',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Call & Message Buttons
          _buildActionIconButton(
            icon: Icons.message,
            color: AppColors.info,
            onTap: _messageDriver,
          ),
          const SizedBox(width: 8),
          _buildActionIconButton(
            icon: Icons.phone,
            color: AppColors.success,
            onTap: _callDriver,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildVehicleInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.acceptedOffer?.vehicleModel ?? 'Vehicle',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (widget.acceptedOffer?.vehicleColor != null) ...[
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _getColorFromName(
                            widget.acceptedOffer!.vehicleColor,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      widget.acceptedOffer?.vehiclePlate ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Fare
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.2),
                  AppColors.success.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '₨${widget.acceptedOffer?.offeredPrice.toStringAsFixed(0) ?? widget.ride.estimatedFare.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
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
      onExpansionChanged:
          (expanded) => setState(() => _showTripDetails = expanded),
      children: [
        // Pickup
        _buildLocationRow(
          icon: Icons.trip_origin,
          iconColor: AppColors.success,
          label: 'Pickup',
          address: widget.ride.pickupAddress,
        ),
        const SizedBox(height: 16),
        // Dropoff
        _buildLocationRow(
          icon: Icons.location_on,
          iconColor: AppColors.error,
          label: 'Dropoff',
          address: widget.ride.dropoffAddress,
        ),
        const SizedBox(height: 16),
        // Distance & Time
        Row(
          children: [
            Expanded(
              child: _buildInfoChip(
                icon: Icons.straighten,
                label: '${widget.ride.distanceKm.toStringAsFixed(1)} km',
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
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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

  Widget _buildOtpDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Text(
                'Trip OTP',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentRide.otp!,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this code with your driver',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _callDriver,
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _messageDriver,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _shareRide,
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                'Share Trip',
                style: TextStyle(color: Colors.white),
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

  Color _getColorFromName(String colorName) {
    final colors = {
      'white': Colors.white,
      'black': Colors.black,
      'silver': Colors.grey.shade400,
      'gray': Colors.grey,
      'grey': Colors.grey,
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'brown': Colors.brown,
      'gold': Colors.amber,
    };
    return colors[colorName.toLowerCase()] ?? Colors.grey;
  }

  // Custom map style for cleaner look
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

class _RideStage {
  final String name;
  final IconData icon;
  bool isCompleted;

  _RideStage(this.name, this.icon, this.isCompleted);
}
