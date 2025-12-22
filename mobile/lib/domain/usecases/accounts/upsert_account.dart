import 'package:cashlytics/domain/entities/account.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';

class UpsertAccount {
  const UpsertAccount(this._repository);

  final AccountRepository _repository;

  Future<Account> call(Account account) => _repository.upsertAccount(account);
}
