import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/presentation/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedLanguage = 'en';

  // Onboarding data
  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Welcome to KhataBook Lite',
      'description': 'Digital ledger for street vendors and small shopkeepers',
      'icon': '📒',
    },
    {
      'title': 'Track Credit Easily',
      'description': 'Record GAVE (credit) and GOT (payment) with just one tap',
      'icon': '💰',
    },
    {
      'title': 'Works Offline',
      'description': 'No internet? No problem! Everything works offline',
      'icon': '📱',
    },
    {
      'title': 'Never Lose Your Data',
      'description': 'Your khata is safely stored on your phone',
      'icon': '🔒',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('user_language', _selectedLanguage);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return _buildOnboardingPage(
                    icon: data['icon']!,
                    title: data['title']!,
                    description: data['description']!,
                  );
                },
              ),
            ),

            // Language Selection
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Select Language', style: AppTextStyles.heading),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLanguageButton('en', 'English'),
                      const SizedBox(width: 12),
                      _buildLanguageButton('ur', 'اردو'),
                    ],
                  ),
                ],
              ),
            ),

            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage < _onboardingData.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _completeOnboarding();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _currentPage < _onboardingData.length - 1
                      ? 'Next'
                      : 'Get Started',
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 30),
          Text(
            title,
            style: AppTextStyles.heading.copyWith(
              color: Colors.white,
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String code, String label) {
    final isSelected = _selectedLanguage == code;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = code;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
