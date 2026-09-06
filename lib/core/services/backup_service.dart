import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:khatabook_lite/data/models/customer_model.dart';
import 'package:khatabook_lite/data/models/transaction_model.dart';

class BackupService {
  // Create backup file
  Future<File> createBackup() async {
    final customerBox = Hive.box<CustomerModel>('customers');
    final transactionBox = Hive.box<TransactionModel>('transactions');

    final backupData = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'customers': customerBox.values.map((c) {
        return {
          'id': c.id,
          'name': c.name,
          'phoneNumber': c.phoneNumber,
          'photoPath': c.photoPath,
          'createdAt': c.createdAt.toIso8601String(),
          'updatedAt': c.updatedAt.toIso8601String(),
        };
      }).toList(),
      'transactions': transactionBox.values.map((t) {
        return {
          'id': t.id,
          'customerId': t.customerId,
          'type': t.type,
          'amount': t.amount,
          'timestamp': t.timestamp.toIso8601String(),
          'note': t.note,
          'voiceNotePath': t.voiceNotePath,
          'photoPath': t.photoPath,
        };
      }).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/khatabook_backup_$timestamp.json');

    await file.writeAsString(jsonEncode(backupData));

    return file;
  }

  // Restore from backup file
  Future<Map<String, int>> restoreFromBackup(File file) async {
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    final customerBox = Hive.box<CustomerModel>('customers');
    final transactionBox = Hive.box<TransactionModel>('transactions');

    int customersRestored = 0;
    int transactionsRestored = 0;

    // Restore customers
    final customers = data['customers'] as List<dynamic>;
    for (final customerData in customers) {
      final customer = CustomerModel(
        id: customerData['id'],
        name: customerData['name'],
        phoneNumber: customerData['phoneNumber'],
        photoPath: customerData['photoPath'],
        createdAt: DateTime.parse(customerData['createdAt']),
        updatedAt: DateTime.parse(customerData['updatedAt']),
      );
      await customerBox.put(customer.id, customer);
      customersRestored++;
    }

    // Restore transactions
    final transactions = data['transactions'] as List<dynamic>;
    for (final transactionData in transactions) {
      final transaction = TransactionModel(
        id: transactionData['id'],
        customerId: transactionData['customerId'],
        type: transactionData['type'],
        amount: transactionData['amount'].toDouble(),
        timestamp: DateTime.parse(transactionData['timestamp']),
        note: transactionData['note'],
        voiceNotePath: transactionData['voiceNotePath'],
        photoPath: transactionData['photoPath'],
      );
      await transactionBox.put(transaction.id, transaction);
      transactionsRestored++;
    }

    return {
      'customers': customersRestored,
      'transactions': transactionsRestored,
    };
  }

  // Validate backup file
  bool isValidBackup(String content) {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data.containsKey('customers') && data.containsKey('transactions');
    } catch (e) {
      return false;
    }
  }
}
