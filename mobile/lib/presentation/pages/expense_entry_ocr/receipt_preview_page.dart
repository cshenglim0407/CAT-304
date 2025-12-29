import 'dart:io';
import 'package:flutter/material.dart';

class ReceiptPreviewPage extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;

  const ReceiptPreviewPage({super.key, this.imageUrl, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Receipt")),
      body: Center(
        child: InteractiveViewer(
          child: imageFile != null
              ? Image.file(imageFile!, fit: BoxFit.contain)
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator();
                  },
                  errorBuilder: (_, _, _) =>
                      const Text("Failed to load receipt"),
                ),
        ),
      ),
    );
  }
}
