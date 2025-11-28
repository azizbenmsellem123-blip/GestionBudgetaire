import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserController {
  final UserModel user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserController(this.user);

  double getSolde() => user.solde;

  /// Met à jour le budget local et dans Firestore
  Future<bool> setSolde(String value) async {
    try {
      double budget = double.parse(value);
      if (budget < 0) return false;

      user.solde = budget;

      await _firestore.collection('users').doc(user.uid).set(user.toMap());

      return true;
    } catch (e) {
      print("Erreur setSolde: $e");
      return false;
    }
  }

  /// Charger le budget depuis Firestore
  Future<void> loadSolde() async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        user.solde = doc['solde'] ?? 0;
      }
    } catch (e) {
      print("Erreur loadSolde: $e");
    }
  }
}
