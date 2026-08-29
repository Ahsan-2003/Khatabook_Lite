enum TransactionType { credit, payment }

class Transaction {
  final String id;
  final String customerId;
  final TransactionType type;
  final double amount;
  final DateTime timestamp;
  final String? note;
  final String? voiceNotePath;
  final String? photoPath;

  const Transaction({
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
