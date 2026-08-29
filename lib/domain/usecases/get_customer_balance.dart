import 'package:khatabook_lite/data/repositories/transaction_repository.dart';

class GetCustomerBalance {
  final TransactionRepository repository;

  GetCustomerBalance(this.repository);

  Future<double> call(String customerId) async {
    return await repository.getCustomerBalance(customerId);
  }
}
