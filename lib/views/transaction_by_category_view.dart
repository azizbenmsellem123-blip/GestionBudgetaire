import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionByCategoryView extends StatelessWidget {
  final String userId;
  final String category;

  const TransactionByCategoryView({
    super.key,
    required this.userId,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transactions : $category"),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("transactions")
            .where("category", isEqualTo: category)
            .orderBy("date", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Aucune transaction trouvée"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final amount = data["amount"];
              final type = data["type"];
              final note = data["note"];
              final date = (data["date"] as Timestamp).toDate();

              return Card(
                elevation: 3,
                child: ListTile(
                  title: Text("$amount TND", style: const TextStyle(fontSize: 18)),
                  subtitle: Text(
                    "$type • ${date.day}/${date.month}/${date.year}\n${note ?? ''}",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
