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
      setState(() {});
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete ${widget.customer.name}? This will also delete all their transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
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
          // Customer Info Section (Compact)
          _buildCustomerInfo(),

          // Transaction History Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaction History', style: AppTextStyles.heading),
                BlocBuilder<TransactionBloc, TransactionState>(
                  builder: (context, state) {
                    if (state is TransactionLoaded) {
                      return Text(
                        '${state.transactions.length} entries',
                        style: AppTextStyles.caption,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

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

      // Bottom Action Buttons (Smaller)
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
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
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_upward, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'GAVE',
                        style: AppTextStyles.button.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Got (Payment) Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _navigateToTransactionEntry('payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.payment,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_downward, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'GOT',
                        style: AppTextStyles.button.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Customer Info Card (Compact)
  Widget _buildCustomerInfo() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(),
          const SizedBox(width: 16),
          // Customer Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.customer.name, style: AppTextStyles.heading),
                if (widget.customer.phoneNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.customer.phoneNumber!,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
          // Balance
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
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: balanceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Balance', style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${balance.abs().toStringAsFixed(0)}',
                      style: AppTextStyles.heading.copyWith(
                        color: balanceColor,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      balance > 0
                          ? 'Owes You'
                          : balance < 0
                          ? 'You Owe'
                          : 'Settled',
                      style: AppTextStyles.caption.copyWith(
                        color: balanceColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
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

  Widget _buildAvatar() {
    if (widget.customer.photoPath != null &&
        File(widget.customer.photoPath!).existsSync()) {
      return Container(
        width: 60,
        height: 60,
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
      width: 60,
      height: 60,
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
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text('No transactions yet', style: AppTextStyles.body),
          const SizedBox(height: 4),
          Text('Use buttons below to add', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
