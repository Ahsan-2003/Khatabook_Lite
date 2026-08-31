import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatabook_lite/domain/usecases/delete_transaction.dart';
import 'app.dart';
import 'data/models/customer_model.dart';
import 'data/models/transaction_model.dart';
import 'data/repositories/customer_repository_impl.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'domain/usecases/add_customer.dart';
import 'domain/usecases/add_transaction.dart';
import 'domain/usecases/delete_customer.dart';
import 'domain/usecases/get_customer_balance.dart';
import 'domain/usecases/get_customers.dart';
import 'domain/usecases/get_dashboard_data.dart';
import 'domain/usecases/get_transactions.dart';

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

  // Initialize Use Cases
  final getCustomers = GetCustomers(customerRepository);
  final addCustomer = AddCustomer(customerRepository);
  final deleteCustomer = DeleteCustomer(customerRepository);
  final getTransactions = GetTransactions(transactionRepository);
  final addTransaction = AddTransaction(transactionRepository);
  final getDashboardData = GetDashboardData(transactionRepository);
  final getCustomerBalance = GetCustomerBalance(transactionRepository);
  // Inside main() after other use cases:
  final deleteTransaction = DeleteTransaction(transactionRepository);

  runApp(
    KhataBookLiteApp(
      customerRepository: customerRepository,
      transactionRepository: transactionRepository,
      getCustomers: getCustomers,
      addCustomer: addCustomer,
      deleteCustomer: deleteCustomer,
      getTransactions: getTransactions,
      addTransaction: addTransaction,
      getDashboardData: getDashboardData,
      getCustomerBalance: getCustomerBalance,
      deleteTransaction: deleteTransaction,
    ),
  );
}
