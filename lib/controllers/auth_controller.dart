import '../services/auth_service.dart';

class AuthController {
  final AuthService _service = AuthService();

  // 🔹 Inscription
  Future<bool> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
    required String password,
  }) async {
    try {
      return await _service.register(
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email,
        password: password,
      );
    } catch (e) {
      print("Erreur AuthController register: $e");
      return false;
    }
  }

  // 🔹 Connexion (à AJOUTER si elle manque)
  Future<bool> login(String email, String password) async {
    try {
      return await _service.login(email, password);
    } catch (e) {
      print("Erreur AuthController login: $e");
      return false;
    }
  }
}
