import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> addTransaction(String userId, TransactionModel transaction) async {
    try {
      await _db
          .collection("users")
          .doc(userId)
          .collection("transactions")
          .add(transaction.toMap());

      return true;
    } catch (e) {
      print("Erreur Firestore: $e");
      return false;
    }
  }

  // Charge la liste
  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _db
        .collection("users")
        .doc(userId)
        .collection("transactions")
        .orderBy("date", descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return TransactionModel(
                title: data["title"],
                amount: data["amount"] * 1.0,
                type: data["type"],
                date: DateTime.parse(data["date"]),
              );
            }).toList());
  }
}
