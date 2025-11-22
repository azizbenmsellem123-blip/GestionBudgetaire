import '../models/home_model.dart';

class HomeController {
  final HomeModel model = HomeModel();

  double getBalance() {
    return model.globalBalance;
  }

  List<TransactionModel> getRecentTransactions() {
    return model.recentTransactions;
  }

  void addTransaction(TransactionModel transaction) {
    model.recentTransactions.insert(0, transaction);
    model.globalBalance += transaction.amount;
  }
}
