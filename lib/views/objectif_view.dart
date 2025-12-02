import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyGoalsView extends StatefulWidget {
  final String userId;

  const MonthlyGoalsView({super.key, required this.userId});

  @override
  State<MonthlyGoalsView> createState() => _MonthlyGoalsViewState();
}

class _MonthlyGoalsViewState extends State<MonthlyGoalsView> {
  final TextEditingController goalController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now();
    final monthId = "${date.year}-${date.month.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Objectif du mois"),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.userId)
            .collection("goals")
            .doc(monthId)
            .get(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data!;
          final goal = doc.exists ? (doc["goalAmount"] ?? 0) : 0;
          final spent = doc.exists ? (doc["spent"] ?? 0) : 0;
          final remaining = goal - spent;

          goalController.text = goal.toString();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // 🟦 CARD MODERNE
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Votre objectif mensuel",
                        style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: goalController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Objectif (TND)",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoBox("Dépensé", "$spent TND", Colors.red),
                          _infoBox("Reste", "$remaining TND", Colors.green),
                        ],
                      ),
                    ],
                  ),
                ),

              ],
            ),
          );
        },
      ),

      // 🟩 Floating SAVE Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.save),
        label: const Text("Sauvegarder"),
        onPressed: () async {
          final date = DateTime.now();
          final monthId = "${date.year}-${date.month.toString().padLeft(2, '0')}";

          final double? newGoal =
              double.tryParse(goalController.text.trim());
          if (newGoal == null) return;

          await FirebaseFirestore.instance
              .collection("users")
              .doc(widget.userId)
              .collection("goals")
              .doc(monthId)
              .set({
            "goalAmount": newGoal,
            "spent": 0,
            "remaining": newGoal,
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Objectif mis à jour !")),
          );
        },
      ),
    );
  }

  // 🔧 Widget pour affichage valeurs
  Widget _infoBox(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
