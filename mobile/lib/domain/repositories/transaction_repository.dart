import 'package:cashlytics/domain/entities/transaction_record.dart';

abstract class TransactionRepository {
  Future<TransactionRecord> upsertTransaction(TransactionRecord transaction);
  Future<void> deleteTransaction(String transactionId);
}
