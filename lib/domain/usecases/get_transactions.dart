import 'package:khatabook_lite/data/repositories/transaction_repository.dart';
import '../entities/transaction.dart';

class GetTransactions {
  final TransactionRepository repository;

  GetTransactions(this.repository);

  Future<List<Transaction>> call(String customerId) async {
    return await repository.getTransactionsByCustomer(customerId);
  }
}
