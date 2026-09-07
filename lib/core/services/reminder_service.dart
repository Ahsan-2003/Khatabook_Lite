import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:khatabook_lite/data/models/customer_model.dart';
import 'package:khatabook_lite/data/models/transaction_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _reminderEnabledKey = 'auto_reminder_enabled';
  static const String _reminderFrequencyKey = 'reminder_frequency';

  // Initialize notifications
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings: initSettings);
  }

  // Check if reminders are enabled
  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? false;
  }

  // Set reminder enabled
  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);
  }

  // Get reminder frequency
  Future<String> getReminderFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_reminderFrequencyKey) ?? 'weekly';
  }

  // Set reminder frequency
  Future<void> setReminderFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderFrequencyKey, frequency);
  }

  // Get customers with outstanding balance
  List<Map<String, dynamic>> getCustomersWithBalance() {
    final customerBox = Hive.box<CustomerModel>('customers');
    final transactionBox = Hive.box<TransactionModel>('transactions');
    final customersWithBalance = <Map<String, dynamic>>[];

    for (final customer in customerBox.values) {
      double balance = 0;

      for (final transaction in transactionBox.values) {
        if (transaction.customerId == customer.id) {
          if (transaction.type == 'credit') {
            balance += transaction.amount;
          } else {
            balance -= transaction.amount;
          }
        }
      }

      if (balance > 0 && customer.phoneNumber != null) {
        customersWithBalance.add({
          'name': customer.name,
          'phone': customer.phoneNumber,
          'balance': balance,
        });
      }
    }

    // Sort by balance (highest first)
    customersWithBalance.sort(
      (a, b) => (b['balance'] as double).compareTo(a['balance'] as double),
    );

    return customersWithBalance;
  }

  // Send reminder to a customer
  Future<void> sendReminderToCustomer({
    required String name,
    required String phone,
    required double balance,
  }) async {
    final message = _buildReminderMessage(name, balance);
    final cleanedNumber = phone.replaceAll(RegExp(r'[^0-9]'), '');

    String formattedNumber = cleanedNumber;
    if (formattedNumber.startsWith('0')) {
      formattedNumber = '92${formattedNumber.substring(1)}';
    }

    final url =
        'https://wa.me/$formattedNumber?text=${Uri.encodeComponent(message)}';

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      print('DEBUG: Failed to send reminder: $e');
    }
  }

  // Send all reminders
  Future<int> sendAllReminders() async {
    final customers = getCustomersWithBalance();
    int sentCount = 0;

    for (final customer in customers) {
      await sendReminderToCustomer(
        name: customer['name'] as String,
        phone: customer['phone'] as String,
        balance: customer['balance'] as double,
      );
      sentCount++;

      // Small delay between sends
      await Future.delayed(const Duration(seconds: 1));
    }

    return sentCount;
  }

  // Show notification
  Future<void> showReminderNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Auto Reminders',
      channelDescription: 'Automatic payment reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinNotificationDetails,
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  String _buildReminderMessage(String name, double balance) {
    return 'Salam $name,\n\n'
        'This is a friendly reminder from your vendor. '
        'Your current balance is Rs. ${balance.toStringAsFixed(0)}.\n\n'
        'Please clear your balance at your earliest convenience.\n\n'
        'Shukriya!';
  }
}
