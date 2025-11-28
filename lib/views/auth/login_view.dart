import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';


class LoginView extends StatefulWidget {
  final AuthController controller;

  const LoginView({required this.controller, super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  // ✅ Fonction de connexion
  void _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool success = await widget.controller.login(email, password);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Redirection vers la page d'accueil
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _error = 'Email ou mot de passe incorrect';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "GestionBudgetaire",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              // IMAGE d’accueil
              SizedBox(
                height: 180,
                child: Image.asset("assets/images/7.webp"),
              ),
              const SizedBox(height: 15),
              const Text(
                "Gérez vos dépenses, maîtrisez votre budget, atteignez vos objectifs financiers.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 30),
              // Champ Email
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Adresse e-mail",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: "Donnez votre adresse e-mail",
                ),
              ),
              const SizedBox(height: 20),
              // Champ Mot de passe
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Mot de passe",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "Écrivez votre mot de passe",
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: _isLoading ? null : _login,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
    ),
    child: _isLoading
        ? const CircularProgressIndicator(color: Colors.white)
        : const Text(
            "Connexion",
            style: TextStyle(color: Colors.white),
          ),
  ),
),

if (_error != null)
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      _error!,
      style: const TextStyle(color: Colors.red),
    ),
  ),

const SizedBox(height: 10),

              // Bouton Créer compte
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/register");
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  child: const Text(
                    "Créer un compte",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
