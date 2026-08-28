import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
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
  String? note;

  @HiveField(6)
  String? voiceNotePath;

  @HiveField(7)
  String? photoPath;

  Transaction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.note,
    this.voiceNotePath,
    this.photoPath,
  });
}
