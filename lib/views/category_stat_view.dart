import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryStatsView extends StatefulWidget {
  final String userId;

  const CategoryStatsView({super.key, required this.userId});

  @override
  State<CategoryStatsView> createState() => _CategoryStatsViewState();
}

class _CategoryStatsViewState extends State<CategoryStatsView> {
  String selectedMonth1 = _monthId(DateTime.now());
  String selectedMonth2 = _monthId(DateTime.now().subtract(const Duration(days: 30)));

  static String _monthId(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}";
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
        String cat = doc["category"] ?? "Autre";
        double amount = (doc["amount"] ?? 0).toDouble();

        totals[cat] = (totals[cat] ?? 0) + amount;
      }
    }

    return totals;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comparaison des dépenses"),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Comparer deux mois",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Sélecteurs des mois
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _monthDropdown("Mois 1", selectedMonth1, (v) {
                  setState(() => selectedMonth1 = v!);
                }),
                _monthDropdown("Mois 2", selectedMonth2, (v) {
                  setState(() => selectedMonth2 = v!);
                }),
              ],
            ),

            const SizedBox(height: 25),

            Expanded(
              child: FutureBuilder(
                future: Future.wait([
                  _loadMonthData(selectedMonth1),
                  _loadMonthData(selectedMonth2),
                ]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final month1Data = snapshot.data![0];
                  final month2Data = snapshot.data![1];

                  final allCategories = {
                    ...month1Data.keys,
                    ...month2Data.keys,
                  }.toList();

                  return BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      barGroups: allCategories.map((cat) {
                        double v1 = month1Data[cat] ?? 0;
                        double v2 = month2Data[cat] ?? 0;

                        return BarChartGroupData(
                          x: allCategories.indexOf(cat),
                          barRods: [
                            BarChartRodData(toY: v1, color: Colors.blue, width: 12),
                            BarChartRodData(toY: v2, color: Colors.orange, width: 12),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              String cat = allCategories[value.toInt()];
                              return Text(cat, style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _monthDropdown(String label, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 5),
        DropdownButton<String>(
          value: value,
          items: List.generate(12, (i) {
            final date = DateTime(DateTime.now().year, i + 1);
            final mid = _monthId(date);
            return DropdownMenuItem(
              value: mid,
              child: Text("${date.month}/${date.year}"),
            );
          }),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
