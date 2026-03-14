import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/lost_found/models/lost_found_model.dart';

/// Supabase Service for Lost & Found feature
class SupabaseLostFoundService extends ChangeNotifier {
  static final SupabaseLostFoundService _instance = SupabaseLostFoundService._internal();
  factory SupabaseLostFoundService() => _instance;
  SupabaseLostFoundService._internal();

  final _supabase = Supabase.instance.client;
  
  List<LostFoundItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<LostFoundItem> get items => _items;
  List<LostFoundItem> get lostItems => _items.where((i) => i.status == LostFoundStatus.lost).toList();
  List<LostFoundItem> get foundItems => _items.where((i) => i.status == LostFoundStatus.found).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all items
  Future<void> fetchItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from(SupabaseTables.lostFoundItems)
          .select()
          .eq('is_resolved', false)
          .order('created_at', ascending: false);

      _items = (response as List).map((json) => _itemFromJson(json)).toList();
      AppLogger.success(' Fetched ${_items.length} lost & found items');
    } catch (e) {
      _error = e.toString();
      AppLogger.error(' Error fetching items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Report a lost or found item
  Future<bool> reportItem({
    required String userId,
    required String userName,
    required String title,
    required String description,
    required String status,
    required String category,
    required String location,
    String? foundLocation,
    required DateTime dateOccurred,
    String? imageUrl,
    String? contactInfo,
  }) async {
    try {
      await _supabase.from(SupabaseTables.lostFoundItems).insert({
        'user_id': userId,
        'user_name': userName,
        'title': title,
        'description': description,
        'status': status,
        'category': category,
        'location': location,
        'found_location': foundLocation,
        'date_occurred': dateOccurred.toIso8601String().split('T')[0],
        'image_url': imageUrl,
        'contact_info': contactInfo,
      });
      await fetchItems();
      return true;
    } catch (e) {
      AppLogger.error(' Error reporting item: $e');
      return false;
    }
  }

  /// Mark item as resolved
  Future<bool> resolveItem(String itemId) async {
    try {
      await _supabase.from(SupabaseTables.lostFoundItems).update({
        'is_resolved': true,
        'status': 'resolved', // DB accepts 'resolved', but Model enum doesn't have it. It might map to 'claimed' or 'expired'?
        // However, if we fetch this item back, we need to handle 'resolved'.
        // For now, we update DB. When fetching, we filter is_resolved=false so it won't show up anyway.
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);
      await fetchItems();
      return true;
    } catch (e) {
      AppLogger.error(' Error resolving item: $e');
      return false;
    }
  }

  /// Delete an item
  Future<bool> deleteItem(String itemId) async {
    try {
      await _supabase.from(SupabaseTables.lostFoundItems).delete().eq('id', itemId);
      await fetchItems();
      return true;
    } catch (e) {
      AppLogger.error(' Error deleting item: $e');
      return false;
    }
  }

  LostFoundItem _itemFromJson(Map<String, dynamic> json) {
    // Map status string to Enum
    final statusStr = json['status']?.toString() ?? 'lost';
    final status = LostFoundStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == statusStr.toLowerCase(),
      orElse: () => LostFoundStatus.lost,
    );

    // Map category string to Enum
    final categoryStr = json['category']?.toString() ?? 'other';
    final category = LostFoundCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == categoryStr.toLowerCase(),
      orElse: () => LostFoundCategory.other,
    );

    return LostFoundItem(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: status,
      category: category,
      location: json['location']?.toString() ?? '',
      // Map date_occurred to itemDate
      itemDate: DateTime.tryParse(json['date_occurred']?.toString() ?? '') ?? DateTime.now(),
      imageUrl: json['image_url']?.toString(),
      contactInfo: json['contact_info']?.toString(),
      // Model lacks resolvedAt and isResolved is not passed in constructor in the same way?
      // Model has claimerId/Name. DB might have them if we update schema, but assuming básico for now.
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.add(const Duration(days: 30)) ?? DateTime.now().add(const Duration(days: 30)),
    );
  }
}

/// Global singleton instance
final supabaseLostFoundService = SupabaseLostFoundService();