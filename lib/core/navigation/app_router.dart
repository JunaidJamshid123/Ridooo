import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/route_constants.dart';
// TODO: Import pages as they are implemented
// import '../../features/auth/presentation/pages/login_page.dart';
// import '../../features/auth/presentation/pages/signup_page.dart';
// etc.

/// Main app router configuration
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash
      GoRoute(
        path: RouteConstants.splash,
        name: 'splash',
        builder: (context, state) => const Placeholder(), // TODO: SplashScreen()
      ),

      // Auth Routes
      GoRoute(
        path: RouteConstants.welcome,
        name: 'welcome',
        builder: (context, state) => const Placeholder(), // TODO: WelcomePage()
      ),
      GoRoute(
        path: RouteConstants.login,
        name: 'login',
        builder: (context, state) => const Placeholder(), // TODO: LoginPage()
      ),
      GoRoute(
        path: RouteConstants.signup,
        name: 'signup',
        builder: (context, state) => const Placeholder(), // TODO: SignupPage()
      ),

      // User Routes (Nested)
      ShellRoute(
        builder: (context, state, child) {
          return const Placeholder(); // TODO: UserNavigation(child: child)
        },
        routes: [
          GoRoute(
            path: RouteConstants.userHome,
            name: 'userHome',
            builder: (context, state) => const Placeholder(), // TODO: UserHomePage()
          ),
          GoRoute(
            path: RouteConstants.userActivity,
            name: 'userActivity',
            builder: (context, state) => const Placeholder(), // TODO: ActivityPage()
          ),
          GoRoute(
            path: RouteConstants.userPayment,
            name: 'userPayment',
            builder: (context, state) => const Placeholder(), // TODO: PaymentPage()
          ),
          GoRoute(
            path: RouteConstants.userChat,
            name: 'userChat',
            builder: (context, state) => const Placeholder(), // TODO: ChatListPage()
          ),
          GoRoute(
            path: RouteConstants.userAccount,
            name: 'userAccount',
            builder: (context, state) => const Placeholder(), // TODO: AccountPage()
          ),
        ],
      ),

      // Driver Routes (Nested)
      ShellRoute(
        builder: (context, state, child) {
          return const Placeholder(); // TODO: DriverNavigation(child: child)
        },
        routes: [
          GoRoute(
            path: RouteConstants.driverHome,
            name: 'driverHome',
            builder: (context, state) => const Placeholder(), // TODO: DriverHomePage()
          ),
          GoRoute(
            path: RouteConstants.driverEarnings,
            name: 'driverEarnings',
            builder: (context, state) => const Placeholder(), // TODO: EarningsPage()
          ),
          GoRoute(
            path: RouteConstants.driverTrips,
            name: 'driverTrips',
            builder: (context, state) => const Placeholder(), // TODO: TripsPage()
          ),
        ],
      ),

      // Shared Routes
      GoRoute(
        path: RouteConstants.profile,
        name: 'profile',
        builder: (context, state) => const Placeholder(), // TODO: ProfilePage()
      ),
      GoRoute(
        path: RouteConstants.settings,
        name: 'settings',
        builder: (context, state) => const Placeholder(), // TODO: SettingsPage()
      ),
      GoRoute(
        path: RouteConstants.notifications,
        name: 'notifications',
        builder: (context, state) => const Placeholder(), // TODO: NotificationsPage()
      ),
      GoRoute(
        path: RouteConstants.chatRoom,
        name: 'chatRoom',
        builder: (context, state) {
          final rideId = state.uri.queryParameters['rideId'];
          return const Placeholder(); // TODO: ChatRoomPage(rideId: rideId)
        },
      ),
    ],
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
