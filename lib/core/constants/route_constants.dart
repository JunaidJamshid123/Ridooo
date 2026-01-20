/// Route/Navigation constants
class RouteConstants {
  RouteConstants._();

  // Auth Routes
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';

  // User Routes
  static const String userHome = '/user/home';
  static const String userActivity = '/user/activity';
  static const String userPayment = '/user/payment';
  static const String userChat = '/user/chat';
  static const String userAccount = '/user/account';
  static const String userRideTracking = '/user/ride-tracking';
  static const String userRideSummary = '/user/ride-summary';
  static const String userRateDriver = '/user/rate-driver';
  static const String userRideDetails = '/user/ride-details';
  static const String userSavedPlaces = '/user/saved-places';
  static const String userAddPlace = '/user/add-place';
  static const String userWallet = '/user/wallet';
  static const String userAddMoney = '/user/add-money';

  // Driver Routes
  static const String driverHome = '/driver/home';
  static const String driverEarnings = '/driver/earnings';
  static const String driverTrips = '/driver/trips';
  static const String driverDocuments = '/driver/documents';
  static const String driverRideRequest = '/driver/ride-request';
  static const String driverNavigation = '/driver/navigation';
  static const String driverRideDetails = '/driver/ride-details';
  static const String driverWallet = '/driver/wallet';
  static const String driverWithdraw = '/driver/withdraw';

  // Shared Routes
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String chatRoom = '/chat-room';
  static const String support = '/support';
  static const String supportTicket = '/support-ticket';
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
}
