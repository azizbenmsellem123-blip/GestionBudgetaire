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
    final userId = FirebaseAuth.instance.currentUser!.uid;

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

            // Type
            DropdownButton<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: "dépense", child: Text("Dépense")),
                DropdownMenuItem(value: "revenu", child: Text("Revenu")),
              ],
              onChanged: (v) => setState(() => type = v!),
            ),

            const SizedBox(height: 10),

            // Note
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Note (optionnel)"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null) return;

                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
                    .collection("transactions")
                    .add({
                  "amount": amount,
                  "type": type,
                  "note": noteController.text.trim(),
                  "date": DateTime.now()
                });

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
