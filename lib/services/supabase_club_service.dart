import 'dart:io';
import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/clubs/models/club_model.dart';

/// Production-ready Supabase service for Clubs
/// Uses proper junction table (club_members) for membership
class SupabaseClubService extends ChangeNotifier {
  static final SupabaseClubService _instance = SupabaseClubService._internal();
  static SupabaseClubService get instance => _instance;
  factory SupabaseClubService() => _instance;
  SupabaseClubService._internal();

  SupabaseClient? _clientOverride;
  SupabaseClient get _supabase => _clientOverride ?? Supabase.instance.client;

  @visibleForTesting
  set client(SupabaseClient client) => _clientOverride = client;
  
  List<Club> _clubs = [];
  bool _isLoading = false;
  String? _error;

  List<Club> get clubs => _clubs;
  List<Club> get approvedClubs => _clubs.where((c) => c.isApproved).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set clubs(List<Club> value) {
    _clubs = value;
    notifyListeners();
  }

  /// Fetch all clubs from Supabase
  Future<void> fetchClubs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from(SupabaseTables.clubs)
          .select()
          .order('created_at', ascending: false);

      _clubs = (response as List).map((json) => _clubFromJson(json)).toList();
      AppLogger.success(' Fetched ${_clubs.length} clubs from Supabase');
    } catch (e) {
      _error = e.toString();
      AppLogger.error(' Error fetching clubs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get club by ID
  Club? getClubById(String id) {
    try {
      return _clubs.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get clubs where user is a member (using junction table)
  Future<List<Club>> getMyClubs(String userId) async {
    try {
      // Query club_members junction table to find user's clubs
      final membershipResponse = await _supabase
          .from(SupabaseTables.clubMembers)
          .select('club_id')
          .eq('user_id', userId);

      final clubIds = (membershipResponse as List)
          .map((m) => m['club_id'] as String)
          .toList();

      if (clubIds.isEmpty) return [];

      // Fetch those clubs
      final clubsResponse = await _supabase
          .from(SupabaseTables.clubs)
          .select()
          .inFilter('id', clubIds);

      return (clubsResponse as List).map((json) => _clubFromJson(json)).toList();
    } catch (e) {
      AppLogger.error(' Error getting my clubs: $e');
      return [];
    }
  }

  /// Get clubs where user is an admin
  Future<List<Club>> getAdminClubs(String userId) async {
    try {
      final membershipResponse = await _supabase
          .from(SupabaseTables.clubMembers)
          .select('club_id')
          .eq('user_id', userId)
          .inFilter('role', ['admin', 'owner']);

      final clubIds = (membershipResponse as List)
          .map((m) => m['club_id'] as String)
          .toList();

      if (clubIds.isEmpty) return [];

      final clubsResponse = await _supabase
          .from(SupabaseTables.clubs)
          .select()
          .inFilter('id', clubIds);

      return (clubsResponse as List).map((json) => _clubFromJson(json)).toList();
    } catch (e) {
      AppLogger.error(' Error getting admin clubs: $e');
      return [];
    }
  }

  /// Check if user is a member of a club
  Future<bool> isMember(String clubId, String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.clubMembers)
          .select('id')
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      AppLogger.error(' Error checking membership: $e');
      return false;
    }
  }

  /// Check if user is an admin of a club
  Future<bool> isAdmin(String clubId, String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.clubMembers)
          .select('id')
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .inFilter('role', ['admin', 'owner'])
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      AppLogger.error(' Error checking admin status: $e');
      return false;
    }
  }

  /// Join a club (insert into junction table)
  Future<bool> joinClub(String clubId, String userId, String userName) async {
    try {
      await _supabase.from(SupabaseTables.clubMembers).insert({
        'club_id': clubId,
        'user_id': userId,
        'user_name': userName,
        'role': 'member',
      });
      AppLogger.success(' User joined club: $clubId');
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error joining club: $e');
      return false;
    }
  }

  /// Leave a club (delete from junction table)
  Future<bool> leaveClub(String clubId, String userId) async {
    try {
      await _supabase
          .from(SupabaseTables.clubMembers)
          .delete()
          .eq('club_id', clubId)
          .eq('user_id', userId);
      AppLogger.success(' User left club: $clubId');
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error leaving club: $e');
      return false;
    }
  }

  /// Get member count for a club
  Future<int> getMemberCount(String clubId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.clubMembers)
          .select('id')
          .eq('club_id', clubId);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Create a new club
  Future<String?> createClub({
    required String name,
    required String description,
    required String category,
    required String creatorId,
    String? logoUrl,
    String? coverImageUrl,
    String? contactEmail,
    String? instagramHandle,
  }) async {
    try {
      // Insert club
      final clubResponse = await _supabase.from(SupabaseTables.clubs).insert({
        'name': name,
        'description': description,
        'category': category,
        'logo_url': logoUrl,
        'cover_image_url': coverImageUrl,
        'contact_email': contactEmail,
        'instagram_handle': instagramHandle,
        'is_approved': false,
        'is_official': false,
        'created_by': creatorId,
      }).select().single();

      final clubId = clubResponse['id'] as String;

      // Add creator as owner in junction table
      await _supabase.from(SupabaseTables.clubMembers).insert({
        'club_id': clubId,
        'user_id': creatorId,
        'role': 'owner',
      });

      AppLogger.success(' Club created: $name');
      await fetchClubs(); // Refresh list
      return clubId;
    } catch (e) {
      AppLogger.error(' Error creating club: $e');
      return null;
    }
  }

  /// Update a club
  Future<bool> updateClub(String clubId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from(SupabaseTables.clubs).update(updates).eq('id', clubId);
      AppLogger.success(' Club updated: $clubId');
      await fetchClubs();
      return true;
    } catch (e) {
      AppLogger.error(' Error updating club: $e');
      return false;
    }
  }

  /// Delete a club
  Future<bool> deleteClub(String clubId) async {
    try {
      await _supabase.from(SupabaseTables.clubs).delete().eq('id', clubId);
      AppLogger.success(' Club deleted: $clubId');
      await fetchClubs();
      return true;
    } catch (e) {
      AppLogger.error(' Error deleting club: $e');
      return false;
    }
  }

  /// Get posts for a club
  Future<List<ClubPost>> getClubPosts(String clubId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.clubPosts)
          .select()
          .eq('club_id', clubId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => _postFromJson(json)).toList();
    } catch (e) {
      AppLogger.error(' Error fetching club posts: $e');
      return [];
    }
  }

  /// Create a new club post
  Future<bool> createClubPost(ClubPost post) async {
    try {
      await _supabase.from(SupabaseTables.clubPosts).insert({
        'club_id': post.clubId,
        'title': post.title,
        'content': post.content,
        'type': post.type.name,
        'image_url': post.imageUrl,
        'author_id': post.authorId,
        'author_name': post.authorName,
        'is_pinned': post.isPinned,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error creating club post: $e');
      return false;
    }
  }

  /// Get all members of a club
  Future<List<Map<String, dynamic>>> getClubMembers(String clubId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.clubMembers)
          .select()
          .eq('club_id', clubId);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      AppLogger.error(' Error fetching club members: $e');
      return [];
    }
  }

  /// Promote member to admin
  Future<bool> promoteToAdmin(String clubId, String userId) async {
    try {
      await _supabase
          .from(SupabaseTables.clubMembers)
          .update({'role': 'admin'})
          .eq('club_id', clubId)
          .eq('user_id', userId);
      
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error promoting member: $e');
      return false;
    }
  }

  // Requests

  /// Get pending join requests
  Future<List<Map<String, dynamic>>> getPendingRequests(String clubId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.clubJoinRequests)
          .select()
          .eq('club_id', clubId)
          .eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      // Table might not exist yet, return empty
      return [];
    }
  }

  /// Request to join a club
  Future<bool> requestToJoin(String clubId, String userId, String userName, {String? note}) async {
    try {
      // Check if already a member
      if (await isMember(clubId, userId)) return true;

      await _supabase.from(SupabaseTables.clubJoinRequests).insert({
        'club_id': clubId,
        'user_id': userId,
        'user_name': userName,
        'note': note,
        'status': 'pending'
      });
      AppLogger.success(' Join request sent to club: $clubId');
      return true;
    } catch (e) {
      AppLogger.error(' Error requesting to join: $e');
      return false;
    }
  }

  /// Approve join request
  Future<bool> approveRequest(String requestId, String clubId, String userId, String userName) async {
    try {
      // 1. Add to members
      await joinClub(clubId, userId, userName);
      
      // 2. Update request status
      await _supabase
          .from(SupabaseTables.clubJoinRequests)
          .update({'status': 'approved'})
          .eq('id', requestId);
      
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error approving request: $e');
      return false;
    }
  }

  /// Reject join request
  Future<bool> rejectRequest(String requestId) async {
    try {
      await _supabase
          .from(SupabaseTables.clubJoinRequests)
          .update({'status': 'rejected'})
          .eq('id', requestId);
      
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error rejecting request: $e');
      return false;
    }
  }

  /// Check if user has a pending join request
  Future<bool> hasPendingRequest(String clubId, String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.clubJoinRequests)
          .select('id')
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .eq('status', 'pending')
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Get join requests made by the user
  Future<List<Map<String, dynamic>>> getMyJoinRequests(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.clubJoinRequests)
          .select('*, clubs(name, category)')
          .eq('user_id', userId)
          .eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      AppLogger.error(' Error getting my join requests: $e');
      return [];
    }
  }

  /// Cancel a join request
  Future<bool> cancelJoinRequest(String requestId) async {
    try {
      await _supabase
          .from(SupabaseTables.clubJoinRequests)
          .delete()
          .eq('id', requestId);
      
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error canceling request: $e');
      return false;
    }
  }

  /// Upload an image to Supabase Storage
  Future<String?> uploadImage(File file, String path) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}_$path.$fileExt';
      final filePath = fileName;

      await _supabase.storage.from(SupabaseTables.clubs).upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final imageUrl = _supabase.storage.from(SupabaseTables.clubs).getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      AppLogger.error(' Error uploading image: $e');
      return null;
    }
  }

  /// Convert JSON to Club model
  Club _clubFromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: ClubCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ClubCategory.other,
      ),
      logoUrl: json['logo_url']?.toString(),
      coverImageUrl: json['cover_image_url']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      instagramHandle: json['instagram_handle']?.toString(),
      isApproved: json['is_approved'] == true,
      isOfficial: json['is_official'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      createdBy: json['created_by']?.toString() ?? '',
      memberCount: json['member_count'] as int? ?? 0,
      adminCount: json['admin_count'] as int? ?? 0,
    );
  }

  /// Convert JSON to ClubPost model
  ClubPost _postFromJson(Map<String, dynamic> json) {
    return ClubPost(
      id: json['id']?.toString() ?? '',
      clubId: json['club_id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: ClubPostType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ClubPostType.general,
      ),
      imageUrl: json['image_url']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isPinned: json['is_pinned'] == true,
    );
  }

  // Note: requestToJoinClub was REMOVED - use requestToJoin() instead
  // which supports userName and optional note parameters

  /// Approve a club (for moderation)
  Future<bool> approveClub(String clubId) async {
    try {
      await _supabase.from(SupabaseTables.clubs).update({
        'is_approved': true,
      }).eq('id', clubId);
      AppLogger.success(' Club approved: $clubId');
      await fetchClubs();
      return true;
    } catch (e) {
      AppLogger.error(' Error approving club: $e');
      return false;
    }
  }
}

/// Global singleton instance
final supabaseClubService = SupabaseClubService.instance;