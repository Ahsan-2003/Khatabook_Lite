import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:khatabook_lite/app.dart';
import 'package:khatabook_lite/data/models/customer_model.dart';
import 'package:khatabook_lite/data/models/transaction_model.dart';
import 'package:khatabook_lite/data/repositories/customer_repository_impl.dart';
import 'package:khatabook_lite/data/repositories/transaction_repository_impl.dart';
import 'package:khatabook_lite/domain/usecases/add_customer.dart';
import 'package:khatabook_lite/domain/usecases/add_transaction.dart';
import 'package:khatabook_lite/domain/usecases/delete_customer.dart';
import 'package:khatabook_lite/domain/usecases/get_customer_balance.dart';
import 'package:khatabook_lite/domain/usecases/get_customers.dart';
import 'package:khatabook_lite/domain/usecases/get_dashboard_data.dart';
import 'package:khatabook_lite/domain/usecases/get_transactions.dart';
import 'package:khatabook_lite/domain/usecases/delete_transaction.dart';

void main() {
  testWidgets('KhataBook Lite app loads successfully', (
    WidgetTester tester,
  ) async {
    // Initialize Hive for testing
    await Hive.initFlutter();
    Hive.registerAdapter(CustomerModelAdapter());
    Hive.registerAdapter(TransactionModelAdapter());

    final customerBox = await Hive.openBox<CustomerModel>('test_customers');
    final transactionBox = await Hive.openBox<TransactionModel>(
      'test_transactions',
    );

    // Create repositories
    final customerRepository = CustomerRepositoryImpl(customerBox: customerBox);
    final transactionRepository = TransactionRepositoryImpl(
      transactionBox: transactionBox,
      customerBox: customerBox,
    );

    // Create use cases
    final getCustomers = GetCustomers(customerRepository);
    final addCustomer = AddCustomer(customerRepository);
    final deleteCustomer = DeleteCustomer(customerRepository);
    final getTransactions = GetTransactions(transactionRepository);
    final addTransaction = AddTransaction(transactionRepository);
    final getDashboardData = GetDashboardData(transactionRepository);
    final getCustomerBalance = GetCustomerBalance(transactionRepository);
    final deleteTransaction = DeleteTransaction(transactionRepository);

    // Build our app
    await tester.pumpWidget(
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

    // Wait for initial load
    await tester.pumpAndSettle();

    // Verify app bar title
    expect(find.text('KhataBook Lite'), findsOneWidget);

    // Verify balance cards
    expect(find.text('Total Owed to Me'), findsOneWidget);
    expect(find.text('I Owe Others'), findsOneWidget);

    // Verify customers section
    expect(find.text('My Customers'), findsOneWidget);

    // Verify empty state
    expect(find.text('No customers yet'), findsOneWidget);

    // Verify FAB exists
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Clean up
    await customerBox.close();
    await transactionBox.close();
  });
}
