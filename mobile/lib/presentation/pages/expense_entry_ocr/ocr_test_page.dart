import 'package:flutter/material.dart';

import 'package:cashlytics/data/services/receipt_picker.dart';
import 'package:cashlytics/data/services/ocr_service.dart';
import 'package:cashlytics/data/models/ocr_result.dart';

class OCRTestPage extends StatefulWidget {
  const OCRTestPage({super.key});

  @override
  State<OCRTestPage> createState() => _OCRTestPageState();
}

class _OCRTestPageState extends State<OCRTestPage> {
  OcrResult? _ocrResult;
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
      if (!mounted) return;
      setState(() {
        _ocrResult = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
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
              Text('Merchant: ${_ocrResult!.merchant ?? '-'}'),
              Text('Total: ${_ocrResult!.total?.toStringAsFixed(2) ?? '-'}'),
              Text(
                'Date: ${_ocrResult!.date != null ? _ocrResult!.date!.toIso8601String().split('T').first : '-'}',
              ),
              Text(
                'Confidence: ${(_ocrResult!.confidence * 100).toStringAsFixed(1)}%',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
