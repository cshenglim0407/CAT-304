import 'package:cashlytics/domain/entities/expense_item.dart';

abstract class ExpenseItemRepository {
  Future<ExpenseItem> upsertExpenseItem(ExpenseItem item);
}
