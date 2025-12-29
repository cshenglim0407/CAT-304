import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

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
  Future<List<TransactionRecord>> getTransactionsByAccountId(
    String accountId,
  ) async {
    final data = await _databaseService.fetchAll(
      _table,
      filters: {'account_id': accountId},
      orderBy: 'spent_at',
      ascending: false,
      limit: 100,
    );
    return data.map((map) => TransactionRecordModel.fromMap(map)).toList();
  }

  @override
  Future<TransactionRecord> upsertTransaction(
    TransactionRecord transaction,
  ) async {
    // For new transactions (id == null), generate a UUID
    final finalTransaction = transaction.id == null
        ? transaction.copyWith(id: const Uuid().v4())
        : transaction;

    final model = TransactionRecordModel.fromEntity(finalTransaction);
    final bool isInsert = transaction.id == null; // Check original, not final

    if (isInsert) {
      debugPrint('Inserting new transaction with ID: ${finalTransaction.id}');
      final insertData = await _databaseService.insert(
        _table,
        model.toInsert(),
      );

      if (insertData == null) {
        // Insert succeeded but select returned no rows (RLS/timing issue)
        // Try to fetch by ID that was sent in the insert
        if (finalTransaction.id != null) {
          debugPrint(
            'Insert returned null, attempting to fetch transaction by ID: ${finalTransaction.id}',
          );
          final fetchedData = await _databaseService.fetchSingle(
            _table,
            matchColumn: 'transaction_id',
            matchValue: finalTransaction.id,
          );

          if (fetchedData != null) {
            debugPrint(
              'Successfully fetched transaction from DB: ${fetchedData['transaction_id']}',
            );
            return TransactionRecordModel.fromMap(fetchedData);
          }
        }

        throw Exception(
          'Failed to insert transaction: select returned no rows',
        );
      }

      debugPrint(
        'Transaction insert succeeded, returned ID: ${insertData['transaction_id']}',
      );
      return TransactionRecordModel.fromMap(insertData);
    } else {
      debugPrint(
        'Updating existing transaction with ID: ${finalTransaction.id}',
      );
      final updateData = await _databaseService.updateById(
        _table,
        matchColumn: 'transaction_id',
        matchValue: finalTransaction.id!,
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
    try {
      final tx = await _databaseService.fetchSingle(
        _table,
        matchColumn: 'transaction_id',
        matchValue: transactionId,
      );

      if (tx == null) {
        debugPrint('deleteTransaction: transaction not found $transactionId');
        throw Exception('Transaction not found');
      }

      final String? type = tx['type'] as String?;

      // Delete child rows first so DB child-level triggers handle balance reversion.
      if (type == 'E') {
        try {
          await _databaseService.deleteById(
            'expense_items',
            matchColumn: 'transaction_id',
            matchValue: transactionId,
          );
        } catch (_) {}
        await _databaseService.deleteById(
          'expenses',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );
      } else if (type == 'I') {
        await _databaseService.deleteById(
          'income',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );
      } else if (type == 'T') {
        await _databaseService.deleteById(
          'transfer',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );
      }

      // Finally delete transaction row (cascade won't double-revert because child already removed)
      await _databaseService.deleteById(
        _table,
        matchColumn: 'transaction_id',
        matchValue: transactionId,
      );

      debugPrint('deleteTransaction: deleted $transactionId type=$type');
    } catch (e, st) {
      debugPrint('Error deleting transaction $transactionId: $e\n$st');
      rethrow;
    }
  }
}
