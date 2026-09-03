import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/domain/entities/transaction.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;

  const TransactionTile({super.key, required this.transaction, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? AppColors.credit : AppColors.payment;
    final icon = isCredit ? Icons.arrow_upward : Icons.arrow_downward;
    final label = isCredit ? 'Gave (Credit)' : 'Got (Payment)';
    final sign = isCredit ? '+' : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(transaction.timestamp),
                  style: AppTextStyles.caption,
                ),
                if (transaction.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.note!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$sign Rs. ${transaction.amount.toStringAsFixed(0)}',
                  style: AppTextStyles.heading.copyWith(
                    color: color,
                    fontSize: 16,
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ),

          // Attachments
          if (transaction.voiceNotePath != null ||
              transaction.photoPath != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  if (transaction.voiceNotePath != null) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      onPressed: () =>
                          _playVoiceNote(transaction.voiceNotePath!),
                    ),
                    const Text('Voice Note', style: AppTextStyles.caption),
                  ],
                  if (transaction.voiceNotePath != null &&
                      transaction.photoPath != null)
                    const SizedBox(width: 16),
                  if (transaction.photoPath != null) ...[
                    GestureDetector(
                      onTap: () => _showPhoto(context, transaction.photoPath!),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(transaction.photoPath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _playVoiceNote(String path) async {
    final player = AudioPlayer();
    await player.play(DeviceFileSource(path));
  }

  void _showPhoto(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(child: Image.file(File(path))),
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
