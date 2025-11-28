import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Auth
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';

// Home
import '../views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      debugShowCheckedModeBanner: false,
      title: "GestionBudgetaire",
      initialRoute: "/login",
      routes: {
        "/login": (context) => LoginView(controller: authController),
        "/register": (context) => RegisterView(controller: authController),
        // Route Home : userId doit être passé depuis login
        "/home": (context) => HomeView(userId: "tempUserId"), // <-- temporaire, sera remplacé par l'ID réel
      },
    );
  }
}
