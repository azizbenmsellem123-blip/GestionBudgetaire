import 'package:flutter/material.dart';
import '../controllers/budget_controller.dart';
import '../services/budget_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Budget mis à jour !")));
    } catch (e) {
      setState(() => _error = "Erreur lors de l’enregistrement");
      print(e);
    } finally {
      setState(() => _loading = false);
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

            // 🔵 Ajouter Dépense / Revenu
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text("Ajouter dépense / revenu"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/addTransaction");
              },
            ),

            const Divider(),

            // 🟢 Modifier budget
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
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
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
        title: const Text("Bonjour Yassine !",
            style: TextStyle(color: Colors.black)),
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
          child: Text("Aucune transaction pour le moment"),
        );
      }

      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final data = docs[index].data();
          final amount = data["amount"];
          final type = data["type"];
          final note = data["note"];
          final date = (data["date"] as Timestamp).toDate();

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Icon(
                type == "revenu" ? Icons.arrow_upward : Icons.arrow_downward,
                color: type == "revenu" ? Colors.green : Colors.red,
              ),

              title: Text("$amount TND"),
              subtitle: Text("$type • ${date.day}/${date.month}/${date.year}"),

              // 👉 TRAILING AVEC EDIT + DELETE
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(note ?? ""),

                  // ✏️ Modifier
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

                  // 🗑️ Supprimer
                  IconButton(
  icon: const Icon(Icons.delete, color: Colors.red),
  onPressed: () async {
    final amount = data["amount"];
    final type = data["type"];

    final userRef = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId);

    final userDoc = await userRef.get();
    double currentBudget = userDoc.data()?["budget"] ?? 0;

    // Annuler l’effet de la transaction supprimée
    if (type == "revenu") {
      currentBudget -= amount;
    } else {
      currentBudget += amount;
    }

    await userRef.update({"budget": currentBudget});

    // Ensuite supprimer la transaction
    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("transactions")
        .doc(docs[index].id)
        .delete();
  },
)

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
