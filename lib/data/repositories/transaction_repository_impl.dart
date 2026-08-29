import 'package:hive/hive.dart';
import 'package:khatabook_lite/data/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transaction.dart';
import '../models/customer_model.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final Box<TransactionModel> _transactionBox;
  final Box<CustomerModel> _customerBox;
  final _uuid = const Uuid();

  TransactionRepositoryImpl({
    required Box<TransactionModel> transactionBox,
    required Box<CustomerModel> customerBox,
  }) : _transactionBox = transactionBox,
       _customerBox = customerBox;

  @override
  Future<List<Transaction>> getTransactionsByCustomer(String customerId) async {
    final transactions =
        _transactionBox.values.where((t) => t.customerId == customerId).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return transactions.map((t) => t.toEntity()).toList();
  }

  @override
  Future<List<Transaction>> getAllTransactions() async {
    final transactions = _transactionBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return transactions.map((t) => t.toEntity()).toList();
  }

  @override
  Future<Transaction> addTransaction({
    required String customerId,
    required TransactionType type,
    required double amount,
    String? note,
    String? voiceNotePath,
    String? photoPath,
  }) async {
    final transactionModel = TransactionModel(
      id: _uuid.v4(),
      customerId: customerId,
      type: type == TransactionType.credit ? 'credit' : 'payment',
      amount: amount,
      timestamp: DateTime.now(),
      note: note,
      voiceNotePath: voiceNotePath,
      photoPath: photoPath,
    );

    await _transactionBox.put(transactionModel.id, transactionModel);

    // Update customer's updatedAt timestamp
    final customer = _customerBox.get(customerId);
    if (customer != null) {
      final updatedCustomer = CustomerModel(
        id: customer.id,
        name: customer.name,
        phoneNumber: customer.phoneNumber,
        photoPath: customer.photoPath,
        createdAt: customer.createdAt,
        updatedAt: DateTime.now(),
      );
      await _customerBox.put(customerId, updatedCustomer);
    }

    return transactionModel.toEntity();
  }

  @override
  Future<double> getCustomerBalance(String customerId) async {
    double balance = 0;

    for (final transaction in _transactionBox.values) {
      if (transaction.customerId == customerId) {
        if (transaction.type == 'credit') {
          balance += transaction.amount;
        } else if (transaction.type == 'payment') {
          balance -= transaction.amount;
        }
      }
    }

    return balance;
  }

  @override
  Future<double> getTotalOwedToVendor() async {
    double total = 0;
    final customerIds = _getAllCustomerIds();

    for (final customerId in customerIds) {
      final balance = await getCustomerBalance(customerId);
      if (balance > 0) {
        total += balance;
      }
    }

    return total;
  }

  @override
  Future<double> getTotalVendorOwes() async {
    double total = 0;
    final customerIds = _getAllCustomerIds();

    for (final customerId in customerIds) {
      final balance = await getCustomerBalance(customerId);
      if (balance < 0) {
        total += balance.abs();
      }
    }

    return total;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
  }

  // Helper: Get all unique customer IDs from transactions
  Set<String> _getAllCustomerIds() {
    final ids = <String>{};
    for (final transaction in _transactionBox.values) {
      ids.add(transaction.customerId);
    }
    return ids;
  }
}
