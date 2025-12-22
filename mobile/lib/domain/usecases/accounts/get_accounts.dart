import 'package:cashlytics/domain/entities/account.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';

class GetAccounts {
  const GetAccounts(this._repository);

  final AccountRepository _repository;

  Future<List<Account>> call(String userId) =>
      _repository.getAccountsByUserId(userId);
}
