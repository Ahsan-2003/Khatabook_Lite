import 'package:equatable/equatable.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {}

class AddCustomerEvent extends CustomerEvent {
  final String name;
  final String? phoneNumber;
  final String? photoPath;

  const AddCustomerEvent({
    required this.name,
    this.phoneNumber,
    this.photoPath,
  });

  @override
  List<Object?> get props => [name, phoneNumber, photoPath];
}

class DeleteCustomerEvent extends CustomerEvent {
  final String customerId;

  const DeleteCustomerEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}
