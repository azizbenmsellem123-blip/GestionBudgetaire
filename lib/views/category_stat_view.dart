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
        title: const Text("Statistiques par catégorie"),
        backgroundColor: Colors.white,
        elevation: 1,
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

          final data = snapshot.data!.docs;

          if (data.isEmpty) {
            return const Center(
              child: Text("Aucune dépense enregistrée."),
            );
          }

          // ➤ Calcul total par catégorie
          Map<String, double> categoryTotals = {};

          for (var doc in data) {
            final map = doc.data() as Map<String, dynamic>;
            String category = map["category"] ?? "Autre";
            double amount = (map["amount"] ?? 0).toDouble();

            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          }

          // ➤ Préparer les données pour le graphique
          final barSpots = categoryTotals.entries.map((e) {
            return BarChartGroupData(
              x: categoryTotals.keys.toList().indexOf(e.key),
              barRods: [
                BarChartRodData(
                  toY: e.value,
                ),
              ],
            );
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  "Graphique des dépenses",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: BarChart(
                    BarChartData(
                      barGroups: barSpots,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index < 0 ||
                                  index >= categoryTotals.keys.length) {
                                return const SizedBox();
                              }
                              return Text(
                                categoryTotals.keys.elementAt(index),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
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
