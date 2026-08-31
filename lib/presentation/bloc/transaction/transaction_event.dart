import 'package:equatable/equatable.dart';
import '../../../domain/entities/transaction.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactions extends TransactionEvent {
  final String customerId;

  const LoadTransactions(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class AddTransactionEvent extends TransactionEvent {
  final String customerId;
  final TransactionType type;
  final double amount;
  final String? note;

  const AddTransactionEvent({
    required this.customerId,
    required this.type,
    required this.amount,
    this.note,
  });

  @override
  List<Object?> get props => [customerId, type, amount, note];
}

class LoadDashboardData extends TransactionEvent {}

class DeleteTransactionEvent extends TransactionEvent {
  final String transactionId;
  final String customerId;

  const DeleteTransactionEvent({
    required this.transactionId,
    required this.customerId,
  });

  @override
  List<Object?> get props => [transactionId, customerId];
}
