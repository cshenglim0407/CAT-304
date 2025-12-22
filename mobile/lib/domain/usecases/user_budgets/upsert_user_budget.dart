import 'package:cashlytics/domain/entities/user_budget.dart';
import 'package:cashlytics/domain/repositories/user_budget_repository.dart';

class UpsertUserBudget {
  const UpsertUserBudget(this._repository);

  final UserBudgetRepository _repository;

  Future<UserBudget> call(UserBudget userBudget) => 
      _repository.upsertUserBudget(userBudget);
}
