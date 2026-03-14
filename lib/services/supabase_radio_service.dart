import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for Radio Track
class RadioTrack {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? durationSeconds;
  final String audioUrl;
  final String? coverUrl;
  final String uploadedBy;
  final String? uploaderName;
  final int playCount;
  final int likesCount;
  final bool isApproved;
  final DateTime createdAt;

  RadioTrack({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.genre,
    this.durationSeconds,
    required this.audioUrl,
    this.coverUrl,
    required this.uploadedBy,
    this.uploaderName,
    this.playCount = 0,
    this.likesCount = 0,
    this.isApproved = true,
    required this.createdAt,
  });
}

/// Supabase Service for Radio feature
class SupabaseRadioService extends ChangeNotifier {
  static final SupabaseRadioService _instance = SupabaseRadioService._internal();
  factory SupabaseRadioService() => _instance;
  SupabaseRadioService._internal();

  final _supabase = Supabase.instance.client;
  
  List<RadioTrack> _tracks = [];
  Set<String> _likedTrackIds = {};
  bool _isLoading = false;
  String? _error;

  List<RadioTrack> get tracks => _tracks;
  List<RadioTrack> get approvedTracks => _tracks.where((t) => t.isApproved).toList();
  Set<String> get likedTrackIds => _likedTrackIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all tracks
  Future<void> fetchTracks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from(SupabaseTables.radioTracks)
          .select()
          .eq('is_approved', true)
          .order('created_at', ascending: false);

      _tracks = (response as List).map((json) => _trackFromJson(json)).toList();
      AppLogger.success(' Fetched ${_tracks.length} radio tracks');
    } catch (e) {
      _error = e.toString();
      AppLogger.error(' Error fetching tracks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch user's liked tracks
  Future<void> fetchLikedTracks(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.userLikedTracks)
          .select('track_id')
          .eq('user_id', userId);

      _likedTrackIds = (response as List).map((r) => r['track_id'] as String).toSet();
      notifyListeners();
    } catch (e) {
      AppLogger.error(' Error fetching liked tracks: $e');
    }
  }

  /// Toggle like on a track
  Future<bool> toggleLike(String trackId, String userId) async {
    try {
      if (_likedTrackIds.contains(trackId)) {
        await _supabase
            .from(SupabaseTables.userLikedTracks)
            .delete()
            .eq('track_id', trackId)
            .eq('user_id', userId);
        _likedTrackIds.remove(trackId);
      } else {
        await _supabase.from(SupabaseTables.userLikedTracks).insert({
          'track_id': trackId,
          'user_id': userId,
        });
        _likedTrackIds.add(trackId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error toggling like: $e');
      return false;
    }
  }

  /// Increment play count
  Future<void> incrementPlayCount(String trackId) async {
    try {
      await _supabase.rpc('increment_play_count', params: {'track_id': trackId});
    } catch (e) {
      AppLogger.error(' Error incrementing play count: $e');
    }
  }

  /// Upload a new track
  Future<bool> uploadTrack({
    required String title,
    String? artist,
    String? album,
    String? genre,
    int? durationSeconds,
    required String audioUrl,
    String? coverUrl,
    required String uploadedBy,
    String? uploaderName,
  }) async {
    try {
      await _supabase.from(SupabaseTables.radioTracks).insert({
        'title': title,
        'artist': artist,
        'album': album,
        'genre': genre,
        'duration_seconds': durationSeconds,
        'audio_url': audioUrl,
        'cover_url': coverUrl,
        'uploaded_by': uploadedBy,
        'uploader_name': uploaderName,
      });
      await fetchTracks();
      return true;
    } catch (e) {
      AppLogger.error(' Error uploading track: $e');
      return false;
    }
  }

  RadioTrack _trackFromJson(Map<String, dynamic> json) {
    return RadioTrack(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      artist: json['artist']?.toString(),
      album: json['album']?.toString(),
      genre: json['genre']?.toString(),
      durationSeconds: json['duration_seconds'] as int?,
      audioUrl: json['audio_url']?.toString() ?? '',
      coverUrl: json['cover_url']?.toString(),
      uploadedBy: json['uploaded_by']?.toString() ?? '',
      uploaderName: json['uploader_name']?.toString(),
      playCount: json['play_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      isApproved: json['is_approved'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Update a track
  Future<bool> updateTrack({
    required String trackId,
    String? title,
    String? artist,
    String? album,
    String? genre,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (artist != null) updates['artist'] = artist;
      if (album != null) updates['album'] = album;
      if (genre != null) updates['genre'] = genre;
      
      await _supabase.from(SupabaseTables.radioTracks).update(updates).eq('id', trackId);
      await fetchTracks();
      return true;
    } catch (e) {
      AppLogger.error(' Error updating track: $e');
      return false;
    }
  }

  /// Delete a track
  Future<bool> deleteTrack(String trackId) async {
    try {
      await _supabase.from(SupabaseTables.radioTracks).delete().eq('id', trackId);
      _tracks.removeWhere((t) => t.id == trackId);
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error deleting track: $e');
      return false;
    }
  }

  /// Fetch all tracks (including unapproved for admins)
  Future<void> fetchAllTracksAdmin() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from(SupabaseTables.radioTracks)
          .select()
          .order('created_at', ascending: false);

      _tracks = (response as List).map((json) => _trackFromJson(json)).toList();
      AppLogger.success(' Fetched ${_tracks.length} radio tracks (admin)');
    } catch (e) {
      _error = e.toString();
      AppLogger.error(' Error fetching tracks (admin): $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approve a track
  Future<bool> approveTrack(String trackId) async {
    try {
      await _supabase.from(SupabaseTables.radioTracks).update({'is_approved': true}).eq('id', trackId);
      await fetchAllTracksAdmin();
      return true;
    } catch (e) {
      AppLogger.error(' Error approving track: $e');
      return false;
    }
  }

  /// Get pending tracks count
  int get pendingCount => _tracks.where((t) => !t.isApproved).length;
}

/// Global singleton instance
final supabaseRadioService = SupabaseRadioService();