import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidyut_vaani/core/theme/app_theme.dart';

/// Shown while the app checks for an existing session.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lightning bolt icon as placeholder logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt,
                size: 60,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'VidyuthVaani',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Electricity Services Platform',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.teal,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
