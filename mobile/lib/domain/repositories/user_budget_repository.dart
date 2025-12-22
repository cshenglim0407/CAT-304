import 'package:cashlytics/domain/entities/user_budget.dart';

abstract class UserBudgetRepository {
  Future<UserBudget> upsertUserBudget(UserBudget userBudget);
}
