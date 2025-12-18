import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddTransactionView extends StatefulWidget {
  const AddTransactionView({super.key});

  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  String type = "dépense";
  String? selectedCategory = "Autre";
  DateTime? selectedDate;
  bool isLoading = false;

  final List<Map<String, dynamic>> categories = [
    {
      "name": "Revenu",
      "icon": Icons.account_balance_wallet_rounded,
      "color": Colors.green,
    },
    {
      "name": "Courses",
      "icon": Icons.shopping_basket_rounded,
      "color": Colors.blue,
    },
    {
      "name": "Transport",
      "icon": Icons.directions_car_rounded,
      "color": Colors.orange,
    },
    {
      "name": "Factures",
      "icon": Icons.receipt_long_rounded,
      "color": Colors.red,
    },
    {
      "name": "Divertissement",
      "icon": Icons.celebration_rounded,
      "color": Colors.purple,
    },
    {
      "name": "Santé",
      "icon": Icons.medical_services_rounded,
      "color": Colors.pink,
    },
    {
      "name": "Éducation",
      "icon": Icons.school_rounded,
      "color": Colors.indigo,
    },
    {
      "name": "Restaurant",
      "icon": Icons.restaurant_rounded,
      "color": Colors.brown,
    },
    {
      "name": "Autre",
      "icon": Icons.category_rounded,
      "color": Colors.grey,
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _addTransaction() async {
    if (!_validateForm()) return;

    setState(() => isLoading = true);

    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;
      final userRef = FirebaseFirestore.instance.collection("users").doc(userId);

      final double amount = double.parse(amountController.text.trim());

      // Charger budget actuel
      final userDoc = await userRef.get();
      double currentBudget = userDoc.data()?["budget"] ?? 0;

      // Mise à jour budget
      if (type == "revenu") {
        currentBudget += amount;
      } else {
        currentBudget -= amount;
      }

      // Date
      final DateTime date = selectedDate ?? DateTime.now();
      final String monthId = "${date.year}-${date.month.toString().padLeft(2, '0')}";

      // Ajouter la transaction
      await userRef.collection("transactions").add({
        "amount": amount,
        "type": type,
        "category": selectedCategory,
        "note": noteController.text.trim(),
        "date": date,
        "dateId": monthId,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Mise à jour des objectifs mensuels
      if (type == "dépense") {
        await _updateMonthlyGoal(userRef, monthId, amount);
      }

      // Mise à jour budget global
      await userRef.update({"budget": currentBudget});

      _showSuccessDialog(context);
    } catch (e) {
      _showErrorDialog(context, e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateMonthlyGoal(
      DocumentReference userRef, String monthId, double amount) async {
    try {
      final goalRef = userRef.collection("goals").doc(monthId);
      final goalDoc = await goalRef.get();

      if (goalDoc.exists) {
        final data = goalDoc.data() as Map<String, dynamic>;
        double goalAmount = data["goalAmount"] ?? 0;
        double spent = data["spent"] ?? 0;

        double newSpent = spent + amount;
        double remaining = goalAmount - newSpent;

        await goalRef.set({
          "goalAmount": goalAmount,
          "spent": newSpent,
          "remaining": remaining,
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Alerte dépassement objectif
        if (goalAmount > 0 && newSpent > goalAmount) {
          _showGoalExceededAlert(context, newSpent, goalAmount);
        }
      }
    } catch (e) {
      print("Erreur mise à jour objectif: $e");
    }
  }

  bool _validateForm() {
    if (amountController.text.trim().isEmpty) {
      _showValidationError("Veuillez saisir un montant");
      return false;
    }

    if (double.tryParse(amountController.text.trim()) == null) {
      _showValidationError("Montant invalide");
      return false;
    }

    if (selectedCategory == null) {
      _showValidationError("Veuillez sélectionner une catégorie");
      return false;
    }

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade100, size: 20),
            const SizedBox(width: 10),
            Text(message),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Nouvelle transaction",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: Colors.blue),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                margin: const EdgeInsets.only(bottom: 30),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_chart_rounded,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Enregistrez vos transactions",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Gardez une trace de vos revenus et dépenses",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Sélection type (revenu/dépense)
              _buildTypeSelector(),

              const SizedBox(height: 30),

              // Montant
              _buildAmountField(),

              const SizedBox(height: 25),

              // Date
              _buildDateField(),

              const SizedBox(height: 25),

              // Catégorie
              _buildCategorySelector(),

              const SizedBox(height: 25),

              // Note
              _buildNoteField(),

              const SizedBox(height: 40),

              // Bouton d'ajout
              _buildSubmitButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => type = "dépense"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: type == "dépense" ? Colors.red.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: type == "dépense" ? Colors.white : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Dépense",
                      style: TextStyle(
                        color: type == "dépense" ? Colors.white : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => type = "revenu"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: type == "revenu" ? Colors.green.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: type == "revenu" ? Colors.white : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Revenu",
                      style: TextStyle(
                        color: type == "revenu" ? Colors.white : Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Montant (TND)",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          ),
          child: TextField(
            controller: amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: type == "dépense" ? Colors.red.shade700 : Colors.green.shade700,
            ),
            decoration: InputDecoration(
              hintText: "0.00",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 24,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 20, top: 18, bottom: 18),
                child: Text(
                  "TND",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 16),
                Text(
                  selectedDate != null
                      ? dateFormat.format(selectedDate!)
                      : "Sélectionner une date",
                  style: TextStyle(
                    color: selectedDate != null ? Colors.black87 : Colors.grey.shade400,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Catégorie",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category["name"];
              
              return GestureDetector(
                onTap: () => setState(() => selectedCategory = category["name"]),
                child: Container(
                  width: 100,
                  margin: EdgeInsets.only(
                    right: index == categories.length - 1 ? 0 : 12,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? category["color"] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isSelected 
                          ? category["color"] as Color 
                          : Colors.grey.shade200,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category["icon"] as IconData,
                        color: isSelected ? Colors.white : category["color"] as Color,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category["name"],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Note (optionnel)",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          ),
          child: TextField(
            controller: noteController,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: "Ajouter une note...",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _addTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: type == "dépense" ? Colors.red.shade700 : Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == "dépense" 
                        ? Icons.arrow_downward_rounded 
                        : Icons.arrow_upward_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Enregistrer la transaction",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade700,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Transaction enregistrée !",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Votre transaction a été ajoutée avec succès.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Fermer le dialog
                    Navigator.pop(context); // Retour à l'accueil
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Retour à l'accueil",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text("Erreur", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(
          "Une erreur est survenue : $error",
          style: TextStyle(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalExceededAlert(BuildContext context, double spent, double goalAmount) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Objectif dépassé !",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Vous avez dépensé ${spent.toStringAsFixed(2)} TND "
                "alors que votre objectif était de ${goalAmount.toStringAsFixed(2)} TND.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Continuer"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Naviguer vers la page des objectifs
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Ajuster"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text(
                    "Conseils",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoItem("💡", "Utilisez des catégories précises"),
                  _buildInfoItem("📊", "Ajoutez des notes pour plus de détails"),
                  _buildInfoItem("🎯", "Définissez des objectifs mensuels"),
                  _buildInfoItem("⏰", "Enregistrez dès que possible"),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Compris",
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }
}