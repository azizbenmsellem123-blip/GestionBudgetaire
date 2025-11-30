class TransactionModel {
  final String title;
  final double amount;
  final String type;
  final DateTime date;

  TransactionModel({
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "amount": amount,
      "type": type,
      "date": date.toIso8601String(),
    };
  }
}
