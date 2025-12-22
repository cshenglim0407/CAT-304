import 'package:flutter/material.dart';

import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/account_model.dart';
import 'package:cashlytics/domain/entities/account.dart';
import 'package:cashlytics/domain/entities/account_transaction_view.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';

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

      final List<AccountTransactionView> views = [];

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
                icon: _getIncomeIcon(category),
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

            views.add(
              AccountTransactionView(
                transactionId: transactionId,
                title: name,
                date: createdAt,
                amount: _parseAmount(expenseData['amount']),
                isExpense: true,
                category: category,
                icon: _getExpenseIcon(categoryData?["name"]),
              ),
            );
          }
        } else if (type == 'T') {
          // Transfer
          final transferData = await _databaseService.fetchSingle(
            'transfer',
            matchColumn: 'transaction_id',
            matchValue: transactionId,
          );

          if (transferData != null) {
            views.add(
              AccountTransactionView(
                transactionId: transactionId,
                title: name,
                date: createdAt,
                amount: _parseAmount(transferData['amount']),
                isExpense: true,
                icon: Icons.swap_horiz,
              ),
            );
          }
        }
      }

      return views;
    } catch (e) {
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

  IconData _getIncomeIcon(String? category) {
    switch (category?.toUpperCase()) {
      case 'SALARY':
        return Icons.attach_money;
      case 'BUSINESS':
        return Icons.business;
      case 'GIFT':
        return Icons.card_giftcard;
      case 'INVESTMENT':
        return Icons.trending_up;
      default:
        return Icons.add_circle;
    }
  }

  IconData _getExpenseIcon(String? category) {
    switch (category?.toUpperCase()) {
      case 'FOOD':
        return Icons.fastfood;
      case 'TRANSPORT':
        return Icons.directions_car;
      case 'ENTERTAINMENT':
        return Icons.movie;
      case 'UTILITIES':
        return Icons.electric_bolt;
      case 'HEALTHCARE':
        return Icons.local_hospital;
      case 'SHOPPING':
        return Icons.shopping_bag;
      case 'TRAVEL':
        return Icons.flight_takeoff;
      case 'EDUCATION':
        return Icons.school;
      case 'RENT':
        return Icons.home;
      default:
        return Icons.attach_money;
    }
  }

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
