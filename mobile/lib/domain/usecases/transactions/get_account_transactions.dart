import 'package:cashlytics/domain/entities/transaction_record.dart';
import 'package:cashlytics/domain/repositories/transaction_repository.dart';

class GetAccountTransactions {
  const GetAccountTransactions(this._repository);

  final TransactionRepository _repository;

  Future<List<TransactionRecord>> call(String accountId) =>
      _repository.getTransactionsByAccountId(accountId);
}
