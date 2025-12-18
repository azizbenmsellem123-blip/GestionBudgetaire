import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class MonthlyGoalsView extends StatefulWidget {
  final String userId;

  const MonthlyGoalsView({super.key, required this.userId});

  @override
  State<MonthlyGoalsView> createState() => _MonthlyGoalsViewState();
}

class _MonthlyGoalsViewState extends State<MonthlyGoalsView> {
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _editGoalController = TextEditingController();
  String _selectedMonth = _getCurrentMonthId();
  bool _isLoading = false;
  bool _showGoalInput = false;

  static String _getCurrentMonthId() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  static String _formatMonthId(String monthId) {
    try {
      final parts = monthId.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      final monthName = DateFormat.MMMM('fr').format(DateTime(2000, month));
      return '${monthName[0].toUpperCase()}${monthName.substring(1)} $year';
    } catch (e) {
      return monthId;
    }
  }

  // Vérifier si un montant est valide (positif et raisonnable)
  bool _isValidAmount(String input) {
    final amount = double.tryParse(input.replaceAll(',', '.'));
    if (amount == null) return false;
    if (amount <= 0) return false;
    if (amount > 1000000) return false; // Limite raisonnable de 1 million
    return true;
  }

  // Formater le montant pour l'affichage
  String _formatAmount(double amount) {
    return NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'TND',
      decimalDigits: 2,
    ).format(amount);
  }

  // Calculer les dépenses du mois
  Future<double> _getMonthlyExpenses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .collection("transactions")
          .where("dateId", isEqualTo: _selectedMonth)
          .where("type", isEqualTo: "depense")
          .get();

      double totalSpent = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalSpent += (data["amount"] ?? 0).toDouble();
      }
      return totalSpent;
    } catch (e) {
      print('Erreur calcul dépenses: $e');
      return 0;
    }
  }

  // Vérifier si un objectif existe déjà
  Future<bool> _checkExistingGoal() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .collection("goals")
          .doc(_selectedMonth)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Sauvegarder un nouvel objectif
  Future<void> _saveGoal() async {
    final input = _goalController.text.trim();
    
    // Vérification du montant
    if (!_isValidAmount(input)) {
      _showError("Veuillez saisir un montant valide (ex: 1500.50)");
      return;
    }

    final newGoal = double.parse(input.replaceAll(',', '.'));
    
    // Vérifier si l'objectif est raisonnable
    if (newGoal < 10) {
      _showError("Le montant minimum est de 10 TND");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final totalSpent = await _getMonthlyExpenses();
      final remaining = newGoal - totalSpent;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .collection("goals")
          .doc(_selectedMonth)
          .set({
        "goalAmount": newGoal,
        "spent": totalSpent,
        "remaining": remaining > 0 ? remaining : 0,
        "month": _formatMonthId(_selectedMonth),
        "monthId": _selectedMonth,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSuccess("Objectif défini avec succès !");
      _goalController.clear();
      setState(() => _showGoalInput = false);
    } catch (e) {
      _showError("Erreur: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Mettre à jour un objectif existant
  Future<void> _updateGoal() async {
    final input = _editGoalController.text.trim();
    
    if (!_isValidAmount(input)) {
      _showError("Veuillez saisir un montant valide");
      return;
    }

    final newGoal = double.parse(input.replaceAll(',', '.'));
    
    if (newGoal < 10) {
      _showError("Le montant minimum est de 10 TND");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final totalSpent = await _getMonthlyExpenses();
      final remaining = newGoal - totalSpent;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .collection("goals")
          .doc(_selectedMonth)
          .update({
        "goalAmount": newGoal,
        "spent": totalSpent,
        "remaining": remaining > 0 ? remaining : 0,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      _showSuccess("Objectif mis à jour avec succès !");
      Navigator.pop(context); // Fermer le dialogue
    } catch (e) {
      _showError("Erreur: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Supprimer un objectif
  Future<void> _deleteGoal() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Supprimer l'objectif"),
          ],
        ),
        content: const Text("Êtes-vous sûr de vouloir supprimer cet objectif ? Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Annuler",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(widget.userId)
                    .collection("goals")
                    .doc(_selectedMonth)
                    .delete();
                
                _showSuccess("Objectif supprimé avec succès");
              } catch (e) {
                _showError("Erreur lors de la suppression");
              } finally {
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  // Afficher le dialogue d'édition
  void _showEditDialog(double currentGoal) {
    _editGoalController.text = currentGoal.toStringAsFixed(2);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Modifier l'objectif"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _editGoalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nouveau montant (TND)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.attach_money_rounded),
                suffixText: "TND",
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Exemple: 1500.50",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _updateGoal,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Afficher le formulaire d'ajout d'objectif
  Widget _buildGoalInputForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Définir un objectif pour ${_formatMonthId(_selectedMonth)}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _goalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Montant de l'objectif (TND)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.attach_money_rounded),
              suffixText: "TND",
              hintText: "Ex: 1500.50",
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Le montant doit être supérieur à 10 TND",
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
                    setState(() => _showGoalInput = false);
                    _goalController.clear();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Annuler"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Enregistrer"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Actions pour un objectif existant
  Widget _buildGoalActions(double goal, double spent, double remaining, bool isOverBudget) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gérer l'objectif",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditDialog(goal),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text("Modifier"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleteGoal,
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  label: const Text("Supprimer"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isOverBudget)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.orange.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Vous avez dépassé votre objectif de ${_formatAmount(spent - goal)}",
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Objectifs Mensuels"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: Colors.blue.shade700),
            onPressed: () => _showHistoryDialog(),
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.userId)
            .collection("goals")
            .doc(_selectedMonth)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          final doc = snapshot.data!;
          final hasGoal = doc.exists;
          final goal = hasGoal ? (doc["goalAmount"] ?? 0).toDouble() : 0;
          final spent = hasGoal ? (doc["spent"] ?? 0).toDouble() : 0;
          final remaining = hasGoal ? (doc["remaining"] ?? 0).toDouble() : 0;
          final progress = goal > 0 ? (spent / goal) : 0;
          final isOverBudget = spent > goal && goal > 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Sélecteur de mois
                _buildMonthSelector(),

                const SizedBox(height: 20),

                // Formulaire d'ajout d'objectif (si affiché)
                if (_showGoalInput) _buildGoalInputForm(),

                // Actions pour objectif existant (si pas de formulaire)
                if (hasGoal && !_showGoalInput) 
                  _buildGoalActions(goal, spent, remaining, isOverBudget),

                // Bouton pour ajouter un objectif (si pas d'objectif)
                if (!hasGoal && !_showGoalInput)
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: Colors.blue.shade700,
                          size: 50,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Aucun objectif défini",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Définissez un objectif pour suivre vos dépenses",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _showGoalInput = true);
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text("Ajouter un objectif"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Carte principale
                _buildMainCard(goal, spent, remaining, progress, isOverBudget, hasGoal),

                const SizedBox(height: 25),

                // Graphique de progression
                if (hasGoal && goal > 0) _buildProgressGauge(progress, isOverBudget),

                const SizedBox(height: 25),

                // Statistiques détaillées
                if (hasGoal) _buildDetailedStats(goal, spent, remaining),

                const SizedBox(height: 25),

                // Conseils
                _buildTipsCard(isOverBudget, progress),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // Les autres méthodes restent les mêmes (_buildLoadingState, _buildMonthSelector, etc.)
  // ... (garder les méthodes existantes comme _buildMainCard, _buildProgressGauge, etc.)
  
  // Note: Les méthodes _buildMainCard, _buildProgressGauge, _buildDetailedStats, 
  // _buildTipsCard, _showHistoryDialog restent identiques à ton code original
  // Seules les méthodes liées à la gestion des objectifs ont été modifiées

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 20),
          Text(
            "Chargement des objectifs...",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final date = now.subtract(Duration(days: 30 * i));
      return _monthId(date);
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sélectionnez le mois",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButton<String>(
              value: _selectedMonth,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.blue.shade700),
              items: months.map((monthId) {
                return DropdownMenuItem(
                  value: monthId,
                  child: Text(
                    _formatMonthId(monthId),
                    style: const TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMonth = value!;
                  _showGoalInput = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(double goal, double spent, double remaining, 
                        double progress, bool isOverBudget, bool hasGoal) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOverBudget
              ? [Colors.red.shade700, Colors.orange.shade700]
              : [Colors.blue.shade700, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: (isOverBudget ? Colors.red : Colors.blue).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatMonthId(_selectedMonth),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasGoal ? "Objectif défini" : "Aucun objectif",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),

          if (hasGoal)
            Column(
              children: [
                Text(
                  _formatAmount(goal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Objectif mensuel",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Icon(
                  Icons.flag_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  "Définissez un objectif",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Commencez à suivre vos dépenses",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 15,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 30),

          if (hasGoal && goal > 0)
            Column(
              children: [
                LinearProgressIndicator(
                  value: progress > 1 ? 1 : progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverBudget ? Colors.orange.shade300 : Colors.white,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 10,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${(progress * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isOverBudget ? "Dépassé !" : "En cours",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProgressGauge(double progress, bool isOverBudget) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Progression de l'objectif",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  showLabels: false,
                  showTicks: false,
                  startAngle: 270,
                  endAngle: 270,
                  radiusFactor: 0.8,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.1,
                    cornerStyle: CornerStyle.bothCurve,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: progress > 1 ? 100 : progress * 100,
                      width: 0.15,
                      cornerStyle: CornerStyle.bothCurve,
                      gradient: SweepGradient(
                        colors: isOverBudget
                            ? [Colors.red, Colors.orange]
                            : [Colors.blue, Colors.green],
                      ),
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      positionFactor: 0.1,
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${(progress * 100).toStringAsFixed(0)}%",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: isOverBudget ? Colors.red : Colors.blue,
                            ),
                          ),
                          Text(
                            "atteint",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
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
        ],
      ),
    );
  }

  Widget _buildDetailedStats(double goal, double spent, double remaining) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Statistiques détaillées",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "Dépensé",
                  _formatAmount(spent),
                  Colors.red.shade700,
                  Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatItem(
                  "Restant",
                  _formatAmount(remaining),
                  Colors.green.shade700,
                  Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatItem(
                  "Objectif",
                  _formatAmount(goal),
                  Colors.blue.shade700,
                  Icons.flag_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(bool isOverBudget, double progress) {
    String tipTitle = "";
    String tipDescription = "";
    Color tipColor = Colors.blue;
    IconData tipIcon = Icons.lightbulb_rounded;

    if (!isOverBudget && progress < 0.5) {
      tipTitle = "Bon début !";
      tipDescription = "Vous êtes bien en dessous de votre objectif, continuez ainsi !";
      tipColor = Colors.green;
    } else if (!isOverBudget && progress >= 0.5 && progress < 0.8) {
      tipTitle = "Attention";
      tipDescription = "Vous avez dépensé plus de la moitié de votre budget, soyez vigilant.";
      tipColor = Colors.orange;
    } else if (!isOverBudget && progress >= 0.8 && progress <= 1) {
      tipTitle = "Limite atteinte";
      tipDescription = "Vous approchez de votre objectif, évitez les dépenses non essentielles.";
      tipColor = Colors.red;
    } else if (isOverBudget) {
      tipTitle = "Dépassement";
      tipDescription = "Vous avez dépassé votre objectif, envisagez de le réajuster pour le mois prochain.";
      tipColor = Colors.red;
      tipIcon = Icons.warning_rounded;
    } else {
      tipTitle = "Conseil";
      tipDescription = "Définissez un objectif réaliste basé sur vos revenus et vos dépenses habituelles.";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tipColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tipColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tipIcon, color: tipColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipTitle,
                  style: TextStyle(
                    color: tipColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tipDescription,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() async {
    final previousGoals = await _getPreviousGoals();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Historique des objectifs",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (previousGoals.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Aucun historique",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: previousGoals.length,
                    itemBuilder: (context, index) {
                      final goal = previousGoals[index];
                      final spent = goal['spent'] as double;
                      final goalAmount = goal['goalAmount'] as double;
                      final progress = goalAmount > 0 ? spent / goalAmount : 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: progress >= 1 
                                    ? Colors.red.shade100 
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                progress >= 1 
                                    ? Icons.warning_rounded 
                                    : Icons.check_circle_rounded,
                                color: progress >= 1 
                                    ? Colors.red.shade700 
                                    : Colors.green.shade700,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatMonthId(goal['monthId'] as String),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${_formatAmount(goalAmount)} • "
                                    "${(progress * 100).toStringAsFixed(0)}% dépensé",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getPreviousGoals() async {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final date = now.subtract(Duration(days: 30 * i));
      return _monthId(date);
    });

    List<Map<String, dynamic>> previousGoals = [];

    for (final monthId in months) {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .collection("goals")
          .doc(monthId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        previousGoals.add({
          'monthId': monthId,
          'goalAmount': data["goalAmount"] ?? 0,
          'spent': data["spent"] ?? 0,
          'remaining': data["remaining"] ?? 0,
        });
      }
    }

    return previousGoals;
  }

  String _monthId(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _goalController.dispose();
    _editGoalController.dispose();
    super.dispose();
  }
}