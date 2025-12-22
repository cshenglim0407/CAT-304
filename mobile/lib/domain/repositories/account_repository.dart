import 'package:cashlytics/domain/entities/account.dart';

abstract class AccountRepository {
  Future<Account> upsertAccount(Account account);
  Future<void> deleteAccount(String accountId);
}
