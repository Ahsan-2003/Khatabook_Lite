import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/models/customer_model.dart';
import 'data/models/transaction_model.dart';
import 'data/repositories/customer_repository_impl.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(CustomerModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());

  // Open Boxes
  final customerBox = await Hive.openBox<CustomerModel>('customers');
  final transactionBox = await Hive.openBox<TransactionModel>('transactions');

  // Initialize Repositories
  final customerRepository = CustomerRepositoryImpl(customerBox: customerBox);
  final transactionRepository = TransactionRepositoryImpl(
    transactionBox: transactionBox,
    customerBox: customerBox,
  );

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
