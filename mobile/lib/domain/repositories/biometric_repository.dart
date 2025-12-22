import 'package:cashlytics/domain/entities/biometric.dart';

abstract class BiometricRepository {
  Future<Biometric> upsertBiometric(Biometric biometric);
  Future<void> deleteBiometric(String biometricId);
}
