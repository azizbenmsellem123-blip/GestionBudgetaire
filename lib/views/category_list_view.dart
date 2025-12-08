import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_by_category_view.dart';

class CategoryListView extends StatelessWidget {
  final String userId;

  const CategoryListView({super.key, required this.userId});

  // Liste des catégories par défaut
  final List<String> categories = const [
    "revenu",
    "courses",
    "transport",
    "factures",
    "divertissement",
    "autre"
  ];

  IconData getCategoryIcon(String category) {
    switch (category) {
      case "revenu":
        return Icons.attach_money;
      case "courses":
        return Icons.shopping_cart;
      case "transport":
        return Icons.directions_car;
      case "factures":
        return Icons.receipt_long;
      case "divertissement":
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catégories"),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          return Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(getCategoryIcon(category), size: 30),
              title: Text(category, style: const TextStyle(fontSize: 18)),
              
              // 🔥 Nombre de transactions dans cette catégorie
              trailing: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
                    .collection("transactions")
                    .where("category", isEqualTo: category)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text("0");

                  return Text(
                    snapshot.data!.docs.length.toString(),
                    style: const TextStyle(fontSize: 16),
                  );
                },
              ),

              // 🔥 Clic → voir transactions par catégorie
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TransactionByCategoryView(userId: userId, category: category),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
