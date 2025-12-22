import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/expense_model.dart';
import 'package:cashlytics/domain/entities/expense.dart';
import 'package:cashlytics/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'expenses';

  @override
  Future<Expense> upsertExpense(Expense expense) async {
    final model = ExpenseModel.fromEntity(expense);

    final upsertData = await _databaseService.upsert(
      _table,
      [model.toInsert()],
      onConflict: 'transaction_id',
    );

    if (upsertData.isEmpty) {
      throw Exception('Failed to upsert expense');
    }

    return ExpenseModel.fromMap(upsertData.first);
  }
}
