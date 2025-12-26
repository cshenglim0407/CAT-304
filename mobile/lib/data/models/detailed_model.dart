import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:cashlytics/domain/entities/detailed.dart';

/// Data model for detailed user information. Converts between Supabase rows and domain entity.
class DetailedModel extends Detailed {
  const DetailedModel({
    super.id,
    required super.userId,
    required super.employmentStatus,
    required super.maritalStatus,
    required super.dependentNumber,
    required super.estimatedLoan,
    super.createdAt,
    super.updatedAt,
    super.educationLevel,
  });

  factory DetailedModel.fromEntity(Detailed entity) {
    return DetailedModel(
      id: entity.id,
      userId: entity.userId,
      educationLevel: entity.educationLevel,
      employmentStatus: entity.employmentStatus,
      maritalStatus: entity.maritalStatus,
      dependentNumber: entity.dependentNumber,
      estimatedLoan: entity.estimatedLoan,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory DetailedModel.fromMap(Map<String, dynamic> map) {
    return DetailedModel(
      id: map['detailed_id'] as String?,
      userId: map['user_id'] as String? ?? '',
      educationLevel: map['edu_lvl'] as String?,
      employmentStatus: map['employment_stat'] as String?,
      maritalStatus: map['marital_stat'] as String?,
      dependentNumber: map['dependent_num'] as int? ?? 0,
      estimatedLoan: MathFormatter.parseDouble(map['estimated_loan']) ?? 0.0,
      createdAt: MathFormatter.parseDateTime(map['created_at']),
      updatedAt: MathFormatter.parseDateTime(map['updated_at']),
    );
  }

  /// Convert to map for insert operations (excludes auto-generated fields)
  Map<String, dynamic> toInsert() {
    return {
      'user_id': userId,
      'edu_lvl': educationLevel,
      'employment_stat': employmentStatus,
      'marital_stat': maritalStatus,
      'dependent_num': dependentNumber,
      'estimated_loan': estimatedLoan,
    };
  }

  /// Convert to map for update operations (includes id, excludes timestamps)
  Map<String, dynamic> toUpdate() {
    return {
      if (id != null) 'detailed_id': id,
      'user_id': userId,
      'edu_lvl': educationLevel,
      'employment_stat': employmentStatus,
      'marital_stat': maritalStatus,
      'dependent_num': dependentNumber,
      'estimated_loan': estimatedLoan,
    };
  }

  Map<String, dynamic> toJson() => toUpdate();

}
