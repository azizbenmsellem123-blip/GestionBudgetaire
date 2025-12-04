import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool darkMode = false;
  bool notifications = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil & Paramètres"),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ---------- AVATAR ----------
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Text(
                (user?.email?[0].toUpperCase() ?? "?"),
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),

            const SizedBox(height: 15),

            // ---------- USER INFO ----------
            Text(
              user?.email ?? "Utilisateur",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // ---------- SETTINGS ----------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Mode sombre"),
                    value: darkMode,
                    onChanged: (v) => setState(() => darkMode = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text("Notifications"),
                    value: notifications,
                    onChanged: (v) => setState(() => notifications = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ---------- EDIT PROFILE ----------
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text("Modifier profil"),
              ),
            ),

            const SizedBox(height: 10),

            // ---------- LOGOUT ----------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Se déconnecter"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
