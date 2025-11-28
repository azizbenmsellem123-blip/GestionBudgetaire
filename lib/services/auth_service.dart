import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<bool> registerUser({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await firestore.collection("users").doc(userCredential.user!.uid).set({
        "nom": nom,
        "prenom": prenom,
        "telephone": telephone,
        "email": email,
        "createdAt": DateTime.now(),
      });

      return true;
    } catch (e) {
      print("Erreur register: $e");
      return false;
    }
  }

  Future<bool> loginUser(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      print("Erreur login: $e");
      return false;
    }
  }
}
