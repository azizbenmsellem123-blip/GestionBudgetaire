import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionController {
  final TransactionService service;

  TransactionController(this.service);

  Future<bool> addTransaction(String userId, TransactionModel t) async {
    return await service.addTransaction(userId, t);
  }

  Stream<List<TransactionModel>> getTransactions(String userId) {
    return service.getTransactions(userId);
  }
}
