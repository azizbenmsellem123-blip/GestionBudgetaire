class TransactionModel {
  final String title;
  final double amount;

  TransactionModel({
    required this.title,
    required this.amount,
  });
}

class HomeModel {
  double globalBalance = 1250.00;

  List<TransactionModel> recentTransactions = [
    TransactionModel(title: "Courses Carrefour", amount: -85.00),
    TransactionModel(title: "Salaire mensuel", amount: 1500.00),
    TransactionModel(title: "Café", amount: -4.50),
    TransactionModel(title: "Carburant", amount: -120),
    TransactionModel(title: "Salaire mensuel", amount: 1500),
  ];
}
