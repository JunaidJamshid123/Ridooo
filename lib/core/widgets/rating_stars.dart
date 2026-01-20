import 'package:flutter/material.dart';

/// Rating stars widget for displaying and inputting ratings
class RatingStars extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool interactive;
  final void Function(int)? onRatingChanged;
  final bool showValue;

  const RatingStars({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.interactive = false,
    this.onRatingChanged,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = activeColor ?? Colors.amber;
    final inactive = inactiveColor ?? Colors.grey.shade300;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxRating, (index) {
          final starNumber = index + 1;
          IconData icon;
          Color color;

          if (rating >= starNumber) {
            icon = Icons.star;
            color = active;
          } else if (rating >= starNumber - 0.5) {
            icon = Icons.star_half;
            color = active;
          } else {
            icon = Icons.star_border;
            color = inactive;
          }

          final star = Icon(icon, size: size, color: color);

          if (interactive) {
            return GestureDetector(
              onTap: () => onRatingChanged?.call(starNumber),
              child: star,
            );
          }
          return star;
        }),
        if (showValue) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

/// Interactive rating input widget
class RatingInput extends StatefulWidget {
  final int initialRating;
  final int maxRating;
  final double size;
  final void Function(int) onRatingChanged;
  final String? label;

  const RatingInput({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.size = 40,
    required this.onRatingChanged,
    this.label,
  });

  @override
  State<RatingInput> createState() => _RatingInputState();
}

class _RatingInputState extends State<RatingInput> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.maxRating, (index) {
            final starNumber = index + 1;
            final isActive = _currentRating >= starNumber;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentRating = starNumber;
                });
                widget.onRatingChanged(starNumber);
              },
              child: AnimatedScale(
                scale: isActive ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  isActive ? Icons.star : Icons.star_border,
                  size: widget.size,
                  color: isActive ? Colors.amber : Colors.grey.shade400,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _getRatingLabel(_currentRating),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Small inline rating display
class RatingBadge extends StatelessWidget {
  final double rating;
  final int? count;

  const RatingBadge({
    super.key,
    required this.rating,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (count != null) ...[
            Text(
              ' ($count)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
