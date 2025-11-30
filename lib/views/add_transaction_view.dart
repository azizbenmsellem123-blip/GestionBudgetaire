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

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter une transaction")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Montant
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Montant"),
            ),

            const SizedBox(height: 10),

            // Type : dépense / revenu
            DropdownButton<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: "dépense", child: Text("Dépense")),
                DropdownMenuItem(value: "revenu", child: Text("Revenu")),
              ],
              onChanged: (value) => setState(() => type = value!),
            ),

            const SizedBox(height: 10),

            // Note optionnelle
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Note (optionnel)"),
            ),

            const SizedBox(height: 20),

            // BOUTON AJOUTER
            ElevatedButton(
              onPressed: () async {
                final double? amount =
                    double.tryParse(amountController.text.trim());
                if (amount == null) return;

                // 🔽 Référence à l'utilisateur
                final userRef =
                    FirebaseFirestore.instance.collection("users").doc(userId);

                // 🔽 On lit le budget actuel
                final userDoc = await userRef.get();
                double currentBudget = userDoc.data()?["budget"] ?? 0;

                // 🔽 Mise à jour automatique du budget
                if (type == "revenu") {
                  currentBudget += amount;
                } else {
                  currentBudget -= amount;
                }

                // 🔽 Enregistrer la transaction
                await userRef.collection("transactions").add({
                  "amount": amount,
                  "type": type,
                  "note": noteController.text.trim(),
                  "date": DateTime.now()
                });

                // 🔽 Enregistrer le nouveau budget
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
}
