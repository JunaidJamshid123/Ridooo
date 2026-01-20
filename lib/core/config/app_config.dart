/// Application configuration constants
class AppConfig {
  AppConfig._();

  // App Info
  static const String appName = 'Ridooo';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Environment
  static const bool isProduction = false;
  static const bool enableLogging = true;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;

  // Location
  static const double defaultLatitude = 31.5204; // Lahore
  static const double defaultLongitude = 74.3587;
  static const int locationUpdateIntervalMs = 5000;

  // Ride
  static const int maxDriverSearchTimeSeconds = 120;
  static const int driverOfferExpirySeconds = 60;
  static const double maxSearchRadiusKm = 10.0;

  // Cache
  static const Duration cacheValidDuration = Duration(hours: 24);
}
