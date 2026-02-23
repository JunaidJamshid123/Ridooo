import 'package:flutter/material.dart';

class SplashLogoWidget extends StatelessWidget {
  const SplashLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Car Image
        Image.asset(
          'assets/images/png/car_new.jpg',
          width: 280,
          height: 160,
          fit: BoxFit.contain,
        ),
        
        const SizedBox(height: 24),
        
        // Ridooo text
        const Text(
          'Ridooo',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: -2,
          ),
        ),
      ],
    );
  }
}
