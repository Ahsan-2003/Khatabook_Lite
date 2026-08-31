import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khatabook_lite/domain/usecases/delete_transaction.dart';
import 'core/theme/app_theme.dart';
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
import 'package:khatabook_lite/presentation/screens/home_screen.dart';

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
  // Add to class properties:
  final DeleteTransaction deleteTransaction;

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
    required this.deleteTransaction,
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
            deleteTransaction: deleteTransaction,
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
