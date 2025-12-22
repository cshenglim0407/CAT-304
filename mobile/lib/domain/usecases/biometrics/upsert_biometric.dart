import 'package:cashlytics/domain/entities/biometric.dart';
import 'package:cashlytics/domain/repositories/biometric_repository.dart';

class UpsertBiometric {
  const UpsertBiometric(this._repository);

  final BiometricRepository _repository;

  Future<Biometric> call(Biometric biometric) => 
      _repository.upsertBiometric(biometric);
}
