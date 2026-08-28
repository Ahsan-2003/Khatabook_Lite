import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'add_customer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigate to Add Customer screen
  Future<void> _navigateToAddCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
    );

    // If result is true, customer was added
    if (result == true) {
      setState(() {
        // Refresh home screen
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer added successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KhataBook Lite')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Rs. 0',
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
                      'Rs. 0',
                      style: AppTextStyles.amountDisplay.copyWith(
                        color: AppColors.creditRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Empty state message
            const Center(
              child: Text(
                'No customers yet.\nTap + to add your first customer.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyText,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCustomer,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }
}
