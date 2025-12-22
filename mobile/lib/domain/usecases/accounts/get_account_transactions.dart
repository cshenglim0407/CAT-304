import 'package:cashlytics/domain/entities/account_transaction_view.dart';
import 'package:cashlytics/domain/repositories/account_repository.dart';

class GetAccountTransactions {
  const GetAccountTransactions(this._repository);

  final AccountRepository _repository;

  Future<List<AccountTransactionView>> call(String accountId) =>
      _repository.getAccountTransactions(accountId);
}
