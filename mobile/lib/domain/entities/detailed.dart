import 'package:meta/meta.dart';

@immutable
class Detailed {
  const Detailed({
    this.id,
    required this.userId,
    this.employmentStatus,
    this.maritalStatus,
    this.dependentNumber,
    this.estimatedLoan,
    this.createdAt,
    this.updatedAt,
    this.educationLevel,
  });

  final String? id;
  final String userId;
  final String? educationLevel;
  final String? employmentStatus;
  final String? maritalStatus;
  final int? dependentNumber;
  final double? estimatedLoan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Detailed copyWith({
    String? id,
    String? userId,
    String? educationLevel,
    String? employmentStatus,
    String? maritalStatus,
    int? dependentNumber,
    double? estimatedLoan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Detailed(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      educationLevel: educationLevel ?? this.educationLevel,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      dependentNumber: dependentNumber ?? this.dependentNumber,
      estimatedLoan: estimatedLoan ?? this.estimatedLoan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Detailed &&
        other.id == id &&
        other.userId == userId &&
        other.educationLevel == educationLevel &&
        other.employmentStatus == employmentStatus &&
        other.maritalStatus == maritalStatus &&
        other.dependentNumber == dependentNumber &&
        other.estimatedLoan == estimatedLoan &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    educationLevel,
    employmentStatus,
    maritalStatus,
    dependentNumber,
    estimatedLoan,
    createdAt,
    updatedAt,
  );
}
