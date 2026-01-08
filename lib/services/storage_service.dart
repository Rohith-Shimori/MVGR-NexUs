/// Supabase Storage Service
/// Handles file uploads for profile photos, club logos, event images, vault files, etc.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../core/errors/result.dart';
import '../core/errors/app_exception.dart';

/// Storage bucket names
class StorageBuckets {
  static const String profilePhotos = 'profile-photos';
  static const String clubLogos = 'club-logos';
  static const String clubCovers = 'club-covers';
  static const String eventImages = 'event-images';
  static const String vaultFiles = 'vault-files';
  static const String lostFoundImages = 'lost-found-images';
  static const String announcements = 'announcement-images';
}

/// Storage service for handling file uploads to Supabase
class StorageService {
  static final StorageService _instance = StorageService._();
  static StorageService get instance => _instance;
  StorageService._();

  SupabaseStorageClient get _storage => SupabaseConfig.client.storage;

  /// Upload a file from bytes (works on all platforms)
  Future<Result<String>> uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    try {
      await _storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType ?? 'application/octet-stream',
          upsert: true,
        ),
      );

      final url = _storage.from(bucket).getPublicUrl(path);
      debugPrint('✅ Uploaded to $bucket/$path');
      return Result.success(url);
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      return Result.failure(DataException.operationFailed('Upload failed: $e'));
    }
  }

  /// Upload a file from File object (mobile only)
  Future<Result<String>> uploadFile({
    required String bucket,
    required String path,
    required File file,
    String? contentType,
  }) async {
    try {
      await _storage.from(bucket).upload(
        path,
        file,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      final url = _storage.from(bucket).getPublicUrl(path);
      debugPrint('✅ Uploaded file to $bucket/$path');
      return Result.success(url);
    } catch (e) {
      debugPrint('❌ File upload failed: $e');
      return Result.failure(DataException.operationFailed('Upload failed: $e'));
    }
  }

  /// Upload profile photo
  Future<Result<String>> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final path = '$userId/profile.$extension';
    return uploadBytes(
      bucket: StorageBuckets.profilePhotos,
      path: path,
      bytes: bytes,
      contentType: 'image/$extension',
    );
  }

  /// Upload club logo
  Future<Result<String>> uploadClubLogo({
    required String clubId,
    required Uint8List bytes,
    String extension = 'png',
  }) async {
    final path = '$clubId/logo.$extension';
    return uploadBytes(
      bucket: StorageBuckets.clubLogos,
      path: path,
      bytes: bytes,
      contentType: 'image/$extension',
    );
  }

  /// Upload club cover image
  Future<Result<String>> uploadClubCover({
    required String clubId,
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final path = '$clubId/cover.$extension';
    return uploadBytes(
      bucket: StorageBuckets.clubCovers,
      path: path,
      bytes: bytes,
      contentType: 'image/$extension',
    );
  }

  /// Upload event image
  Future<Result<String>> uploadEventImage({
    required String eventId,
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final path = '$eventId/image.$extension';
    return uploadBytes(
      bucket: StorageBuckets.eventImages,
      path: path,
      bytes: bytes,
      contentType: 'image/$extension',
    );
  }

  /// Upload vault file (documents, PDFs, etc.)
  Future<Result<String>> uploadVaultFile({
    required String userId,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/${timestamp}_$fileName';
    return uploadBytes(
      bucket: StorageBuckets.vaultFiles,
      path: path,
      bytes: bytes,
      contentType: contentType,
    );
  }

  /// Upload lost & found item image
  Future<Result<String>> uploadLostFoundImage({
    required String itemId,
    required Uint8List bytes,
    String extension = 'jpg',
  }) async {
    final path = '$itemId/image.$extension';
    return uploadBytes(
      bucket: StorageBuckets.lostFoundImages,
      path: path,
      bytes: bytes,
      contentType: 'image/$extension',
    );
  }

  /// Delete a file
  Future<Result<void>> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _storage.from(bucket).remove([path]);
      debugPrint('🗑️ Deleted $bucket/$path');
      return Result.success(null);
    } catch (e) {
      debugPrint('❌ Delete failed: $e');
      return Result.failure(DataException.operationFailed('Delete failed: $e'));
    }
  }

  /// Get public URL for a file
  String getPublicUrl(String bucket, String path) {
    return _storage.from(bucket).getPublicUrl(path);
  }

  /// Get signed URL (for private files)
  Future<Result<String>> getSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 3600,
  }) async {
    try {
      final url = await _storage.from(bucket).createSignedUrl(path, expiresInSeconds);
      return Result.success(url);
    } catch (e) {
      return Result.failure(DataException.operationFailed('Failed to get signed URL: $e'));
    }
  }
}

/// Singleton instance
final storageService = StorageService.instance;
