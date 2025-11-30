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
  late TextEditingController noteController;
  late String type;

  @override
  void initState() {
    super.initState();
    amountController =
        TextEditingController(text: widget.data["amount"].toString());
    noteController =
        TextEditingController(text: widget.data["note"] ?? "");
    type = widget.data["type"];
  }

  Future<void> save() async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("transactions")
        .doc(widget.transactionId)
        .update({
      "amount": double.parse(amountController.text),
      "note": noteController.text,
      "type": type,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier transaction")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Montant"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: "Note"),
            ),
            const SizedBox(height: 10),

            DropdownButton<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: "revenu", child: Text("Revenu")),
                DropdownMenuItem(value: "depense", child: Text("Dépense")),
              ],
              onChanged: (v) => setState(() => type = v!),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: save,
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}
