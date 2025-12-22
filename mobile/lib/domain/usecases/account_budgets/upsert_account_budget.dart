import 'package:cashlytics/domain/entities/account_budget.dart';
import 'package:cashlytics/domain/repositories/account_budget_repository.dart';

class UpsertAccountBudget {
  const UpsertAccountBudget(this._repository);

  final AccountBudgetRepository _repository;

  Future<AccountBudget> call(AccountBudget accountBudget) => 
      _repository.upsertAccountBudget(accountBudget);
}
