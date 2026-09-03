import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/domain/entities/customer.dart';
import 'package:khatabook_lite/domain/entities/transaction.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_bloc.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_event.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_state.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_bloc.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_event.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_state.dart';
import 'package:khatabook_lite/presentation/widgets/balance_card.dart';
import 'package:khatabook_lite/presentation/widgets/customer_card.dart';
import 'package:khatabook_lite/presentation/widgets/overdue_filter.dart';
import 'add_customer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'all';
  List<Transaction> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    context.read<CustomerBloc>().add(LoadCustomers());
    context.read<TransactionBloc>().add(LoadDashboardData());
  }

  double _calculateBalance(String customerId) {
    double balance = 0;
    for (final transaction in _allTransactions) {
      if (transaction.customerId == customerId) {
        if (transaction.type == TransactionType.credit) {
          balance += transaction.amount;
        } else {
          balance -= transaction.amount;
        }
      }
    }
    return balance;
  }

  List<Customer> _filterCustomers(List<Customer> customers) {
    switch (_selectedFilter) {
      case 'balance':
        return customers.where((customer) {
          return _calculateBalance(customer.id) > 0;
        }).toList();

      case 'settled':
        return customers.where((customer) {
          return _calculateBalance(customer.id) == 0;
        }).toList();

      case 'overdue':
        return customers.where((customer) {
          final balance = _calculateBalance(customer.id);
          if (balance <= 0) return false;

          final customerTransactions = _allTransactions
              .where((t) => t.customerId == customer.id)
              .toList();

          if (customerTransactions.isEmpty) return false;

          customerTransactions.sort(
            (a, b) => b.timestamp.compareTo(a.timestamp),
          );
          final lastTransaction = customerTransactions.first;
          final daysSinceLast = DateTime.now()
              .difference(lastTransaction.timestamp)
              .inDays;

          return daysSinceLast > 30;
        }).toList();

      default:
        return customers;
    }
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
                  // Store transactions for filtering
                  _allTransactions = state.allTransactions;

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

            // Filter Chips
            OverdueFilter(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
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

                  final filteredCustomers = _filterCustomers(state.customers);

                  if (filteredCustomers.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return Column(
                    children: filteredCustomers
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          );
          if (result == true) {
            _loadData();
          }
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

  Widget _buildNoResultsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text('No customers match this filter', style: AppTextStyles.body),
            const SizedBox(height: 4),
            Text(
              'Try selecting a different filter',
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
