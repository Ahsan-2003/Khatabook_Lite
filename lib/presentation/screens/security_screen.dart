import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:khatabook_lite/core/services/app_lock_service.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/presentation/screens/pin_entry_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final AppLockService _appLockService = AppLockService();
  bool _lockEnabled = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lockEnabled = await _appLockService.isLockEnabled();
    final biometricEnabled = await _appLockService.isBiometricEnabled();
    setState(() {
      _lockEnabled = lockEnabled;
      _biometricEnabled = biometricEnabled;
    });
  }

  Future<void> _setupPin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PinEntryScreen(isSetup: true),
      ),
    );

    if (result == true) {
      _loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('pin_set_success'.tr()),
          backgroundColor: AppColors.payment,
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
  }

  Future<void> _disableLock() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('disable_lock'.tr()),
        content: Text('disable_lock_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _appLockService.disableLock();
              _loadSettings();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.credit),
            child: Text('disable'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('security'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Lock Card
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('app_lock'.tr(), style: AppTextStyles.heading),
                  subtitle: Text(
                    'app_lock_subtitle'.tr(),
                    style: AppTextStyles.caption,
                  ),
                  value: _lockEnabled,
                  onChanged: (value) {
                    if (value) {
                      _setupPin();
                    } else {
                      _disableLock();
                    }
                  },
                  activeColor: AppColors.primary,
                ),
                if (_lockEnabled) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(
                      'biometric_lock'.tr(),
                      style: AppTextStyles.body,
                    ),
                    subtitle: Text(
                      'biometric_lock_subtitle'.tr(),
                      style: AppTextStyles.caption,
                    ),
                    value: _biometricEnabled,
                    onChanged: (value) async {
                      await _appLockService.setBiometricEnabled(value);
                      setState(() {
                        _biometricEnabled = value;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.lock_reset,
                      color: AppColors.primary,
                    ),
                    title: Text('change_pin'.tr(), style: AppTextStyles.body),
                    onTap: _setupPin,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.credit),
                      const SizedBox(width: 8),
                      Text('security_info'.tr(), style: AppTextStyles.heading),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('security_info_text'.tr(), style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
