import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khatabook_lite/core/theme/app_theme.dart';
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
import 'package:khatabook_lite/presentation/bloc/customer/customer_bloc.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_bloc.dart';
import 'package:khatabook_lite/presentation/screens/home_screen.dart';

class KhataBookLiteApp extends StatelessWidget {
  final CustomerRepositoryImpl customerRepository;
  final TransactionRepositoryImpl transactionRepository;
  final GetCustomers getCustomers;
  final AddCustomer addCustomer;
  final DeleteCustomer deleteCustomer;
  final GetTransactions getTransactions;
  final AddTransaction addTransaction;
  final DeleteTransaction deleteTransaction;
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
    required this.deleteTransaction,
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
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: const HomeScreen(),
      ),
    );
  }
}
