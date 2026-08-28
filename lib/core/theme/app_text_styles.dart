import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Large display text for amounts (Home Dashboard)
  static const TextStyle amountDisplay = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
  );

  // Section headers
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Customer name in list
  static const TextStyle customerName = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Balance text
  static const TextStyle balanceText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Button text (large for easy touch)
  static const TextStyle buttonText = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Body text
  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  // Small caption text
  static const TextStyle captionText = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}
