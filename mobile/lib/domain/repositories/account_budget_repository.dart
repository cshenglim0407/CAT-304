import 'package:cashlytics/domain/entities/account_budget.dart';

abstract class AccountBudgetRepository {
  Future<AccountBudget> upsertAccountBudget(AccountBudget accountBudget);
}
