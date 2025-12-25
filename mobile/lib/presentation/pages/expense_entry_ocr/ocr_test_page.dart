import 'package:flutter/material.dart';

import 'package:cashlytics/data/services/receipt_picker.dart';
import 'package:cashlytics/data/services/ocr_service.dart';

class OCRTestPage extends StatefulWidget {
  const OCRTestPage({super.key});

  @override
  State<OCRTestPage> createState() => _OCRTestPageState();
}

class _OCRTestPageState extends State<OCRTestPage> {
  Map<String, dynamic>? _ocrResult;
  bool _loading = false;

  Future<void> _pickAndScan() async {
    final image = await ReceiptPicker.pickReceipt();
    if (image == null) return;

    setState(() {
      _loading = true;
      _ocrResult = null;
    });

    try {
      final result = await OCRService.scanReceipt(image);
      setState(() => _ocrResult = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OCR failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _pickAndScan,
              child: const Text('Pick Receipt Image'),
            ),

            const SizedBox(height: 20),

            if (_loading) const CircularProgressIndicator(),

            if (_ocrResult != null) ...[
              Text('Merchant: ${_ocrResult!['merchant_name']}'),
              Text('Total: ${_ocrResult!['total_amount']}'),
              Text('Date: ${_ocrResult!['expense_date']}'),
              Text('Confidence: ${_ocrResult!['confidence_score']}'),
            ],
          ],
        ),
      ),
    );
  }
}
