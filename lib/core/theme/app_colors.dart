import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Black & White Theme
  static const Color primary = Color(0xFF1A1A1A); // Dark grey/black for buttons
  static const Color primaryDark = Color(0xFF000000); // Pure black
  static const Color primaryLight = Color(0xFF2C2C2C); // Light black
  
  // Accent Colors
  static const Color accent = Color(0xFF333333);
  static const Color accentDark = Color(0xFF1A1A1A);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Background Colors
  static const Color background = Color(0xFFFFFFFF); // Pure white
  static const Color backgroundWhite = Color(0xFFFFFFFF); // Pure white
  static const Color backgroundGrey = Color(0xFFF8F8F8); // Very light grey
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  // Neutral Colors
  static const Color grey = Color(0xFF9CA3AF);
  static const Color greyLight = Color(0xFFE5E7EB);
  static const Color greyDark = Color(0xFF4B5563);
  
  // Shadow Colors
  static Color shadowLight = Colors.black.withOpacity(0.04);
  static Color shadowMedium = Colors.black.withOpacity(0.08);
  static Color shadowDark = Colors.black.withOpacity(0.12);
}
