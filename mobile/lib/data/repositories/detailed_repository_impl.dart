import 'package:cashlytics/core/services/supabase/database/database_service.dart';

import 'package:cashlytics/data/models/detailed_model.dart';
import 'package:cashlytics/domain/entities/detailed.dart';
import 'package:cashlytics/domain/repositories/detailed_repository.dart';

class DetailedRepositoryImpl implements DetailedRepository {
  DetailedRepositoryImpl({DatabaseService? databaseService})
    : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'detailed';

  @override
  Future<Detailed?> getDetailedByUserId(String userId) async {
    final data = await _databaseService.fetchSingle(
      _table,
      matchColumn: 'user_id',
      matchValue: userId,
    );

    if (data == null) return null;
    return DetailedModel.fromMap(data);
  }

  @override
  Future<Detailed> upsertDetailed(Detailed detailed) async {
    final model = DetailedModel.fromEntity(detailed);

    // Check if this is an insert (no id) or update (has id)
    final bool isInsert = detailed.id == null;

    if (isInsert) {
      // For insert, use toInsert() which excludes all auto-generated fields
      final insertData = await _databaseService.insert(
        _table,
        model.toInsert(),
      );

      if (insertData == null) {
        throw Exception('Failed to insert detailed record');
      }

      // Return the newly created record with Supabase-generated fields
      return DetailedModel.fromMap(insertData);
    } else {
      // For update, use toUpdate() which includes id but excludes timestamps
      final updateData = await _databaseService.updateById(
        _table,
        matchColumn: 'detailed_id',
        matchValue: detailed.id!,
        values: model.toUpdate(),
      );

      if (updateData == null) {
        throw Exception('Failed to update detailed record');
      }

      // Return the updated record with refreshed timestamps from Supabase
      return DetailedModel.fromMap(updateData);
    }
  }

  @override
  Future<void> deleteDetailed(String detailedId) async {
    await _databaseService.deleteById(
      _table,
      matchColumn: 'detailed_id',
      matchValue: detailedId,
    );
  }
}
