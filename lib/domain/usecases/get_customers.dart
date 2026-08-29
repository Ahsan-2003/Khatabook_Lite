import 'package:khatabook_lite/data/repositories/customer_repository.dart';

import '../entities/customer.dart';

class GetCustomers {
  final CustomerRepository repository;

  GetCustomers(this.repository);

  Future<List<Customer>> call() async {
    return await repository.getAllCustomers();
  }
}
