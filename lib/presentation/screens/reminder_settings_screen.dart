import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:khatabook_lite/core/services/background_service.dart';
import 'package:khatabook_lite/core/services/reminder_service.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final ReminderService _reminderService = ReminderService();
  final BackgroundService _backgroundService = BackgroundService();

  bool _reminderEnabled = false;
  String _frequency = 'weekly';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _reminderService.isReminderEnabled();
    final frequency = await _reminderService.getReminderFrequency();

    setState(() {
      _reminderEnabled = enabled;
      _frequency = frequency;
    });
  }

  Future<void> _toggleReminder(bool value) async {
    await _reminderService.setReminderEnabled(value);
    setState(() {
      _reminderEnabled = value;
    });

    if (value) {
      await _backgroundService.scheduleReminderCheck(frequency: _frequency);
      _showSnackBar('reminders_scheduled'.tr());
    } else {
      await _backgroundService.cancelReminderCheck();
      _showSnackBar('reminders_cancelled'.tr());
    }
  }

  Future<void> _changeFrequency(String value) async {
    await _reminderService.setReminderFrequency(value);
    setState(() {
      _frequency = value;
    });

    if (_reminderEnabled) {
      await _backgroundService.cancelReminderCheck();
      await _backgroundService.scheduleReminderCheck(frequency: value);
      _showSnackBar('frequency_updated'.tr());
    }
  }

  Future<void> _sendAllRemindersNow() async {
    setState(() => _isSending = true);

    final customers = _reminderService.getCustomersWithBalance();

    if (customers.isEmpty) {
      _showSnackBar('no_customers_with_balance'.tr());
      setState(() => _isSending = false);
      return;
    }

    final sentCount = await _reminderService.sendAllReminders();

    setState(() => _isSending = false);
    _showSnackBar(
      'reminders_sent'.tr(namedArgs: {'count': sentCount.toString()}),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.credit : AppColors.payment,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('auto_reminders'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'enable_reminders'.tr(),
                    style: AppTextStyles.heading,
                  ),
                  subtitle: Text(
                    'enable_reminders_desc'.tr(),
                    style: AppTextStyles.caption,
                  ),
                  value: _reminderEnabled,
                  onChanged: _toggleReminder,
                  activeColor: AppColors.primary,
                ),
                if (_reminderEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: Text(
                      'reminder_frequency'.tr(),
                      style: AppTextStyles.body,
                    ),
                    trailing: DropdownButton<String>(
                      value: _frequency,
                      items: [
                        DropdownMenuItem(
                          value: 'daily',
                          child: Text('daily'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('weekly'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('monthly'.tr()),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) _changeFrequency(value);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.payment.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: AppColors.payment,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('send_now'.tr(), style: AppTextStyles.heading),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('send_now_desc'.tr(), style: AppTextStyles.caption),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendAllRemindersNow,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text('send_all_reminders'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.payment,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
