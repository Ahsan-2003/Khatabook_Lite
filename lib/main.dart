import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/models/customer_model.dart';
import 'data/models/transaction_model.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(CustomerModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());

  // Open Boxes
  await Hive.openBox<CustomerModel>('customers');
  await Hive.openBox<TransactionModel>('transactions');

  runApp(const KhataBookLiteApp());
}

class KhataBookLiteApp extends StatelessWidget {
  const KhataBookLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KhataBook Lite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
