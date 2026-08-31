import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khatabook_lite/domain/entities/customer.dart';
import 'package:khatabook_lite/domain/usecases/add_customer.dart';
import 'package:khatabook_lite/domain/usecases/delete_customer.dart';
import 'package:khatabook_lite/domain/usecases/get_customers.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final GetCustomers _getCustomers;
  final AddCustomer _addCustomer;
  final DeleteCustomer _deleteCustomer;

  CustomerBloc({
    required GetCustomers getCustomers,
    required AddCustomer addCustomer,
    required DeleteCustomer deleteCustomer,
  }) : _getCustomers = getCustomers,
       _addCustomer = addCustomer,
       _deleteCustomer = deleteCustomer,
       super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<AddCustomerEvent>(_onAddCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final customers = await _getCustomers();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onAddCustomer(
    AddCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await _addCustomer(
        name: event.name,
        phoneNumber: event.phoneNumber,
        photoPath: event.photoPath,
      );
      final customers = await _getCustomers();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      // Get the existing customer
      final customers = await _getCustomers();
      final existingCustomer = customers.firstWhere(
        (c) => c.id == event.customerId,
        orElse: () => throw Exception('Customer not found'),
      );

      // Create updated customer
      final updatedCustomer = Customer(
        id: existingCustomer.id,
        name: event.name,
        phoneNumber: event.phoneNumber,
        photoPath: event.photoPath ?? existingCustomer.photoPath,
        createdAt: existingCustomer.createdAt,
        updatedAt: DateTime.now(),
      );

      // Update in repository
      await _addCustomer(
        name: updatedCustomer.name,
        phoneNumber: updatedCustomer.phoneNumber,
        photoPath: updatedCustomer.photoPath,
      );

      // Delete old customer
      await _deleteCustomer(event.customerId);

      // Reload customers
      final updatedCustomers = await _getCustomers();
      emit(CustomerLoaded(updatedCustomers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await _deleteCustomer(event.customerId);
      final customers = await _getCustomers();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }
}
