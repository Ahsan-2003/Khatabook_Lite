import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khatabook_lite/presentation/screens/add_customer_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../bloc/customer/customer_bloc.dart';
import '../bloc/customer/customer_event.dart';
import '../bloc/customer/customer_state.dart';
import '../bloc/transaction/transaction_bloc.dart';
import '../bloc/transaction/transaction_event.dart';
import '../bloc/transaction/transaction_state.dart';
import '../widgets/balance_card.dart';
import '../widgets/customer_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<CustomerBloc>().add(LoadCustomers());
    context.read<TransactionBloc>().add(LoadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KhataBook Lite'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Dashboard Balances
            BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is DashboardDataLoaded) {
                  return Column(
                    children: [
                      BalanceCard(
                        title: 'Total Owed to Me',
                        amount: state.totalOwedToVendor,
                        color: AppColors.payment,
                        icon: Icons.arrow_downward,
                      ),
                      const SizedBox(height: 12),
                      BalanceCard(
                        title: 'I Owe Others',
                        amount: state.totalVendorOwes,
                        color: AppColors.credit,
                        icon: Icons.arrow_upward,
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    BalanceCard(
                      title: 'Total Owed to Me',
                      amount: 0,
                      color: AppColors.payment,
                      icon: Icons.arrow_downward,
                    ),
                    const SizedBox(height: 12),
                    BalanceCard(
                      title: 'I Owe Others',
                      amount: 0,
                      color: AppColors.credit,
                      icon: Icons.arrow_upward,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Customers', style: AppTextStyles.heading),
                BlocBuilder<CustomerBloc, CustomerState>(
                  builder: (context, state) {
                    if (state is CustomerLoaded) {
                      return Text(
                        '${state.customers.length} total',
                        style: AppTextStyles.caption,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Customer List
            BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                if (state is CustomerLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is CustomerLoaded) {
                  if (state.customers.isEmpty) {
                    return _buildEmptyState();
                  }
                  return Column(
                    children: state.customers
                        .map((customer) => CustomerCard(customer: customer))
                        .toList(),
                  );
                }

                if (state is CustomerError) {
                  return _buildErrorState(state.message);
                }

                return _buildEmptyState();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text('No customers yet', style: AppTextStyles.body),
            const SizedBox(height: 4),
            Text(
              'Tap + to add your first customer',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.credit),
            const SizedBox(height: 12),
            Text('Something went wrong', style: AppTextStyles.body),
            const SizedBox(height: 4),
            Text(
              message,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
