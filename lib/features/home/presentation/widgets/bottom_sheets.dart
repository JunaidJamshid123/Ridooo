import 'package:flutter/material.dart';
import '../../../../core/services/directions_service.dart';
import '../../../../core/services/places_service.dart';
import 'location_widgets.dart';
import 'ride_type_card.dart';

/// Location selection bottom sheet
class LocationSelectionSheet extends StatelessWidget {
  final ScrollController scrollController;
  final PlaceDetails? pickupLocation;
  final PlaceDetails? destinationLocation;
  final String currentAddress;
  final VoidCallback onPickupTap;
  final VoidCallback onDestinationTap;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onClearPickup;
  final VoidCallback onClearDestination;

  const LocationSelectionSheet({
    super.key,
    required this.scrollController,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.currentAddress,
    required this.onPickupTap,
    required this.onDestinationTap,
    required this.onUseCurrentLocation,
    required this.onClearPickup,
    required this.onClearDestination,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        // Drag Handle - Enhanced
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[350],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),

        // Header - Enhanced
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Where to?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.8,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Set your pickup and destination',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Location Inputs - Enhanced
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Pickup Location
              LocationInput(
                icon: Icons.circle_outlined,
                iconColor: const Color(0xFF00C853),
                title: pickupLocation?.name ?? 'Pickup location',
                subtitle: pickupLocation?.formattedAddress ?? currentAddress,
                onTap: onPickupTap,
                trailing: pickupLocation == null
                    ? GestureDetector(
                        onTap: onUseCurrentLocation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.my_location,
                                size: 14,
                                color: Color(0xFF00C853),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF00C853),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: onClearPickup,
                      ),
              ),

              // Connecting Line
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Row(
                  children: [
                    Container(
                      width: 2,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF00C853).withOpacity(0.3),
                            const Color(0xFFFF1744).withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Destination Location
              LocationInput(
                icon: Icons.location_on,
                iconColor: const Color(0xFFFF1744),
                title: destinationLocation?.name ?? 'Where to?',
                subtitle: destinationLocation?.formattedAddress ?? 'Enter your destination',
                onTap: onDestinationTap,
                trailing: destinationLocation != null
                    ? IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onPressed: onClearDestination,
                      )
                    : const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Quick Access - InDrive Style
        if (pickupLocation == null && destinationLocation == null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Saved places',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const QuickAccessButtons(),
        ],

        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }
}

/// Ride options bottom sheet with ride type selection and pricing
class RideOptionsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final DirectionsResult? currentRoute;
  final String selectedRideType;
  final List<Map<String, dynamic>> rideTypes;
  final bool useCustomPrice;
  final double? customPrice;
  final TextEditingController customPriceController;
  final Function(String) onRideTypeSelected;
  final Function(bool) onCustomPriceToggle;
  final Function(String) onCustomPriceChanged;
  final VoidCallback onSearchDriver;

  const RideOptionsSheet({
    super.key,
    required this.scrollController,
    required this.currentRoute,
    required this.selectedRideType,
    required this.rideTypes,
    required this.useCustomPrice,
    required this.customPrice,
    required this.customPriceController,
    required this.onRideTypeSelected,
    required this.onCustomPriceToggle,
    required this.onCustomPriceChanged,
    required this.onSearchDriver,
  });

  @override
  Widget build(BuildContext context) {
    final fare = currentRoute?.calculateFare() ?? 0.0;
    final minimumFare = fare * 0.8;
    final selectedRide = rideTypes.firstWhere(
      (r) => r['name'] == selectedRideType,
    );
    final calculatedPrice = (fare * (selectedRide['price'] / 18.0));
    final displayPrice = useCustomPrice && customPrice != null ? customPrice! : calculatedPrice;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        // Drag Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Route Summary - Enhanced
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A1A),
                const Color(0xFF2D2D2D),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1A1A).withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${currentRoute?.distance ?? ''} • ${currentRoute?.duration ?? ''}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentRoute?.summary ?? 'Fastest route available',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Ride Selection Header - Enhanced
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Text(
                'Choose your ride',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${rideTypes.length} options',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Ride Type Cards
        SizedBox(
          height: 128,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: rideTypes.length,
            itemBuilder: (context, index) {
              final ride = rideTypes[index];
              final isSelected = ride['name'] == selectedRideType;
              final ridePrice = (fare * (ride['price'] / 18.0));
              return RideTypeCard(
                name: ride['name'],
                price: ridePrice,
                time: ride['time'],
                icon: ride['icon'],
                capacity: ride['capacity'],
                isSelected: isSelected,
                onTap: () => onRideTypeSelected(ride['name']),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Custom Price
        _buildCustomPriceSection(context, minimumFare, calculatedPrice),

        const SizedBox(height: 24),

        // Find Driver Button
        _buildFindDriverButton(context, displayPrice),

        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }

  Widget _buildCustomPriceSection(BuildContext context, double minimumFare, double calculatedPrice) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: useCustomPrice ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: useCustomPrice ? const Color(0xFFFFC107) : Colors.grey[200]!,
          width: useCustomPrice ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  size: 18,
                  color: useCustomPrice ? const Color(0xFFF57C00) : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Set your own price',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Switch(
                value: useCustomPrice,
                onChanged: onCustomPriceToggle,
                activeColor: const Color(0xFFFFC107),
              ),
            ],
          ),

          if (useCustomPrice) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Minimum: \$${minimumFare.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: customPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                labelText: 'Your price offer',
                labelStyle: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                prefixText: '\$ ',
                prefixStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
                hintText: '${calculatedPrice.toStringAsFixed(2)}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              ),
              onChanged: onCustomPriceChanged,
            ),
            if (customPriceController.text.isNotEmpty && (customPrice == null || customPrice! < minimumFare))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Must be at least \$${minimumFare.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFindDriverButton(BuildContext context, double displayPrice) {
    final isDisabled = useCustomPrice && customPrice == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDisabled
                ? [Colors.grey[350]!, Colors.grey[400]!]
                : [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2D2D2D),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDisabled)
              BoxShadow(
                color: const Color(0xFF1A1A1A).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: isDisabled ? null : onSearchDriver,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_rounded,
                size: 22,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              const Text(
                'Find Driver',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\$${displayPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Searching driver bottom sheet
class SearchingDriverSheet extends StatelessWidget {
  final ScrollController scrollController;
  final String selectedRideType;
  final double displayPrice;
  final VoidCallback onCancel;

  const SearchingDriverSheet({
    super.key,
    required this.scrollController,
    required this.selectedRideType,
    required this.displayPrice,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[350],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),

        // Searching Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Animated Loading Indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Searching for drivers...',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$selectedRideType \u2022 \$${displayPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Cancel Button
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
