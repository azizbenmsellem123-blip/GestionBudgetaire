import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/budget_controller.dart';
import '../services/budget_service.dart';

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
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  // 🔵 Charger budget depuis Firestore
  Future<void> _loadBudget() async {
    try {
      final budget = await controller.getUserBudget(widget.userId);
      setState(() {
        currentBudget = budget;
        budgetController.text = budget.toString();
      });
    } catch (e) {
      setState(() => _error = "Erreur lors du chargement du budget");
      print(e);
    }
  }

  // 🔵 Sauvegarder nouveau budget
  Future<void> _saveBudget() async {
    final amount = double.tryParse(budgetController.text.trim());

    if (amount == null || amount <= 0) {
      setState(() => _error = "Montant invalide");
      return;
    }

    setState(() => _loading = true);

    try {
      await controller.setUserBudget(widget.userId, amount);

      setState(() {
        currentBudget = amount;
        _error = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Budget mis à jour !")),
      );
    } catch (e) {
      setState(() => _error = "Erreur lors de l’enregistrement");
      print(e);
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🔵 Choisir icône selon catégorie
  IconData getCategoryIcon(String category) {
    switch (category) {
      case "Revenu":
        return Icons.attach_money;
      case "Courses":
        return Icons.shopping_cart;
      case "Transport":
        return Icons.directions_car;
      case "Factures":
        return Icons.receipt_long;
      case "Divertissement":
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),

            // 🔵 Modifier budget
            Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Modifier votre budget",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),


                      // 🔵 Ajouter transaction
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text("Ajouter transaction"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/addTransaction");
              },
            ),

            const Divider(),
                      TextField(
                        controller: budgetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Nouveau budget",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: _loading
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.check),
                            onPressed: _loading ? null : _saveBudget,
                          ),
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red)),
                        )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Bonjour Yassine !", style: TextStyle(color: Colors.black)),
        
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔵 Solde actuel
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Solde actuel",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("$currentBudget TND",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),
            const Text("Vos transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 🔵 STREAM DES TRANSACTIONS
            Expanded(
              child: StreamBuilder(
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
                    return const Center(
                        child: Text("Aucune transaction pour le moment"));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>;

                      final amount = data["amount"];
                      final type = data["type"];
                      final note = data["note"];
                      final category = data["category"] ?? "Autre";
                      final date = (data["date"] as Timestamp).toDate();

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            getCategoryIcon(category),
                            color: type == "revenu"
                                ? Colors.green
                                : Colors.red,
                            size: 32,
                          ),

                          title: Text("$amount TND",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),

                          subtitle: Text(
                            "$category • $type • "
                            "${date.day}/${date.month}/${date.year}",
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(note ?? ""), // Note affichée

                              // ✏️ EDIT
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    "/editTransaction",
                                    arguments: {
                                      "id": docs[index].id,
                                      "data": data,
                                      "userId": widget.userId
                                    },
                                  );
                                },
                              ),

                              // 🗑 DELETE
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final double amountFix =
                                      (data["amount"] * 1.0);

                                  // 🔥 Mise à jour budget
                                  final userRef = FirebaseFirestore.instance
                                      .collection("users")
                                      .doc(widget.userId);

                                  final userDoc = await userRef.get();
                                  double budget =
                                      userDoc.data()?["budget"] ?? 0;

                                  if (type == "revenu") {
                                    budget -= amountFix;
                                  } else {
                                    budget += amountFix;
                                  }

                                  await userRef.update({"budget": budget});

                                  // 🔥 Supprimer transaction
                                  await userRef
                                      .collection("transactions")
                                      .doc(docs[index].id)
                                      .delete();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Transaction supprimée")),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
