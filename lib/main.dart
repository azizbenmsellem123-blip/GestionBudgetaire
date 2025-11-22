import 'package:flutter/material.dart';

// AUTH
import '../services/auth_service.dart';
import '../controllers/auth_controller.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';

import '../views/home_view.dart'; 


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Service et contrôleur Auth
  final authService = AuthService();
  final authController = AuthController(authService);

  runApp(MyApp(authController: authController));
}

class MyApp extends StatelessWidget {
  final AuthController authController;

  const MyApp({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "GestionBudgetaire",
      debugShowCheckedModeBanner: false,
      initialRoute: "/login",
      routes: {
        "/login": (context) => LoginView(controller: authController),
        "/register": (context) => RegisterView(controller: authController),
        "/home": (context) => const HomeView(),

      },
    );
  }
}
