/// Vault Repository - Handles academic vault data operations
library;

import '../core/errors/result.dart';
import '../features/vault/models/vault_model.dart';
import '../config/supabase_config.dart';
import 'base_repository.dart';

/// Helper to build VaultItem from JSON map
VaultItem _vaultItemFromJson(Map<String, dynamic> json) {
  return VaultItem(
    id: json['id'] ?? '',
    uploaderId: json['uploaderId'] ?? json['uploader_id'] ?? '',
    uploaderName: json['uploaderName'] ?? json['uploader_name'] ?? '',
    title: json['title'] ?? '',
    description: json['description'],
    fileUrl: json['fileUrl'] ?? json['file_url'] ?? '',
    fileName: json['fileName'] ?? json['file_name'] ?? '',
    fileSizeBytes: json['fileSizeBytes'] ?? json['file_size_bytes'] ?? 0,
    type: VaultItemType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => VaultItemType.other,
    ),
    subject: json['subject'] ?? '',
    branch: json['branch'] ?? '',
    year: json['year'] ?? 1,
    semester: json['semester'] ?? 1,
    downloadCount: json['downloadCount'] ?? json['download_count'] ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    isApproved: json['isApproved'] ?? json['is_approved'] ?? true,
    createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    tags: List<String>.from(json['tags'] ?? []),
  );
}

/// Parse DateTime from various formats
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

/// Repository for Vault Items
class VaultRepository extends BaseRepository<VaultItem> {
  @override
  String get tableName => SupabaseTables.vaultItems;

  @override
  Map<String, dynamic> toJson(VaultItem model) => model.toFirestore();

  @override
  VaultItem fromJson(Map<String, dynamic> json) => _vaultItemFromJson(json);

  @override
  String getId(VaultItem model) => model.id;

  /// Get items by type
  Future<Result<List<VaultItem>>> getByType(VaultItemType type) async {
    return getByField('type', type.name);
  }

  /// Get items by branch
  Future<Result<List<VaultItem>>> getByBranch(String branch) async {
    return getByField('branch', branch);
  }

  /// Get items by semester
  Future<Result<List<VaultItem>>> getBySemester(int semester) async {
    return getByField('semester', semester);
  }

  /// Get items by subject
  Future<Result<List<VaultItem>>> getBySubject(String subject) async {
    return getByField('subject', subject);
  }

  /// Get trending items (most downloads)
  Future<Result<List<VaultItem>>> getTrending({int limit = 10}) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .order('downloadCount', ascending: false)
          .limit(limit);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Get recent items
  Future<Result<List<VaultItem>>> getRecent({int limit = 20}) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .order('createdAt', ascending: false)
          .limit(limit);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Increment download count
  Future<Result<void>> incrementDownloads(String itemId) async {
    return runCatchingAsync(() async {
      await client.rpc('increment_download_count', params: {'item_id': itemId});
    });
  }

  /// Search vault items
  Future<Result<List<VaultItem>>> search(String query) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .or('title.ilike.%$query%,subject.ilike.%$query%,description.ilike.%$query%')
          .order('downloadCount', ascending: false)
          .limit(20);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Get items by uploader
  Future<Result<List<VaultItem>>> getByUploader(String userId) async {
    return getByField('uploaderId', userId);
  }

  /// Filter items
  Future<Result<List<VaultItem>>> filter({
    VaultItemType? type,
    String? branch,
    int? semester,
    String? subject,
    int limit = 50,
  }) async {
    return runCatchingAsync(() async {
      var query = client.from(tableName).select();

      if (type != null) query = query.eq('type', type.name);
      if (branch != null) query = query.eq('branch', branch);
      if (semester != null) query = query.eq('semester', semester);
      if (subject != null) query = query.eq('subject', subject);

      final response = await query.order('downloadCount', ascending: false).limit(limit);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}
