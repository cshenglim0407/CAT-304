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
      orderBy: 'created_at',
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
      // Fetch the transaction to determine its type and account
      final tx = await _databaseService.fetchSingle(
        _table,
        matchColumn: 'transaction_id',
        matchValue: transactionId,
      );

      if (tx == null) {
        debugPrint('deleteTransaction: transaction not found $transactionId');
        return;
      }

      final String? type = tx['type'] as String?;
      final String? accountId = tx['account_id'] as String?;

      double _toDouble(dynamic v) {
        if (v == null) return 0.0;
        if (v is double) return v;
        if (v is int) return v.toDouble();
        if (v is String) return double.tryParse(v) ?? 0.0;
        return 0.0;
      }

      // Helper to update a single account's current_balance (no-op if account missing)
      Future<void> updateAccountBalance(String accId, double newBalance) async {
        await _databaseService.updateById(
          'accounts',
          matchColumn: 'account_id',
          matchValue: accId,
          values: {'current_balance': newBalance},
        );
      }

      // Read & compute adjustments BEFORE deleting child rows
      if (type == 'I') {
        final income = await _databaseService.fetchSingle(
          'income',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );
        final amount = _toDouble(income?['amount']);
        if (accountId != null && accountId.isNotEmpty) {
          final account = await _databaseService.fetchSingle(
            'accounts',
            matchColumn: 'account_id',
            matchValue: accountId,
          );
          if (account != null) {
            final current = _toDouble(account['current_balance']);
            final updated = current - amount; // revert income
            await updateAccountBalance(accountId, updated);
          }
        }

        // delete income row
        await _databaseService.deleteById(
          'income',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );
      } else if (type == 'E') {
        final expense = await _databaseService.fetchSingle(
          'expenses',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );
        final amount = _toDouble(expense?['amount']);
        if (accountId != null && accountId.isNotEmpty) {
          final account = await _databaseService.fetchSingle(
            'accounts',
            matchColumn: 'account_id',
            matchValue: accountId,
          );
          if (account != null) {
            final current = _toDouble(account['current_balance']);
            final updated = current + amount; // revert expense
            await updateAccountBalance(accountId, updated);
          }
        }

        // delete any expense_items then expense row
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
      } else if (type == 'T') {
        final transfer = await _databaseService.fetchSingle(
          'transfer',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );
        final amount = _toDouble(transfer?['amount']);
        final fromAcc = transfer?['from_account_id'] as String?;
        final toAcc = transfer?['to_account_id'] as String?;

        // revert: add back to source, subtract from destination
        if (fromAcc != null && fromAcc.isNotEmpty) {
          final account = await _databaseService.fetchSingle(
            'accounts',
            matchColumn: 'account_id',
            matchValue: fromAcc,
          );
          if (account != null) {
            final current = _toDouble(account['current_balance']);
            await updateAccountBalance(fromAcc, current + amount);
          }
        }
        if (toAcc != null && toAcc.isNotEmpty) {
          final account = await _databaseService.fetchSingle(
            'accounts',
            matchColumn: 'account_id',
            matchValue: toAcc,
          );
          if (account != null) {
            final current = _toDouble(account['current_balance']);
            await updateAccountBalance(toAcc, current - amount);
          }
        }

        await _databaseService.deleteById(
          'transfer',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );
      }

      // Finally delete the transaction row itself (transaction must be removed last)
      await _databaseService.deleteById(
        _table,
        matchColumn: 'transaction_id',
        matchValue: transactionId,
      );

      debugPrint(
        'deleteTransaction: deleted $transactionId type=$type and adjusted accounts',
      );
    } catch (e, st) {
      debugPrint('Error deleting transaction $transactionId: $e\n$st');
      rethrow;
    }
  }
}
