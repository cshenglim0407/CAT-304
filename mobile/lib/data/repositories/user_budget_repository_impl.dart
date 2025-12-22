import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/user_budget_model.dart';
import 'package:cashlytics/domain/entities/user_budget.dart';
import 'package:cashlytics/domain/repositories/user_budget_repository.dart';

class UserBudgetRepositoryImpl implements UserBudgetRepository {
  UserBudgetRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'user_budget';

  @override
  Future<UserBudget> upsertUserBudget(UserBudget userBudget) async {
    final model = UserBudgetModel.fromEntity(userBudget);

    final upsertData = await _databaseService.upsert(
      _table,
      [model.toInsert()],
      onConflict: 'budget_id',
    );

    if (upsertData.isEmpty) {
      throw Exception('Failed to upsert user budget');
    }

    return UserBudgetModel.fromMap(upsertData.first);
  }
}
