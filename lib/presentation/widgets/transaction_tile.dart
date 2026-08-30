import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/transaction.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? AppColors.credit : AppColors.payment;
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
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _formatDate(transaction.timestamp),
          style: AppTextStyles.caption,
        ),
        trailing: Text(
          '$sign Rs. ${transaction.amount.toStringAsFixed(0)}',
          style: AppTextStyles.heading.copyWith(color: color, fontSize: 16),
        ),
      ),
    );
  }

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
