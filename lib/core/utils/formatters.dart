import 'package:intl/intl.dart';

/// Formatters for dates, currencies, and other data types
class Formatters {
  Formatters._();

  // ==================== DATE FORMATTERS ====================

  /// Format date as "Jan 15, 2025"
  static String dateShort(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  /// Format date as "January 15, 2025"
  static String dateLong(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  /// Format date as "15/01/2025"
  static String dateNumeric(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format time as "2:30 PM"
  static String time12Hour(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  /// Format time as "14:30"
  static String time24Hour(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format date and time as "Jan 15, 2025 at 2:30 PM"
  static String dateTime(DateTime date) {
    return DateFormat('MMM d, y \'at\' h:mm a').format(date);
  }

  /// Format date as relative time (e.g., "2 hours ago", "Yesterday")
  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return dateShort(date);
    }
  }

  /// Format duration as "5 min" or "1 hr 30 min"
  static String duration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '$hours hr';
      }
      return '$hours hr $minutes min';
    }
  }

  // ==================== CURRENCY FORMATTERS ====================

  /// Format as Pakistani Rupees: "Rs. 1,500"
  static String currency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format as Pakistani Rupees with decimals: "Rs. 1,500.50"
  static String currencyWithDecimals(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format compact currency: "Rs. 1.5K" for 1500
  static String currencyCompact(double amount) {
    if (amount < 1000) {
      return currency(amount);
    }
    final formatter = NumberFormat.compactCurrency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }

  // ==================== DISTANCE FORMATTERS ====================

  /// Format distance as "2.5 km" or "500 m"
  static String distance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  // ==================== PHONE FORMATTERS ====================

  /// Format phone number as "+92 300 1234567"
  static String phone(String phone) {
    // Remove all non-digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 11 && digits.startsWith('0')) {
      // Format: 0300 1234567
      return '${digits.substring(0, 4)} ${digits.substring(4)}';
    } else if (digits.length == 12 && digits.startsWith('92')) {
      // Format: +92 300 1234567
      return '+${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5)}';
    }
    return phone; // Return as-is if format unknown
  }

  /// Mask phone number as "+92 *** ***4567"
  static String phoneMasked(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 7) {
      final lastFour = digits.substring(digits.length - 4);
      return '+92 *** ***$lastFour';
    }
    return phone;
  }

  // ==================== CNIC FORMATTER ====================

  /// Format CNIC as "12345-1234567-1"
  static String cnic(String cnic) {
    final digits = cnic.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 13) {
      return '${digits.substring(0, 5)}-${digits.substring(5, 12)}-${digits.substring(12)}';
    }
    return cnic;
  }

  // ==================== RATING FORMATTER ====================

  /// Format rating as "4.5" or "4.5 (123)"
  static String rating(double rating, {int? count}) {
    final formatted = rating.toStringAsFixed(1);
    if (count != null) {
      return '$formatted ($count)';
    }
    return formatted;
  }

  // ==================== VEHICLE PLATE FORMATTER ====================

  /// Format vehicle plate as "ABC-1234"
  static String vehiclePlate(String plate) {
    final cleaned = plate.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length >= 6) {
      final letters = cleaned.substring(0, cleaned.length - 4);
      final numbers = cleaned.substring(cleaned.length - 4);
      return '$letters-$numbers';
    }
    return plate.toUpperCase();
  }
}
