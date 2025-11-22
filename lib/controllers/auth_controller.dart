import '../services/auth_service.dart';

class AuthController {
  final AuthService authService;

  AuthController(this.authService);

  Future<bool> login(String email, String password) {
    return authService.login(email, password);
  }

  Future<bool> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
    required String password,
  }) {
    return authService.register(
      nom: nom,
      prenom: prenom,
      telephone: telephone,
      email: email,
      password: password,
    );
  }
}
