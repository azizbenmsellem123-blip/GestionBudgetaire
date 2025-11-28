import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveBudget(String userId, double amount) async {
    try {
      await _db.collection("users").doc(userId).set({
        "budget": amount,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception("Erreur Firestore: $e");
    }
  }

  Future<double> getBudget(String userId) async {
    final doc = await _db.collection("users").doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return (doc.data()!['budget'] ?? 0).toDouble();
    }
    return 0;
  }
}
