/// Validators for form fields and inputs
class Validators {
  Validators._();

  /// Validate email address
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validate confirm password
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate phone number (Pakistani format)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    // Pakistani phone: +92XXXXXXXXXX or 03XXXXXXXXX
    final phoneRegex = RegExp(r'^(\+92|0)?3[0-9]{9}$');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate name
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    return null;
  }

  /// Validate CNIC (Pakistani National ID)
  static String? cnic(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNIC is required';
    }
    // Remove dashes
    final cleaned = value.replaceAll('-', '');
    if (cleaned.length != 13) {
      return 'CNIC must be 13 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      return 'CNIC must contain only numbers';
    }
    return null;
  }

  /// Validate vehicle number plate
  static String? vehiclePlate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vehicle number is required';
    }
    // Pakistani format: ABC-123 or ABC-1234
    final plateRegex = RegExp(r'^[A-Z]{2,3}[-\s]?[0-9]{3,4}$', caseSensitive: false);
    if (!plateRegex.hasMatch(value)) {
      return 'Please enter a valid vehicle number';
    }
    return null;
  }

  /// Validate OTP
  static String? otp(String? value, {int length = 4}) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != length) {
      return 'OTP must be $length digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  /// Validate amount
  static String? amount(String? value, {double min = 0, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount < min) {
      return 'Amount must be at least $min';
    }
    if (max != null && amount > max) {
      return 'Amount cannot exceed $max';
    }
    return null;
  }

  /// Validate promo code
  static String? promoCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a promo code';
    }
    if (value.length < 4) {
      return 'Promo code must be at least 4 characters';
    }
    if (value.length > 20) {
      return 'Promo code is too long';
    }
    return null;
  }

  /// Validate required field
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
