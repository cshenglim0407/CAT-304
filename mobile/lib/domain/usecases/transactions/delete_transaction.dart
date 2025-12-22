import 'package:cashlytics/domain/repositories/transaction_repository.dart';

class DeleteTransaction {
  const DeleteTransaction(this._repository);

  final TransactionRepository _repository;

  Future<void> call(String transactionId) => 
      _repository.deleteTransaction(transactionId);
}
