import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
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
import 'presentation/bloc/customer/customer_bloc.dart';
import 'presentation/bloc/transaction/transaction_bloc.dart';
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

  // Initialize Use Cases
  final getCustomers = GetCustomers(customerRepository);
  final addCustomer = AddCustomer(customerRepository);
  final deleteCustomer = DeleteCustomer(customerRepository);
  final getTransactions = GetTransactions(transactionRepository);
  final addTransaction = AddTransaction(transactionRepository);
  final getDashboardData = GetDashboardData(transactionRepository);
  final getCustomerBalance = GetCustomerBalance(transactionRepository);

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
    ),
  );
}

class KhataBookLiteApp extends StatelessWidget {
  final CustomerRepositoryImpl customerRepository;
  final TransactionRepositoryImpl transactionRepository;
  final GetCustomers getCustomers;
  final AddCustomer addCustomer;
  final DeleteCustomer deleteCustomer;
  final GetTransactions getTransactions;
  final AddTransaction addTransaction;
  final GetDashboardData getDashboardData;
  final GetCustomerBalance getCustomerBalance;

  const KhataBookLiteApp({
    super.key,
    required this.customerRepository,
    required this.transactionRepository,
    required this.getCustomers,
    required this.addCustomer,
    required this.deleteCustomer,
    required this.getTransactions,
    required this.addTransaction,
    required this.getDashboardData,
    required this.getCustomerBalance,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CustomerBloc>(
          create: (context) => CustomerBloc(
            getCustomers: getCustomers,
            addCustomer: addCustomer,
            deleteCustomer: deleteCustomer,
          ),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) => TransactionBloc(
            getTransactions: getTransactions,
            addTransaction: addTransaction,
            getDashboardData: getDashboardData,
            getCustomerBalance: getCustomerBalance,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'KhataBook Lite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
