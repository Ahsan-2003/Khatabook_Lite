import 'package:khatabook_lite/domain/entities/transaction.dart'
    show Transaction, TransactionType;

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactionsByCustomer(String customerId);
  Future<List<Transaction>> getAllTransactions();
  Future<Transaction> addTransaction({
    required String customerId,
    required TransactionType type,
    required double amount,
    String? note,
    String? voiceNotePath,
    String? photoPath,
  });
  Future<double> getCustomerBalance(String customerId);
  Future<double> getTotalOwedToVendor();
  Future<double> getTotalVendorOwes();
  Future<void> deleteTransaction(String id);
}
