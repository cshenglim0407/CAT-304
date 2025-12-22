import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/income_model.dart';
import 'package:cashlytics/domain/entities/income.dart';
import 'package:cashlytics/domain/repositories/income_repository.dart';

class IncomeRepositoryImpl implements IncomeRepository {
  IncomeRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'income';

  @override
  Future<Income> upsertIncome(Income income) async {
    final model = IncomeModel.fromEntity(income);

    final upsertData = await _databaseService.upsert(
      _table,
      [model.toInsert()],
      onConflict: 'transaction_id',
    );

    if (upsertData.isEmpty) {
      throw Exception('Failed to upsert income');
    }

    return IncomeModel.fromMap(upsertData.first);
  }
}
