import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditTransactionView extends StatefulWidget {
  final String userId;
  final String transactionId;
  final Map<String, dynamic> data;

  const EditTransactionView({
    super.key,
    required this.userId,
    required this.transactionId,
    required this.data,
  });

  @override
  State<EditTransactionView> createState() => _EditTransactionViewState();
}

class _EditTransactionViewState extends State<EditTransactionView> {
  late TextEditingController amountController;
  late TextEditingController descriptionController;
  late TextEditingController categoryController;
  String selectedType = "dépense";
  String selectedCategory = "Autre";
  DateTime? selectedDate;
  bool isLoading = false;

  final List<Map<String, dynamic>> categories = [
    {
      "name": "Revenu",
      "icon": Icons.account_balance_wallet_rounded,
      "color": Colors.green,
      "type": "revenu",
    },
    {
      "name": "Courses",
      "icon": Icons.shopping_basket_rounded,
      "color": Colors.blue,
      "type": "dépense",
    },
    {
      "name": "Transport",
      "icon": Icons.directions_car_rounded,
      "color": Colors.orange,
      "type": "dépense",
    },
    {
      "name": "Factures",
      "icon": Icons.receipt_long_rounded,
      "color": Colors.red,
      "type": "dépense",
    },
    {
      "name": "Divertissement",
      "icon": Icons.celebration_rounded,
      "color": Colors.purple,
      "type": "dépense",
    },
    {
      "name": "Santé",
      "icon": Icons.medical_services_rounded,
      "color": Colors.pink,
      "type": "dépense",
    },
    {
      "name": "Éducation",
      "icon": Icons.school_rounded,
      "color": Colors.indigo,
      "type": "dépense",
    },
    {
      "name": "Restaurant",
      "icon": Icons.restaurant_rounded,
      "color": Colors.brown,
      "type": "dépense",
    },
    {
      "name": "Autre",
      "icon": Icons.category_rounded,
      "color": Colors.grey,
      "type": "dépense",
    },
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.data;
    amountController = TextEditingController(text: data["amount"]?.toString() ?? "");
    descriptionController = TextEditingController(text: data["note"] ?? data["description"] ?? "");
    selectedType = data["type"] ?? "dépense";
    selectedCategory = data["category"] ?? "Autre";
    
    if (data["date"] != null) {
      if (data["date"] is Timestamp) {
        selectedDate = (data["date"] as Timestamp).toDate();
      } else if (data["date"] is String) {
        selectedDate = DateTime.tryParse(data["date"]);
      }
    }
    
    categoryController = TextEditingController(text: selectedCategory);
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = selectedDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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

  Future<void> _updateTransaction() async {
    if (!_validateForm()) return;

    setState(() => isLoading = true);

    try {
      final double amount = double.parse(amountController.text.trim());
      final String description = descriptionController.text.trim();
      final DateTime date = selectedDate ?? DateTime.now();
      final String monthId = "${date.year}-${date.month.toString().padLeft(2, '0')}";

      // Récupérer l'ancienne transaction
      final oldDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .collection("transactions")
          .doc(widget.transactionId)
          .get();

      final oldData = oldDoc.data() as Map<String, dynamic>;
      final oldAmount = (oldData["amount"] ?? 0).toDouble();
      final oldType = oldData["type"] ?? "dépense";
      final oldMonthId = oldData["dateId"];

      // Mettre à jour le budget utilisateur (annuler l'ancienne transaction)
      final userRef = FirebaseFirestore.instance.collection("users").doc(widget.userId);
      final userDoc = await userRef.get();
      double currentBudget = userDoc.data()?["budget"] ?? 0;

      // Annuler l'effet de l'ancienne transaction
      if (oldType == "revenu") {
        currentBudget -= oldAmount;
      } else {
        currentBudget += oldAmount;
      }

      // Appliquer la nouvelle transaction
      if (selectedType == "revenu") {
        currentBudget += amount;
      } else {
        currentBudget -= amount;
      }

      // Mettre à jour la transaction
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .collection("transactions")
          .doc(widget.transactionId)
          .update({
        "amount": amount,
        "note": description,
        "type": selectedType,
        "category": selectedCategory,
        "date": date,
        "dateId": monthId,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      // Mettre à jour le budget
      await userRef.update({"budget": currentBudget});

      // Mettre à jour les objectifs si le mois a changé
      if (oldMonthId != monthId || oldType != selectedType || oldAmount != amount) {
        await _updateGoals(oldMonthId, monthId, oldType, selectedType, oldAmount, amount);
      }

      _showSuccessDialog(context);
    } catch (e) {
      _showErrorDialog(context, e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateGoals(
    String oldMonthId, 
    String newMonthId, 
    String oldType, 
    String newType, 
    double oldAmount, 
    double newAmount
  ) async {
    try {
      final userRef = FirebaseFirestore.instance.collection("users").doc(widget.userId);

      // Mettre à jour l'ancien mois si nécessaire
      if (oldMonthId != newMonthId || oldType != newType) {
        if (oldType == "dépense") {
          final oldGoalRef = userRef.collection("goals").doc(oldMonthId);
          final oldGoalDoc = await oldGoalRef.get();
          if (oldGoalDoc.exists) {
            final data = oldGoalDoc.data() as Map<String, dynamic>;
            double spent = data["spent"] ?? 0;
            double goalAmount = data["goalAmount"] ?? 0;
            spent -= oldAmount;
            final remaining = goalAmount - spent;
            
            await oldGoalRef.set({
              "spent": spent,
              "remaining": remaining,
              "updatedAt": FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      }

      // Mettre à jour le nouveau mois si nécessaire
      if (newType == "dépense") {
        final newGoalRef = userRef.collection("goals").doc(newMonthId);
        final newGoalDoc = await newGoalRef.get();
        
        double spent = 0;
        double goalAmount = 0;
        
        if (newGoalDoc.exists) {
          final data = newGoalDoc.data() as Map<String, dynamic>;
          spent = data["spent"] ?? 0;
          goalAmount = data["goalAmount"] ?? 0;
        }
        
        spent += newAmount;
        final remaining = goalAmount - spent;
        
        await newGoalRef.set({
          "goalAmount": goalAmount,
          "spent": spent,
          "remaining": remaining,
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Alerte si dépassement
        if (goalAmount > 0 && spent > goalAmount) {
          _showGoalExceededAlert(context, spent, goalAmount);
        }
      }
    } catch (e) {
      print("Erreur mise à jour objectifs: $e");
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

    if (selectedCategory.isEmpty) {
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
    final originalAmount = widget.data["amount"] ?? 0;
    final originalType = widget.data["type"] ?? "dépense";
    final originalCategory = widget.data["category"] ?? "Autre";

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Modifier la transaction",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec infos originales
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
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
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: originalType == "revenu" 
                          ? Colors.green.shade100 
                          : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        originalType == "revenu" 
                          ? Icons.arrow_upward_rounded 
                          : Icons.arrow_downward_rounded,
                        color: originalType == "revenu" 
                          ? Colors.green.shade700 
                          : Colors.red.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Transaction originale",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${originalAmount.toStringAsFixed(2)} TND • $originalCategory",
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

              const SizedBox(height: 25),

              // Montant
              _buildAmountField(),

              const SizedBox(height: 25),

              // Date
              _buildDateField(),

              const SizedBox(height: 25),

              // Catégorie
              _buildCategorySelector(),

              const SizedBox(height: 25),

              // Description
              _buildDescriptionField(),

              const SizedBox(height: 40),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Annuler",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _updateTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                                Icon(Icons.check_circle_rounded, size: 20),
                                const SizedBox(width: 10),
                                const Text(
                                  "Enregistrer les modifications",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),

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
              onTap: () => setState(() => selectedType = "dépense"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: selectedType == "dépense" ? Colors.red.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: selectedType == "dépense" ? Colors.white : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Dépense",
                      style: TextStyle(
                        color: selectedType == "dépense" ? Colors.white : Colors.red,
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
              onTap: () => setState(() => selectedType = "revenu"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: selectedType == "revenu" ? Colors.green.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: selectedType == "revenu" ? Colors.white : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Revenu",
                      style: TextStyle(
                        color: selectedType == "revenu" ? Colors.white : Colors.green,
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
              color: selectedType == "dépense" ? Colors.red.shade700 : Colors.green.shade700,
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
    final filteredCategories = categories.where((cat) => cat["type"] == selectedType).toList();
    
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
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filteredCategories.length,
            itemBuilder: (context, index) {
              final category = filteredCategories[index];
              final isSelected = selectedCategory == category["name"];
              
              return GestureDetector(
                onTap: () => setState(() => selectedCategory = category["name"]),
                child: Container(
                  width: 100,
                  margin: EdgeInsets.only(
                    right: index == filteredCategories.length - 1 ? 0 : 12,
                  ),
                  padding: const EdgeInsets.all(12),
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
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category["name"],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 11,
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

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Description (optionnel)",
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
            controller: descriptionController,
            maxLines: 3,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: "Ajouter une description...",
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
                "Transaction mise à jour !",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Vos modifications ont été enregistrées avec succès.",
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
                    Navigator.pop(context); // Retour à la page précédente
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
                    "Retour",
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
                "Avec cette modification, vous avez dépensé ${spent.toStringAsFixed(2)} TND "
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

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    super.dispose();
  }
}