import 'package:khatabook_lite/domain/entities/customer.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getAllCustomers();
  Future<Customer?> getCustomerById(String id);
  Future<Customer> addCustomer({
    required String name,
    String? phoneNumber,
    String? photoPath,
  });
  Future<void> updateCustomer(Customer customer);
  Future<void> deleteCustomer(String id);
  Future<int> getCustomerCount();
}
