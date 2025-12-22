import 'package:meta/meta.dart';

@immutable
class AccountBudget {
  const AccountBudget({
    required this.budgetId,
    required this.accountId,
    required this.threshold,
  });

  final String budgetId;
  final String accountId;
  final double threshold;

  AccountBudget copyWith({
    String? budgetId,
    String? accountId,
    double? threshold,
  }) {
    return AccountBudget(
      budgetId: budgetId ?? this.budgetId,
      accountId: accountId ?? this.accountId,
      threshold: threshold ?? this.threshold,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccountBudget &&
        other.budgetId == budgetId &&
        other.accountId == accountId &&
        other.threshold == threshold;
  }

  @override
  int get hashCode => Object.hash(budgetId, accountId, threshold);
}
