/// Club Repository - Handles all club-related data operations
library;

import '../core/errors/result.dart';
import '../core/errors/app_exception.dart';
import '../features/clubs/models/club_model.dart';
import '../models/join_request_model.dart';
import '../config/supabase_config.dart';
import 'base_repository.dart';

/// Helper to build Club from JSON map
Club _clubFromJson(Map<String, dynamic> json) {
  return Club(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    category: ClubCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => ClubCategory.other,
    ),
    adminIds: List<String>.from(json['adminIds'] ?? json['admin_ids'] ?? []),
    memberIds: List<String>.from(json['memberIds'] ?? json['member_ids'] ?? []),
    logoUrl: json['logoUrl'] ?? json['logo_url'],
    coverImageUrl: json['coverImageUrl'] ?? json['cover_image_url'],
    contactEmail: json['contactEmail'] ?? json['contact_email'],
    instagramHandle: json['instagramHandle'] ?? json['instagram_handle'],
    isApproved: json['isApproved'] ?? json['is_approved'] ?? true,
    isOfficial: json['isOfficial'] ?? json['is_official'] ?? false,
    createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    createdBy: json['createdBy'] ?? json['created_by'],
  );
}

/// Helper to build ClubPost from JSON map
ClubPost _clubPostFromJson(Map<String, dynamic> json) {
  return ClubPost(
    id: json['id'] ?? '',
    clubId: json['clubId'] ?? json['club_id'] ?? '',
    authorId: json['authorId'] ?? json['author_id'] ?? '',
    authorName: json['authorName'] ?? json['author_name'] ?? '',
    type: ClubPostType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => ClubPostType.general,
    ),
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    imageUrl: json['imageUrl'] ?? json['image_url'],
    createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    isPinned: json['isPinned'] ?? json['is_pinned'] ?? false,
  );
}

/// Helper to build ClubJoinRequest from JSON map
ClubJoinRequest _joinRequestFromJson(Map<String, dynamic> json) {
  return ClubJoinRequest(
    id: json['id'] ?? '',
    clubId: json['clubId'] ?? json['club_id'] ?? '',
    clubName: json['clubName'] ?? json['club_name'] ?? '',
    userId: json['userId'] ?? json['user_id'] ?? '',
    userName: json['userName'] ?? json['user_name'] ?? '',
    note: json['note'],
    status: ClubJoinStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => ClubJoinStatus.pending,
    ),
    requestedAt: _parseDateTime(json['requestedAt'] ?? json['requested_at']),
  );
}

/// Parse DateTime from various formats
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

/// Repository for Club operations
class ClubRepository extends BaseRepository<Club> {
  @override
  String get tableName => SupabaseTables.clubs;

  @override
  Map<String, dynamic> toJson(Club model) => model.toFirestore();

  @override
  Club fromJson(Map<String, dynamic> json) => _clubFromJson(json);

  @override
  String getId(Club model) => model.id;

  /// Get clubs by category
  Future<Result<List<Club>>> getByCategory(ClubCategory category) async {
    return getByField('category', category.name);
  }

  /// Get clubs where user is a member
  Future<Result<List<Club>>> getMyClubs(String userId) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .contains('memberIds', [userId]);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Get clubs where user is an admin
  Future<Result<List<Club>>> getAdminClubs(String userId) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .contains('adminIds', [userId]);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Join club directly (add user to members)
  Future<Result<void>> joinClub(String clubId, String userId) async {
    return runCatchingAsync(() async {
      final clubResult = await getById(clubId);
      final club = clubResult.valueOrNull;
      
      if (club == null) {
        throw DataException.notFound('Club');
      }

      final updatedMembers = [...club.memberIds, userId];
      await client
          .from(tableName)
          .update({'memberIds': updatedMembers})
          .eq('id', clubId);
    });
  }

  /// Leave club
  Future<Result<void>> leaveClub(String clubId, String userId) async {
    return runCatchingAsync(() async {
      final clubResult = await getById(clubId);
      final club = clubResult.valueOrNull;
      
      if (club == null) {
        throw DataException.notFound('Club');
      }

      final updatedMembers = club.memberIds.where((id) => id != userId).toList();
      await client
          .from(tableName)
          .update({'memberIds': updatedMembers})
          .eq('id', clubId);
    });
  }

  /// Search clubs by name
  Future<Result<List<Club>>> searchByName(String query) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .ilike('name', '%$query%');

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}

/// Repository for Club Posts
class ClubPostRepository extends BaseRepository<ClubPost> {
  @override
  String get tableName => SupabaseTables.clubPosts;

  @override
  Map<String, dynamic> toJson(ClubPost model) => model.toFirestore();

  @override
  ClubPost fromJson(Map<String, dynamic> json) => _clubPostFromJson(json);

  @override
  String getId(ClubPost model) => model.id;

  /// Get posts for a specific club
  Future<Result<List<ClubPost>>> getClubPosts(String clubId) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .eq('clubId', clubId)
          .order('createdAt', ascending: false);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}

/// Repository for Club Join Requests
class ClubJoinRequestRepository extends BaseRepository<ClubJoinRequest> {
  @override
  String get tableName => SupabaseTables.clubJoinRequests;

  @override
  Map<String, dynamic> toJson(ClubJoinRequest model) => model.toFirestore();

  @override
  ClubJoinRequest fromJson(Map<String, dynamic> json) => _joinRequestFromJson(json);

  @override
  String getId(ClubJoinRequest model) => model.id;

  /// Get pending requests for a club
  Future<Result<List<ClubJoinRequest>>> getPendingForClub(String clubId) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .eq('clubId', clubId)
          .eq('status', ClubJoinStatus.pending.name);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Get user's join requests
  Future<Result<List<ClubJoinRequest>>> getMyRequests(String userId) async {
    return getByField('userId', userId);
  }

  /// Approve a join request
  Future<Result<void>> approve(String requestId, String approvedBy) async {
    return runCatchingAsync(() async {
      await client.from(tableName).update({
        'status': ClubJoinStatus.approved.name,
      }).eq('id', requestId);
    });
  }

  /// Reject a join request
  Future<Result<void>> reject(String requestId, String rejectedBy, {String? reason}) async {
    return runCatchingAsync(() async {
      await client.from(tableName).update({
        'status': ClubJoinStatus.rejected.name,
      }).eq('id', requestId);
    });
  }
}
