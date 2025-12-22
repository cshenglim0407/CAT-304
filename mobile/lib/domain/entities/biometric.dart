import 'package:meta/meta.dart';

@immutable
class Biometric {
  const Biometric({
    this.id,
    required this.userId,
    required this.templateData,
    required this.algoVersion,
    this.deviceId,
    this.deviceName,
    this.type,
    this.isActive = true,
    this.lastUsedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String userId;
  final String templateData;
  final String algoVersion;
  final String? deviceId;
  final String? deviceName;
  final String? type;
  final bool isActive;
  final DateTime? lastUsedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Biometric copyWith({
    String? id,
    String? userId,
    String? templateData,
    String? algoVersion,
    String? deviceId,
    String? deviceName,
    String? type,
    bool? isActive,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Biometric(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateData: templateData ?? this.templateData,
      algoVersion: algoVersion ?? this.algoVersion,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Biometric &&
        other.id == id &&
        other.userId == userId &&
        other.templateData == templateData &&
        other.algoVersion == algoVersion &&
        other.deviceId == deviceId &&
        other.deviceName == deviceName &&
        other.type == type &&
        other.isActive == isActive &&
        other.lastUsedAt == lastUsedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        templateData,
        algoVersion,
        deviceId,
        deviceName,
        type,
        isActive,
        lastUsedAt,
        createdAt,
        updatedAt,
      );
}
