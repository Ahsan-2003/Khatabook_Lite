import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatabook_lite/app.dart';
import 'package:khatabook_lite/data/models/customer_model.dart';
import 'package:khatabook_lite/data/models/transaction_model.dart';
import 'package:khatabook_lite/data/repositories/customer_repository_impl.dart';
import 'package:khatabook_lite/data/repositories/transaction_repository_impl.dart';
import 'package:khatabook_lite/domain/usecases/add_customer.dart';
import 'package:khatabook_lite/domain/usecases/add_transaction.dart';
import 'package:khatabook_lite/domain/usecases/delete_customer.dart';
import 'package:khatabook_lite/domain/usecases/delete_transaction.dart';
import 'package:khatabook_lite/domain/usecases/get_customer_balance.dart';
import 'package:khatabook_lite/domain/usecases/get_customers.dart';
import 'package:khatabook_lite/domain/usecases/get_dashboard_data.dart';
import 'package:khatabook_lite/domain/usecases/get_transactions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(CustomerModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());

  final customerBox = await Hive.openBox<CustomerModel>('customers');
  final transactionBox = await Hive.openBox<TransactionModel>('transactions');

  final customerRepository = CustomerRepositoryImpl(customerBox: customerBox);
  final transactionRepository = TransactionRepositoryImpl(
    transactionBox: transactionBox,
    customerBox: customerBox,
  );

  final getCustomers = GetCustomers(customerRepository);
  final addCustomer = AddCustomer(customerRepository);
  final deleteCustomer = DeleteCustomer(customerRepository);
  final getTransactions = GetTransactions(transactionRepository);
  final addTransaction = AddTransaction(transactionRepository);
  final deleteTransaction = DeleteTransaction(transactionRepository);
  final getDashboardData = GetDashboardData(transactionRepository);
  final getCustomerBalance = GetCustomerBalance(transactionRepository);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ur')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: KhataBookLiteApp(
        customerRepository: customerRepository,
        transactionRepository: transactionRepository,
        getCustomers: getCustomers,
        addCustomer: addCustomer,
        deleteCustomer: deleteCustomer,
        getTransactions: getTransactions,
        addTransaction: addTransaction,
        deleteTransaction: deleteTransaction,
        getDashboardData: getDashboardData,
        getCustomerBalance: getCustomerBalance,
      ),
    ),
  );
}
