import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:cashlytics/core/services/cache/cache_service.dart';

/// Service for handling image compression and caching operations
class ImageCacheService {
  // Cache key for compressed profile image
  static const String compressedImageCacheKey = 'compressed_profile_image';

  /// Compresses an image to 200x200 pixels with PNG compression level 6
  /// Returns base64 encoded string, or null if compression fails
  static Future<String?> compressAndEncodeImage(String filePath) async {
    try {
      // Read image file as bytes
      final file = File(filePath);
      final imageBytes = await file.readAsBytes();

      // Decode image
      var image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('Failed to decode image');
        return null;
      }

      // Resize to 200x200 (thumbnail size)
      var resized = img.copyResize(
        image,
        width: 200,
        height: 200,
        interpolation: img.Interpolation.linear,
      );

      // Encode as PNG with compression level 6 (equivalent to ~70% quality)
      final compressed = img.encodePng(resized, level: 6);

      // Convert to base64
      return base64Encode(compressed);
    } catch (e) {
      debugPrint('Image compression error: $e');
      return null;
    }
  }

  /// Caches the compressed image base64 string locally
  /// Returns true if successful, false otherwise
  static Future<bool> cacheCompressedImage(String compressedBase64) async {
    try {
      CacheService.save(compressedImageCacheKey, compressedBase64);
      final sizeInKb = (compressedBase64.length / 1024).toStringAsFixed(2);
      debugPrint('Compressed image cached (size: $sizeInKb KB)');
      return true;
    } catch (e) {
      debugPrint('Error caching compressed image: $e');
      return false;
    }
  }

  /// Retrieves cached compressed image as MemoryImage
  /// Returns MemoryImage if cache exists, null otherwise
  static MemoryImage? getCompressedImageFromCache() {
    try {
      final cachedCompressedImage =
          CacheService.load<String>(compressedImageCacheKey);
      if (cachedCompressedImage != null && cachedCompressedImage.isNotEmpty) {
        final imageBytes = base64Decode(cachedCompressedImage);
        return MemoryImage(imageBytes);
      }
    } catch (e) {
      debugPrint('Error decoding cached compressed image: $e');
    }
    return null;
  }

  /// Clears cached compressed image from storage
  static Future<void> clearCachedImage() async {
    try {
      await CacheService.remove(compressedImageCacheKey);
      debugPrint('Cached compressed image cleared');
    } catch (e) {
      debugPrint('Error clearing cached image: $e');
    }
  }

  /// Compresses image and immediately caches it
  /// Useful for one-shot compression and caching operations
  static Future<bool> compressAndCache(String filePath) async {
    try {
      final compressedBase64 = await compressAndEncodeImage(filePath);
      if (compressedBase64 != null) {
        return await cacheCompressedImage(compressedBase64);
      }
      return false;
    } catch (e) {
      debugPrint('Error in compressAndCache: $e');
      return false;
    }
  }
}
