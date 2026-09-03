import 'package:equatable/equatable.dart';
import 'package:khatabook_lite/domain/entities/transaction.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;

  const TransactionLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class AllTransactionsLoaded extends TransactionState {
  final List<Transaction> transactions;

  const AllTransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class DashboardDataLoaded extends TransactionState {
  final double totalOwedToVendor;
  final double totalVendorOwes;
  final List<Transaction> allTransactions;

  const DashboardDataLoaded({
    required this.totalOwedToVendor,
    required this.totalVendorOwes,
    this.allTransactions = const [],
  });

  @override
  List<Object?> get props => [
    totalOwedToVendor,
    totalVendorOwes,
    allTransactions,
  ];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}
