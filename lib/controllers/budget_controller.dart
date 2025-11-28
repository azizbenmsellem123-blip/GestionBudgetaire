import '../services/budget_service.dart';

class BudgetController {
  final BudgetService service;
  BudgetController(this.service);

  Future<void> setUserBudget(String userId, double amount) async {
    await service.saveBudget(userId, amount);
  }

  Future<double> getUserBudget(String userId) async {
    return await service.getBudget(userId);
  }
}
