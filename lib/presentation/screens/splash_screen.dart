import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khatabook_lite/core/services/app_lock_service.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/presentation/screens/home_screen.dart';
import 'package:khatabook_lite/presentation/screens/onboarding_screen.dart';
import 'package:khatabook_lite/presentation/screens/pin_entry_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AppLockService _appLockService = AppLockService();

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    final savedLanguage = prefs.getString('user_language') ?? 'en';
    final lockEnabled = await _appLockService.isLockEnabled();

    if (mounted) {
      context.setLocale(Locale(savedLanguage));
    }

    if (!mounted) return;

    if (!onboardingCompleted) {
      // Show onboarding for first time
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else if (lockEnabled) {
      // Show PIN entry
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PinEntryScreen(
            onUnlocked: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
        ),
      );
    } else {
      // Go directly to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.book, size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'app_name'.tr(),
              style: AppTextStyles.heading.copyWith(
                color: Colors.white,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Digital Khata for Everyone',
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
