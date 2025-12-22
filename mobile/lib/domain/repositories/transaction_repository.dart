import 'package:cashlytics/domain/entities/transaction_record.dart';

abstract class TransactionRepository {
  Future<List<TransactionRecord>> getTransactionsByAccountId(String accountId);
  Future<TransactionRecord> upsertTransaction(TransactionRecord transaction);
  Future<void> deleteTransaction(String transactionId);
}
