import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/transfer_model.dart';
import 'package:cashlytics/domain/entities/transfer.dart';
import 'package:cashlytics/domain/repositories/transfer_repository.dart';

class TransferRepositoryImpl implements TransferRepository {
  TransferRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'transfer';

  @override
  Future<Transfer> upsertTransfer(Transfer transfer) async {
    final model = TransferModel.fromEntity(transfer);

    final upsertData = await _databaseService.upsert(
      _table,
      [model.toInsert()],
      onConflict: 'transaction_id',
    );

    if (upsertData.isEmpty) {
      throw Exception('Failed to upsert transfer');
    }

    return TransferModel.fromMap(upsertData.first);
  }
}
