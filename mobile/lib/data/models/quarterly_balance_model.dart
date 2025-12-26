import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:cashlytics/domain/entities/quarterly_balance.dart';

class QuarterlyBalanceModel extends QuarterlyBalance {
  const QuarterlyBalanceModel({
    required super.quarterNumber,
    required super.startDate,
    required super.endDate,
    required super.totalIncome,
    required super.totalExpense,
    required super.balance,
    super.isCurrentQuarter,
  });

  factory QuarterlyBalanceModel.fromMap(Map<String, dynamic> map) {
    return QuarterlyBalanceModel(
      quarterNumber: MathFormatter.parseInt(map['quarter_number']) ?? 0,
      startDate: MathFormatter.parseDateTime(map['start_date']) ?? DateTime.now(),
      endDate: MathFormatter.parseDateTime(map['end_date']) ?? DateTime.now(),
      totalIncome: MathFormatter.parseDouble(map['total_income']) ?? 0.0,
      totalExpense: MathFormatter.parseDouble(map['total_expense']) ?? 0.0,
      balance: MathFormatter.parseDouble(map['balance']) ?? 0.0,
      isCurrentQuarter: MathFormatter.parseBool(map['is_current_quarter']) ?? false,
    );
  }

  factory QuarterlyBalanceModel.fromEntity(QuarterlyBalance entity) {
    return QuarterlyBalanceModel(
      quarterNumber: entity.quarterNumber,
      startDate: entity.startDate,
      endDate: entity.endDate,
      totalIncome: entity.totalIncome,
      totalExpense: entity.totalExpense,
      balance: entity.balance,
      isCurrentQuarter: entity.isCurrentQuarter,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quarter_number': quarterNumber,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'balance': balance,
      'is_current_quarter': isCurrentQuarter,
    };
  }
}
