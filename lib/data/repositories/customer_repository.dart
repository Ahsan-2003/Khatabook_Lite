import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';

class CustomerRepository {
  static final CustomerRepository _instance = CustomerRepository._internal();
  factory CustomerRepository() => _instance;
  CustomerRepository._internal();

  final _uuid = const Uuid();

  Box<Customer>? _customerBox;

  // Initialize the box
  Future<void> init() async {
    _customerBox = Hive.box<Customer>('customers');
  }

  Box<Customer> get _box {
    if (_customerBox == null) {
      throw Exception('CustomerRepository not initialized. Call init() first.');
    }
    return _customerBox!;
  }

  // Add a new customer
  Future<Customer> addCustomer({
    required String name,
    String? phoneNumber,
    String? photoPath,
  }) async {
    final now = DateTime.now();
    final customer = Customer(
      id: _uuid.v4(),
      name: name,
      phoneNumber: phoneNumber,
      photoPath: photoPath,
      createdAt: now,
      updatedAt: now,
    );

    await _box.add(customer);
    return customer;
  }

  // Get all customers sorted by updatedAt (most recent first)
  List<Customer> getAllCustomers() {
    final customers = _box.values.toList();
    customers.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return customers;
  }

  // Get a customer by ID
  Customer? getCustomerById(String id) {
    return _box.get(id);
  }

  // Update a customer
  Future<void> updateCustomer(Customer customer) async {
    customer.updatedAt = DateTime.now();
    await customer.save();
  }

  // Delete a customer
  Future<void> deleteCustomer(Customer customer) async {
    await customer.delete();
  }

  // Get customer count
  int getCustomerCount() {
    return _box.length;
  }
}
