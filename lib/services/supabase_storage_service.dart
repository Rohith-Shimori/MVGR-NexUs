import 'dart:io';
import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService extends ChangeNotifier {
  static final SupabaseStorageService instance = SupabaseStorageService._internal();
  
  factory SupabaseStorageService() => instance;
  
  SupabaseStorageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Uploads a profile image and returns the public URL
  /// Returns null if upload fails
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      await _supabase.storage.from(SupabaseBuckets.profiles).upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(upsert: true),
      );

      final imageUrl = _supabase.storage.from(SupabaseBuckets.profiles).getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      AppLogger.error('Error uploading profile image: $e');
      return null;
    }
  }

  /// Uploads a generic file to a specified bucket
  Future<String?> uploadFile(String bucket, String path, File file) async {
    try {
      await _supabase.storage.from(bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return _supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      AppLogger.error('Error uploading file: $e');
      return null;
    }
  }
}

// Global instance
final supabaseStorageService = SupabaseStorageService.instance;