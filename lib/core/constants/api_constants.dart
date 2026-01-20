/// API related constants
class ApiConstants {
  ApiConstants._();

  // Google Maps
  static const String googleMapsBaseUrl = 'https://maps.googleapis.com/maps/api';
  static const String placesAutocomplete = '/place/autocomplete/json';
  static const String placeDetails = '/place/details/json';
  static const String directions = '/directions/json';
  static const String geocode = '/geocode/json';
  static const String distanceMatrix = '/distancematrix/json';

  // Supabase Tables
  static const String usersTable = 'users';
  static const String driversTable = 'drivers';
  static const String ridesTable = 'rides';
  static const String rideRequestsTable = 'ride_requests';
  static const String driverOffersTable = 'driver_offers';
  static const String driverLocationsTable = 'driver_locations';
  static const String vehicleTypesTable = 'vehicle_types';
  static const String fareConfigsTable = 'fare_configs';
  static const String walletsTable = 'wallets';
  static const String walletTransactionsTable = 'wallet_transactions';
  static const String paymentsTable = 'payments';
  static const String ratingsTable = 'ratings';
  static const String savedPlacesTable = 'saved_places';
  static const String notificationsTable = 'notifications';
  static const String chatMessagesTable = 'chat_messages';
  static const String promoCodesTable = 'promo_codes';
  static const String userPromoUsageTable = 'user_promo_usage';
  static const String supportTicketsTable = 'support_tickets';
  static const String supportMessagesTable = 'support_messages';
  static const String deviceTokensTable = 'device_tokens';
  static const String userSettingsTable = 'user_settings';
  static const String emergencyContactsTable = 'emergency_contacts';
  static const String sosAlertsTable = 'sos_alerts';

  // Supabase Storage Buckets
  static const String profilePhotosBucket = 'profile-photos';
  static const String driverDocumentsBucket = 'driver-documents';
  static const String chatMediaBucket = 'chat-media';

  // Supabase Realtime Channels
  static const String rideUpdatesChannel = 'ride-updates';
  static const String driverLocationChannel = 'driver-location';
  static const String chatChannel = 'chat';
  static const String notificationsChannel = 'notifications';
}
