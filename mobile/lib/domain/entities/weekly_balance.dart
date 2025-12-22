class WeeklyBalance {
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final bool isCurrentWeek;

  const WeeklyBalance({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    this.isCurrentWeek = false,
  });

  WeeklyBalance copyWith({
    int? weekNumber,
    DateTime? startDate,
    DateTime? endDate,
    double? totalIncome,
    double? totalExpense,
    double? balance,
    bool? isCurrentWeek,
  }) {
    return WeeklyBalance(
      weekNumber: weekNumber ?? this.weekNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      isCurrentWeek: isCurrentWeek ?? this.isCurrentWeek,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyBalance &&
          runtimeType == other.runtimeType &&
          weekNumber == other.weekNumber &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          totalIncome == other.totalIncome &&
          totalExpense == other.totalExpense &&
          balance == other.balance &&
          isCurrentWeek == other.isCurrentWeek;

  @override
  int get hashCode =>
      weekNumber.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      totalIncome.hashCode ^
      totalExpense.hashCode ^
      balance.hashCode ^
      isCurrentWeek.hashCode;

  @override
  String toString() {
    return 'WeeklyBalance(weekNumber: $weekNumber, startDate: $startDate, endDate: $endDate, '
        'totalIncome: $totalIncome, totalExpense: $totalExpense, balance: $balance, '
        'isCurrentWeek: $isCurrentWeek)';
  }
}
