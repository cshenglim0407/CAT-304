class QuarterlyBalance {
  final int quarterNumber;
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final bool isCurrentQuarter;

  const QuarterlyBalance({
    required this.quarterNumber,
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    this.isCurrentQuarter = false,
  });

  QuarterlyBalance copyWith({
    int? quarterNumber,
    DateTime? startDate,
    DateTime? endDate,
    double? totalIncome,
    double? totalExpense,
    double? balance,
    bool? isCurrentQuarter,
  }) {
    return QuarterlyBalance(
      quarterNumber: quarterNumber ?? this.quarterNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      isCurrentQuarter: isCurrentQuarter ?? this.isCurrentQuarter,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuarterlyBalance &&
          runtimeType == other.runtimeType &&
          quarterNumber == other.quarterNumber &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          totalIncome == other.totalIncome &&
          totalExpense == other.totalExpense &&
          balance == other.balance &&
          isCurrentQuarter == other.isCurrentQuarter;

  @override
  int get hashCode =>
      quarterNumber.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      totalIncome.hashCode ^
      totalExpense.hashCode ^
      balance.hashCode ^
      isCurrentQuarter.hashCode;

  @override
  String toString() {
    return 'QuarterlyBalance(quarterNumber: $quarterNumber, startDate: $startDate, endDate: $endDate, '
        'totalIncome: $totalIncome, totalExpense: $totalExpense, balance: $balance, '
        'isCurrentQuarter: $isCurrentQuarter)';
  }
}
