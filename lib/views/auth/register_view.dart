import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  final AuthController controller;

  const RegisterView({required this.controller, super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;

  void handleRegister() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe ne correspondent pas ❌")),
      );
      return;
    }

    setState(() => isLoading = true);

   bool success = await widget.controller.login(email, password);



    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compte créé avec succès ✔")),
      );
      // Navigation vers login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'inscription")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crée un compte"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Image en haut
            SizedBox(
              height: 160,
              child: Image.asset("assets/images/crea.webp"),
            ),

            const SizedBox(height: 20),

            // NOM
            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: "NOM"),
            ),
            const SizedBox(height: 10),

            // Prénom
            TextField(
              controller: prenomController,
              decoration: const InputDecoration(labelText: "Prénom"),
            ),
            const SizedBox(height: 10),

            // Téléphone
            TextField(
              controller: telephoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Téléphone"),
            ),
            const SizedBox(height: 10),

            // Email
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Adresse e-mail"),
            ),
            const SizedBox(height: 10),

            // Mot de passe
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mot de passe"),
            ),
            const SizedBox(height: 10),

            // Confirmation mot de passe
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirmation du mot de passe"),
            ),

            const SizedBox(height: 25),

            // Bouton S'inscrire
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "S’inscrire",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            // Déjà un compte ? Se connecter
GestureDetector(
  onTap: () {
    // Ici tu peux ajouter une condition si nécessaire
    // Par exemple, vérifier si l'utilisateur a déjà un compte
    // Mais souvent on suppose qu'il a un compte et on retourne au login
    Navigator.pushReplacementNamed(context, "/login"); // redirige vers login
  },
  child: const Text(
    "Déjà un compte ? Se connecter",
    style: TextStyle(
      fontSize: 16,
      decoration: TextDecoration.underline,
      color: Colors.black, // pour ressembler à un lien
    ),
  ),
)

          ],
        ),
      ),
    );
  }
}
