import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Cached image widget with loading and error states
class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildShimmer(context),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildPlaceholder(context),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        size: (width ?? 100) * 0.3,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

/// Profile avatar with cached image
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 48,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget avatar;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CachedImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(size / 2),
      );
    } else {
      avatar = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _getInitials(),
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      );
    }

    if (showEditIcon) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: size * 0.2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';
    final names = name!.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return names[0][0].toUpperCase();
  }
}

/// Vehicle image with fallback
class VehicleImage extends StatelessWidget {
  final String? imageUrl;
  final String vehicleType; // 'bike', 'economy', 'standard', 'premium', 'xl'
  final double width;
  final double height;

  const VehicleImage({
    super.key,
    this.imageUrl,
    required this.vehicleType,
    this.width = 80,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.contain,
      );
    }

    // Fallback icon based on vehicle type
    IconData icon;
    switch (vehicleType.toLowerCase()) {
      case 'bike':
        icon = Icons.two_wheeler;
        break;
      case 'premium':
        icon = Icons.local_taxi;
        break;
      case 'xl':
        icon = Icons.airport_shuttle;
        break;
      default:
        icon = Icons.directions_car;
    }

    return SizedBox(
      width: width,
      height: height,
      child: Icon(
        icon,
        size: height * 0.8,
        color: Colors.grey.shade600,
      ),
    );
  }
}
