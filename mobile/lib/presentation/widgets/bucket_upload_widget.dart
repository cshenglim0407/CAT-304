// mobile/lib/presentation/widgets/storage/bucket_upload_widget.dart

import 'package:flutter/material.dart';
import 'package:cashlytics/core/services/supabase/storage/storage_service.dart';

class BucketUploadWidget extends StatefulWidget {
  final Function(String filePath, String bucketId) onUploadSuccess;
  final Function(String error) onError;

  const BucketUploadWidget({
    super.key,
    required this.onUploadSuccess,
    required this.onError,
  });

  @override
  State<BucketUploadWidget> createState() => _BucketUploadWidgetState();
}

class _BucketUploadWidgetState extends State<BucketUploadWidget> {
  final _storageService = StorageService();
  List<StorageBucket> _buckets = [];
  StorageBucket? _selectedBucket;
  bool _isLoading = true;
  double _uploadProgress = 0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadBuckets();
  }

  Future<void> _loadBuckets() async {
    final buckets = await _storageService.fetchAvailableBuckets(
      onError: (error) {
        widget.onError(error);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      },
    );

    if (mounted) {
      setState(() {
        _buckets = buckets;
        _selectedBucket = buckets.isNotEmpty ? buckets.first : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedBucket == null) {
      widget.onError('Please select a bucket');
      return;
    }

    setState(() => _isUploading = true);

    final filePath = await _storageService.pickAndUploadFile(
      bucketId: _selectedBucket!.id,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _uploadProgress = progress);
        }
      },
      onError: (error) {
        widget.onError(error);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
      },
    );

    if (mounted) {
      setState(() => _isUploading = false);
    }

    if (filePath != null) {
      widget.onUploadSuccess(filePath, _selectedBucket!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_buckets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No buckets available'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadBuckets, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<StorageBucket>(
          value: _selectedBucket,
          isExpanded: true,
          items: _buckets
              .map(
                (bucket) => DropdownMenuItem(
                  value: bucket,
                  child: Text(
                    '${bucket.name} ${bucket.isPublic ? '(public)' : '(private)'}',
                  ),
                ),
              )
              .toList(),
          onChanged: _isUploading
              ? null
              : (bucket) {
                  setState(() => _selectedBucket = bucket);
                },
        ),
        const SizedBox(height: 16),
        if (_isUploading)
          Column(
            children: [
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text('${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded'),
            ],
          )
        else
          ElevatedButton.icon(
            onPressed: _handleUpload,
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose & Upload File'),
          ),
      ],
    );
  }
}
