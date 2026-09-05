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
  final PageController _pageController = PageController(initialPage: 500);
  List<Transaction> _allTransactions = [];
  int _currentMonthIndex = 0;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadTransactions() {
    context.read<TransactionBloc>().add(LoadAllTransactions());
  }

  DateTime _getMonthFromIndex(int index) {
    final now = DateTime.now();
    return DateTime(now.year, now.month - index, 1);
  }

  List<Transaction> _getTransactionsForMonth(DateTime month) {
    return _allTransactions.where((t) {
      return t.timestamp.year == month.year && t.timestamp.month == month.month;
    }).toList();
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

  Map<String, double> _getDailyDataForMonth(DateTime month) {
    final data = <String, double>{};
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      data['$day'] = 0;
    }

    for (final transaction in _allTransactions) {
      if (transaction.timestamp.year == month.year &&
          transaction.timestamp.month == month.month) {
        final day = transaction.timestamp.day.toString();
        data[day] = (data[day] ?? 0) + transaction.amount;
      }
    }

    return data;
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonthIndex++;
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });
    _pageController.animateToPage(
      500 - _currentMonthIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextMonth() {
    if (_currentMonthIndex <= 0) return;
    setState(() {
      _currentMonthIndex--;
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });
    _pageController.animateToPage(
      500 - _currentMonthIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('analytics'.tr())),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is AllTransactionsLoaded) {
            _allTransactions = state.transactions;
          }

          return Column(
            children: [
              // Month Navigation Header
              _buildMonthNavigation(),

              const SizedBox(height: 8),

              // Summary Cards
              _buildSummarySection(),

              const SizedBox(height: 12),

              // Chart Title
              Text('daily_activity'.tr(), style: AppTextStyles.heading),
              const SizedBox(height: 8),

              // Swipeable Chart
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentMonthIndex = 500 - index;
                      _selectedMonth = _getMonthFromIndex(_currentMonthIndex);
                    });
                  },
                  itemBuilder: (context, index) {
                    final month = _getMonthFromIndex(500 - index);
                    return _buildMonthChart(month);
                  },
                ),
              ),

              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final monthName = _getMonthName(_selectedMonth);
    final year = _selectedMonth.year.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: _goToPreviousMonth,
            tooltip: 'previous_month'.tr(),
          ),
          Column(
            children: [
              Text(
                monthName,
                style: AppTextStyles.heading.copyWith(fontSize: 18),
              ),
              Text(year, style: AppTextStyles.caption),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              size: 28,
              color: _currentMonthIndex <= 0
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
            onPressed: _currentMonthIndex <= 0 ? null : _goToNextMonth,
            tooltip: 'next_month'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final transactions = _getTransactionsForMonth(_selectedMonth);
    final totalCredit = _getTotalCredit(transactions);
    final totalPayment = _getTotalPayment(transactions);
    final netBalance = totalCredit - totalPayment;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
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
          _buildNetBalanceCard(netBalance),
        ],
      ),
    );
  }

  Widget _buildMonthChart(DateTime month) {
    final dailyData = _getDailyDataForMonth(month);
    final transactions = _getTransactionsForMonth(month);

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'no_data'.tr(),
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(dailyData),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final keys = dailyData.keys.toList();
                final day = keys[groupIndex];
                return BarTooltipItem(
                  'Day $day\nRs. ${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
                  final keys = dailyData.keys.toList();
                  if (value.toInt() < keys.length) {
                    // Show every 5th day label to avoid clutter
                    final day = int.parse(keys[value.toInt()]);
                    if (day % 5 == 0 || day == 1) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          keys[value.toInt()],
                          style: AppTextStyles.caption.copyWith(fontSize: 8),
                        ),
                      );
                    }
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
          gridData: FlGridData(
            show: true,
            horizontalInterval: _getMaxY(dailyData) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.divider.withOpacity(0.5),
                strokeWidth: 1,
                dashArray: [4, 4],
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: dailyData.entries.map((entry) {
            final index = dailyData.keys.toList().indexOf(entry.key);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: entry.value > 0
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.3),
                  width: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(title, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: AppTextStyles.heading.copyWith(color: color, fontSize: 16),
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                netBalance > 0
                    ? Icons.trending_up
                    : netBalance < 0
                    ? Icons.trending_down
                    : Icons.trending_flat,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.heading.copyWith(fontSize: 16)),
            ],
          ),
          Text(
            'Rs. ${netBalance.abs().toStringAsFixed(0)}',
            style: AppTextStyles.heading.copyWith(color: color, fontSize: 20),
          ),
        ],
      ),
    );
  }

  String _getMonthName(DateTime month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return monthNames[month.month - 1];
  }

  double _getMaxY(Map<String, double> data) {
    final maxValue = data.values.isEmpty
        ? 0
        : data.values.reduce((a, b) => a > b ? a : b);
    return maxValue == 0 ? 100 : maxValue * 1.2;
  }
}
