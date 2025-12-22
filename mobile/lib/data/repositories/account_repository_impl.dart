import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/account_model.dart';
import 'package:cashlytics/domain/entities/account.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  static const String _table = 'accounts';

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
