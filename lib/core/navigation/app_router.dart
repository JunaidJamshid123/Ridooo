import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/route_constants.dart';

// Auth Pages
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';

// Splash
import '../../features/splash/presentation/pages/splash_page.dart';

// User Pages
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/user/activity/presentation/pages/activity_page.dart';
import '../../features/user/payment/presentation/pages/payment_page.dart';
import '../../features/user/chat/presentation/pages/user_chat_list_page.dart';
import '../../features/user/chat/presentation/pages/chat_screen_page.dart';
import '../../features/user/profile/presentation/pages/user_profile_page.dart';
import '../../features/user/booking/presentation/pages/rate_driver_page.dart';
import '../../features/user/booking/presentation/pages/ride_summary_page.dart';
import '../../features/user/booking/presentation/pages/user_ride_tracking_page.dart';
import '../../features/user/booking/presentation/pages/incoming_offers_page.dart';
import '../../features/user/booking/domain/entities/ride.dart';
import '../../features/user/booking/domain/entities/driver_offer.dart';

// Driver Pages
import '../../features/driver/home/presentation/pages/driver_home_page.dart';
import '../../features/driver/earnings/presentation/pages/earnings_page.dart';
import '../../features/driver/trips/presentation/pages/driver_rides_page.dart';
import '../../features/driver/profile/presentation/pages/driver_profile_page.dart';
import '../../features/driver/rides/presentation/pages/available_rides_page.dart';

// Shared Pages
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';

// Navigation Shells
import 'main_navigation.dart';
import 'driver_navigation.dart';

/// Main app router configuration using GoRouter
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    routes: [
      // ==================== Auth Routes ====================
      GoRoute(
        path: RouteConstants.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteConstants.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: RouteConstants.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteConstants.signup,
        name: 'signup',
        builder: (context, state) => const SignupPage(),
      ),

      // ==================== User Routes (Shell) ====================
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return const MainNavigation();
        },
        routes: [
          GoRoute(
            path: RouteConstants.userHome,
            name: 'userHome',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: RouteConstants.userActivity,
            name: 'userActivity',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UserActivityPage(),
            ),
          ),
          GoRoute(
            path: RouteConstants.userPayment,
            name: 'userPayment',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UserPaymentPage(),
            ),
          ),
          GoRoute(
            path: RouteConstants.userChat,
            name: 'userChat',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UserChatListPage(),
            ),
          ),
          GoRoute(
            path: RouteConstants.userAccount,
            name: 'userAccount',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UserProfilePage(),
            ),
          ),
        ],
      ),

      // ==================== User Standalone Routes ====================
      GoRoute(
        path: RouteConstants.userRideTracking,
        name: 'userRideTracking',
        builder: (context, state) {
          final ride = state.extra as Ride?;
          if (ride == null) {
            return const Scaffold(
              body: Center(child: Text('No ride data')),
            );
          }
          return UserRideTrackingPage(ride: ride);
        },
      ),
      GoRoute(
        path: RouteConstants.userRideSummary,
        name: 'userRideSummary',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final ride = data?['ride'] as Ride?;
          final offer = data?['offer'] as DriverOffer?;
          if (ride == null) {
            return const Scaffold(
              body: Center(child: Text('No ride data')),
            );
          }
          return RideSummaryPage(
            ride: ride,
            offer: offer,
          );
        },
      ),
      GoRoute(
        path: RouteConstants.userRateDriver,
        name: 'userRateDriver',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return RateDriverPage(
            rideId: data?['rideId'] ?? '',
            driverName: data?['driverName'] ?? 'Driver',
            driverPhoto: data?['driverPhoto'],
          );
        },
      ),
      GoRoute(
        path: '/user/incoming-offers',
        name: 'incomingOffers',
        builder: (context, state) {
          final ride = state.extra as Ride;
          return IncomingOffersPage(ride: ride);
        },
      ),

      // ==================== Driver Routes (Shell) ====================
      ShellRoute(
        builder: (context, state, child) {
          return const DriverNavigation();
        },
        routes: [
          GoRoute(
            path: RouteConstants.driverHome,
            name: 'driverHome',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DriverHomePage(),
            ),
          ),
          GoRoute(
            path: RouteConstants.driverTrips,
            name: 'driverTrips',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DriverRidesPage(),
            ),
          ),
          GoRoute(
            path: RouteConstants.driverEarnings,
            name: 'driverEarnings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EarningsPage(),
            ),
          ),
        ],
      ),

      // ==================== Driver Standalone Routes ====================
      GoRoute(
        path: '/driver/available-rides',
        name: 'availableRides',
        builder: (context, state) => const AvailableRidesPage(),
      ),
      GoRoute(
        path: '/driver/profile',
        name: 'driverProfile',
        builder: (context, state) => const DriverProfilePage(),
      ),

      // ==================== Shared Routes ====================
      GoRoute(
        path: RouteConstants.profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: RouteConstants.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: RouteConstants.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: RouteConstants.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: RouteConstants.support,
        name: 'support',
        builder: (context, state) => const SupportPage(),
      ),
      GoRoute(
        path: RouteConstants.chatRoom,
        name: 'chatRoom',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          final conversationId = data?['conversationId'] ?? 
              state.uri.queryParameters['conversationId'] ?? '';
          final otherUserName = data?['otherUserName'] ?? 
              state.uri.queryParameters['otherUserName'];
          return ChatRoomPage(
            conversationId: conversationId,
            otherUserName: otherUserName,
          );
        },
      ),
      GoRoute(
        path: '/chat/:conversationId',
        name: 'chatScreen',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return ChatScreenPage(
            recipientId: data?['recipientId'] ?? '',
            recipientName: data?['recipientName'] ?? 'Driver',
            recipientImage: data?['recipientImage'],
            rideId: data?['rideId'],
            isOnline: data?['isOnline'] ?? false,
          );
        },
      ),
    ],
    
    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri.path}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(RouteConstants.splash),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
