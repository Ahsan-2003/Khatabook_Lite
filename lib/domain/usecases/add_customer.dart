import 'package:khatabook_lite/data/repositories/customer_repository.dart';
import '../entities/customer.dart';

class AddCustomer {
  final CustomerRepository repository;

  AddCustomer(this.repository);

  Future<Customer> call({
    required String name,
    String? phoneNumber,
    String? photoPath,
  }) async {
    return await repository.addCustomer(
      name: name,
      phoneNumber: phoneNumber,
      photoPath: photoPath,
    );
  }
}
