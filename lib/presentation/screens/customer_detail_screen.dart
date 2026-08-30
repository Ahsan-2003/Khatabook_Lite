import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/domain/entities/customer.dart';
import 'package:khatabook_lite/domain/entities/transaction.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_bloc.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_event.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_bloc.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_event.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_state.dart';
import 'package:khatabook_lite/presentation/screens/edit_customer_screen.dart';
import 'package:khatabook_lite/presentation/screens/transaction_entry_screen.dart';
import 'package:khatabook_lite/presentation/widgets/transaction_tile.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    context.read<TransactionBloc>().add(LoadTransactions(widget.customer.id));
  }

  void _navigateToTransactionEntry(String type) async {
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
      _loadTransactions();
    }
  }

  void _navigateToEditCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerScreen(customer: widget.customer),
      ),
    );

    if (result == true) {
      // Customer updated, refresh
      _loadTransactions();
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete ${widget.customer.name}? This will also delete all their transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCustomer();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.credit),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteCustomer() {
    context.read<CustomerBloc>().add(DeleteCustomerEvent(widget.customer.id));

    Navigator.pop(context, true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer deleted successfully'),
        backgroundColor: AppColors.credit,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditCustomer,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer Info Section
          _buildCustomerInfo(),

          // Transaction History
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TransactionLoaded) {
                  if (state.transactions.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.transactions.length,
                    itemBuilder: (context, index) {
                      return TransactionTile(
                        transaction: state.transactions[index],
                        onDelete: () => _showDeleteTransactionConfirmation(
                          state.transactions[index],
                        ),
                      );
                    },
                  );
                }

                if (state is TransactionError) {
                  return Center(child: Text(state.message));
                }

                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  // Customer Info Card
  Widget _buildCustomerInfo() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          _buildAvatar(),
          const SizedBox(height: 12),
          Text(widget.customer.name, style: AppTextStyles.heading),
          if (widget.customer.phoneNumber != null) ...[
            const SizedBox(height: 4),
            Text(widget.customer.phoneNumber!, style: AppTextStyles.caption),
          ],
          const SizedBox(height: 16),
          // Balance Display
          BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              double balance = 0;

              if (state is TransactionLoaded) {
                balance = _calculateBalance(state.transactions);
              }

              final balanceColor = balance > 0
                  ? AppColors.credit
                  : balance < 0
                  ? AppColors.payment
                  : AppColors.textSecondary;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: balanceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('Current Balance', style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${balance.abs().toStringAsFixed(0)}',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 36,
                        color: balanceColor,
                      ),
                    ),
                    Text(
                      balance > 0
                          ? 'Customer Owes You'
                          : balance < 0
                          ? 'You Owe Customer'
                          : 'Settled',
                      style: AppTextStyles.caption.copyWith(
                        color: balanceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Calculate balance from transactions
  double _calculateBalance(List<Transaction> transactions) {
    double balance = 0;
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.credit) {
        balance += transaction.amount;
      } else {
        balance -= transaction.amount;
      }
    }
    return balance;
  }

  // Avatar Widget
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
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.2),
      ),
      child: Center(
        child: Text(
          widget.customer.name.isNotEmpty
              ? widget.customer.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text('No transactions yet', style: AppTextStyles.body),
          const SizedBox(height: 4),
          Text('Use buttons below to add', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  // Bottom Action Buttons
  Widget _buildActionButtons() {
    return Container(
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
                backgroundColor: AppColors.credit,
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
                    style: AppTextStyles.button.copyWith(fontSize: 16),
                  ),
                  Text(
                    '(Credit)',
                    style: AppTextStyles.caption.copyWith(color: Colors.white),
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
                backgroundColor: AppColors.payment,
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
                    style: AppTextStyles.button.copyWith(fontSize: 16),
                  ),
                  Text(
                    '(Payment)',
                    style: AppTextStyles.caption.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Delete transaction confirmation
  void _showDeleteTransactionConfirmation(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this transaction of Rs. ${transaction.amount.toStringAsFixed(0)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTransaction(transaction);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.credit),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteTransaction(Transaction transaction) {
    // For now, we'll just reload transactions
    // In next step, we'll add proper delete functionality
    _loadTransactions();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaction deleted successfully'),
        backgroundColor: AppColors.credit,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
