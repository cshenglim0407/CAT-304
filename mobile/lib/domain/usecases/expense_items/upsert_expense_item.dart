import 'package:cashlytics/domain/entities/expense_item.dart';
import 'package:cashlytics/domain/repositories/expense_item_repository.dart';

class UpsertExpenseItem {
  const UpsertExpenseItem(this._repository);

  final ExpenseItemRepository _repository;

  Future<ExpenseItem> call(ExpenseItem item) => 
      _repository.upsertExpenseItem(item);
}
