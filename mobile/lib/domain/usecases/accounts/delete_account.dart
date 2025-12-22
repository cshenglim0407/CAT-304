import 'package:cashlytics/domain/repositories/account_repository.dart';

class DeleteAccount {
  const DeleteAccount(this._repository);

  final AccountRepository _repository;

  Future<void> call(String accountId) => _repository.deleteAccount(accountId);
}
