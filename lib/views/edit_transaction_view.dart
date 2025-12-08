import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTransactionView extends StatefulWidget {
  final String userId;
  final String transactionId;
  final Map<String, dynamic> data;

  const EditTransactionView({
    super.key,
    required this.userId,
    required this.transactionId,
    required this.data,
  });

  @override
  State<EditTransactionView> createState() => _EditTransactionViewState();
}

class _EditTransactionViewState extends State<EditTransactionView> {
  late TextEditingController amountController;
  late TextEditingController descriptionController;
  String type = "depense";

  @override
  void initState() {
    super.initState();
    amountController =
        TextEditingController(text: widget.data["amount"].toString());
    descriptionController =
        TextEditingController(text: widget.data["description"] ?? "");
    type = widget.data["type"];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier la transaction"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Montant"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField(
              value: type,
              decoration: const InputDecoration(labelText: "Type"),
              items: const [
                DropdownMenuItem(
                  value: "Revenu",
                  child: Text("Revenu"),
                ),
                DropdownMenuItem(
                  value: "Depense",
                  child: Text("dépense"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  type = value.toString();
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.userId)
                    .collection("transactions")
                    .doc(widget.transactionId)
                    .update({
                  "amount": double.parse(amountController.text),
                  "description": descriptionController.text,
                  "type": type,
                });

                Navigator.pop(context);
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}
