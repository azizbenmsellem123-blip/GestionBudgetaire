class AuthService {
  // Méthode de login
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    // Exemple de condition : remplacer par la vraie logique Firebase plus tard
    if (email == "aziz@gmail.com" && password == "12") {
      return true;
    }
    return false;
  }

  // Méthode de registration
  Future<bool> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    // Exemple de condition : remplacer par la vraie logique Firebase plus tard
    if (email == "aziz@gmail.com") {
      // L'utilisateur existe déjà
      return false;
    }

    // Ici tu peux ajouter la logique pour créer l'utilisateur
    // Ex: envoyer les données à Firebase ou API

    return true; // Retourne true si l'inscription réussit
  }
}
