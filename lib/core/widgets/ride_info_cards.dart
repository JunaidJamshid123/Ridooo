import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// A beautiful card to display driver information to passengers
class DriverInfoCard extends StatelessWidget {
  final String? driverName;
  final String? driverPhoto;
  final double? driverRating;
  final int? totalRides;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehiclePlate;
  final String? eta;
  final double? distance;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onShare;
  final bool isCompact;

  const DriverInfoCard({
    super.key,
    this.driverName,
    this.driverPhoto,
    this.driverRating,
    this.totalRides,
    this.vehicleModel,
    this.vehicleColor,
    this.vehiclePlate,
    this.eta,
    this.distance,
    this.onCall,
    this.onMessage,
    this.onShare,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildCompactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Driver photo
          _buildDriverAvatar(size: 48),
          const SizedBox(width: 12),

          // Driver info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      driverName ?? 'Driver',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRatingBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${vehicleModel ?? 'Vehicle'} • ${vehiclePlate ?? ''}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconButton(
                icon: Icons.message_rounded,
                onTap: onMessage,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.phone_rounded,
                onTap: onCall,
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with ETA
          if (eta != null || distance != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    eta != null ? '$eta' : '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (distance != null) ...[
                    const SizedBox(width: 16),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.directions_car_rounded,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${distance!.toStringAsFixed(1)} km',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),

          // Driver info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Driver photo with rating
                Stack(
                  children: [
                    _buildDriverAvatar(size: 64),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildRatingBadge()),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Driver details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName ?? 'Driver',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (totalRides != null)
                        Row(
                          children: [
                            Icon(
                              Icons.local_taxi_rounded,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalRides rides',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Action buttons
                Column(
                  children: [
                    _buildActionButton(
                      icon: Icons.phone_rounded,
                      label: 'Call',
                      onTap: onCall,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      icon: Icons.message_rounded,
                      label: 'Chat',
                      onTap: onMessage,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey[200]),

          // Vehicle info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Vehicle icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    size: 28,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),

                // Vehicle details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleModel ?? 'Vehicle',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (vehicleColor != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                vehicleColor!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // License plate
                if (vehiclePlate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      vehiclePlate!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Share button
          if (onShare != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onShare?.call();
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share Trip Details'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child:
            driverPhoto != null
                ? Image.network(
                  driverPhoto!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildDefaultAvatar(size),
                )
                : _buildDefaultAvatar(size),
      ),
    );
  }

  Widget _buildDefaultAvatar(double size) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.5,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            (driverRating ?? 4.8).toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A beautiful card to display passenger information to drivers
class PassengerInfoCard extends StatelessWidget {
  final String? passengerName;
  final String? passengerPhoto;
  final double? passengerRating;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? fare;
  final double? distance;
  final String? eta;
  final String? paymentMethod;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onNavigate;
  final bool isCompact;

  const PassengerInfoCard({
    super.key,
    this.passengerName,
    this.passengerPhoto,
    this.passengerRating,
    this.pickupAddress,
    this.dropoffAddress,
    this.fare,
    this.distance,
    this.eta,
    this.paymentMethod,
    this.onCall,
    this.onMessage,
    this.onNavigate,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    }
    return _buildFullCard(context);
  }

  Widget _buildCompactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Passenger photo
          _buildPassengerAvatar(size: 48),
          const SizedBox(width: 12),

          // Passenger info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      passengerName ?? 'Passenger',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRatingBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (paymentMethod != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              paymentMethod == 'cash'
                                  ? Icons.money_rounded
                                  : Icons.credit_card_rounded,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              paymentMethod!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (fare != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Rs${fare!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconButton(
                icon: Icons.message_rounded,
                onTap: onMessage,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.phone_rounded,
                onTap: onCall,
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with ETA and Distance
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  icon: Icons.access_time_rounded,
                  value: eta ?? '--',
                  label: 'ETA',
                ),
                Container(height: 30, width: 1, color: Colors.grey[300]),
                _buildInfoItem(
                  icon: Icons.route_rounded,
                  value: '${(distance ?? 0).toStringAsFixed(1)} km',
                  label: 'Distance',
                ),
                Container(height: 30, width: 1, color: Colors.grey[300]),
                _buildInfoItem(
                  icon: Icons.payments_rounded,
                  value: 'Rs${(fare ?? 0).toStringAsFixed(0)}',
                  label: 'Fare',
                  valueColor: AppColors.success,
                ),
              ],
            ),
          ),

          // Passenger info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Passenger photo with rating
                Stack(
                  children: [
                    _buildPassengerAvatar(size: 56),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildRatingBadge()),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Passenger details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passengerName ?? 'Passenger',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (paymentMethod != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                paymentMethod == 'cash'
                                    ? Colors.green[50]
                                    : Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                paymentMethod == 'cash'
                                    ? Icons.money_rounded
                                    : Icons.credit_card_rounded,
                                size: 14,
                                color:
                                    paymentMethod == 'cash'
                                        ? Colors.green[700]
                                        : Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                paymentMethod == 'cash'
                                    ? 'Cash Payment'
                                    : 'Card Payment',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      paymentMethod == 'cash'
                                          ? Colors.green[700]
                                          : Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Call and message buttons
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.message_rounded,
                      onTap: onMessage,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.phone_rounded,
                      onTap: onCall,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey[200]),

          // Location details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Pickup
                _buildLocationRow(
                  icon: Icons.circle,
                  iconColor: AppColors.success,
                  address: pickupAddress ?? 'Pickup location',
                  label: 'Pickup',
                ),
                // Connector line
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Container(
                    height: 24,
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.success, AppColors.error],
                      ),
                    ),
                  ),
                ),
                // Dropoff
                _buildLocationRow(
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.error,
                  address: dropoffAddress ?? 'Destination',
                  label: 'Drop-off',
                ),
              ],
            ),
          ),

          // Navigate button
          if (onNavigate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onNavigate?.call();
                  },
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Navigate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPassengerAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: ClipOval(
        child:
            passengerPhoto != null
                ? Image.network(
                  passengerPhoto!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildDefaultAvatar(size),
                )
                : _buildDefaultAvatar(size),
      ),
    );
  }

  Widget _buildDefaultAvatar(double size) {
    return Container(
      color: Colors.grey[100],
      child: Icon(
        Icons.person_rounded,
        size: size * 0.5,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            (passengerRating ?? 4.5).toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: valueColor ?? AppColors.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String address,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
