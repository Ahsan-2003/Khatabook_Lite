import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/presentation/screens/security_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock, color: AppColors.primary),
                  title: Text('security'.tr(), style: AppTextStyles.heading),
                  subtitle: Text(
                    'app_lock_subtitle'.tr(),
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecurityScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.primary),
                  title: Text('language'.tr(), style: AppTextStyles.heading),
                  subtitle: Text(
                    'change_language'.tr(),
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Language selection
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info, color: AppColors.primary),
                  title: Text('about'.tr(), style: AppTextStyles.heading),
                  subtitle: Text('app_name'.tr(), style: AppTextStyles.caption),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
