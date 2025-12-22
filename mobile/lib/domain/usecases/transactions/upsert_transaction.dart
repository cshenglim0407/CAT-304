import 'package:cashlytics/domain/entities/transaction_record.dart';
import 'package:cashlytics/domain/repositories/transaction_repository.dart';

class UpsertTransaction {
  const UpsertTransaction(this._repository);

  final TransactionRepository _repository;

  Future<TransactionRecord> call(TransactionRecord transaction) => 
      _repository.upsertTransaction(transaction);
}
