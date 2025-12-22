import 'package:cashlytics/domain/entities/expense_category.dart';

/// Data model for expense categories.
class ExpenseCategoryModel extends ExpenseCategory {
  const ExpenseCategoryModel({
    super.id,
    required super.name,
    super.description,
  });

  factory ExpenseCategoryModel.fromEntity(ExpenseCategory entity) {
    return ExpenseCategoryModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
    );
  }

  factory ExpenseCategoryModel.fromMap(Map<String, dynamic> map) {
    return ExpenseCategoryModel(
      id: map['expense_cat_id'] as String?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      if (id != null) 'expense_cat_id': id,
      'name': name,
      'description': description,
    };
  }

  Map<String, dynamic> toUpdate() => toInsert();

  Map<String, dynamic> toJson() => toUpdate();
}
