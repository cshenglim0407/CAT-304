import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/account_budget_model.dart';
import 'package:cashlytics/domain/entities/account_budget.dart';
import 'package:cashlytics/domain/repositories/account_budget_repository.dart';

class AccountBudgetRepositoryImpl implements AccountBudgetRepository {
  AccountBudgetRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'account_budget';

  @override
  Future<AccountBudget> upsertAccountBudget(AccountBudget accountBudget) async {
    final model = AccountBudgetModel.fromEntity(accountBudget);

    final upsertData = await _databaseService.upsert(
      _table,
      [model.toInsert()],
      onConflict: 'budget_id',
    );

    if (upsertData.isEmpty) {
      throw Exception('Failed to upsert account budget');
    }

    return AccountBudgetModel.fromMap(upsertData.first);
  }
}
