import 'package:flutter/material.dart';

import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/account_model.dart';
import 'package:cashlytics/domain/entities/account.dart';
import 'package:cashlytics/domain/entities/account_transaction_view.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';
import 'package:cashlytics/core/config/icons.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({DatabaseService? databaseService})
    : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'accounts';

  @override
  Future<List<Account>> getAccountsByUserId(String userId) async {
    try {
      final data = await _databaseService.fetchAll(
        _table,
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );

      return data.map<Account>((map) => AccountModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
      return [];
    }
  }

  @override
  Future<List<AccountTransactionView>> getAccountTransactions(
    String accountId,
  ) async {
    try {
      // Fetch all transactions for the account
      final transactions = await _databaseService.fetchAll(
        'transaction',
        filters: {'account_id': accountId},
        orderBy: 'created_at',
        ascending: false,
        limit: 100,
      );

      // Also fetch transfers where this account is the recipient
      final incomingTransfers = await _databaseService.fetchAll(
        'transfer',
        filters: {'to_account_id': accountId},
        limit: 100,
      );

      final List<AccountTransactionView> views = [];

      // Process regular transactions
      for (final tx in transactions) {
        final transactionId = tx['transaction_id'] as String;
        final type = tx['type'] as String;
        final name = tx['name'] as String;
        final createdAt =
            DateTime.tryParse(tx['created_at'] as String? ?? '') ??
            DateTime.now();

        if (type == 'I') {
          // Income
          final incomeData = await _databaseService.fetchSingle(
            'income',
            matchColumn: 'transaction_id',
            matchValue: transactionId,
          );

          if (incomeData != null) {
            final category = incomeData['category'] as String?;
            views.add(
              AccountTransactionView(
                transactionId: transactionId,
                title: name,
                date: createdAt,
                amount: _parseAmount(incomeData['amount']),
                isExpense: false,
                category: category,
                icon: getIncomeIcon(category),
                description: incomeData['description'] as String?,
              ),
            );
          }
        } else if (type == 'E') {
          // Expense
          final expenseData = await _databaseService.fetchSingle(
            'expenses',
            matchColumn: 'transaction_id',
            matchValue: transactionId,
          );

          if (expenseData != null) {
            final category = expenseData['expense_cat_id'] as String?;

            // get category name from expense_categories table
            final categoryData = await _databaseService.fetchSingle(
              'expense_category',
              matchColumn: 'expense_cat_id',
              matchValue: category,
            );
            final categoryName = categoryData?['name'] as String?;

            views.add(
              AccountTransactionView(
                transactionId: transactionId,
                title: name,
                date: createdAt,
                amount: _parseAmount(expenseData['amount']),
                isExpense: true,
                category: categoryName ?? category ?? 'Expense',
                icon: getExpenseIcon(categoryName),
                description: expenseData['description'] as String?,
              ),
            );
          }
        } else if (type == 'T') {
          // Transfer - money going OUT of this account
          final transferData = await _databaseService.fetchSingle(
            'transfer',
            matchColumn: 'transaction_id',
            matchValue: transactionId,
          );

          if (transferData != null) {
            // Get destination account name (nullable after ON DELETE SET NULL)
            final String? toAccountId = transferData['to_account_id'] as String?;
            String toAccountName = 'Account';
            if (toAccountId != null && toAccountId.isNotEmpty) {
              final toAccount = await _databaseService.fetchSingle(
                'accounts',
                matchColumn: 'account_id',
                matchValue: toAccountId,
                columns: 'name',
              );
              toAccountName = (toAccount?['name'] as String?) ?? 'Account';
            } else {
              toAccountName = 'Deleted account';
            }

            views.add(
              AccountTransactionView(
                transactionId: transactionId,
                title: 'To $toAccountName',
                date: createdAt,
                amount: _parseAmount(transferData['amount']),
                isExpense: true, // Deducting from this account
                category: 'Transfer',
                icon: Icons.north_east_rounded,
                // description is stored on TRANSACTION, not TRANSFER; keep nullable
                description: transferData['description'] as String?,
              ),
            );
          }
        }
      }

      // Process incoming transfers (money coming INTO this account)
      for (final transfer in incomingTransfers) {
        final transactionId = transfer['transaction_id'] as String;

        // Get the transaction details
        final tx = await _databaseService.fetchSingle(
          'transaction',
          matchColumn: 'transaction_id',
          matchValue: transactionId,
        );

        if (tx != null) {
          final createdAt =
              DateTime.tryParse(tx['created_at'] as String? ?? '') ??
              DateTime.now();

          // Get source account name (nullable after ON DELETE SET NULL)
          final String? fromAccountId = transfer['from_account_id'] as String?;
          String fromAccountName = 'Account';
          if (fromAccountId != null && fromAccountId.isNotEmpty) {
            final fromAccount = await _databaseService.fetchSingle(
              'accounts',
              matchColumn: 'account_id',
              matchValue: fromAccountId,
              columns: 'name',
            );
            fromAccountName = (fromAccount?['name'] as String?) ?? 'Account';
          } else {
            fromAccountName = 'Deleted account';
          }

          views.add(
            AccountTransactionView(
              transactionId: transactionId,
              title: 'From $fromAccountName',
              date: createdAt,
              amount: _parseAmount(transfer['amount']),
              isExpense: false, // Adding to this account
              category: 'Transfer',
              icon: Icons.south_east_rounded,
              // description is stored on TRANSACTION, not TRANSFER; keep nullable
              description: transfer['description'] as String?,
            ),
          );
        }
      }

      // Sort by date (most recent first)
      views.sort((a, b) => b.date.compareTo(a.date));

      return views;
    } catch (e) {
      debugPrint('Error fetching account transactions: $e');
      // Return empty list on error instead of throwing
      return [];
    }
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Icon mapping moved to config/icons.dart

  @override
  Future<Account> upsertAccount(Account account) async {
    final model = AccountModel.fromEntity(account);
    final bool isInsert = account.id == null;

    if (isInsert) {
      final insertData = await _databaseService.insert(
        _table,
        model.toInsert(),
      );

      if (insertData == null) {
        throw Exception('Failed to insert account');
      }

      return AccountModel.fromMap(insertData);
    } else {
      final updateData = await _databaseService.updateById(
        _table,
        matchColumn: 'account_id',
        matchValue: account.id!,
        values: model.toUpdate(),
      );

      if (updateData == null) {
        throw Exception('Failed to update account');
      }

      return AccountModel.fromMap(updateData);
    }
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    await _databaseService.deleteById(
      _table,
      matchColumn: 'account_id',
      matchValue: accountId,
    );
  }
}
