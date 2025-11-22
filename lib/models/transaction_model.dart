class TransactionModel {
  final String title;
  final double amount;
  final bool isIncome; // true = revenu, false = dépense

  TransactionModel({
    required this.title,
    required this.amount,
    required this.isIncome,
  });
}
