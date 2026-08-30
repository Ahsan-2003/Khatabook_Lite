import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transaction/transaction_bloc.dart';
import '../bloc/transaction/transaction_event.dart';
import '../bloc/transaction/transaction_state.dart';

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
  final _noteController = TextEditingController();

  String _amount = '';
  bool _isSubmitting = false;

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

  // Submit transaction
  void _submitTransaction() {
    if (_amount.isEmpty || double.parse(_amount) <= 0) {
      _showSnackBar('Please enter an amount', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    context.read<TransactionBloc>().add(
      AddTransactionEvent(
        customerId: widget.customer.id,
        type: widget.transactionType == 'credit'
            ? TransactionType.credit
            : TransactionType.payment,
        amount: double.parse(_amount),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  // Show snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.credit : AppColors.payment,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.transactionType == 'credit';
    final color = isCredit ? AppColors.credit : AppColors.payment;
    final title = isCredit ? 'Gave (Credit)' : 'Got (Payment)';
    final icon = isCredit ? Icons.arrow_upward : Icons.arrow_downward;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionLoaded && _isSubmitting) {
            _isSubmitting = false;
            Navigator.pop(context, true);
            _showSnackBar('Transaction saved successfully');
          } else if (state is TransactionError) {
            _isSubmitting = false;
            _showSnackBar(state.message, isError: true);
          }
        },
        child: Column(
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
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _amount.isEmpty ? 'Rs. 0' : 'Rs. $_amount',
                    style: AppTextStyles.displayLarge.copyWith(color: color),
                  ),
                ],
              ),
            ),

            // Note Field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _noteController,
                style: AppTextStyles.body,
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
                onPressed: _isSubmitting ? null : _submitTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 28),
                          const SizedBox(width: 8),
                          Text('Save $title', style: AppTextStyles.button),
                        ],
                      ),
              ),
            ),
          ],
        ),
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
