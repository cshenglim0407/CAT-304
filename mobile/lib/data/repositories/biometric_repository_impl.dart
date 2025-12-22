import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/biometric_model.dart';
import 'package:cashlytics/domain/entities/biometric.dart';
import 'package:cashlytics/domain/repositories/biometric_repository.dart';

class BiometricRepositoryImpl implements BiometricRepository {
  BiometricRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'biometrics';

  @override
  Future<Biometric> upsertBiometric(Biometric biometric) async {
    final model = BiometricModel.fromEntity(biometric);
    final bool isInsert = biometric.id == null;

    if (isInsert) {
      final insertData = await _databaseService.insert(
        _table,
        model.toInsert(),
      );

      if (insertData == null) {
        throw Exception('Failed to insert biometric');
      }

      return BiometricModel.fromMap(insertData);
    } else {
      final updateData = await _databaseService.updateById(
        _table,
        matchColumn: 'biometric_id',
        matchValue: biometric.id!,
        values: model.toUpdate(),
      );

      if (updateData == null) {
        throw Exception('Failed to update biometric');
      }

      return BiometricModel.fromMap(updateData);
    }
  }

  @override
  Future<void> deleteBiometric(String biometricId) async {
    await _databaseService.deleteById(
      _table,
      matchColumn: 'biometric_id',
      matchValue: biometricId,
    );
  }
}
