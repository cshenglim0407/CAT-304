import 'package:cashlytics/domain/repositories/biometric_repository.dart';

class DeleteBiometric {
  const DeleteBiometric(this._repository);

  final BiometricRepository _repository;

  Future<void> call(String biometricId) => 
      _repository.deleteBiometric(biometricId);
}
