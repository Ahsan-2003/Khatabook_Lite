import 'package:hive/hive.dart';
import '../../domain/entities/transaction.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final String type; // 'credit' or 'payment'

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String? note;

  @HiveField(6)
  final String? voiceNotePath;

  @HiveField(7)
  final String? photoPath;

  TransactionModel({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.note,
    this.voiceNotePath,
    this.photoPath,
  });

  // Convert to Domain Entity
  Transaction toEntity() {
    return Transaction(
      id: id,
      customerId: customerId,
      type: type == 'credit' ? TransactionType.credit : TransactionType.payment,
      amount: amount,
      timestamp: timestamp,
      note: note,
      voiceNotePath: voiceNotePath,
      photoPath: photoPath,
    );
  }

  // Convert from Domain Entity
  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      customerId: transaction.customerId,
      type: transaction.type == TransactionType.credit ? 'credit' : 'payment',
      amount: transaction.amount,
      timestamp: transaction.timestamp,
      note: transaction.note,
      voiceNotePath: transaction.voiceNotePath,
      photoPath: transaction.photoPath,
    );
  }
}
