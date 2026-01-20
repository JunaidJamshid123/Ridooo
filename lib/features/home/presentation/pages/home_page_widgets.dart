// Helper widgets for HomePage

Widget _buildLocationSelectionSheet(ScrollController scrollController) {
  return ListView(
    controller: scrollController,
    padding: EdgeInsets.zero,
    children: [
      // Drag Handle
      Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),

      // Location Card
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            _buildLocationInputRow(
              icon: Icons.circle,
              iconColor: AppColors.success,
              iconSize: 12,
              title: _pickupLocation?.name ?? 'Pickup Location',
              subtitle: _pickupLocation?.formattedAddress ?? 'Tap to select pickup point',
              onTap: () => _openLocationSearch(isPickup: true),
              trailing: _pickupLocation == null
                  ? TextButton(
                      onPressed: _useCurrentLocationAsPickup,
                      child: const Text('Use Current'),
                    )
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _pickupLocation = null;
                          _clearRoute();
                        });
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Divider(height: 1, color: Colors.grey[200]),
            ),
            _buildLocationInputRow(
              icon: Icons.location_on,
              iconColor: AppColors.error,
              iconSize: 20,
              title: _destinationLocation?.name ?? 'Where to?',
              subtitle: _destinationLocation?.formattedAddress ?? 'Enter destination',
              onTap: () => _openLocationSearch(isPickup: false),
              trailing: _destinationLocation != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _destinationLocation = null;
                          _clearRoute();
                        });
                      },
                    )
                  : null,
            ),
          ],
        ),
      ),

      const SizedBox(height: 24),

      // Quick Suggestions (optional)
      if (_pickupLocation == null && _destinationLocation == null) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Quick Suggestions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickSuggestions(),
      ],

      SizedBox(
        height: MediaQuery.of(context).padding.bottom + 16,
      ),
    ],
  );
}

Widget _buildRideOptionsSheet(ScrollController scrollController) {
  final fare = _currentRoute?.calculateFare() ?? 0.0;
  
  return ListView(
    controller: scrollController,
    padding: EdgeInsets.zero,
    children: [
      // Drag Handle
      Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),

      // Route Info
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.route, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_currentRoute?.distance ?? ''} • ${_currentRoute?.duration ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _currentRoute?.summary ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      // Ride Type Header
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Choose ride',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Est. \$${fare.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 14),

      // Horizontal Ride Types
      SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _rideTypes.length,
          itemBuilder: (context, index) {
            final ride = _rideTypes[index];
            final isSelected = ride['name'] == _selectedRideType;
            final ridePrice = (fare * (ride['price'] / 18.0));
            
            return _buildHorizontalRideCard(
              name: ride['name'],
              price: ridePrice,
              time: ride['time'],
              icon: ride['icon'],
              capacity: ride['capacity'],
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedRideType = ride['name'];
                });
              },
            );
          },
        ),
      ),

      const SizedBox(height: 20),

      // Confirm Button
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              final selectedRide = _rideTypes.firstWhere(
                (r) => r['name'] == _selectedRideType,
              );
              final ridePrice = (fare * (selectedRide['price'] / 18.0));
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Booking ${selectedRide['name']} • \$${ridePrice.toStringAsFixed(2)} • ${_currentRoute?.distance}',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Confirm $_selectedRideType',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• \$${(fare * (_rideTypes.firstWhere((r) => r['name'] == _selectedRideType)['price'] / 18.0)).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      SizedBox(
        height: MediaQuery.of(context).padding.bottom + 16,
      ),
    ],
  );
}

Widget _buildLocationInputRow({
  required IconData icon,
  required Color iconColor,
  required double iconSize,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  Widget? trailing,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Icon(icon, color: iconColor, size: iconSize),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    ),
  );
}

Widget _buildQuickSuggestions() {
  final suggestions = [
    {'icon': Icons.home, 'title': 'Home', 'subtitle': 'Add your home address'},
    {'icon': Icons.work, 'title': 'Work', 'subtitle': 'Add your work address'},
    {'icon': Icons.access_time, 'title': 'Recent', 'subtitle': 'Your recent places'},
  ];

  return SizedBox(
    height: 80,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 0,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      suggestion['icon'] as IconData,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      suggestion['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
