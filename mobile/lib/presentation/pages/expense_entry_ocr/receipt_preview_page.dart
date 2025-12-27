import 'package:flutter/material.dart';

class ReceiptPreviewPage extends StatelessWidget {
  final String imageUrl;

  const ReceiptPreviewPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Receipt")),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const CircularProgressIndicator();
            },
            errorBuilder: (_, _, _) {
              return const Text("Failed to load receipt");
            },
          ),
        ),
      ),
    );
  }
}
