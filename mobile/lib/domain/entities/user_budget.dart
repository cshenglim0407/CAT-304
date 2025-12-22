import 'package:meta/meta.dart';

@immutable
class UserBudget {
  const UserBudget({
    required this.budgetId,
    required this.threshold,
  });

  final String budgetId;
  final double threshold;

  UserBudget copyWith({
    String? budgetId,
    double? threshold,
  }) {
    return UserBudget(
      budgetId: budgetId ?? this.budgetId,
      threshold: threshold ?? this.threshold,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserBudget &&
        other.budgetId == budgetId &&
        other.threshold == threshold;
  }

  @override
  int get hashCode => Object.hash(budgetId, threshold);
}
