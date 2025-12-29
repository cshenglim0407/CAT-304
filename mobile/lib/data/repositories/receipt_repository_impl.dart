import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/services/supabase/client.dart';
import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/data/models/receipt_model.dart';
import 'package:cashlytics/domain/entities/receipt.dart';
import 'package:cashlytics/domain/repositories/receipt_repository.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  ReceiptRepositoryImpl({DatabaseService? databaseService})
    : _databaseService = databaseService ?? const DatabaseService();

  final DatabaseService _databaseService;
  final SupabaseClient _supabase = supabase;

  static const String _table = 'receipt';
  static const String _bucket = 'receipts';

  // ---------------------------
  // INSERT RECEIPT ROW
  // ---------------------------
  @override
  Future<Receipt> upsertReceipt(Receipt receipt) async {
    if (receipt.id != null) {
      throw StateError(
        'ReceiptRepository.upsertReceipt called with non-null id. '
        'Receipts must be inserted only after Save Expense.',
      );
    }

    final model = ReceiptModel.fromEntity(receipt);

    final insertData = await _databaseService.insert(_table, model.toInsert());

    if (insertData == null) {
      throw Exception('Failed to insert receipt');
    }

    return ReceiptModel.fromMap(insertData);
  }

  // ---------------------------
  // UPLOAD RECEIPT IMAGE
  // ---------------------------
  @override
  Future<String> uploadReceiptImage({
    required Object imageSource,
    required String receiptId,
  }) async {
    // Mobile-only assumption (safe for your project)
    if (imageSource is! File) {
      throw ArgumentError('uploadReceiptImage expects a File imageSource');
    }

    final File imageFile = imageSource;
    final String storagePath = 'receipts/$receiptId.jpg';

    await _supabase.storage
        .from(_bucket)
        .upload(
          storagePath,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    return storagePath;
  }

  Future<String> uploadTempReceiptImage(File imageFile) async {
    final fileName =
        'temp/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

    try {
      await supabase.storage.from('receipts').upload(fileName, imageFile);

      return fileName;
    } catch (e) {
      throw Exception('Failed to upload temp receipt: $e');
    }
  }

  // ---------------------------
  // FETCH RECEIPT BY ID
  // ---------------------------
  @override
  Future<Receipt?> getReceiptById(String receiptId) async {
    final data = await _databaseService.fetchSingle(
      _table,
      matchColumn: 'receipt_id',
      matchValue: receiptId,
    );

    if (data == null) return null;
    return ReceiptModel.fromMap(data);
  }

  // ---------------------------
  // SIGNED URL FOR VIEWING
  // ---------------------------
  @override
  Future<String> getSignedReceiptUrl(String storagePath) async {
    return await _supabase.storage
        .from(_bucket)
        .createSignedUrl(storagePath, 60 * 5);
  }

  // ---------------------------
  // GET RECEIPT FOR VIEWING
  // ---------------------------
  @override
  Future<Receipt?> getReceiptByTransactionId(String transactionId) async {
    final data = await _databaseService.fetchSingle(
      _table,
      matchColumn: 'transaction_id',
      matchValue: transactionId,
    );

    if (data == null) return null;
    return ReceiptModel.fromMap(data);
  }

  // ---------------------------
  // DELETE IMAGE FROM STORAGE
  // ---------------------------
  Future<void> deleteReceiptImage(String path) async {
    await supabase.storage.from('receipts').remove([path]);
  }

  // ---------------------------
  // DELETE ENTRY IN DATABASE
  // ---------------------------
  Future<void> deleteReceipt(String receiptId) async {
    final response = await supabase
        .from('receipt')
        .delete()
        .eq('id', receiptId);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }
}
