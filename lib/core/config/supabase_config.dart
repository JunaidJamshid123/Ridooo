import 'env_config.dart';

class SupabaseConfig {
  static String get supabaseUrl => EnvConfig.supabaseUrl;
  static String get supabaseAnonKey => EnvConfig.supabaseAnonKey;
  
  // Table names
  static const String usersTable = 'users';
  static const String driversTable = 'drivers';
  static const String ridesTable = 'rides';
  
  // Storage buckets
  static const String profileImagesBucket = 'profile-images';
}
