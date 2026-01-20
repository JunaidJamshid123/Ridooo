import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/navigation/main_navigation.dart';
import '../../../../core/navigation/driver_navigation.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user.dart' as app_user;
import '../../../auth/presentation/pages/welcome_page.dart';
import '../widgets/splash_logo_widget.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set status bar to match splash screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _controller.forward();
    
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      // Check for existing session
      await _checkAuthSession();
    }
  }

  Future<void> _checkAuthSession() async {
    try {
      print('=== CHECKING AUTH SESSION ===');
      
      // Check if user is logged in via Supabase
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final currentUser = supabase.auth.currentUser;
      
      print('Session exists: ${session != null}');
      print('User exists: ${currentUser != null}');
      
      if (session != null && currentUser != null) {
        print('Active session found for user: ${currentUser.id}');
        
        // Try to get cached user data first
        final prefs = await SharedPreferences.getInstance();
        final cachedUserJson = prefs.getString('CACHED_USER');
        
        app_user.User? user;
        
        if (cachedUserJson != null) {
          print('Using cached user data');
          final userModel = UserModel.fromJson(jsonDecode(cachedUserJson));
          user = userModel.toEntity();
        } else {
          print('Fetching user data from database');
          // Fetch user data from database
          final response = await supabase
              .from(SupabaseConfig.usersTable)
              .select()
              .eq('id', currentUser.id)
              .single();
          
          final userModel = UserModel.fromJson(response);
          user = userModel.toEntity();
          
          // Cache the user data
          await prefs.setString('CACHED_USER', jsonEncode(userModel.toJson()));
          print('User data cached');
        }
        
        print('User role: ${user.role}');
        
        // Navigate based on user role
        if (mounted) {
          if (user.role == app_user.UserRole.driver) {
            print('Navigating to driver dashboard');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DriverNavigation()),
            );
          } else {
            print('Navigating to user home');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigation()),
            );
          }
        }
        return;
      }
      
      print('No active session, navigating to welcome page');
      
      // No active session, navigate to welcome page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WelcomePage(),
          ),
        );
      }
    } catch (e) {
      print('Error checking auth session: $e');
      
      // On error, navigate to welcome page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const WelcomePage(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: const SplashLogoWidget(),
          ),
        ),
      ),
    );
  }
}
