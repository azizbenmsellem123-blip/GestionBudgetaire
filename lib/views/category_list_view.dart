import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transaction_by_category_view.dart';

class CategoryListView extends StatefulWidget {
  final String userId;

  const CategoryListView({super.key, required this.userId});

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> {
  String _selectedFilter = 'toutes';
  String _selectedMonth = _getCurrentMonthId();
  bool _isLoading = false;
  Map<String, Map<String, dynamic>> _categoryStats = {};

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

  // Catégories organisées
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'revenu',
      'name': 'Revenu',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Colors.green,
      'type': 'revenu',
    },
    {
      'id': 'courses',
      'name': 'Courses',
      'icon': Icons.shopping_basket_rounded,
      'color': Colors.blue,
      'type': 'depense',
    },
    {
      'id': 'transport',
      'name': 'Transport',
      'icon': Icons.directions_car_rounded,
      'color': Colors.orange,
      'type': 'depense',
    },
    {
      'id': 'factures',
      'name': 'Factures',
      'icon': Icons.receipt_long_rounded,
      'color': Colors.red,
      'type': 'depense',
    },
    {
      'id': 'divertissement',
      'name': 'Divertissement',
      'icon': Icons.celebration_rounded,
      'color': Colors.purple,
      'type': 'depense',
    },
    {
      'id': 'sante',
      'name': 'Santé',
      'icon': Icons.medical_services_rounded,
      'color': Colors.pink,
      'type': 'depense',
    },
    {
      'id': 'education',
      'name': 'Éducation',
      'icon': Icons.school_rounded,
      'color': Colors.indigo,
      'type': 'depense',
    },
    {
      'id': 'restaurant',
      'name': 'Restaurant',
      'icon': Icons.restaurant_rounded,
      'color': Colors.brown,
      'type': 'depense',
    },
    {
      'id': 'autre',
      'name': 'Autre',
      'icon': Icons.category_rounded,
      'color': Colors.grey,
      'type': 'depense',
    },
  ];

  List<Map<String, dynamic>> get _filteredCategories {
    if (_selectedFilter == 'toutes') return _categories;
    return _categories
        .where((cat) => cat['type'] == _selectedFilter)
        .toList();
  }

  Future<void> _loadCategoryStats() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final statsMap = <String, Map<String, dynamic>>{};

      for (var category in _categories) {
        final categoryName = category['name'];
        
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('transactions')
            .where('category', isEqualTo: categoryName)
            .where('dateId', isEqualTo: _selectedMonth)
            .get();

        int transactionCount = snapshot.docs.length;
        double totalAmount = 0;

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0).toDouble();
          totalAmount += amount;
        }

        statsMap[categoryName] = {
          'count': transactionCount,
          'total': totalAmount,
          'hasData': transactionCount > 0,
        };
      }

      setState(() {
        _categoryStats = statsMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadCategoryStats();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoryStats();
    });
  }

  @override
  void didUpdateWidget(CategoryListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadCategoryStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Catégories',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.blue.shade700),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt_rounded, color: Colors.blue.shade700),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrer',
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec filtres
          _buildHeaderSection(),
          
          // Liste ou état vide
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    color: Colors.blue,
                    child: _filteredCategories.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _filteredCategories.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final category = _filteredCategories[index];
                              final categoryName = category['name'];
                              final stats = _categoryStats[categoryName] ?? {
                                'count': 0,
                                'total': 0.0,
                                'hasData': false,
                              };
                              return _buildCategoryCard(category, stats);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sélecteur de mois
          _buildMonthSelector(),
          const SizedBox(height: 16),
          
          // Filtres rapides
          _buildQuickFilters(),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return GestureDetector(
      onTap: _showMonthPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade100, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_rounded, 
                color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 10),
            Text(
              _formatMonthId(_selectedMonth),
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.expand_more_rounded, color: Colors.blue.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFilterButton('Toutes', 'toutes', Icons.all_inclusive_rounded),
        _buildFilterButton('Revenus', 'revenus', Icons.arrow_upward_rounded),
        _buildFilterButton('Dépenses', 'depenses', Icons.arrow_downward_rounded),
      ],
    );
  }

  Widget _buildFilterButton(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: isSelected ? _getColorForFilter(value) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _selectedFilter = value),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(icon,
                    size: 18,
                    color: isSelected ? Colors.white : _getColorForFilter(value),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, 
                            Map<String, dynamic> stats) {
    final count = stats['count'] as int;
    final total = stats['total'] as double;
    final hasData = stats['hasData'] as bool? ?? false;
    final isRevenue = category['type'] == 'revenu';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionByCategoryView(
                userId: widget.userId,
                category: category['name'],
                monthId: _selectedMonth,
              ),
            ),
          );
        },
        onLongPress: () {
          // Optionnel: Action longue pression
          _showCategoryDetails(category, stats);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icône
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(category['icon'], 
                    color: category['color'], size: 24),
              ),
              const SizedBox(width: 16),
              
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isRevenue 
                              ? Colors.green.shade100 
                              : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isRevenue ? 'REVENU' : 'DÉPENSE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isRevenue 
                                ? Colors.green.shade800 
                                : Colors.red.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.receipt_rounded,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count transaction${count != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Montant
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${total.toStringAsFixed(2)} TND',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isRevenue 
                        ? Colors.green.shade700 
                        : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!hasData)
                    Text(
                      'Aucune donnée',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (hasData && _selectedFilter == 'toutes')
                    Text(
                      _formatMonthId(_selectedMonth),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              _selectedFilter == 'toutes' 
                ? 'Aucune catégorie disponible'
                : 'Aucune catégorie de type "${_selectedFilter}"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Essayez un autre filtre ou un autre mois',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'toutes';
                  _selectedMonth = _getCurrentMonthId();
                });
                _loadCategoryStats();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réinitialiser les filtres'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  const Text(
                    'Filtrer par type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('Toutes', 'toutes'),
                  _buildFilterChip('Revenus', 'revenus'),
                  _buildFilterChip('Dépenses', 'depenses'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadCategoryStats();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.blue.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  void _showMonthPicker() {
    final now = DateTime.now();
    final List<String> months = [];
    
    // Générer 12 derniers mois
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i);
      if (date.year > 2000) { // Limite raisonnable
        months.add("${date.year}-${date.month.toString().padLeft(2, '0')}");
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 16, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Sélectionnez un mois',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final monthId = months[index];
                    return ListTile(
                      leading: Icon(
                        Icons.calendar_today_rounded,
                        color: _selectedMonth == monthId 
                            ? Colors.blue.shade700 
                            : Colors.grey.shade600,
                      ),
                      title: Text(
                        _formatMonthId(monthId),
                        style: TextStyle(
                          fontWeight: _selectedMonth == monthId 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                          color: _selectedMonth == monthId 
                              ? Colors.blue.shade700 
                              : Colors.black87,
                        ),
                      ),
                      trailing: _selectedMonth == monthId
                          ? Icon(Icons.check_rounded, color: Colors.blue.shade700)
                          : null,
                      onTap: () {
                        setState(() => _selectedMonth = monthId);
                        Navigator.pop(context);
                        _loadCategoryStats();
                      },
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

  void _showCategoryDetails(Map<String, dynamic> category, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            category['name'],
            style: TextStyle(
              color: category['color'] as Color,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    category['icon'],
                    color: category['color'] as Color,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type: ${category['type'] == 'revenu' ? 'Revenu' : 'Dépense'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mois: ${_formatMonthId(_selectedMonth)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade300),
              const SizedBox(height: 16),
              _buildStatRow('Transactions', '${stats['count']}'),
              const SizedBox(height: 8),
              _buildStatRow('Total', '${stats['total'].toStringAsFixed(2)} TND'),
              const SizedBox(height: 8),
              _buildStatRow(
                'Moyenne',
                stats['count'] > 0 
                  ? '${(stats['total'] / stats['count']).toStringAsFixed(2)} TND'
                  : '0.00 TND'
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getColorForFilter(String filter) {
    switch (filter) {
      case 'revenus':
        return Colors.green.shade600;
      case 'depenses':
        return Colors.red.shade600;
      default:
        return Colors.blue.shade600;
    }
  }
}