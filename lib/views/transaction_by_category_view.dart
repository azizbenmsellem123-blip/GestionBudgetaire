import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionByCategoryView extends StatefulWidget {
  final String userId;
  final String category;
  final String? monthId; // Ajout du paramètre monthId

  const TransactionByCategoryView({
    super.key,
    required this.userId,
    required this.category,
    this.monthId, // Rend optionnel
  });

  @override
  State<TransactionByCategoryView> createState() => _TransactionByCategoryViewState();
}

class _TransactionByCategoryViewState extends State<TransactionByCategoryView> {
  String _selectedPeriod = 'tous'; // 'tous', 'mois', 'semaine'
  double _totalAmount = 0;
  int _transactionCount = 0;
  String _selectedMonthId = '';

  @override
  void initState() {
    super.initState();
    // Utilise le monthId passé ou génère le mois courant
    _selectedMonthId = widget.monthId ?? _getCurrentMonthId();
    _calculateStats();
  }

  String _getCurrentMonthId() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  IconData _getCategoryIcon(String category) {
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Revenu":
        return Colors.green.shade700;
      case "Courses":
        return Colors.teal.shade700;
      case "Transport":
        return Colors.amber.shade700;
      case "Factures":
        return Colors.deepOrange.shade700;
      case "Divertissement":
        return Colors.purple.shade700;
      case "Santé":
        return Colors.pink.shade700;
      case "Éducation":
        return Colors.indigo.shade700;
      case "Restaurant":
        return Colors.brown.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Future<void> _calculateStats() async {
    Query query = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("transactions")
        .where("category", isEqualTo: widget.category);

    // Appliquer les filtres de période
    if (_selectedPeriod != 'tous') {
      final now = DateTime.now();
      DateTime startDate;
      
      if (_selectedPeriod == 'mois') {
        // Utiliser le monthId sélectionné
        final parts = _selectedMonthId.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        startDate = DateTime(year, month, 1);
      } else {
        // semaine
        startDate = now.subtract(const Duration(days: 7));
      }
      
      query = query.where("date", isGreaterThanOrEqualTo: startDate);
    }

    // Ajouter le filtre par dateId si disponible
    if (_selectedPeriod == 'tous' || _selectedPeriod == 'mois') {
      query = query.where("dateId", isEqualTo: _selectedMonthId);
    }

    final snapshot = await query.get();
    
    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data["amount"] ?? 0).toDouble();
    }

    setState(() {
      _totalAmount = total;
      _transactionCount = snapshot.docs.length;
    });
  }

  // Formatte le monthId en nom de mois
  String _formatMonthId(String monthId) {
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

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.category);
    final categoryIcon = _getCategoryIcon(widget.category);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          // Affichage du mois sélectionné
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              backgroundColor: categoryColor.withOpacity(0.1),
              label: Text(
                _formatMonthId(_selectedMonthId),
                style: TextStyle(
                  color: categoryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              avatar: Icon(Icons.calendar_today_rounded, 
                  size: 14, color: categoryColor),
            ),
          ),
          IconButton(
            icon: Icon(Icons.filter_alt_rounded, color: categoryColor),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec statistiques
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  categoryColor.withOpacity(0.9),
                  categoryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        categoryIcon,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedPeriod == 'tous' 
                              ? _formatMonthId(_selectedMonthId)
                              : _selectedPeriod == 'mois'
                                ? _formatMonthId(_selectedMonthId)
                                : "Cette semaine",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      "Total",
                      "${_totalAmount.toStringAsFixed(2)} TND",
                      Colors.white,
                      Icons.attach_money_rounded,
                    ),
                    _buildStatItem(
                      "Transactions",
                      _transactionCount.toString(),
                      Colors.white,
                      Icons.receipt_long_rounded,
                    ),
                    _buildStatItem(
                      "Moyenne",
                      _transactionCount > 0 
                        ? "${(_totalAmount / _transactionCount).toStringAsFixed(2)} TND"
                        : "0.00 TND",
                      Colors.white,
                      Icons.trending_up_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filtres rapides
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip("Ce mois", 'mois'),
                  const SizedBox(width: 8),
                  _buildPeriodChip("Cette semaine", 'semaine'),
                  const SizedBox(width: 8),
                  _buildPeriodChip("Toutes périodes", 'tous'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Titre liste
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Transactions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: categoryColor,
                  ),
                ),
                Text(
                  "$_transactionCount transaction${_transactionCount != 1 ? 's' : ''}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Liste des transactions
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    final categoryColor = _getCategoryColor(widget.category);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
          _calculateStats();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? categoryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? categoryColor : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: categoryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    Query query = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("transactions")
        .where("category", isEqualTo: widget.category)
        .orderBy("date", descending: true);

    // Appliquer les filtres de période
    if (_selectedPeriod != 'tous') {
      final now = DateTime.now();
      DateTime startDate;
      
      if (_selectedPeriod == 'mois') {
        // Utiliser le monthId sélectionné
        final parts = _selectedMonthId.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        startDate = DateTime(year, month, 1);
      } else {
        // semaine
        startDate = now.subtract(const Duration(days: 7));
      }
      
      query = query.where("date", isGreaterThanOrEqualTo: startDate);
    }

    // Ajouter le filtre par dateId si disponible
    if (_selectedPeriod == 'tous' || _selectedPeriod == 'mois') {
      query = query.where("dateId", isEqualTo: _selectedMonthId);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final docs = snapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: _calculateStats,
          color: _getCategoryColor(widget.category),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildTransactionItem(data, docs[index].id);
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> data, String transactionId) {
    final amount = (data["amount"] ?? 0).toDouble();
    final type = data["type"] ?? "dépense";
    final note = data["note"] ?? data["description"] ?? "";
    final date = (data["date"] as Timestamp).toDate();
    final isIncome = type == "revenu";
    final categoryColor = _getCategoryColor(widget.category);
    final dateFormat = DateFormat('dd MMM yyyy', 'fr');
    final timeFormat = DateFormat('HH:mm', 'fr');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navigation vers l'édition
            // Navigator.push(context, MaterialPageRoute(
            //   builder: (_) => EditTransactionView(
            //     userId: widget.userId,
            //     transactionId: transactionId,
            //     data: data,
            //   ),
            // ));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(widget.category),
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${amount.toStringAsFixed(2)} TND",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isIncome ? Colors.green.shade700 : Colors.deepOrange.shade700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isIncome 
                                ? Colors.green.shade100 
                                : Colors.deepOrange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isIncome ? "REVENU" : "DÉPENSE",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isIncome 
                                  ? Colors.green.shade700 
                                  : Colors.deepOrange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            note,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${dateFormat.format(date)} à ${timeFormat.format(date)}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final categoryColor = _getCategoryColor(widget.category);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            color: categoryColor,
          ),
          const SizedBox(height: 20),
          Text(
            "Chargement des transactions...",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final categoryColor = _getCategoryColor(widget.category);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(widget.category),
                color: categoryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Aucune transaction",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: categoryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Vous n'avez pas encore de transactions\n dans la catégorie ${widget.category}",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Naviguer vers l'ajout de transaction
                // Navigator.push(context, MaterialPageRoute(
                //   builder: (_) => AddTransactionView(userId: widget.userId),
                // ));
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text("Ajouter une transaction"),
              style: ElevatedButton.styleFrom(
                backgroundColor: categoryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        final categoryColor = _getCategoryColor(widget.category);
        
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Filtrer les transactions",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: categoryColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: categoryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Text(
                "Période",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPeriodOption("Ce mois", 'mois'),
                  _buildPeriodOption("Cette semaine", 'semaine'),
                  _buildPeriodOption("Toutes périodes", 'tous'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Text(
                "Trier par",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSortOption("Date (récent)"),
                  _buildSortOption("Date (ancien)"),
                  _buildSortOption("Montant (haut)"),
                  _buildSortOption("Montant (bas)"),
                ],
              ),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _calculateStats();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: categoryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Appliquer les filtres',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(String label, String value) {
    final isSelected = _selectedPeriod == value;
    final categoryColor = _getCategoryColor(widget.category);
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = value;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: categoryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildSortOption(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: false,
      onSelected: (selected) {
        // TODO: Implémenter le tri
      },
      backgroundColor: Colors.grey.shade100,
      labelStyle: const TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}