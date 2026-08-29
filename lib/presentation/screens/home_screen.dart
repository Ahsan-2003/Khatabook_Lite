import 'dart:io';
import 'package:flutter/material.dart';
import 'package:khatabook_lite/presentation/screens/customer_detail_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/customer.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import 'add_customer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _customerRepository = CustomerRepository();
  final _transactionRepository = TransactionRepository();

  List<Customer> _customers = [];
  double _totalOwedToVendor = 0;
  double _totalVendorOwes = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load all data from repositories
  void _loadData() {
    setState(() {
      _customers = _customerRepository.getAllCustomers();
      _totalOwedToVendor = _transactionRepository.getTotalOwedToVendor();
      _totalVendorOwes = _transactionRepository.getTotalVendorOwes();
    });
  }

  // Navigate to Add Customer screen
  Future<void> _navigateToAddCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
    );

    // If result is true, customer was added
    if (result == true) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer added successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KhataBook Lite')),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Total Owed to Vendor (Green)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Owed to Me',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs. ${_totalOwedToVendor.toStringAsFixed(0)}',
                      style: AppTextStyles.amountDisplay.copyWith(
                        color: AppColors.paymentGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Total Vendor Owes (Red)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'I Owe Others',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs. ${_totalVendorOwes.toStringAsFixed(0)}',
                      style: AppTextStyles.amountDisplay.copyWith(
                        color: AppColors.creditRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Customers Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Customers', style: AppTextStyles.sectionHeader),
                Text(
                  '${_customers.length} total',
                  style: AppTextStyles.captionText,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Customer List
            if (_customers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No customers yet.\nTap + to add your first customer.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyText,
                  ),
                ),
              )
            else
              ..._customers.map((customer) => _buildCustomerCard(customer)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCustomer,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  // Build individual customer card
  Widget _buildCustomerCard(Customer customer) {
    final balance = _transactionRepository.getCustomerBalance(customer.id);
    final balanceColor = balance > 0
        ? AppColors.creditRed
        : balance < 0
        ? AppColors.paymentGreen
        : AppColors.textSecondary;

    final balanceText = balance > 0
        ? 'Owes: Rs. ${balance.toStringAsFixed(0)}'
        : balance < 0
        ? 'Advance: Rs. ${balance.abs().toStringAsFixed(0)}'
        : 'Settled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildCustomerAvatar(customer),
        title: Text(customer.name, style: AppTextStyles.customerName),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            balanceText,
            style: AppTextStyles.balanceText.copyWith(
              color: balanceColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
          size: 28,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailScreen(customer: customer),
            ),
          ).then((_) => _loadData());
        },
      ),
    );
  }

  // Build customer avatar (photo or initial)
  Widget _buildCustomerAvatar(Customer customer) {
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
        ),
      );
    } else {
      // Show first letter of name
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.accentBlue.withOpacity(0.2),
        ),
        child: Center(
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.accentBlue,
            ),
          ),
        ),
      );
    }
  }
}
