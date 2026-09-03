import 'package:equatable/equatable.dart';
import 'package:khatabook_lite/domain/entities/transaction.dart';

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

class LoadAllTransactions extends TransactionEvent {}

class AddTransactionEvent extends TransactionEvent {
  final String customerId;
  final TransactionType type;
  final double amount;
  final String? note;
  final DateTime timestamp;

  const AddTransactionEvent({
    required this.customerId,
    required this.type,
    required this.amount,
    this.note,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [customerId, type, amount, note, timestamp];
}

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

class LoadDashboardData extends TransactionEvent {}
