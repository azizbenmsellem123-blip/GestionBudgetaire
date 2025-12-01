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

    return Scaffold(
      appBar: AppBar(title: const Text("Ajouter une transaction")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Montant"),
            ),

            const SizedBox(height: 15),

            DropdownButton<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: "dépense", child: Text("Dépense")),
                DropdownMenuItem(value: "revenu", child: Text("Revenu")),
              ],
              onChanged: (value) => setState(() => type = value!),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField(
              decoration: const InputDecoration(labelText: "Catégorie"),
              value: selectedCategory,
              items: categories
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: noteController,
              decoration:
                  const InputDecoration(labelText: "Note (optionnel)"),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: () async {
                final double? amount =
                    double.tryParse(amountController.text.trim());
                if (amount == null) return;

                final userRef = FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId);

                final userDoc = await userRef.get();
                double currentBudget = userDoc.data()?["budget"] ?? 0;

                if (type == "revenu") {
                  currentBudget += amount;
                } else {
                  currentBudget -= amount;
                }

                await userRef.collection("transactions").add({
                  "amount": amount,
                  "type": type,
                  "category": selectedCategory,
                  "note": noteController.text.trim(),
                  "date": DateTime.now()
                });

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
