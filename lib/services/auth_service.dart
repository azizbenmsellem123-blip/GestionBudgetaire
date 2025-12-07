import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  

  Future<bool> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      print("Erreur register : $e");
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      print("Erreur login : $e");
      return false;
    }
  }

  /// 👇 ICI → getter pour récupérer l'utilisateur Firebase actuel
  User? get currentUser => _auth.currentUser;
}
