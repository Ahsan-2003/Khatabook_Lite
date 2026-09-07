import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/domain/entities/customer.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_bloc.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_event.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_bloc.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_event.dart';
import 'package:khatabook_lite/presentation/screens/customer_detail_screen.dart';
import 'package:khatabook_lite/presentation/screens/edit_customer_screen.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final int index;

  const CustomerCard({super.key, required this.customer, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _openCustomerDetail(context),
            onLongPress: () => _showOptions(context),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name, style: AppTextStyles.heading),
                        if (customer.phoneNumber != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            customer.phoneNumber!,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: () => _openEditCustomer(context),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: AppColors.credit,
                      size: 22,
                    ),
                    onPressed: () => _showDeleteConfirmation(context),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 50),
        )
        .slideX(
          begin: -0.1,
          end: 0,
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 50),
        );
  }

  Widget _buildAvatar() {
    if (customer.photoPath != null && File(customer.photoPath!).existsSync()) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: FileImage(File(customer.photoPath!)),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
          ],
        ),
      );
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.2),
      ),
      child: Center(
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  void _openCustomerDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customer: customer),
      ),
    ).then((_) {
      context.read<CustomerBloc>().add(LoadCustomers());
      context.read<TransactionBloc>().add(LoadDashboardData());
    });
  }

  void _openEditCustomer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerScreen(customer: customer),
      ),
    ).then((_) {
      context.read<CustomerBloc>().add(LoadCustomers());
    });
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CustomerBloc>().add(
                DeleteCustomerEvent(customer.id),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.credit),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
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
                leading: const Icon(
                  Icons.receipt_long,
                  color: AppColors.primary,
                ),
                title: const Text('View Ledger'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _openCustomerDetail(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.payment),
                title: const Text('Edit Customer'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _openEditCustomer(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.credit),
                title: const Text('Delete Customer'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
