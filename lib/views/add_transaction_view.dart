import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddTransactionView extends StatefulWidget {
  const AddTransactionView({super.key});

  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  String type = "dépense";
  String? selectedCategory = "Autre";

  final List<String> categories = [
    "Revenu",
    "Courses",
    "Transport",
    "Factures",
    "Divertissement",
    "Autre"
  ];

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection("users").doc(userId);

    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter une transaction")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔵 Montant
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Montant"),
            ),
            const SizedBox(height: 15),

            // 🔵 Type revenu / dépense
            DropdownButton<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: "dépense", child: Text("Dépense")),
                DropdownMenuItem(value: "revenu", child: Text("Revenu")),
              ],
              onChanged: (value) => setState(() => type = value!),
            ),
            const SizedBox(height: 15),

            // 🔵 Catégorie
            DropdownButtonFormField(
              decoration: const InputDecoration(labelText: "Catégorie"),
              value: selectedCategory,
              items: categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (value) => setState(() => selectedCategory = value),
            ),
            const SizedBox(height: 15),

            // 🔵 Note
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Note (optionnel)"),
            ),
            const SizedBox(height: 25),

            // 🔵 Bouton ajouter
            ElevatedButton(
              onPressed: () async {
                final double? amount =
                    double.tryParse(amountController.text.trim());
                if (amount == null) return;

                // Charger budget actuel
                final userDoc = await userRef.get();
                double currentBudget = userDoc.data()?["budget"] ?? 0;

                // 🔵 Mise à jour budget
                if (type == "revenu") {
                  currentBudget += amount;
                } else {
                  currentBudget -= amount;
                }

                // 🔵 Date actuelle
                final DateTime date = DateTime.now();

                // 🔵 Ajouter la transaction
                await userRef.collection("transactions").add({
                  "amount": amount,
                  "type": type,
                  "category": selectedCategory,
                  "note": noteController.text.trim(),
                  "date": date
                });

                // -----------------------------------
                // ⭐ MISE À JOUR DES OBJECTIFS MENSUELS ⭐
                // -----------------------------------
                final String monthId =
                    "${date.year}-${date.month.toString().padLeft(2, '0')}";

                final goalRef = userRef.collection("goals").doc(monthId);
                final goalDoc = await goalRef.get();

                double goalAmount = goalDoc.data()?["goalAmount"] ?? 0;
                double spent = goalDoc.data()?["spent"] ?? 0;

                // 🔵 Si dépense → l'ajouter aux dépenses du mois
                if (type == "dépense") {
                  double newSpent = spent + amount;
                  double remaining = goalAmount - newSpent;

                  await goalRef.set({
                    "goalAmount": goalAmount,
                    "spent": newSpent,
                    "remaining": remaining,
                  }, SetOptions(merge: true));

                  // 🚨 Alerte dépassement objectif
                  if (goalAmount > 0 && newSpent > goalAmount) {
                    _showAlertGoalExceeded(context, newSpent, goalAmount);
                  }
                }

                // 🔵 Mise à jour budget global
                await userRef.update({"budget": currentBudget});

                Navigator.pop(context);
              },
              child: const Text("Ajouter"),
            )
          ],
        ),
      ),
    );
  }

  // 🚨 ALERTE SI OBJECTIF DÉPASSÉ
  void _showAlertGoalExceeded(
      BuildContext context, double spent, double goalAmount) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("⚠️ Objectif dépassé !"),
        content: Text(
            "Vous avez dépensé $spent TND alors que votre objectif était de $goalAmount TND."),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }
}
