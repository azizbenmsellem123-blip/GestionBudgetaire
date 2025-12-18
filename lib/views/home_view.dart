import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../services/budget_service.dart';
import '../controllers/budget_controller.dart';
import '../views/category_list_view.dart';
import '../views/objectif_view.dart';
import '../views/category_stats_view.dart';
import '../views/profile_view.dart';
import '../views/edit_transaction_view.dart';

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
  bool _showBudgetInput = false;

  @override
  void initState() {
    super.initState();
    loadBudget();
  }

  Future<void> loadBudget() async {
    final amount = await controller.getUserBudget(widget.userId);
    setState(() {
      currentBudget = amount;
      budgetController.text = amount.toStringAsFixed(2);
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
      _showBudgetInput = false;
    });
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case "Revenu":
        return Icons.account_balance_wallet_rounded;
      case "Courses":
        return Icons.shopping_basket_rounded;
      case "Transport":
        return Icons.directions_car_rounded;
      case "Factures":
        return Icons.receipt_long_rounded;
      case "Divertissement":
        return Icons.celebration_rounded;
      case "Santé":
        return Icons.medical_services_rounded;
      case "Éducation":
        return Icons.school_rounded;
      case "Restaurant":
        return Icons.restaurant_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case "Revenu":
        return Colors.green.shade100;
      case "Courses":
        return Colors.blue.shade100;
      case "Transport":
        return Colors.orange.shade100;
      case "Factures":
        return Colors.red.shade100;
      case "Divertissement":
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Widget _buildDrawerSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 1,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.blue,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      minLeadingWidth: 0,
    );
  }

  Future<void> _deleteTransaction(String id, Map<String, dynamic> data) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer la transaction"),
        content: const Text(
            "Êtes-vous sûr de vouloir supprimer cette transaction ? Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Annuler",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Supprimer",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

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

    setState(() {
      currentBudget = budget;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Transaction supprimée avec succès"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Text(
                "Bonjour  👋",
                 textAlign: TextAlign.center, // Ajoute cette ligne
                 style: TextStyle(
                 color: Colors.black87,
                 fontSize: 18,
                 fontWeight: FontWeight.w600,
                ),
                ),
            Text(
              "Gérez votre budget simplement",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              backgroundColor: Colors.red,
              smallSize: 8,
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.black87,
              ),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte du budget
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade700,
                      Colors.blue.shade500,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Solde actuel",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "$currentBudget TND",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              
              // Statistiques rapides
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.userId)
                    .collection("transactions")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildStatsPlaceholder();
                  }

                  double totalIncome = 0;
                  double totalExpense = 0;

                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final amount = (data["amount"] ?? 0).toDouble();
                    if (data["type"] == "revenu") {
                      totalIncome += amount;
                    } else {
                      totalExpense += amount;
                    }
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.arrow_upward_rounded,
                          title: "Revenus",
                          value: "${totalIncome.toStringAsFixed(2)} TND",
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.arrow_downward_rounded,
                          title: "Dépenses",
                          value: "${totalExpense.toStringAsFixed(2)} TND",
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.savings_rounded,
                          title: "Économies",
                          value: "${(totalIncome - totalExpense).toStringAsFixed(2)} TND",
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 25),

              // En-tête des transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Dernières transactions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/addTransaction");
                    },
                    child: Text(
                      "Voir tout",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Liste des transactions
              _buildTransactionStream(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsPlaceholder() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.arrow_upward_rounded,
            title: "Revenus",
            value: "0.00 TND",
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.arrow_downward_rounded,
            title: "Dépenses",
            value: "0.00 TND",
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.savings_rounded,
            title: "Économies",
            value: "0.00 TND",
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionStream() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .collection("transactions")
          .orderBy("date", descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingTransactions();
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _buildEmptyTransactions();
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final date = (data["date"] as Timestamp).toDate();
            final isIncome = data["type"] == "revenu";
            final amount = data["amount"] * 1.0;
            final category = data["category"] ?? "Autre";

            return _buildTransactionItem(
              id: docs[index].id,
              data: data,
              amount: amount,
              category: category,
              isIncome: isIncome,
              date: date,
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionItem({
    required String id,
    required Map<String, dynamic> data,
    required double amount,
    required String category,
    required bool isIncome,
    required DateTime date,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: getCategoryColor(category),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            getCategoryIcon(category),
            color: isIncome ? Colors.green : Colors.blue,
            size: 24,
          ),
        ),
        title: Text(
          "$amount TND",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isIncome ? Colors.green : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              category,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            Text(
              "${date.day}/${date.month}/${date.year} • ${isIncome ? "Revenu" : "Dépense"}",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditTransactionView(
                      userId: widget.userId,
                      transactionId: id,
                      data: data,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                  size: 18,
                ),
              ),
              onPressed: () async {
                await _deleteTransaction(id, data);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingTransactions() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            title: Container(
              width: 100,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            subtitle: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 150,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            color: Colors.grey.shade300,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            "Aucune transaction",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Commencez par ajouter votre première transaction",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade700,
                    Colors.blue.shade400,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Yassine",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "Gestion de budget",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Section menu principal uniquement
            _buildDrawerSection(
              title: "Navigation",
              children: [
                _buildDrawerItem(
                  icon: Icons.home_rounded,
                  text: "Accueil",
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_chart_rounded,
                  text: "Transactions",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, "/addTransaction");
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.category_rounded,
                  text: "Catégories",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryListView(userId: widget.userId),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bar_chart_rounded,
                  text: "Statistiques",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryStatsView(userId: widget.userId),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.flag_rounded,
                  text: "Objectifs",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MonthlyGoalsView(userId: widget.userId),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_rounded,
                  text: "Mon Profil",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileView(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // ... (le reste du code reste inchangé jusqu'à la section Budget du drawer)

// Section Budget mensuel - STYLE FOCUS DINAR TUNISIEN
Padding(
  padding: const EdgeInsets.all(16),
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.green.shade800,
          Colors.teal.shade700,
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.green.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.amber.shade300,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Budget Mensuel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "En Dinar Tunisien",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.currency_exchange_rounded,
                      color: Colors.amber.shade300,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "TND",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Affichage du budget actuel - DESIGN DINAR
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "DT",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      currentBudget.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Roboto',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "DINAR TUNISIEN",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMMM yyyy').format(DateTime.now()),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 15),
          
          // Bouton pour modifier le budget (design moderne et professionnel)
if (!_showBudgetInput)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 0), // Assurez-vous d'avoir de l'espace autour si nécessaire
    child: ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _showBudgetInput = true;
        });
      },
      style: ElevatedButton.styleFrom(
        // Fond principal : Vert foncé pour le contraste ou couleur neutre
        backgroundColor: Colors.amber.shade600, // Couleur accentuée
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50), // Bouton pleine largeur et bonne hauteur
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Bordures douces
        ),
        elevation: 5, // Ajoute un peu de profondeur pour un look professionnel
        shadowColor: Colors.amber.shade900.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: const Icon(
        Icons.edit_rounded,
        size: 20,
      ),
      label: const Text(
        "MODIFIER LE BUDGET",
        style: TextStyle(
          fontSize: 16, // Légèrement plus grand
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0, // Espacement pour un look premium
        ),
      ),
    ),
  ),
          
          // Champ de saisie (seulement visible si _showBudgetInput est true)
if (_showBudgetInput)
  Column(
    children: [
      const SizedBox(height: 20),
      Container(
        // ... (votre Container existant)
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.15), // Ombre plus marquée
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // ... (Titre "NOUVEAU BUDGET")

            const SizedBox(height: 20),
            
            // Champ avec mise en évidence DT (gardé tel quel, il est déjà bien)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.shade300,
                  width: 2,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Badge DT à gauche
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "DT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  
                  // Champ de saisie
                  Expanded(
                    child: TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                      ),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: "0,00",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),
                  
                  // Symbole dinar à droite (adapté pour le look)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: Text(
                      "د.ت", // Symbole dinar en arabe
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // ... (Message d'information)
            Text(
              "Saisissez le montant en Dinar Tunisien",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showBudgetInput = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      side: BorderSide(
                        color: Colors.grey.shade300, // Couleur de bordure plus neutre
                        width: 1.5, // Épaisseur réduite
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Bordures douces
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14, // Hauteur ajustée
                      ),
                    ),
                    child: const Text(
                      "ANNULER",
                      style: TextStyle(
                        fontWeight: FontWeight.w600, // Poids ajusté
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon( // Changement en ElevatedButton.icon pour plus de style
                    onPressed: loading ? null : updateBudget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      elevation: 4,
                    ),
                    icon: loading
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                          ),
                    label: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "CONFIRMER",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            
            // ... (Conseils financiers)
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.green.shade100,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Conseil Budgétaire :",
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Un budget réaliste vous aide à mieux gérer vos finances et à atteindre vos objectifs d'épargne.",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  ),

// ... (votre Message d'encouragement quand le champ est caché, qui est bien)
    
          // Message d'encouragement quand le champ est caché
          if (!_showBudgetInput)
            Column(
              children: [
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        color: Colors.amber.shade300,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Budget actuel : ${currentBudget.toStringAsFixed(2)} DT",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.trending_up_rounded,
                        color: Colors.green.shade300,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  ),
),

// ... (le reste du code reste inchangé)
          ],
        ),
      ),
    );
  }
}