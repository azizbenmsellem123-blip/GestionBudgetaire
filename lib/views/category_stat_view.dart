import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryStatsView extends StatelessWidget {
  final String userId;

  const CategoryStatsView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dépenses par catégorie"),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("transactions")
            .where("type", isEqualTo: "dépense")
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔵 Regroupement des montants par catégorie
          Map<String, double> totals = {};

          for (var doc in snapshot.data!.docs) {
            String category = doc["category"] ?? "Autre";
            double amount = (doc["amount"] ?? 0).toDouble();

            totals[category] = (totals[category] ?? 0) + amount;
          }

          final categories = totals.keys.toList();
          final values = totals.values.toList();

          if (categories.isEmpty) {
            return const Center(
              child: Text("Aucune dépense pour le moment."),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Analyse des dépenses",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // 🔥 GRAPH BARRES
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value < 0 || value >= categories.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                categories[value.toInt()],
                                style: const TextStyle(fontSize: 11),
                              );
                            },
                          ),
                        ),
                      ),

                      barGroups: List.generate(categories.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: values[i],
                              width: 22,
                              borderRadius: BorderRadius.circular(6),
                            )
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
