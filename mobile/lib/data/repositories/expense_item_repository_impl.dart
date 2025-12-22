import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/expense_item_model.dart';
import 'package:cashlytics/domain/entities/expense_item.dart';
import 'package:cashlytics/domain/repositories/expense_item_repository.dart';

class ExpenseItemRepositoryImpl implements ExpenseItemRepository {
  ExpenseItemRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'expense_items';

  @override
  Future<ExpenseItem> upsertExpenseItem(ExpenseItem item) async {
    final model = ExpenseItemModel.fromEntity(item);

    final upsertData = await _databaseService.upsert(
      _table,
      [model.toInsert()],
      onConflict: 'transaction_id,item_id',
    );

    if (upsertData.isEmpty) {
      throw Exception('Failed to upsert expense item');
    }

    return ExpenseItemModel.fromMap(upsertData.first);
  }
}
