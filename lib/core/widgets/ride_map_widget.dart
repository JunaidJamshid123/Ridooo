import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/directions_service.dart';
import '../theme/app_colors.dart';

/// A reusable map widget for displaying ride routes with real-time tracking
class RideMapWidget extends StatefulWidget {
  final LatLng? driverLocation;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final double? driverHeading;
  final String? driverName;
  final String? passengerName;
  final RideMapPhase phase;
  final bool showTrafficLayer;
  final bool enableZoomControls;
  final Function(GoogleMapController)? onMapCreated;
  final VoidCallback? onCameraMove;

  const RideMapWidget({
    super.key,
    this.driverLocation,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.driverHeading,
    this.driverName,
    this.passengerName,
    this.phase = RideMapPhase.driverToPickup,
    this.showTrafficLayer = false,
    this.enableZoomControls = true,
    this.onMapCreated,
    this.onCameraMove,
  });

  @override
  State<RideMapWidget> createState() => _RideMapWidgetState();
}

class _RideMapWidgetState extends State<RideMapWidget>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  final DirectionsService _directionsService = DirectionsService();

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};

  // Route data
  List<LatLng>? _driverToPickupRoute;
  List<LatLng>? _pickupToDropoffRoute;
  bool _isLoadingRoutes = true;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Custom markers
  BitmapDescriptor? _driverMarkerIcon;
  BitmapDescriptor? _pickupMarkerIcon;
  BitmapDescriptor? _dropoffMarkerIcon;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCustomMarkers();
    _loadRoutes();
  }

  @override
  void didUpdateWidget(RideMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload routes if locations changed
    if (oldWidget.driverLocation != widget.driverLocation ||
        oldWidget.pickupLocation != widget.pickupLocation ||
        oldWidget.dropoffLocation != widget.dropoffLocation ||
        oldWidget.phase != widget.phase) {
      _updateMarkersAndRoutes();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    _pulseAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _updateCircles();
        });
      }
    });
  }

  Future<void> _loadCustomMarkers() async {
    // Using default markers with custom colors
    _driverMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
    _pickupMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueGreen,
    );
    _dropoffMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueRed,
    );
    setState(() {});
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoadingRoutes = true);

    try {
      // Load pickup to dropoff route (always needed)
      final pickupToDropoffResult = await _directionsService.getDirections(
        origin: widget.pickupLocation,
        destination: widget.dropoffLocation,
        optimizeRoute: true,
      );

      if (pickupToDropoffResult != null) {
        _pickupToDropoffRoute = pickupToDropoffResult.polylinePoints;
      }

      // Load driver to pickup route if driver location is available
      if (widget.driverLocation != null) {
        final driverToPickupResult = await _directionsService.getDirections(
          origin: widget.driverLocation!,
          destination: widget.pickupLocation,
          optimizeRoute: true,
        );

        if (driverToPickupResult != null) {
          _driverToPickupRoute = driverToPickupResult.polylinePoints;
        }
      }
    } catch (e) {
      debugPrint('Error loading routes: $e');
    }

    setState(() {
      _isLoadingRoutes = false;
      _updateMarkersAndRoutes();
    });

    // Fit map to show all points
    _fitMapBounds();
  }

  void _updateMarkersAndRoutes() {
    _updateMarkers();
    _updatePolylines();
    _updateCircles();
  }

  void _updateMarkers() {
    _markers = {};

    // Driver marker
    if (widget.driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: widget.driverLocation!,
          icon: _driverMarkerIcon ?? BitmapDescriptor.defaultMarker,
          rotation: widget.driverHeading ?? 0,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          infoWindow: InfoWindow(
            title: widget.driverName ?? 'Driver',
            snippet: 'Your driver is on the way',
          ),
        ),
      );
    }

    // Pickup marker
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickupLocation,
        icon: _pickupMarkerIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: widget.passengerName ?? 'Passenger pickup point',
        ),
      ),
    );

    // Dropoff marker
    _markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: widget.dropoffLocation,
        icon: _dropoffMarkerIcon ?? BitmapDescriptor.defaultMarker,
        alpha: widget.phase == RideMapPhase.driverToPickup ? 0.6 : 1.0,
        infoWindow: const InfoWindow(
          title: 'Destination',
          snippet: 'Drop-off point',
        ),
      ),
    );
  }

  void _updatePolylines() {
    _polylines = {};

    switch (widget.phase) {
      case RideMapPhase.driverToPickup:
        // Show driver to pickup route (active)
        if (_driverToPickupRoute != null && _driverToPickupRoute!.isNotEmpty) {
          // Shadow line
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('driver_to_pickup_shadow'),
              points: _driverToPickupRoute!,
              color: Colors.black.withOpacity(0.2),
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
          // Main route (animated dash)
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
        }

        // Show pickup to dropoff route (faded preview)
        if (_pickupToDropoffRoute != null &&
            _pickupToDropoffRoute!.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('pickup_to_dropoff_preview'),
              points: _pickupToDropoffRoute!,
              color: Colors.grey.withOpacity(0.4),
              width: 4,
              geodesic: true,
              patterns: [PatternItem.dot, PatternItem.gap(8)],
              zIndex: 0,
            ),
          );
        }
        break;

      case RideMapPhase.pickupToDropoff:
        // Show pickup to dropoff route (active)
        if (_pickupToDropoffRoute != null &&
            _pickupToDropoffRoute!.isNotEmpty) {
          // Shadow line
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('trip_shadow'),
              points: _pickupToDropoffRoute!,
              color: Colors.black.withOpacity(0.2),
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
              polylineId: const PolylineId('trip_bg'),
              points: _pickupToDropoffRoute!,
              color: Colors.white,
              width: 7,
              geodesic: true,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
              zIndex: 1,
            ),
          );
          // Main route
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('trip_main'),
              points: _pickupToDropoffRoute!,
              color: AppColors.success,
              width: 5,
              geodesic: true,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
              zIndex: 2,
            ),
          );
        }
        break;

      case RideMapPhase.completed:
        // Show completed route (solid grey)
        if (_pickupToDropoffRoute != null &&
            _pickupToDropoffRoute!.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('completed_route'),
              points: _pickupToDropoffRoute!,
              color: Colors.grey,
              width: 4,
              geodesic: true,
              zIndex: 0,
            ),
          );
        }
        break;
    }
  }

  void _updateCircles() {
    _circles = {};

    final pulseValue = _pulseAnimation.value;

    switch (widget.phase) {
      case RideMapPhase.driverToPickup:
        // Pulse around pickup location
        _circles.add(
          Circle(
            circleId: const CircleId('pickup_pulse_outer'),
            center: widget.pickupLocation,
            radius: 30 + (pulseValue * 70),
            fillColor: AppColors.success.withOpacity(0.1 * (1 - pulseValue)),
            strokeColor: AppColors.success.withOpacity(0.3 * (1 - pulseValue)),
            strokeWidth: 2,
          ),
        );
        _circles.add(
          Circle(
            circleId: const CircleId('pickup_pulse_inner'),
            center: widget.pickupLocation,
            radius: 15,
            fillColor: AppColors.success.withOpacity(0.3),
            strokeColor: AppColors.success,
            strokeWidth: 2,
          ),
        );
        break;

      case RideMapPhase.pickupToDropoff:
        // Pulse around dropoff location
        _circles.add(
          Circle(
            circleId: const CircleId('dropoff_pulse_outer'),
            center: widget.dropoffLocation,
            radius: 30 + (pulseValue * 70),
            fillColor: AppColors.error.withOpacity(0.1 * (1 - pulseValue)),
            strokeColor: AppColors.error.withOpacity(0.3 * (1 - pulseValue)),
            strokeWidth: 2,
          ),
        );
        _circles.add(
          Circle(
            circleId: const CircleId('dropoff_pulse_inner'),
            center: widget.dropoffLocation,
            radius: 15,
            fillColor: AppColors.error.withOpacity(0.3),
            strokeColor: AppColors.error,
            strokeWidth: 2,
          ),
        );
        break;

      case RideMapPhase.completed:
        // No pulse for completed
        break;
    }
  }

  void _fitMapBounds() {
    if (_mapController == null) return;

    final points = <LatLng>[];

    if (widget.driverLocation != null) {
      points.add(widget.driverLocation!);
    }
    points.add(widget.pickupLocation);
    points.add(widget.dropoffLocation);

    if (points.length < 2) return;

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

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.pickupLocation,
            zoom: 14,
          ),
          markers: _markers,
          polylines: _polylines,
          circles: _circles,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: widget.enableZoomControls,
          mapToolbarEnabled: false,
          trafficEnabled: widget.showTrafficLayer,
          compassEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
            _setMapStyle();
            widget.onMapCreated?.call(controller);
            // Fit bounds after map is created
            Future.delayed(const Duration(milliseconds: 500), _fitMapBounds);
          },
          onCameraMove: (_) => widget.onCameraMove?.call(),
        ),

        // Loading indicator
        if (_isLoadingRoutes)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading route...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Center on route button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'centerMap',
            backgroundColor: Colors.white,
            onPressed: _fitMapBounds,
            child: const Icon(
              Icons.center_focus_strong,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _setMapStyle() async {
    // Clean modern map style
    const String mapStyle = '''
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
    await _mapController?.setMapStyle(mapStyle);
  }

  /// Refresh routes from current positions
  Future<void> refreshRoutes() async {
    await _loadRoutes();
  }

  /// Animate camera to show driver
  void focusOnDriver() {
    if (widget.driverLocation != null && _mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(widget.driverLocation!, 16),
      );
    }
  }

  /// Animate camera to show pickup
  void focusOnPickup() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(widget.pickupLocation, 16),
    );
  }
}

/// Represents the current phase of the ride
enum RideMapPhase { driverToPickup, pickupToDropoff, completed }
