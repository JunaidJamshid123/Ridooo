import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection_container.dart';
import '../../../../user/booking/domain/entities/ride.dart';
import '../../../rides/presentation/bloc/driver_rides_bloc.dart';
import '../../../rides/presentation/bloc/driver_rides_event.dart';
import '../../../rides/presentation/bloc/driver_rides_state.dart';
import '../../../rides/presentation/widgets/create_offer_bottom_sheet.dart';
import '../../../rides/presentation/pages/active_ride_page.dart';

/// Driver rides page - shows available ride requests from real Supabase data
class DriverRidesPage extends StatefulWidget {
  const DriverRidesPage({super.key});

  @override
  State<DriverRidesPage> createState() => _DriverRidesPageState();
}

class _DriverRidesPageState extends State<DriverRidesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, Timer> _offerTimers = {};
  
  String? _driverName;
  String? _driverPhone;
  String? _driverPhoto;
  double _driverRating = 4.5;
  int _driverTotalRides = 0;
  String _vehicleModel = 'Unknown';
  String? _vehicleColor;
  String _vehiclePlate = 'Unknown';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Fetch user data
      final userData = await supabase
          .from('users')
          .select('name, phone_number, profile_image')
          .eq('id', currentUser.id)
          .maybeSingle();

      // Fetch driver profile
      final driverData = await supabase
          .from('drivers')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _driverName = userData?['name'] as String? ?? 'Driver';
          _driverPhone = userData?['phone_number'] as String?;
          _driverPhoto = userData?['profile_image'] as String?;
          _driverRating = (driverData?['rating'] as num?)?.toDouble() ?? 4.5;
          _driverTotalRides = driverData?['total_rides'] as int? ?? 0;
          _vehicleModel = driverData?['vehicle_model'] as String? ?? 'Unknown';
          _vehicleColor = driverData?['vehicle_color'] as String?;
          _vehiclePlate = driverData?['vehicle_plate'] as String? ?? 'Unknown';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading driver profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var timer in _offerTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Create the bloc with fetched driver info
    return BlocProvider(
      create: (context) => sl<DriverRidesBloc>(
        param1: DriverBlocParams(
          driverId: currentUser.id,
          driverName: _driverName ?? 'Driver',
          driverPhone: _driverPhone,
          driverPhoto: _driverPhoto,
          driverRating: _driverRating,
          driverTotalRides: _driverTotalRides,
          vehicleModel: _vehicleModel,
          vehicleColor: _vehicleColor,
          vehiclePlate: _vehiclePlate,
        ),
      ),
      child: _DriverRidesContent(
        tabController: _tabController,
      ),
    );
  }
}

class _DriverRidesContent extends StatefulWidget {
  final TabController tabController;

  const _DriverRidesContent({
    required this.tabController,
  });

  @override
  State<_DriverRidesContent> createState() => _DriverRidesContentState();
}

class _DriverRidesContentState extends State<_DriverRidesContent> {
  bool _isOnline = false;
  Timer? _refreshTimer;
  
  // TODO: Get actual location from GPS
  double _currentLat = 31.5204;
  double _currentLng = 74.3587;

  @override
  void initState() {
    super.initState();
    _initializeBloc();
  }

  void _initializeBloc() {
    // Start listening for new rides
    context.read<DriverRidesBloc>().add(const ListenToNewRides());
    context.read<DriverRidesBloc>().add(const ListenToOfferStatus());
    
    // Load nearby rides
    _loadNearbyRides();
  }

  void _loadNearbyRides() {
    context.read<DriverRidesBloc>().add(LoadNearbyRideRequests(
      latitude: _currentLat,
      longitude: _currentLng,
      radiusKm: 15,
    ));
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isOnline && mounted) {
        context.read<DriverRidesBloc>().add(RefreshRides(
          latitude: _currentLat,
          longitude: _currentLng,
        ));
      }
    });
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });
    
    context.read<DriverRidesBloc>().add(ToggleOnlineStatus(_isOnline));
    
    if (_isOnline) {
      context.read<DriverRidesBloc>().add(UpdateDriverLocation(
        latitude: _currentLat,
        longitude: _currentLng,
        isOnline: true,
      ));
      _loadNearbyRides();
      _startAutoRefresh();
    } else {
      _refreshTimer?.cancel();
    }
  }

  void _showCreateOfferSheet(Ride ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<DriverRidesBloc>(),
        child: CreateOfferBottomSheet(ride: ride),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Rides',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: widget.tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(
                  child: BlocBuilder<DriverRidesBloc, DriverRidesState>(
                    builder: (context, state) {
                      int count = 0;
                      if (state is NearbyRidesLoaded) {
                        count = state.rides.length;
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Available'),
                          if (count > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const Tab(text: 'History'),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: widget.tabController,
              children: [
                _buildAvailableRidesTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableRidesTab() {
    return BlocConsumer<DriverRidesBloc, DriverRidesState>(
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
          Navigator.pop(context);
        } else if (state is OfferAccepted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
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
        } else if (state is NearbyRidesLoaded) {
          if (state.isOnline != _isOnline) {
            setState(() {
              _isOnline = state.isOnline;
            });
          }
        }
      },
      builder: (context, state) {
        if (state is DriverRidesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is NearbyRidesLoaded) {
          if (state.rides.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _loadNearbyRides(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.rides.length,
              itemBuilder: (context, index) {
                final ride = state.rides[index];
                final hasActiveOffer = state.activeOffer?.rideId == ride.id;
                return _buildRideRequestCard(ride, hasActiveOffer);
              },
            ),
          );
        }

        // Initial state - show loading or empty
        return _buildEmptyState();
      },
    );
  }

  Widget _buildRideRequestCard(Ride ride, bool hasActiveOffer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status indicator
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: hasActiveOffer ? Colors.orange : Colors.green,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ride Request',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                ride.vehicleType,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Time indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getTimeAgo(ride.createdAt),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Drivers offering badge
                if (!hasActiveOffer)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_taxi, size: 14, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '${(ride.hashCode % 5) + 1} offering',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Pickup and destination
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.grey.shade300,
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.pickupAddress,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            ride.dropoffAddress,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Ride details
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              ride.offeredPrice != null ? "User's Offer" : 'Est. Fare',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₨${(ride.offeredPrice ?? ride.estimatedFare).toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Distance',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ride.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Duration',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ride.estimatedDurationMinutes} min',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Make offer button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: hasActiveOffer 
                        ? null 
                        : () => _showCreateOfferSheet(ride),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasActiveOffer 
                          ? Colors.grey 
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      hasActiveOffer ? 'Offer Sent' : 'Make an Offer',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else {
      return '${diff.inHours}h';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_taxi_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No rides available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh or check back later',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadNearbyRides,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return _DriverHistoryTab();
  }

  Widget _buildCompletedRideCard(Map<String, dynamic> ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ride['date'] ?? '',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ride['userName'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text('${ride['pickup']} → ${ride['destination']}'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${ride['distance']} • ${ride['duration']}'),
              Text(
                '₨${ride['driverEarnings']?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Driver History Tab - Loads completed rides from Supabase
class _DriverHistoryTab extends StatefulWidget {
  @override
  State<_DriverHistoryTab> createState() => _DriverHistoryTabState();
}

class _DriverHistoryTabState extends State<_DriverHistoryTab> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _completedRides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedRides();
  }

  Future<void> _loadCompletedRides() async {
    try {
      final driverId = _supabase.auth.currentUser?.id;
      if (driverId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Get completed rides where driver had accepted offers
      final response = await _supabase
          .from('driver_offers')
          .select('''
            id,
            offered_price,
            status,
            ride:ride_id(
              id,
              status,
              pickup_address,
              dropoff_address,
              distance_km,
              estimated_duration_minutes,
              final_fare,
              created_at,
              completed_at,
              user:user_id(name, phone_number, profile_image)
            )
          ''')
          .eq('driver_id', driverId)
          .eq('status', 'accepted')
          .order('created_at', ascending: false)
          .limit(50);

      final List<Map<String, dynamic>> rides = [];

      for (final offer in response as List) {
        final ride = offer['ride'];
        if (ride == null) continue;
        
        final status = ride['status'] as String?;
        if (status != 'completed' && status != 'cancelled') continue;

        final user = ride['user'];
        final userName = user?['name'] as String? ?? 'Passenger';
        final pickup = _shortenAddress(ride['pickup_address'] as String? ?? '');
        final dropoff = _shortenAddress(ride['dropoff_address'] as String? ?? '');
        final distance = ride['distance_km'] as num? ?? 0;
        final duration = ride['estimated_duration_minutes'] as num? ?? 0;
        final fare = (ride['final_fare'] ?? offer['offered_price']) as num? ?? 0;

        String date = 'Unknown';
        if (ride['completed_at'] != null) {
          date = _formatDate(DateTime.parse(ride['completed_at'] as String));
        } else if (ride['created_at'] != null) {
          date = _formatDate(DateTime.parse(ride['created_at'] as String));
        }

        rides.add({
          'id': ride['id'],
          'status': status,
          'userName': userName,
          'pickup': pickup,
          'destination': dropoff,
          'distance': '${distance.toStringAsFixed(1)} km',
          'duration': '$duration min',
          'driverEarnings': fare.toDouble(),
          'date': date,
        });
      }

      setState(() {
        _completedRides = rides;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  String _shortenAddress(String address) {
    final parts = address.split(',');
    return parts.isNotEmpty ? parts.first.trim() : address;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final rideDate = DateTime(date.year, date.month, date.day);

    if (rideDate == today) {
      return 'Today';
    } else if (rideDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_completedRides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No completed rides yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ride history will appear here',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCompletedRides,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedRides.length,
        itemBuilder: (context, index) {
          final ride = _completedRides[index];
          return _buildHistoryCard(ride);
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> ride) {
    final isCompleted = ride['status'] == 'completed';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ride['date'] ?? '',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'Cancelled',
                  style: TextStyle(
                    color: isCompleted ? Colors.green.shade700 : Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ride['userName'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride['pickup'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride['destination'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.straighten, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${ride['distance']}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${ride['duration']}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              Text(
                'Rs. ${ride['driverEarnings']?.toStringAsFixed(0) ?? '0'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
