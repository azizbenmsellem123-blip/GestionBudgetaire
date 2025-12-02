import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/budget_service.dart';
import '../controllers/budget_controller.dart';
import '../views/category_list_view.dart';
import '../views/objectif_view.dart';



class HomeView extends StatefulWidget {
  final String userId;

  const HomeView({super.key, required this.userId});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final BudgetController controller = BudgetController(BudgetService());
  final TextEditingController budgetController = TextEditingController();

  double currentBudget = 0;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadBudget();
  }

  Future<void> loadBudget() async {
    final amount = await controller.getUserBudget(widget.userId);
    setState(() {
      currentBudget = amount;
      budgetController.text = amount.toString();
    });
  }

  Future<void> updateBudget() async {
    final value = double.tryParse(budgetController.text.trim());
    if (value == null || value <= 0) return;

    setState(() => loading = true);
    await controller.setUserBudget(widget.userId, value);
    setState(() {
      currentBudget = value;
      loading = false;
    });
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case "Revenu": return Icons.attach_money;
      case "Courses": return Icons.shopping_cart;
      case "Transport": return Icons.directions_car;
      case "Factures": return Icons.receipt_long;
      case "Divertissement": return Icons.movie;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 1,
  iconTheme: const IconThemeData(color: Colors.black),
  title: const Text(
    "Bonjour Yassine !",
    style: TextStyle(color: Colors.black),
  ),
  actions: [
    // 🔵 Bouton catégories
    IconButton(
      icon: const Icon(Icons.category),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryListView(userId: widget.userId),
          ),
        );
      },
    ),

    // 🔵 Bouton Objectifs mensuels
    IconButton(
      icon: const Icon(Icons.flag),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MonthlyGoalsView(userId: widget.userId),
          ),
        );
      },
    ),
    
    IconButton(
  icon: const Icon(Icons.bar_chart),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryStatsView(userId: widget.userId),
      ),
    );
  },
),

  ],
),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBudgetCard(),
            const SizedBox(height: 25),
            const Text("Vos transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(child: _buildTransactionStream())
          ],
        ),
      ),
    );
  }

  // ⭐ Drawer modernisé
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text("Menu",
                style: TextStyle(color: Colors.white, fontSize: 22)),
          ),

          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text("Ajouter transaction"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, "/addTransaction");
            },
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("Modifier votre budget",
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Budget",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check),
                          onPressed: loading ? null : updateBudget,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ⭐ Budget Card
  Widget _buildBudgetCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Solde actuel",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("$currentBudget TND",
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ⭐ Transactions Stream
  Widget _buildTransactionStream() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .collection("transactions")
          .orderBy("date", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("Aucune transaction pour le moment"));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final date = (data["date"] as Timestamp).toDate();

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(
                  getCategoryIcon(data["category"] ?? "Autre"),
                  color: data["type"] == "revenu" ? Colors.green : Colors.red,
                  size: 32,
                ),
                title: Text("${data["amount"]} TND",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    "${data["category"]} • ${data["type"]} • ${date.day}/${date.month}/${date.year}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.pushNamed(context, "/editTransaction",
                            arguments: {
                              "id": docs[index].id,
                              "data": data,
                              "userId": widget.userId
                            });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await _deleteTransaction(docs[index].id, data);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ⭐ Suppression + mise à jour budget
  Future<void> _deleteTransaction(String id, Map<String, dynamic> data) async {
    final userRef =
        FirebaseFirestore.instance.collection("users").doc(widget.userId);

    final userDoc = await userRef.get();
    double budget = userDoc.data()?["budget"] ?? 0;
    final double amount = data["amount"] * 1.0;

    if (data["type"] == "revenu") {
      budget -= amount;
    } else {
      budget += amount;
    }

    await userRef.update({"budget": budget});
    await userRef.collection("transactions").doc(id).delete();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Transaction supprimée")));
  }
}
