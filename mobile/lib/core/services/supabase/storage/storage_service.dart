import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cashlytics/core/services/supabase/client.dart';

/// Storage bucket model
class StorageBucket {
  final String id;
  final String name;
  final bool isPublic;

  StorageBucket({
    required this.id,
    required this.name,
    required this.isPublic,
  });
}

/// Storage service for handling file uploads to Supabase storage
class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  /// Fetch all available buckets for the user
  /// Returns a list of buckets the user has access to
  Future<List<StorageBucket>> fetchAvailableBuckets({
    required Function(String) onError,
  }) async {
    try {
      final buckets = await supabase.storage.listBuckets();
      return buckets
          .map((bucket) => StorageBucket(
                id: bucket.id,
                name: bucket.name,
                isPublic: bucket.public,
              ))
          .toList();
    } on StorageException catch (e) {
      onError('Failed to fetch buckets: ${e.message}');
      return [];
    } catch (e) {
      onError('Unexpected error while fetching buckets: $e');
      return [];
    }
  }

  /// Upload a file to the selected bucket
  /// 
  /// [bucketId] - The ID of the bucket to upload to
  /// [filePath] - The path of the file to upload
  /// [fileName] - Optional custom file name; if null, uses original file name
  /// [onProgress] - Callback for upload progress (0.0 to 1.0)
  /// [onError] - Callback for error handling
  /// 
  /// Returns the uploaded file path on success
  Future<String?> uploadFile({
    required String bucketId,
    required String filePath,
    String? fileName,
    required Function(double) onProgress,
    required Function(String) onError,
  }) async {
    try {
      final file = File(filePath);

      if (!file.existsSync()) {
        onError('File not found at path: $filePath');
        return null;
      }

      // Use custom file name or original
      final uploadFileName = fileName ?? file.path.split('/').last;

      // Generate unique path to avoid conflicts
      final userId = supabase.auth.currentUser?.id ?? 'anonymous';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final remotePath = '$userId/$timestamp/$uploadFileName';

      // Read file bytes
      final bytes = await file.readAsBytes();

      // Upload with progress tracking
      final response = await supabase.storage.from(bucketId).uploadBinary(
            remotePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      onProgress(1.0); // Upload complete
      return response;
    } on StorageException catch (e) {
      onError('Storage error: ${e.message}');
      return null;
    } on SocketException catch (e) {
      onError('Network error during upload: ${e.message}');
      return null;
    } catch (e) {
      onError('Unexpected error during upload: $e');
      return null;
    }
  }

  /// Pick a file and upload to selected bucket
  /// Shows file picker, then uploads to the chosen bucket
  /// 
  /// [bucketId] - The bucket ID to upload to
  /// [onProgress] - Progress callback (0.0 to 1.0)
  /// [onError] - Error callback
  /// 
  /// Returns the uploaded file path on success
  Future<String?> pickAndUploadFile({
    required String bucketId,
    required Function(double) onProgress,
    required Function(String) onError,
  }) async {
    try {
      // Open file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) {
        onError('No file selected');
        return null;
      }

      final file = result.files.first;
      final filePath = file.path ?? '';

      if (filePath.isEmpty) {
        onError('Unable to access file path');
        return null;
      }

      // Upload the file
      return await uploadFile(
        bucketId: bucketId,
        filePath: filePath,
        fileName: file.name,
        onProgress: onProgress,
        onError: onError,
      );
    } catch (e) {
      onError('Error picking file: $e');
      return null;
    }
  }

  /// Get public URL for a file in a bucket
  /// 
  /// [bucketId] - The bucket ID
  /// [filePath] - The path to the file within the bucket
  /// 
  /// Returns the public URL if bucket is public, null otherwise
  String? getPublicUrl({
    required String bucketId,
    required String filePath,
  }) {
    try {
      final url = supabase.storage.from(bucketId).getPublicUrl(filePath);
      return url;
    } catch (e) {
      return null;
    }
  }

  /// Delete a file from a bucket
  /// 
  /// [bucketId] - The bucket ID
  /// [filePath] - The path to the file within the bucket
  /// [onError] - Error callback
  Future<bool> deleteFile({
    required String bucketId,
    required String filePath,
    required Function(String) onError,
  }) async {
    try {
      await supabase.storage.from(bucketId).remove([filePath]);
      return true;
    } on StorageException catch (e) {
      onError('Failed to delete file: ${e.message}');
      return false;
    } catch (e) {
      onError('Unexpected error deleting file: $e');
      return false;
    }
  }
}