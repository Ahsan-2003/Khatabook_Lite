import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/models/customer.dart';
import 'data/models/transaction.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(TransactionAdapter());

  // Open Boxes
  await Hive.openBox<Customer>('customers');
  await Hive.openBox<Transaction>('transactions');

  // Initialize Repositories
  await CustomerRepository().init();
  await TransactionRepository().init();

  runApp(const KhataBookLiteApp());
}

class KhataBookLiteApp extends StatelessWidget {
  const KhataBookLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KhataBook Lite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
