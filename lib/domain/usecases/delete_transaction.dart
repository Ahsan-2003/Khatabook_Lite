import 'package:khatabook_lite/data/repositories/transaction_repository.dart';

class DeleteTransaction {
  final TransactionRepository repository;

  DeleteTransaction(this.repository);

  Future<void> call(String id) async {
    await repository.deleteTransaction(id);
  }
}
