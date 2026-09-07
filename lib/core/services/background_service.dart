import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatabook_lite/data/models/customer_model.dart';
import 'package:khatabook_lite/data/models/transaction_model.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize background service
  Future<void> initialize() async {
    // Initialize notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings: initSettings);

    // Initialize WorkManager
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  }

  // Schedule periodic reminder check
  Future<void> scheduleReminderCheck({required String frequency}) async {
    Duration interval;

    switch (frequency) {
      case 'daily':
        interval = const Duration(hours: 24);
        break;
      case 'monthly':
        interval = const Duration(days: 30);
        break;
      default:
        interval = const Duration(days: 7); // weekly
    }

    await Workmanager().registerPeriodicTask(
      'reminder_check_task',
      'reminderCheckTask',
      frequency: interval,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  // Cancel scheduled task
  Future<void> cancelReminderCheck() async {
    await Workmanager().cancelByUniqueName('reminder_check_task');
  }
}

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'reminderCheckTask':
        await _checkAndNotifyReminders();
        break;
    }
    return true;
  });
}

// Check reminders and show notification
Future<void> _checkAndNotifyReminders() async {
  // Initialize Hive
  await Hive.initFlutter();

  if (!Hive.isBoxOpen('customers')) {
    await Hive.openBox<CustomerModel>('customers');
  }
  if (!Hive.isBoxOpen('transactions')) {
    await Hive.openBox<TransactionModel>('transactions');
  }

  final customerBox = Hive.box<CustomerModel>('customers');
  final transactionBox = Hive.box<TransactionModel>('transactions');
  final customersWithBalance = <Map<String, dynamic>>[];

  // Calculate balances
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
      customersWithBalance.add({'name': customer.name, 'balance': balance});
    }
  }

  // Show notification if there are customers with balance
  if (customersWithBalance.isNotEmpty) {
    final notificationPlugin = FlutterLocalNotificationsPlugin();

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Auto Reminders',
      channelDescription: 'Automatic payment reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    final totalBalance = customersWithBalance.fold<double>(
      0,
      (sum, customer) => sum + (customer['balance'] as double),
    );

    await notificationPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Payment Reminder',
      body:
          '${customersWithBalance.length} customers owe you Rs. ${totalBalance.toStringAsFixed(0)}',
      notificationDetails: notificationDetails,
    );
  }
}
