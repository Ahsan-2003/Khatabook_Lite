import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:khatabook_lite/presentation/widgets/empty_state_widget.dart';
import 'add_customer_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

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

  void _changeLanguage(String languageCode) async {
    if (context.locale.languageCode == languageCode) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_language', languageCode);

    if (mounted) {
      context.setLocale(Locale(languageCode));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('language_changed'.tr()),
          backgroundColor: AppColors.payment,
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
        return customers.where((c) => _calculateBalance(c.id) > 0).toList();
      case 'settled':
        return customers.where((c) => _calculateBalance(c.id) == 0).toList();
      case 'overdue':
        return customers.where((c) {
          final balance = _calculateBalance(c.id);
          if (balance <= 0) return false;
          final transactions = _allTransactions
              .where((t) => t.customerId == c.id)
              .toList();
          if (transactions.isEmpty) return false;
          transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return DateTime.now()
                  .difference(transactions.first.timestamp)
                  .inDays >
              30;
        }).toList();
      default:
        return customers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'analytics'.tr(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: 'change_language'.tr(),
            onSelected: _changeLanguage,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'ur', child: Text('اردو')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'settings'.tr(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'refresh'.tr(),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Dashboard Balances
            BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is DashboardDataLoaded) {
                  _allTransactions = state.allTransactions;
                  return Column(
                    children: [
                      BalanceCard(
                        title: 'total_owed_to_me'.tr(),
                        amount: state.totalOwedToVendor,
                        color: AppColors.payment,
                        icon: Icons.arrow_downward,
                      ),
                      const SizedBox(height: 12),
                      BalanceCard(
                        title: 'i_owe_others'.tr(),
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
                      title: 'total_owed_to_me'.tr(),
                      amount: 0,
                      color: AppColors.payment,
                      icon: Icons.arrow_downward,
                    ),
                    const SizedBox(height: 12),
                    BalanceCard(
                      title: 'i_owe_others'.tr(),
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
                Text('my_customers'.tr(), style: AppTextStyles.heading),
                BlocBuilder<CustomerBloc, CustomerState>(
                  builder: (context, state) {
                    if (state is CustomerLoaded) {
                      return Text(
                        '${state.customers.length} ${'total'.tr()}',
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
                setState(() => _selectedFilter = filter);
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
                    return EmptyStateWidget(
                      icon: Icons.people_outline,
                      title: 'no_customers_yet'.tr(),
                      subtitle: 'tap_to_add_customer'.tr(),
                    );
                  }

                  final filteredCustomers = _filterCustomers(state.customers);

                  if (filteredCustomers.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'no_results'.tr(),
                      subtitle: 'try_different_filter'.tr(),
                    );
                  }

                  return Column(
                    children: filteredCustomers
                        .asMap()
                        .entries
                        .map(
                          (entry) => CustomerCard(
                            customer: entry.value,
                            index: entry.key,
                          ),
                        )
                        .toList(),
                  );
                }

                if (state is CustomerError) {
                  return EmptyStateWidget(
                    icon: Icons.error_outline,
                    title: 'error'.tr(),
                    subtitle: state.message,
                  );
                }

                return const SizedBox.shrink();
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
          if (result == true) _loadData();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}
