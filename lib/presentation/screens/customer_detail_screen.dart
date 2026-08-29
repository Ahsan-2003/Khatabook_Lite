import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/customer.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import 'transaction_entry_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final _transactionRepository = TransactionRepository();

  List<Transaction> _transactions = [];
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _transactions = _transactionRepository.getTransactionsByCustomer(
        widget.customer.id,
      );
      _balance = _transactionRepository.getCustomerBalance(widget.customer.id);
    });
  }

  // Navigate to Transaction Entry
  Future<void> _navigateToTransactionEntry(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionEntryScreen(
          customer: widget.customer,
          transactionType: type,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceColor = _balance > 0
        ? AppColors.creditRed
        : _balance < 0
        ? AppColors.paymentGreen
        : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(widget.customer.name)),
      body: Column(
        children: [
          // Customer Info Card
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Customer Avatar
                _buildAvatar(),
                const SizedBox(height: 12),
                Text(widget.customer.name, style: AppTextStyles.sectionHeader),
                if (widget.customer.phoneNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.customer.phoneNumber!,
                    style: AppTextStyles.bodyText.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Balance Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: balanceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('Current Balance', style: AppTextStyles.captionText),
                      const SizedBox(height: 4),
                      Text(
                        'Rs. ${_balance.abs().toStringAsFixed(0)}',
                        style: AppTextStyles.amountDisplay.copyWith(
                          fontSize: 36,
                          color: balanceColor,
                        ),
                      ),
                      Text(
                        _balance > 0
                            ? 'Customer Owes You'
                            : _balance < 0
                            ? 'You Owe Customer'
                            : 'Settled',
                        style: AppTextStyles.captionText.copyWith(
                          color: balanceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Transaction History
          Expanded(
            child: _transactions.isEmpty
                ? Center(
                    child: Text(
                      'No transactions yet.\nUse buttons below to add.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyText.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return _buildTransactionTile(transaction);
                    },
                  ),
          ),
        ],
      ),

      // Bottom Action Buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gave (Credit) Button
            Expanded(
              child: ElevatedButton(
                onPressed: () => _navigateToTransactionEntry('credit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.creditRed,
                  minimumSize: const Size(double.infinity, 70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_upward, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      'GAVE',
                      style: AppTextStyles.buttonText.copyWith(fontSize: 18),
                    ),
                    Text(
                      '(Credit)',
                      style: AppTextStyles.captionText.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Got (Payment) Button
            Expanded(
              child: ElevatedButton(
                onPressed: () => _navigateToTransactionEntry('payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.paymentGreen,
                  minimumSize: const Size(double.infinity, 70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_downward, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      'GOT',
                      style: AppTextStyles.buttonText.copyWith(fontSize: 18),
                    ),
                    Text(
                      '(Payment)',
                      style: AppTextStyles.captionText.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build avatar
  Widget _buildAvatar() {
    if (widget.customer.photoPath != null &&
        File(widget.customer.photoPath!).existsSync()) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: FileImage(File(widget.customer.photoPath!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentBlue.withOpacity(0.2),
        ),
        child: Center(
          child: Text(
            widget.customer.name.isNotEmpty
                ? widget.customer.name[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.accentBlue,
            ),
          ),
        ),
      );
    }
  }

  // Build transaction tile
  Widget _buildTransactionTile(Transaction transaction) {
    final isCredit = transaction.type == 'credit';
    final color = isCredit ? AppColors.creditRed : AppColors.paymentGreen;
    final icon = isCredit ? Icons.arrow_upward : Icons.arrow_downward;
    final label = isCredit ? 'Gave (Credit)' : 'Got (Payment)';
    final sign = isCredit ? '+' : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          label,
          style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _formatDate(transaction.timestamp),
          style: AppTextStyles.captionText,
        ),
        trailing: Text(
          '$sign Rs. ${transaction.amount.toStringAsFixed(0)}',
          style: AppTextStyles.customerName.copyWith(
            color: color,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Format date
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    String time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (transactionDate == today) {
      return 'Today at $time';
    } else if (transactionDate == yesterday) {
      return 'Yesterday at $time';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at $time';
    }
  }
}
