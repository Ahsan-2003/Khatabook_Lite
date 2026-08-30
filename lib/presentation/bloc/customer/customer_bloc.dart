import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/add_customer.dart';
import '../../../domain/usecases/delete_customer.dart';
import '../../../domain/usecases/get_customers.dart';
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
