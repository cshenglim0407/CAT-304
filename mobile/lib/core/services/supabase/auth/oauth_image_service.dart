import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/services/supabase/storage/storage_service.dart';
import 'package:cashlytics/core/services/cache/image_cache_service.dart';

/// Service for fetching and managing OAuth provider profile images
class OAuthImageService {
  static final _storageService = StorageService();

  /// Fetches profile image URL from Google OAuth account
  static Future<String?> getGoogleProfileImageUrl(
    GoogleSignInAccount account,
  ) async {
    try {
      if (account.photoUrl != null && account.photoUrl!.isNotEmpty) {
        return account.photoUrl;
      }
    } catch (e) {
      debugPrint('Error fetching Google profile image URL: $e');
    }
    return null;
  }

  /// Downloads image from URL and uploads to Supabase storage
  /// Returns the relative path in storage, or null if failed
  static Future<String?> downloadAndUploadProfileImage(
    String imageUrl,
    String userId, {
    String bucketId = 'profile-pictures',
    VoidCallback? onStart,
    VoidCallback? onEnd,
    Function(String)? onError,
  }) async {
    try {
      onStart?.call();

      // Download image from URL
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(imageUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      final imageBytes = await response.fold<List<int>>(
        [],
        (previous, element) => previous..addAll(element),
      );
      httpClient.close();

      // Save to temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_oauth_profile.jpg',
      );
      await tempFile.writeAsBytes(imageBytes);

      // Upload to Supabase storage
      final uploadedPath = await _storageService.uploadFile(
        bucketId: bucketId,
        filePath: tempFile.path,
        fileName: '${userId}_profile.jpg',
        onProgress: (progress) {
          debugPrint(
            'OAuth image upload progress: ${(progress * 100).toStringAsFixed(0)}%',
          );
        },
        onError: onError ?? (_) {},
      );

      // Compress and cache the image BEFORE deleting temp file
      if (uploadedPath != null) {
        // Clear old cached image from previous user
        await ImageCacheService.clearCachedImage();
        
        await ImageCacheService.compressAndCache(tempFile.path).catchError((e) {
          debugPrint('Error caching compressed image: $e');
          // Continue even if caching fails
          return true;
        });
      }

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (e) {
        debugPrint('Error deleting temp file: $e');
      }

      return uploadedPath;
    } catch (e) {
      debugPrint('Error downloading/uploading OAuth profile image: $e');
      onError?.call('Failed to save profile image: $e');
      return null;
    } finally {
      onEnd?.call();
    }
  }

  /// Fetches profile image from Google account and uploads to storage
  /// Returns the relative path in storage, or null if failed
  static Future<String?> fetchAndSaveGoogleProfileImage(
    GoogleSignInAccount account,
    String userId, {
    VoidCallback? onStart,
    VoidCallback? onEnd,
    Function(String)? onError,
  }) async {
    try {
      final imageUrl = await getGoogleProfileImageUrl(account);
      if (imageUrl == null || imageUrl.isEmpty) {
        debugPrint('No profile image URL available from Google');
        return null;
      }

      return await downloadAndUploadProfileImage(
        imageUrl,
        userId,
        onStart: onStart,
        onEnd: onEnd,
        onError: onError,
      );
    } catch (e) {
      debugPrint('Error fetching Google profile image: $e');
      onError?.call('Failed to fetch Google profile image');
      return null;
    }
  }

  /// Fetches profile image from Supabase OAuth session (works for Facebook and other providers)
  /// Returns image URL from provider metadata
  static String? getOAuthProfileImageUrl(Session session) {
    try {
      final user = session.user;
      final rawUserMetadata = user.userMetadata;

      if (rawUserMetadata != null) {
        // Check for common OAuth provider image field names
        final imageUrl =
            rawUserMetadata['picture'] ??
            rawUserMetadata['image_url'] ??
            rawUserMetadata['avatar_url'] ??
            rawUserMetadata['profile_picture_url'];

        if (imageUrl is String && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }
    } catch (e) {
      debugPrint('Error extracting OAuth profile image URL from session: $e');
    }
    return null;
  }

  /// Fetches and saves profile image from OAuth session (Facebook, GitHub, etc.)
  /// Returns the relative path in storage, or null if failed
  static Future<String?> fetchAndSaveOAuthProfileImage(
    Session session,
    String userId, {
    VoidCallback? onStart,
    VoidCallback? onEnd,
    Function(String)? onError,
  }) async {
    try {
      final imageUrl = getOAuthProfileImageUrl(session);
      if (imageUrl == null || imageUrl.isEmpty) {
        debugPrint('No profile image URL available in OAuth session');
        return null;
      }

      return await downloadAndUploadProfileImage(
        imageUrl,
        userId,
        onStart: onStart,
        onEnd: onEnd,
        onError: onError,
      );
    } catch (e) {
      debugPrint('Error fetching OAuth profile image from session: $e');
      onError?.call('Failed to fetch profile image from provider');
      return null;
    }
  }
}
