import 'package:hive/hive.dart';
import 'package:khatabook_lite/data/repositories/customer_repository.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/customer.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final Box<CustomerModel> _customerBox;
  final _uuid = const Uuid();

  CustomerRepositoryImpl({required Box<CustomerModel> customerBox})
    : _customerBox = customerBox;

  @override
  Future<List<Customer>> getAllCustomers() async {
    final customers = _customerBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return customers.map((c) => c.toEntity()).toList();
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    final customer = _customerBox.get(id);
    return customer?.toEntity();
  }

  @override
  Future<Customer> addCustomer({
    required String name,
    String? phoneNumber,
    String? photoPath,
  }) async {
    final now = DateTime.now();
    final customerModel = CustomerModel(
      id: _uuid.v4(),
      name: name,
      phoneNumber: phoneNumber,
      photoPath: photoPath,
      createdAt: now,
      updatedAt: now,
    );

    await _customerBox.put(customerModel.id, customerModel);
    return customerModel.toEntity();
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    final customerModel = CustomerModel.fromEntity(customer);
    await _customerBox.put(customerModel.id, customerModel);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _customerBox.delete(id);
  }

  @override
  Future<int> getCustomerCount() async {
    return _customerBox.length;
  }
}
