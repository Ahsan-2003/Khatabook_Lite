import 'package:khatabook_lite/data/repositories/transaction_repository.dart';
import '../entities/transaction.dart';

class AddTransaction {
  final TransactionRepository repository;

  AddTransaction(this.repository);

  Future<Transaction> call({
    required String customerId,
    required TransactionType type,
    required double amount,
    String? note,
    String? voiceNotePath,
    String? photoPath,
    DateTime? timestamp,
  }) async {
    return await repository.addTransaction(
      customerId: customerId,
      type: type,
      amount: amount,
      note: note,
      voiceNotePath: voiceNotePath,
      photoPath: photoPath,
      timestamp: timestamp,
    );
  }
}
