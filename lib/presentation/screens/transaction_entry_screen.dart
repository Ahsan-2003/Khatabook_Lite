import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/transaction_repository.dart';

class TransactionEntryScreen extends StatefulWidget {
  final Customer customer;
  final String transactionType; // 'credit' or 'payment'

  const TransactionEntryScreen({
    super.key,
    required this.customer,
    required this.transactionType,
  });

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  final _transactionRepository = TransactionRepository();
  final _noteController = TextEditingController();

  String _amount = '';
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Add digit to amount
  void _addDigit(String digit) {
    setState(() {
      if (_amount.length < 7) {
        _amount += digit;
      }
    });
  }

  // Remove last digit
  void _removeDigit() {
    setState(() {
      if (_amount.isNotEmpty) {
        _amount = _amount.substring(0, _amount.length - 1);
      }
    });
  }

  // Clear amount
  void _clearAmount() {
    setState(() {
      _amount = '';
    });
  }

  // Save transaction
  Future<void> _saveTransaction() async {
    if (_amount.isEmpty || double.parse(_amount) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _transactionRepository.addTransaction(
        customerId: widget.customer.id,
        type: widget.transactionType,
        amount: double.parse(_amount),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving transaction: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.transactionType == 'credit';
    final color = isCredit ? AppColors.creditRed : AppColors.paymentGreen;
    final title = isCredit ? 'Gave (Credit)' : 'Got (Payment)';
    final icon = isCredit ? Icons.arrow_upward : Icons.arrow_downward;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Amount Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: color.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  widget.customer.name,
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _amount.isEmpty ? 'Rs. 0' : 'Rs. $_amount',
                  style: AppTextStyles.amountDisplay.copyWith(color: color),
                ),
              ],
            ),
          ),

          // Note Field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _noteController,
              style: AppTextStyles.bodyText,
              decoration: const InputDecoration(
                hintText: 'Note (Optional)',
                prefixIcon: Icon(Icons.note, size: 24),
              ),
            ),
          ),

          // Numeric Keypad
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildKeypadButton('1'),
                _buildKeypadButton('2'),
                _buildKeypadButton('3'),
                _buildKeypadButton('4'),
                _buildKeypadButton('5'),
                _buildKeypadButton('6'),
                _buildKeypadButton('7'),
                _buildKeypadButton('8'),
                _buildKeypadButton('9'),
                _buildKeypadButton('C', isClear: true),
                _buildKeypadButton('0'),
                _buildKeypadButton('⌫', isDelete: true),
              ],
            ),
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 28),
                        const SizedBox(width: 8),
                        Text('Save $title', style: AppTextStyles.buttonText),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Build keypad button
  Widget _buildKeypadButton(
    String label, {
    bool isClear = false,
    bool isDelete = false,
  }) {
    return ElevatedButton(
      onPressed: () {
        if (isClear) {
          _clearAmount();
        } else if (isDelete) {
          _removeDigit();
        } else {
          _addDigit(label);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isClear || isDelete
            ? AppColors.textSecondary
            : AppColors.surface,
        foregroundColor: isClear || isDelete
            ? Colors.white
            : AppColors.textPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
