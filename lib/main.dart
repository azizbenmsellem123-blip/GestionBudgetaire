import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart'; // AJOUTE CET IMPORT

// Auth
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';

// Home
import '../views/home_view.dart';
import 'package:mon_app/views/add_transaction_view.dart';
import 'package:mon_app/views/edit_transaction_view.dart';
import 'package:mon_app/controllers/budget_controller.dart';
import 'package:mon_app/services/budget_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // AJOUTE CETTE LIGNE : Initialisation des locales pour le français
  await initializeDateFormatting('fr_FR', null);
  
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

        // 🔥 Route Home — maintenant correcte
        "/home": (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String;

          return HomeView(
            userId: userId,
          );
        },

        "/addTransaction": (context) => AddTransactionView(),

        "/editTransaction": (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return EditTransactionView(
            userId: args["userId"],
            transactionId: args["id"],
            data: args["data"],
          );
        },
      },
    );
  }
}