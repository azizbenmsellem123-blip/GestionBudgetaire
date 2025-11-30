import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthController {
  final AuthService _service;

  AuthController(this._service);

  Future<bool> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
    required String password,
  }) {
    return _service.register(
      nom: nom,
      prenom: prenom,
      telephone: telephone,
      email: email,
      password: password,
    );
  }

  Future<bool> login(String email, String password) {
    return _service.login(email, password);
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;
}
