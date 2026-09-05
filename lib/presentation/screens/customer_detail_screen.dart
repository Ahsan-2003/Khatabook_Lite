import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'package:share_plus/share_plus.dart';
import 'package:khatabook_lite/core/services/pdf_service.dart';

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
    if (result == true) _loadTransactions();
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
      _loadTransactions();
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete_customer'.tr()),
        content: Text(
          'delete_customer_confirm'.tr(args: [widget.customer.name]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteCustomer();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.credit),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _deleteCustomer() {
    context.read<CustomerBloc>().add(DeleteCustomerEvent(widget.customer.id));
    Navigator.pop(context, true);
  }

  void _showReminderOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                title: Text('send_via_whatsapp'.tr()),
                subtitle: Text('requires_whatsapp'.tr()),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _sendWhatsAppReminder();
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms, color: AppColors.primary),
                title: Text('send_via_sms'.tr()),
                subtitle: Text('uses_sms_app'.tr()),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _sendSmsReminder();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendWhatsAppReminder() async {
    final phoneNumber = widget.customer.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showSnackBar('no_phone_number'.tr(), isError: true);
      return;
    }
    final message = _buildReminderMessage();
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    String formattedNumber = cleanedNumber;
    if (formattedNumber.startsWith('0')) {
      formattedNumber = '92${formattedNumber.substring(1)}';
    } else if (formattedNumber.startsWith('3')) {
      formattedNumber = '92$formattedNumber';
    }
    final url =
        'https://wa.me/$formattedNumber?text=${Uri.encodeComponent(message)}';
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showSnackBar('whatsapp_not_available'.tr(), isError: true);
      }
    } catch (e) {
      _showSnackBar('whatsapp_not_available'.tr(), isError: true);
    }
  }

  Future<void> _sendSmsReminder() async {
    final phoneNumber = widget.customer.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      _showSnackBar('no_phone_number'.tr(), isError: true);
      return;
    }
    final message = _buildReminderMessage();
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'sms:$cleanedNumber?body=${Uri.encodeComponent(message)}';
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showSnackBar('sms_not_available'.tr(), isError: true);
      }
    } catch (e) {
      _showSnackBar('sms_not_available'.tr(), isError: true);
    }
  }

  String _buildReminderMessage() {
    double balance = 0;
    final state = context.read<TransactionBloc>().state;
    if (state is TransactionLoaded) {
      balance = _calculateBalance(state.transactions);
    }
    if (balance > 0) {
      return 'reminder_message'.tr(
        namedArgs: {
          'name': widget.customer.name,
          'amount': balance.toStringAsFixed(0),
        },
      );
    } else if (balance < 0) {
      return 'owe_message'.tr(
        namedArgs: {
          'name': widget.customer.name,
          'amount': balance.abs().toStringAsFixed(0),
        },
      );
    } else {
      return 'settled_message'.tr(namedArgs: {'name': widget.customer.name});
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.credit : AppColors.payment,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteTransaction(Transaction transaction) {
    context.read<TransactionBloc>().add(
      DeleteTransactionEvent(
        transactionId: transaction.id,
        customerId: widget.customer.id,
      ),
    );
    _showSnackBar('transaction_deleted'.tr());
  }

  void _showDeleteTransactionConfirmation(Transaction transaction) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete_transaction'.tr()),
        content: Text(
          'delete_transaction_confirm'.tr(
            namedArgs: {'amount': transaction.amount.toStringAsFixed(0)},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteTransaction(transaction);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.credit),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _shareLedger() async {
    try {
      final transactionState = context.read<TransactionBloc>().state;

      if (transactionState is! TransactionLoaded) {
        _showSnackBar('No transactions to share', isError: true);
        return;
      }

      final transactions = transactionState.transactions;
      final balance = _calculateBalance(transactions);

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdfService = PdfService();
      final file = await pdfService.generateCustomerLedger(
        customer: widget.customer,
        transactions: transactions,
        balance: balance,
      );

      // Close loading dialog
      Navigator.pop(context);

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Ledger for ${widget.customer.name}',
        text:
            'Customer Ledger: ${widget.customer.name}\nBalance: Rs. ${balance.abs().toStringAsFixed(0)}',
      );
    } catch (e) {
      Navigator.pop(context);
      _showSnackBar('Failed to share ledger', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareLedger,
            tooltip: 'Share Ledger',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: _showReminderOptions,
            tooltip: 'send_reminder'.tr(),
          ),
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
          _buildCustomerInfo(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('transaction_history'.tr(), style: AppTextStyles.heading),
                BlocBuilder<TransactionBloc, TransactionState>(
                  builder: (context, state) {
                    if (state is TransactionLoaded) {
                      return Text(
                        '${state.transactions.length} ${'entries'.tr()}',
                        style: AppTextStyles.caption,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TransactionLoaded) {
                  if (state.transactions.isEmpty) return _buildEmptyState();
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
                        '${'gave'.tr()} (${'credit'.tr()})',
                        style: AppTextStyles.button.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                        '${'got'.tr()} (${'payment'.tr()})',
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

  Widget _buildCustomerInfo() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
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
                    Text('balance'.tr(), style: AppTextStyles.caption),
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
                          ? 'owes_you'.tr()
                          : balance < 0
                          ? 'you_owe'.tr()
                          : 'settled'.tr(),
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
          Text('no_transactions'.tr(), style: AppTextStyles.body),
          const SizedBox(height: 4),
          Text('use_buttons_below'.tr(), style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
