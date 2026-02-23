import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/auth/presentation/pages/welcome_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _carController;
  late AnimationController _textController;
  
  late Animation<double> _carSlideAnimation;
  late Animation<double> _carFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Car animation
    _carController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _carSlideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _carController,
      curve: Curves.easeOutCubic,
    ));
    
    _carFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _carController,
      curve: Curves.easeOut,
    ));
    
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));
    
    _textSlideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _carController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();
    
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const WelcomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _carController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Car Image
            AnimatedBuilder(
              animation: _carController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_carSlideAnimation.value, 0),
                  child: Opacity(
                    opacity: _carFadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/png/car_new.jpg',
                width: 280,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Ridooo Text
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _textSlideAnimation.value),
                  child: Opacity(
                    opacity: _textFadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: const Text(
                'Ridooo',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -2,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
