import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryTransactionsView extends StatelessWidget {
  final String categoryName;

  const CategoryTransactionsView({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Transactions : $categoryName")),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("transactions")
            .where("category", isEqualTo: categoryName)
            .orderBy("date", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!.docs;

          if (transactions.isEmpty) {
            return Center(
              child: Text("Aucune transaction dans $categoryName"),
            );
          }

          double total = 0;
          for (var t in transactions) {
            final d = t.data() as Map<String, dynamic>;
            total += d["amount"] ?? 0;
          }

          return Column(
            children: [
              // --- Petit résumé ---
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                color: Colors.blue.shade50,
                child: Text(
                  "Total : ${total.toStringAsFixed(2)} DT\n"
                  "Nombre de transactions : ${transactions.length}",
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final data =
                        transactions[index].data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(data["title"]),
                      subtitle: Text(data["date"]),
                      trailing: Text("${data["amount"]} DT"),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
