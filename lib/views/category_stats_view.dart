import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategoryStatsView extends StatefulWidget {
  final String userId;

  const CategoryStatsView({super.key, required this.userId});

  @override
  State<CategoryStatsView> createState() => _CategoryStatsViewState();
}

class _CategoryStatsViewState extends State<CategoryStatsView> {
  String selectedMonth1 = _monthId(DateTime.now());
  String selectedMonth2 = _monthId(DateTime.now().subtract(const Duration(days: 30)));
  String _viewMode = 'comparaison'; // 'comparaison' ou 'détails'
  String _selectedYear = DateTime.now().year.toString();
  
  // Couleurs pour les graphiques
  final List<Color> _chartColors = [
    Colors.blue.shade700,
    Colors.green.shade700,
    Colors.orange.shade700,
    Colors.purple.shade700,
    Colors.red.shade700,
    Colors.pink.shade700,
    Colors.indigo.shade700,
    Colors.cyan.shade700,
    Colors.amber.shade700,
    Colors.deepPurple.shade700,
  ];

  static String _monthId(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}";
  }

  static String _formatMonthId(String monthId) {
    final parts = monthId.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);
    final monthName = DateFormat('MMMM', 'fr').format(DateTime(2000, month));
    return '$monthName $year';
  }

  Future<Map<String, double>> _loadMonthData(String monthId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .collection("transactions")
        .where("dateId", isEqualTo: monthId)
        .get();

    Map<String, double> totals = {};

    for (var doc in snapshot.docs) {
      if (doc["type"] == "dépense") {
        String category = doc["category"] ?? "Autre";
        double amount = (doc["amount"] ?? 0).toDouble();
        totals[category] = (totals[category] ?? 0) + amount;
      }
    }

    return totals;
  }

  Future<Map<String, Map<String, double>>> _loadYearData(String year) async {
    Map<String, Map<String, double>> monthlyData = {};

    for (int month = 1; month <= 12; month++) {
      final monthId = "$year-${month.toString().padLeft(2, '0')}";
      final data = await _loadMonthData(monthId);
      if (data.isNotEmpty) {
        monthlyData[monthId] = data;
      }
    }

    return monthlyData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analyses Financières"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _viewMode == 'comparaison' 
                ? Icons.bar_chart_rounded 
                : Icons.list_rounded,
              color: Colors.blue.shade700,
            ),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == 'comparaison' ? 'détails' : 'comparaison';
              });
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec infos
              Container(
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
                        Icons.insights_rounded,
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
                            "Analyse de vos dépenses",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Visualisez et comparez vos habitudes de dépenses",
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

              const SizedBox(height: 25),

              // Sélecteurs de périodes
              if (_viewMode == 'comparaison')
                _buildComparisonControls()
              else
                _buildYearlyControls(),

              const SizedBox(height: 25),

              // Titre de la section
              Text(
                _viewMode == 'comparaison' 
                  ? "Comparaison mensuelle" 
                  : "Analyse annuelle",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
  child: FutureBuilder(
    future: _viewMode == 'comparaison'
        ? Future.wait<Map<String, double>>([
            _loadMonthData(selectedMonth1),
            _loadMonthData(selectedMonth2),
          ])
        : _loadYearData(_selectedYear),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return _buildLoadingState();
      }

      if (_viewMode == 'comparaison') {
        // Ici snapshot.data est List<Map<String,double>>
        final data = snapshot.data as List<Map<String, double>>;
        final month1 = data[0];
        final month2 = data[1];
        return _buildComparisonView(month1, month2);
      } else {
        // Ici snapshot.data est Map<String, Map<String,double>>
        final yearlyData = snapshot.data as Map<String, Map<String, double>>;
        return _buildYearlyView(yearlyData);
      }
    },
  ),
),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonControls() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMonthSelector("Mois 1", selectedMonth1, (v) {
                setState(() => selectedMonth1 = v!);
              }),
              _buildMonthSelector("Mois 2", selectedMonth2, (v) {
                setState(() => selectedMonth2 = v!);
              }),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade100,
                  Colors.blue.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.compare_arrows_rounded, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  "Comparez les tendances",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyControls() {
    final years = List.generate(5, (index) => 
      (DateTime.now().year - index).toString()
    );

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sélectionnez l'année",
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
              value: _selectedYear,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.blue.shade700),
              items: years.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(
                    "Année $year",
                    style: TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedYear = value!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(String label, String value, Function(String?) onChanged) {
    final months = List.generate(6, (i) {
      final date = DateTime.now().subtract(Duration(days: 30 * i));
      return _monthId(date);
    });

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.calendar_today_rounded, color: Colors.blue.shade700),
              items: months.map((monthId) {
                return DropdownMenuItem(
                  value: monthId,
                  child: Text(
                    _formatMonthId(monthId),
                    style: TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Chargement des données...",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonView(Map<String, double> month1, Map<String, double> month2) {
    final allCats = {...month1.keys, ...month2.keys}.toList();
    final maxAmount = [...month1.values, ...month2.values].fold(0.0, (a, b) => a > b ? a : b);
    
    if (allCats.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Graphique en barres comparatif
          Container(
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
              children: [
                Text(
                  "Comparaison graphique",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxAmount * 1.2,
                      barGroups: allCats.asMap().entries.map((entry) {
                        final index = entry.key;
                        final cat = entry.value;
                        final m1 = month1[cat] ?? 0;
                        final m2 = month2[cat] ?? 0;
                        
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: m1,
                              color: Colors.blue.shade700,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: m2,
                              color: Colors.orange.shade700,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < allCats.length) {
                                final cat = allCats[value.toInt()];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    cat.length > 6 ? "${cat.substring(0, 6)}.." : cat,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem("Mois 1", Colors.blue.shade700),
                    const SizedBox(width: 20),
                    _buildLegendItem("Mois 2", Colors.orange.shade700),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Détails par catégorie
          Container(
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
                  "Détails par catégorie",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ...allCats.map((cat) => _buildCategoryItem(cat, month1[cat] ?? 0, month2[cat] ?? 0)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Total
          Container(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Mois 1",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_calculateTotal(month1).toStringAsFixed(2)} TND",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Total Mois 2",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_calculateTotal(month2).toStringAsFixed(2)} TND",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
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

  Widget _buildYearlyView(Map<String, Map<String, double>> yearlyData) {
    if (yearlyData.isEmpty) {
      return _buildEmptyState();
    }

    final months = yearlyData.keys.toList()..sort();
    final allCategories = _getAllCategories(yearlyData);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Graphique annuel
          Container(
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
              children: [
                Text(
                  "Évolution mensuelle des dépenses",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxYearlyAmount(yearlyData) * 1.2,
                      barGroups: months.asMap().entries.map((entry) {
                        final index = entry.key;
                        final monthId = entry.value;
                        final data = yearlyData[monthId]!;
                        final total = data.values.fold(0.0, (a, b) => a + b);
                        
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: total,
                              color: _getColorForMonth(index),
                              width: 25,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < months.length) {
                                final monthId = months[value.toInt()];
                                final monthName = DateFormat('MMM', 'fr')
                                  .format(DateTime(int.parse(monthId.split('-')[0]), 
                                                  int.parse(monthId.split('-')[1])));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    monthName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Détails par catégorie sur l'année
          Container(
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
                  "Dépenses par catégorie sur l'année",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ...allCategories.map((cat) {
                  final yearlyTotal = _calculateYearlyCategoryTotal(yearlyData, cat);
                  return _buildYearlyCategoryItem(cat, yearlyTotal);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Aucune donnée disponible",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ajoutez des transactions pour voir les statistiques",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String category, double amount1, double amount2) {
    final difference = amount1 - amount2;
    final isIncrease = difference > 0;
    final percentChange = amount2 > 0 ? (difference / amount2 * 100) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getColorForCategory(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForCategory(category),
              color: _getColorForCategory(category),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${amount1.toStringAsFixed(2)} TND vs ${amount2.toStringAsFixed(2)} TND",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${difference.abs().toStringAsFixed(2)} TND",
                style: TextStyle(
                  color: isIncrease ? Colors.red.shade700 : Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "${isIncrease ? '+' : ''}${percentChange.toStringAsFixed(1)}%",
                style: TextStyle(
                  color: isIncrease ? Colors.red.shade600 : Colors.green.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyCategoryItem(String category, double total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getColorForCategory(category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIconForCategory(category),
              color: _getColorForCategory(category),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            "${total.toStringAsFixed(2)} TND",
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  double _calculateTotal(Map<String, double> data) {
    return data.values.fold(0.0, (a, b) => a + b);
  }

  List<String> _getAllCategories(Map<String, Map<String, double>> yearlyData) {
    final allCategories = <String>{};
    yearlyData.values.forEach((monthData) {
      allCategories.addAll(monthData.keys);
    });
    return allCategories.toList();
  }

  double _getMaxYearlyAmount(Map<String, Map<String, double>> yearlyData) {
    double max = 0;
    yearlyData.values.forEach((monthData) {
      final total = monthData.values.fold(0.0, (a, b) => a + b);
      if (total > max) max = total;
    });
    return max;
  }

  double _calculateYearlyCategoryTotal(Map<String, Map<String, double>> yearlyData, String category) {
    double total = 0;
    yearlyData.values.forEach((monthData) {
      total += monthData[category] ?? 0;
    });
    return total;
  }

  Color _getColorForCategory(String category) {
    final index = categories.indexOf(category);
    return _chartColors[index % _chartColors.length];
  }

  IconData _getIconForCategory(String category) {
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

  Color _getColorForMonth(int monthIndex) {
    return _chartColors[monthIndex % _chartColors.length];
  }

  final List<String> categories = [
    "Revenu",
    "Courses",
    "Transport",
    "Factures",
    "Divertissement",
    "Santé",
    "Éducation",
    "Restaurant",
    "Autre"
  ];
}