import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mon_app/views/auth/login_view.dart';
import 'package:mon_app/controllers/auth_controller.dart';
import '../services/auth_service.dart';



class ProfileView extends StatefulWidget {
  final String userId;

  const ProfileView({super.key, required this.userId});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) {
    final userDoc = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .get();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Profil"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: userDoc,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final String username = data["name"] ?? "Utilisateur";
          final double budget = data["budget"] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar + Nom
                Center(
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.person, size: 55, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Informations principales
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Informations",
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined,
                                color: Colors.blueAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text("Budget actuel : $budget TND",
                                  style: const TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Paramètres
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      ListTile(
                        leading:
                            const Icon(Icons.settings, color: Colors.black54),
                        title: const Text("Paramètres"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline,
                            color: Colors.black54),
                        title: const Text("À propos"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Déconnexion
                SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () async {
      await FirebaseAuth.instance.signOut();

      Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (_) => LoginView(
      controller: AuthController(AuthService()),
    ),
  ),
  (route) => false,
);

    },
    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
    child: const Text("Se déconnecter"),
  ),
)



              ],
            ),
          );
        },
      ),
    );
  }
}
