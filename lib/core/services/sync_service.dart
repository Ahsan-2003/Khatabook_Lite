import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:khatabook_lite/data/models/customer_model.dart';
import 'package:khatabook_lite/data/models/transaction_model.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sync all data to cloud
  Future<void> syncToCloud() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final customerBox = Hive.box<CustomerModel>('customers');
    final transactionBox = Hive.box<TransactionModel>('transactions');

    // Sync customers
    for (final customer in customerBox.values) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('customers')
          .doc(customer.id)
          .set({
            'name': customer.name,
            'phoneNumber': customer.phoneNumber,
            'createdAt': customer.createdAt,
            'updatedAt': customer.updatedAt,
          });
    }

    // Sync transactions
    for (final transaction in transactionBox.values) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transaction.id)
          .set({
            'customerId': transaction.customerId,
            'type': transaction.type,
            'amount': transaction.amount,
            'timestamp': transaction.timestamp,
            'note': transaction.note,
            'voiceNotePath': transaction.voiceNotePath,
            'photoPath': transaction.photoPath,
          });
    }
  }

  // Restore from cloud
  Future<void> restoreFromCloud() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final customerBox = Hive.box<CustomerModel>('customers');
    final transactionBox = Hive.box<TransactionModel>('transactions');

    // Restore customers
    final customerSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('customers')
        .get();

    for (final doc in customerSnapshot.docs) {
      final data = doc.data();
      final customer = CustomerModel(
        id: doc.id,
        name: data['name'] ?? 'Unknown',
        phoneNumber: data['phoneNumber'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
      await customerBox.put(customer.id, customer);
    }

    // Restore transactions
    final transactionSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .get();

    for (final doc in transactionSnapshot.docs) {
      final data = doc.data();
      final transaction = TransactionModel(
        id: doc.id,
        customerId: data['customerId'] ?? '',
        type: data['type'] ?? 'credit',
        amount: (data['amount'] ?? 0).toDouble(),
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        note: data['note'],
        voiceNotePath: data['voiceNotePath'],
        photoPath: data['photoPath'],
      );
      await transactionBox.put(transaction.id, transaction);
    }
  }
}
