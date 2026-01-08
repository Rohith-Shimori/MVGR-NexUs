import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../features/vault/models/vault_model.dart';

/// Production-ready Supabase service for Vault (Study Materials)
class SupabaseVaultService extends ChangeNotifier {
  static final SupabaseVaultService _instance = SupabaseVaultService._internal();
  static SupabaseVaultService get instance => _instance;
  factory SupabaseVaultService() => _instance;
  SupabaseVaultService._internal();

  final _supabase = Supabase.instance.client;
  
  List<VaultItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<VaultItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch vault items with optional filters
  Future<void> fetchItems({
    String? branch,
    int? year,
    int? semester,
    String? subject,
    VaultItemType? type,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var query = _supabase.from('vault_items').select();

      if (branch != null) {
        query = query.eq('branch', branch);
      }
      if (year != null) {
        query = query.eq('year', year);
      }
      if (semester != null) {
        query = query.eq('semester', semester);
      }
      if (subject != null) {
        query = query.eq('subject', subject);
      }
      if (type != null) {
        query = query.eq('type', type.name);
      }

      final response = await query.order('created_at', ascending: false);

      _items = (response as List).map((json) => _itemFromJson(json)).toList();
      debugPrint('✅ Fetched ${_items.length} vault items');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error fetching vault items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get item by ID
  VaultItem? getItemById(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Search vault items
  Future<List<VaultItem>> searchItems(String query) async {
    try {
      final response = await _supabase
          .from('vault_items')
          .select()
          .or('title.ilike.%$query%,subject.ilike.%$query%,description.ilike.%$query%')
          .order('download_count', ascending: false);

      return (response as List).map((json) => _itemFromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error searching vault: $e');
      return [];
    }
  }

  /// Upload a file to Supabase Storage and create vault item
  Future<String?> uploadFile({
    required String title,
    required String description,
    required String filePath,
    required String fileName,
    required VaultItemType type,
    required String subject,
    required String branch,
    required int year,
    required int semester,
    required String uploaderId,
    required String uploaderName,
    List<String> tags = const [],
  }) async {
    try {
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      final fileSize = fileBytes.length;
      
      // Generate unique file path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'vault/$branch/$year/$semester/${timestamp}_$fileName';

      // Upload to Supabase Storage
      await _supabase.storage
          .from('vault-files')
          .uploadBinary(storagePath, fileBytes);

      // Get public URL
      final fileUrl = _supabase.storage
          .from('vault-files')
          .getPublicUrl(storagePath);

      // Create vault item record
      final response = await _supabase.from('vault_items').insert({
        'title': title,
        'description': description,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size_bytes': fileSize,
        'type': type.name,
        'subject': subject,
        'branch': branch,
        'year': year,
        'semester': semester,
        'tags': tags,
        'uploader_id': uploaderId,
        'uploader_name': uploaderName,
        'is_approved': false,
      }).select().single();

      debugPrint('✅ Vault item uploaded: $title');
      await fetchItems();
      return response['id'] as String;
    } catch (e) {
      debugPrint('❌ Error uploading vault item: $e');
      return null;
    }
  }

  /// Record a download
  Future<void> recordDownload(String itemId) async {
    try {
      // Increment download count using RPC or manual update
      await _supabase.rpc('increment_download_count', params: {'item_id': itemId});
    } catch (e) {
      // Fallback: direct update
      try {
        final current = await _supabase
            .from('vault_items')
            .select('download_count')
            .eq('id', itemId)
            .single();
        
        final newCount = (current['download_count'] as int? ?? 0) + 1;
        await _supabase
            .from('vault_items')
            .update({'download_count': newCount})
            .eq('id', itemId);
      } catch (e2) {
        debugPrint('❌ Error recording download: $e2');
      }
    }
  }

  /// Rate a vault item
  Future<bool> rateItem(String itemId, double rating) async {
    try {
      await _supabase
          .from('vault_items')
          .update({'rating': rating})
          .eq('id', itemId);
      debugPrint('✅ Item rated');
      return true;
    } catch (e) {
      debugPrint('❌ Error rating item: $e');
      return false;
    }
  }

  /// Delete a vault item
  Future<bool> deleteItem(String itemId) async {
    try {
      // Get item to find file path
      final item = await _supabase
          .from('vault_items')
          .select('file_url')
          .eq('id', itemId)
          .single();

      // Delete from storage (extract path from URL)
      final fileUrl = item['file_url'] as String;
      final storagePath = fileUrl.split('/vault-files/').last;
      await _supabase.storage.from('vault-files').remove([storagePath]);

      // Delete record
      await _supabase.from('vault_items').delete().eq('id', itemId);

      debugPrint('✅ Vault item deleted');
      await fetchItems();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting vault item: $e');
      return false;
    }
  }

  /// Get popular items (most downloaded)
  Future<List<VaultItem>> getPopularItems({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('vault_items')
          .select()
          .eq('is_approved', true)
          .order('download_count', ascending: false)
          .limit(limit);

      return (response as List).map((json) => _itemFromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting popular items: $e');
      return [];
    }
  }

  /// Get items uploaded by user
  Future<List<VaultItem>> getMyUploads(String userId) async {
    try {
      final response = await _supabase
          .from('vault_items')
          .select()
          .eq('uploader_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => _itemFromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting my uploads: $e');
      return [];
    }
  }

  /// Convert JSON to VaultItem model
  VaultItem _itemFromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileSizeBytes: json['file_size_bytes'] as int? ?? 0,
      type: VaultItemType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => VaultItemType.other,
      ),
      subject: json['subject']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      year: json['year'] as int? ?? 1,
      semester: json['semester'] as int? ?? 1,
      tags: List<String>.from(json['tags'] ?? []),
      uploaderId: json['uploader_id']?.toString() ?? '',
      uploaderName: json['uploader_name']?.toString() ?? '',
      downloadCount: json['download_count'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isApproved: json['is_approved'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Global singleton instance
final supabaseVaultService = SupabaseVaultService.instance;
