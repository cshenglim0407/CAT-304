import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:cashlytics/core/utils/date_formatter.dart';
import 'package:cashlytics/domain/entities/weekly_balance.dart';

class WeeklyBalanceModel extends WeeklyBalance {
  const WeeklyBalanceModel({
    required super.weekNumber,
    required super.startDate,
    required super.endDate,
    required super.totalIncome,
    required super.totalExpense,
    required super.balance,
    super.isCurrentWeek,
  });

  factory WeeklyBalanceModel.fromMap(Map<String, dynamic> map) {
    return WeeklyBalanceModel(
      weekNumber: MathFormatter.parseInt(map['week_number']) ?? 0,
      startDate: DateFormatter.parseDateTime(map['start_date']) ?? DateTime.now(),
      endDate: DateFormatter.parseDateTime(map['end_date']) ?? DateTime.now(),
      totalIncome: MathFormatter.parseDouble(map['total_income']) ?? 0.0,
      totalExpense: MathFormatter.parseDouble(map['total_expense']) ?? 0.0,
      balance: MathFormatter.parseDouble(map['balance']) ?? 0.0,
      isCurrentWeek: MathFormatter.parseBool(map['is_current_week']) ?? false,
    );
  }

  factory WeeklyBalanceModel.fromEntity(WeeklyBalance entity) {
    return WeeklyBalanceModel(
      weekNumber: entity.weekNumber,
      startDate: entity.startDate,
      endDate: entity.endDate,
      totalIncome: entity.totalIncome,
      totalExpense: entity.totalExpense,
      balance: entity.balance,
      isCurrentWeek: entity.isCurrentWeek,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week_number': weekNumber,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'balance': balance,
      'is_current_week': isCurrentWeek,
    };
  }
}
