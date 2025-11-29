import 'package:flutter/material.dart';
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
    final text = budgetController.text.trim();
    final amount = double.tryParse(text);

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
      setState(() => _error = "Erreur lors de l'enregistrement");
      print(e);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // MENU À GAUCHE
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

            // === PARTIE MODIFIER LE BUDGET ===
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
          children: [
            // === SOLDE ACTUEL ===
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
          ],
        ),
      ),
    );
  }
}
