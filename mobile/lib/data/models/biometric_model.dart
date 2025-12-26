import 'package:cashlytics/core/utils/math_formatter.dart';
import 'package:cashlytics/domain/entities/biometric.dart';

/// Data model for biometric templates.
class BiometricModel extends Biometric {
  const BiometricModel({
    super.id,
    required super.userId,
    required super.templateData,
    required super.algoVersion,
    super.deviceId,
    super.deviceName,
    super.type,
    super.isActive = true,
    super.lastUsedAt,
    super.createdAt,
    super.updatedAt,
  });

  factory BiometricModel.fromEntity(Biometric entity) {
    return BiometricModel(
      id: entity.id,
      userId: entity.userId,
      templateData: entity.templateData,
      algoVersion: entity.algoVersion,
      deviceId: entity.deviceId,
      deviceName: entity.deviceName,
      type: entity.type,
      isActive: entity.isActive,
      lastUsedAt: entity.lastUsedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory BiometricModel.fromMap(Map<String, dynamic> map) {
    return BiometricModel(
      id: map['biometric_id'] as String?,
      userId: map['user_id'] as String? ?? '',
      templateData: map['template_data'] as String? ?? '',
      algoVersion: map['algo_version'] as String? ?? '',
      deviceId: map['device_id'] as String?,
      deviceName: map['device_name'] as String?,
      type: map['type'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      lastUsedAt: MathFormatter.parseDateTime(map['last_used_at']),
      createdAt: MathFormatter.parseDateTime(map['created_at']),
      updatedAt: MathFormatter.parseDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      if (id != null) 'biometric_id': id,
      'user_id': userId,
      'template_data': templateData,
      'algo_version': algoVersion,
      'device_id': deviceId,
      'device_name': deviceName,
      'type': type,
      'is_active': isActive,
      'last_used_at': lastUsedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdate() {
    return {
      'biometric_id': id,
      'user_id': userId,
      'template_data': templateData,
      'algo_version': algoVersion,
      'device_id': deviceId,
      'device_name': deviceName,
      'type': type,
      'is_active': isActive,
      'last_used_at': lastUsedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toUpdate();

  
}
