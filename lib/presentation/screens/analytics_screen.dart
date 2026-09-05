import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/domain/entities/transaction.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_bloc.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_event.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'all'; // 'week', 'month', 'all'
  List<Transaction> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    context.read<TransactionBloc>().add(LoadAllTransactions());
  }

  List<Transaction> _getFilteredTransactions() {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return _allTransactions
            .where((t) => t.timestamp.isAfter(weekAgo))
            .toList();

      case 'month':
        final monthAgo = now.subtract(const Duration(days: 30));
        return _allTransactions
            .where((t) => t.timestamp.isAfter(monthAgo))
            .toList();

      case 'year':
        final yearAgo = now.subtract(const Duration(days: 365));
        return _allTransactions
            .where((t) => t.timestamp.isAfter(yearAgo))
            .toList();

      default:
        return _allTransactions;
    }
  }

  double _getTotalCredit(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.credit)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double _getTotalPayment(List<Transaction> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.payment)
        .fold(0, (sum, t) => sum + t.amount);
  }

  Map<String, double> _getChartData(List<Transaction> transactions) {
    final data = <String, double>{};
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'week':
        // Last 7 days
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayKey = '${date.day}/${date.month}';
          data[dayKey] = 0;
        }
        for (final transaction in transactions) {
          final date = transaction.timestamp;
          if (date.isAfter(now.subtract(const Duration(days: 7)))) {
            final dayKey = '${date.day}/${date.month}';
            data[dayKey] = (data[dayKey] ?? 0) + transaction.amount;
          }
        }
        break;

      case 'month':
        // Last 30 days grouped by week
        for (int i = 4; i >= 0; i--) {
          final weekStart = now.subtract(Duration(days: (i * 7) + 7));
          final weekEnd = now.subtract(Duration(days: i * 7));
          final weekKey = '${weekStart.day}/${weekStart.month}';
          data[weekKey] = 0;
        }
        for (final transaction in transactions) {
          final date = transaction.timestamp;
          if (date.isAfter(now.subtract(const Duration(days: 35)))) {
            final diffDays = now.difference(date).inDays;
            final weekIndex = (diffDays ~/ 7);
            final weekStart = now.subtract(Duration(days: (weekIndex * 7) + 7));
            final weekKey = '${weekStart.day}/${weekStart.month}';
            data[weekKey] = (data[weekKey] ?? 0) + transaction.amount;
          }
        }
        break;

      default:
        // Group by month for all transactions
        for (final transaction in transactions) {
          final monthKey =
              '${transaction.timestamp.month}/${transaction.timestamp.year}';
          data[monthKey] = (data[monthKey] ?? 0) + transaction.amount;
        }
        if (data.isEmpty) {
          final currentMonthKey = '${now.month}/${now.year}';
          data[currentMonthKey] = 0;
        }
        break;
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('analytics'.tr())),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is AllTransactionsLoaded) {
            _allTransactions = state.transactions;
            print(
              'DEBUG: Analytics loaded ${_allTransactions.length} transactions',
            );
            for (final t in _allTransactions) {
              print(
                'DEBUG: Transaction - Date: ${t.timestamp}, Type: ${t.type}, Amount: ${t.amount}',
              );
            }
          }

          final filteredTransactions = _getFilteredTransactions();
          final totalCredit = _getTotalCredit(filteredTransactions);
          final totalPayment = _getTotalPayment(filteredTransactions);
          final netBalance = totalCredit - totalPayment;
          final chartData = _getChartData(filteredTransactions);

          print('DEBUG: Selected period: $_selectedPeriod');
          print('DEBUG: Filtered transactions: ${filteredTransactions.length}');
          print('DEBUG: Total credit: $totalCredit');
          print('DEBUG: Total payment: $totalPayment');

          return RefreshIndicator(
            onRefresh: () async {
              _loadTransactions();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  Row(
                    children: [
                      _buildPeriodButton('all', 'all'.tr()),
                      const SizedBox(width: 8),
                      _buildPeriodButton('week', 'week'.tr()),
                      const SizedBox(width: 8),
                      _buildPeriodButton('month', 'month'.tr()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'credit_given'.tr(),
                          amount: totalCredit,
                          color: AppColors.credit,
                          icon: Icons.arrow_upward,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'payments_received'.tr(),
                          amount: totalPayment,
                          color: AppColors.payment,
                          icon: Icons.arrow_downward,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Net Balance Card
                  _buildNetBalanceCard(netBalance),

                  const SizedBox(height: 24),

                  // Chart
                  Text('activity_chart'.tr(), style: AppTextStyles.heading),
                  const SizedBox(height: 16),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: chartData.isEmpty
                        ? Center(child: Text('no_data'.tr()))
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _getMaxY(chartData),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          'Rs. ${rod.toY.toStringAsFixed(0)}',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final keys = chartData.keys.toList();
                                      if (value.toInt() < keys.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            keys[value.toInt()],
                                            style: AppTextStyles.caption
                                                .copyWith(fontSize: 9),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: chartData.entries.map((entry) {
                                final index = chartData.keys.toList().indexOf(
                                  entry.key,
                                );
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value,
                                      color: AppColors.primary,
                                      width: 20,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Transaction Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('summary'.tr(), style: AppTextStyles.heading),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'total_transactions'.tr(),
                            '${filteredTransactions.length}',
                          ),
                          _buildInfoRow(
                            'credit_transactions'.tr(),
                            '${filteredTransactions.where((t) => t.type == TransactionType.credit).length}',
                          ),
                          _buildInfoRow(
                            'payment_transactions'.tr(),
                            '${filteredTransactions.where((t) => t.type == TransactionType.payment).length}',
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            'total_credit_amount'.tr(),
                            'Rs. ${totalCredit.toStringAsFixed(0)}',
                          ),
                          _buildInfoRow(
                            'total_payment_amount'.tr(),
                            'Rs. ${totalPayment.toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedPeriod = period),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
          foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
          ),
        ),
        child: Text(label, style: AppTextStyles.body.copyWith(fontSize: 13)),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Rs. ${amount.toStringAsFixed(0)}',
              style: AppTextStyles.heading.copyWith(color: color, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetBalanceCard(double netBalance) {
    final color = netBalance > 0
        ? AppColors.credit
        : netBalance < 0
        ? AppColors.payment
        : AppColors.textSecondary;
    final label = netBalance > 0
        ? 'net_credit'.tr()
        : netBalance < 0
        ? 'net_payment'.tr()
        : 'balanced'.tr();

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.heading),
            Text(
              'Rs. ${netBalance.abs().toStringAsFixed(0)}',
              style: AppTextStyles.heading.copyWith(color: color, fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  double _getMaxY(Map<String, double> data) {
    final maxValue = data.values.isEmpty
        ? 0
        : data.values.reduce((a, b) => a > b ? a : b);
    return maxValue == 0 ? 100 : maxValue * 1.2;
  }
}
