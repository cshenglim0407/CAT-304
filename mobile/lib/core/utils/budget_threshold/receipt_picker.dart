import 'dart:io';

import 'package:file_picker/file_picker.dart';

class ReceiptPicker {
  static Future<File?> pickReceipt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }
}
