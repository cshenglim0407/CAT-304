import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/receipt_model.dart';
import 'package:cashlytics/domain/entities/receipt.dart';
import 'package:cashlytics/domain/repositories/receipt_repository.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  ReceiptRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'receipt';

  @override
  Future<Receipt> upsertReceipt(Receipt receipt) async {
    final model = ReceiptModel.fromEntity(receipt);
    final bool isInsert = receipt.id == null;

    if (isInsert) {
      final insertData = await _databaseService.insert(
        _table,
        model.toInsert(),
      );

      if (insertData == null) {
        throw Exception('Failed to insert receipt');
      }

      return ReceiptModel.fromMap(insertData);
    } else {
      final updateData = await _databaseService.updateById(
        _table,
        matchColumn: 'receipt_id',
        matchValue: receipt.id!,
        values: model.toUpdate(),
      );

      if (updateData == null) {
        throw Exception('Failed to update receipt');
      }

      return ReceiptModel.fromMap(updateData);
    }
  }
}
