import 'package:cashlytics/domain/entities/account.dart';
import 'package:cashlytics/domain/entities/account_transaction_view.dart';

abstract class AccountRepository {
  Future<List<Account>> getAccountsByUserId(String userId);
  Future<List<AccountTransactionView>> getAccountTransactions(String accountId);
  Future<Account> upsertAccount(Account account);
  Future<void> deleteAccount(String accountId);
}
