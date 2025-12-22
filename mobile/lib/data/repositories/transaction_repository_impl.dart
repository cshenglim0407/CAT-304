import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/transaction_record_model.dart';
import 'package:cashlytics/domain/entities/transaction_record.dart';
import 'package:cashlytics/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'transaction';

  @override
  Future<TransactionRecord> upsertTransaction(TransactionRecord transaction) async {
    final model = TransactionRecordModel.fromEntity(transaction);
    final bool isInsert = transaction.id == null;

    if (isInsert) {
      final insertData = await _databaseService.insert(
        _table,
        model.toInsert(),
      );

      if (insertData == null) {
        throw Exception('Failed to insert transaction');
      }

      return TransactionRecordModel.fromMap(insertData);
    } else {
      final updateData = await _databaseService.updateById(
        _table,
        matchColumn: 'transaction_id',
        matchValue: transaction.id!,
        values: model.toUpdate(),
      );

      if (updateData == null) {
        throw Exception('Failed to update transaction');
      }

      return TransactionRecordModel.fromMap(updateData);
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _databaseService.deleteById(
      _table,
      matchColumn: 'transaction_id',
      matchValue: transactionId,
    );
  }
}
