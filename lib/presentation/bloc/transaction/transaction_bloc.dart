import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khatabook_lite/domain/usecases/delete_transaction.dart';
import '../../../domain/usecases/add_transaction.dart';
import '../../../domain/usecases/get_customer_balance.dart';
import '../../../domain/usecases/get_dashboard_data.dart';
import '../../../domain/usecases/get_transactions.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactions _getTransactions;
  final AddTransaction _addTransaction;
  final DeleteTransaction _deleteTransaction;
  final GetDashboardData _getDashboardData;
  final GetCustomerBalance _getCustomerBalance;

  TransactionBloc({
    required GetTransactions getTransactions,
    required AddTransaction addTransaction,
    required DeleteTransaction deleteTransaction,
    required GetDashboardData getDashboardData,
    required GetCustomerBalance getCustomerBalance,
  }) : _getTransactions = getTransactions,
       _addTransaction = addTransaction,
       _deleteTransaction = deleteTransaction,
       _getDashboardData = getDashboardData,
       _getCustomerBalance = getCustomerBalance,
       super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransactionEvent>(_onAddTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final transactions = await _getTransactions(event.customerId);
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _addTransaction(
        customerId: event.customerId,
        type: event.type,
        amount: event.amount,
        note: event.note,
      );
      final transactions = await _getTransactions(event.customerId);
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      final dashboardData = await _getDashboardData();
      emit(
        DashboardDataLoaded(
          totalOwedToVendor: dashboardData.totalOwedToVendor,
          totalVendorOwes: dashboardData.totalVendorOwes,
        ),
      );
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await _deleteTransaction(event.transactionId);
      final transactions = await _getTransactions(event.customerId);
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionError(e.toString()));
    }
  }
}
