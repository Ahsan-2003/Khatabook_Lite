import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/customer.dart';

class TransactionRepository {
  static final TransactionRepository _instance =
      TransactionRepository._internal();
  factory TransactionRepository() => _instance;
  TransactionRepository._internal();

  final _uuid = const Uuid();

  Box<Transaction>? _transactionBox;
  Box<Customer>? _customerBox;

  // Initialize the boxes
  Future<void> init() async {
    _transactionBox = Hive.box<Transaction>('transactions');
    _customerBox = Hive.box<Customer>('customers');
  }

  Box<Transaction> get _box {
    if (_transactionBox == null) {
      throw Exception(
        'TransactionRepository not initialized. Call init() first.',
      );
    }
    return _transactionBox!;
  }

  // Add a new transaction
  Future<Transaction> addTransaction({
    required String customerId,
    required String type, // 'credit' or 'payment'
    required double amount,
    String? note,
    String? voiceNotePath,
    String? photoPath,
  }) async {
    final transaction = Transaction(
      id: _uuid.v4(),
      customerId: customerId,
      type: type,
      amount: amount,
      timestamp: DateTime.now(),
      note: note,
      voiceNotePath: voiceNotePath,
      photoPath: photoPath,
    );

    await _box.add(transaction);

    // Update customer's updatedAt timestamp
    final customer = _customerBox?.get(customerId);
    if (customer != null) {
      customer.updatedAt = DateTime.now();
      await customer.save();
    }

    return transaction;
  }

  // Get all transactions for a specific customer
  List<Transaction> getTransactionsByCustomer(String customerId) {
    final transactions = _box.values
        .where((t) => t.customerId == customerId)
        .toList();

    transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return transactions;
  }

  // Get all transactions (most recent first)
  List<Transaction> getAllTransactions() {
    final transactions = _box.values.toList();
    transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return transactions;
  }

  // Calculate customer balance (positive = vendor owes, negative = customer owes)
  double getCustomerBalance(String customerId) {
    double balance = 0;

    for (final transaction in _box.values) {
      if (transaction.customerId == customerId) {
        if (transaction.type == 'credit') {
          balance += transaction.amount; // Customer owes more
        } else if (transaction.type == 'payment') {
          balance -= transaction.amount; // Customer paid back
        }
      }
    }

    return balance;
  }

  // Get total amount owed to vendor (all customers' positive balances)
  double getTotalOwedToVendor() {
    double total = 0;
    final customerIds = _getAllCustomerIds();

    for (final customerId in customerIds) {
      final balance = getCustomerBalance(customerId);
      if (balance > 0) {
        total += balance;
      }
    }

    return total;
  }

  // Get total amount vendor owes to customers (negative balances)
  double getTotalVendorOwes() {
    double total = 0;
    final customerIds = _getAllCustomerIds();

    for (final customerId in customerIds) {
      final balance = getCustomerBalance(customerId);
      if (balance < 0) {
        total += balance.abs();
      }
    }

    return total;
  }

  // Delete a transaction
  Future<void> deleteTransaction(Transaction transaction) async {
    await transaction.delete();
  }

  // Helper: Get all customer IDs
  Set<String> _getAllCustomerIds() {
    final ids = <String>{};
    for (final transaction in _box.values) {
      ids.add(transaction.customerId);
    }
    return ids;
  }
}
