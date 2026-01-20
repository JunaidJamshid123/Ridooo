import 'dart:math' as Math;
import 'package:flutter/material.dart';

/// Custom painter for ripple effect animation (InDrive style)
class RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Offset center;
  final Color color;

  RipplePainter({
    required this.animation,
    required this.center,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw multiple ripples at different stages
    for (int i = 0; i < 3; i++) {
      final progress = (animation.value + (i * 0.33)) % 1.0;
      final radius = 80 + (progress * 100);
      final opacity = (1.0 - progress) * 0.4;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);

      // Inner filled circle
      if (i == 0) {
        final fillPaint = Paint()
          ..color = color.withOpacity(opacity * 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius * 0.8, fillPaint);
      }
    }

    // Draw central pulsing dot
    final pulsePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final pulseRadius = 8 + (Math.sin(animation.value * Math.pi * 2) * 4);
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    // Outer ring
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, pulseRadius + 4, ringPaint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) => true;
}
