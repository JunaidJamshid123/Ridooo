import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SplashLogoWidget extends StatelessWidget {
  const SplashLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // "Ri" text
        const Text(
          'Ri',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1,
          ),
        ),
        
        // Car icon replacing 'd'
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_taxi_rounded,
            size: 48,
            color: AppColors.textPrimary,
          ),
        ),
        
        // "ooo" text
        const Text(
          'ooo',
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1,
          ),
        ),
      ],
    );
  }
}
