import 'package:meta/meta.dart';

@immutable
class CategoryBudget {
  const CategoryBudget({
    required this.budgetId,
    required this.expenseCategoryId,
    required this.threshold,
  });

  final String budgetId;
  final String expenseCategoryId;
  final double threshold;

  CategoryBudget copyWith({
    String? budgetId,
    String? expenseCategoryId,
    double? threshold,
  }) {
    return CategoryBudget(
      budgetId: budgetId ?? this.budgetId,
      expenseCategoryId: expenseCategoryId ?? this.expenseCategoryId,
      threshold: threshold ?? this.threshold,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryBudget &&
        other.budgetId == budgetId &&
        other.expenseCategoryId == expenseCategoryId &&
        other.threshold == threshold;
  }

  @override
  int get hashCode => Object.hash(budgetId, expenseCategoryId, threshold);
}
