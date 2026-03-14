import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/events/models/event_model.dart';

class SupabaseAnnouncementService extends ChangeNotifier {
  static final SupabaseAnnouncementService _instance = SupabaseAnnouncementService._internal();
  static SupabaseAnnouncementService get instance => _instance;
  factory SupabaseAnnouncementService() => _instance;

  SupabaseAnnouncementService._internal() {
    _init();
  }

  final SupabaseClient _supabase = Supabase.instance.client;
  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _error;

  List<Announcement> get announcements => List.unmodifiable(_announcements);
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _init() {
    fetchAnnouncements();
    _subscribeToAnnouncements();
  }

  /// Subscribe to realtime updates
  void _subscribeToAnnouncements() {
    _supabase
        .from(SupabaseTables.announcements)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
          _announcements = data.map((json) => _announcementFromJson(json)).toList();
          notifyListeners();
        });
  }

  /// Fetch all announcements
  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from(SupabaseTables.announcements)
          .select()
          .order('created_at', ascending: false);

      _announcements = (response as List)
          .map((json) => _announcementFromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching announcements: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new announcement
  Future<bool> createAnnouncement(Announcement announcement) async {
    try {
      await _supabase.from(SupabaseTables.announcements).insert({
        'title': announcement.title,
        'content': announcement.content,
        'author_id': announcement.authorId,
        'author_name': announcement.authorName,
        'source': announcement.authorRole,
        'is_pinned': announcement.isPinned,
        'is_urgent': announcement.isUrgent,
        'expires_at': announcement.expiresAt?.toIso8601String(),
        'image_url': announcement.imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      AppLogger.error('Error creating announcement: $e');
      return false;
    }
  }

  /// Update an existing announcement
  Future<bool> updateAnnouncement(Announcement announcement) async {
    try {
      await _supabase.from(SupabaseTables.announcements).update({
        'title': announcement.title,
        'content': announcement.content,
        'is_pinned': announcement.isPinned,
        'is_urgent': announcement.isUrgent,
        'expires_at': announcement.expiresAt?.toIso8601String(),
        'image_url': announcement.imageUrl,
      }).eq('id', announcement.id);
      return true;
    } catch (e) {
      AppLogger.error('Error updating announcement: $e');
      return false;
    }
  }

  /// Delete an announcement
  Future<bool> deleteAnnouncement(String id) async {
    try {
      await _supabase.from(SupabaseTables.announcements).delete().eq('id', id);
      return true;
    } catch (e) {
      AppLogger.error('Error deleting announcement: $e');
      return false;
    }
  }

  /// Helper to parse JSON
  Announcement _announcementFromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? '',
      authorRole: json['source']?.toString() ?? 'Council',
      isPinned: json['is_pinned'] == true,
      isUrgent: json['is_urgent'] == true,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) : null,
      imageUrl: json['image_url']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Global singleton instance
final supabaseAnnouncementService = SupabaseAnnouncementService();