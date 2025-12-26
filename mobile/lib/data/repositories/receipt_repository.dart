import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:cashlytics/data/models/ocr_result.dart';

import 'package:cashlytics/core/services/supabase/client.dart';

class ReceiptRepository {
  final SupabaseClient _supabase = supabase;

  /// Saves a receipt WITHOUT linking to an expense yet.
  /// Returns the generated receipt_id.
  Future<String> saveDraftReceipt({
    required File imageFile,
    required OcrResult ocr,
    String? rawOcrText,
  }) async {
    final receiptId = const Uuid().v4();
    final storagePath = 'receipts/$receiptId.jpg';

    // 1️⃣ Upload image to Supabase Storage
    await _supabase.storage
        .from('receipts')
        .upload(
          storagePath,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    // 2️⃣ Insert receipt row (transaction_id = NULL)
    await _supabase.from('receipt').insert({
      'receipt_id': receiptId,
      'path': storagePath,
      'merchant_name': ocr.merchant,
      'confidence_score': ocr.confidence,
      'ocr_raw_text': rawOcrText,
      'scanned_at': DateTime.now().toIso8601String(),
      'transaction_id': null,
    });

    return receiptId;
  }
}
