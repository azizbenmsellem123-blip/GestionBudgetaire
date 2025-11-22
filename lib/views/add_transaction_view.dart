import 'package:flutter/material.dart';
import '../controllers/transaction_controller.dart';
import '../models/transaction_model.dart';

class AddTransactionView extends StatefulWidget {
  final TransactionController controller;

  const AddTransactionView({super.key, required this.controller});

  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  bool isIncome = false; // false = dépense par défaut
  String? errorMessage;

  void _saveTransaction() {
    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text.trim());

    if (title.isEmpty || amount == null) {
      setState(() {
        errorMessage = "Veuillez remplir tous les champs correctement.";
      });
      return;
    }

    final newTransaction = TransactionModel(
      title: title,
      amount: isIncome ? amount : -amount,
      isIncome: isIncome,
    );

    widget.controller.addTransaction(newTransaction);

    Navigator.pop(context, newTransaction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter une transaction"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Type de transaction :",
                style: TextStyle(fontWeight: FontWeight.bold)),

            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text("Revenu"),
                    value: true,
                    groupValue: isIncome,
                    onChanged: (value) {
                      setState(() => isIncome = true);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text("Dépense"),
                    value: false,
                    groupValue: isIncome,
                    onChanged: (value) {
                      setState(() => isIncome = false);
                    },
                  ),
                ),
              ],
            ),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Montant",
                border: OutlineInputBorder(),
              ),
            ),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Ajouter",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
