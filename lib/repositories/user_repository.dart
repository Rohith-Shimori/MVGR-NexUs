/// User Repository - Handles user profile data operations
library;

import '../core/errors/result.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';
import '../config/supabase_config.dart';
import 'base_repository.dart';

/// Helper to build AppUser from JSON map
AppUser _userFromJson(Map<String, dynamic> json) {
  return AppUser(
    uid: json['id'] ?? json['uid'] ?? '',
    email: json['email'] ?? '',
    name: json['name'] ?? '',
    rollNumber: json['roll_number'] ?? '',
    department: json['department'] ?? '',
    year: json['year'] ?? 1,
    role: UserRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => UserRole.student,
    ),
    bio: json['bio'],
    profilePhotoUrl: json['profile_photo_url'],
    interests: json['interests'] != null 
        ? List<String>.from(json['interests']) 
        : [],
    skills: json['skills'] != null 
        ? List<String>.from(json['skills']) 
        : [],
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
    lastActiveAt: json['last_active_at'] != null 
        ? DateTime.parse(json['last_active_at']) 
        : null,
  );
}

/// Repository for User operations
class UserRepository extends BaseRepository<AppUser> {
  @override
  String get tableName => SupabaseTables.users;

  @override
  Map<String, dynamic> toJson(AppUser model) => model.toFirestore();

  @override
  AppUser fromJson(Map<String, dynamic> json) => _userFromJson(json);

  @override
  String getId(AppUser model) => model.uid;

  /// Get user by email
  Future<Result<AppUser?>> getByEmail(String email) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) return null;
      return fromJson(response as Map<String, dynamic>);
    });
  }

  /// Get users by department
  Future<Result<List<AppUser>>> getByDepartment(String department) async {
    return getByField('department', department);
  }

  /// Get users by role
  Future<Result<List<AppUser>>> getByRole(UserRole role) async {
    return getByField('role', role.name);
  }

  /// Update user interests
  Future<Result<void>> updateInterests(String userId, List<String> interests) async {
    return runCatchingAsync(() async {
      await client
          .from(tableName)
          .update({'interests': interests})
          .eq('id', userId);
    });
  }

  /// Update user skills
  Future<Result<void>> updateSkills(String userId, List<String> skills) async {
    return runCatchingAsync(() async {
      await client
          .from(tableName)
          .update({'skills': skills})
          .eq('id', userId);
    });
  }

  /// Update profile photo URL
  Future<Result<void>> updateProfilePhoto(String userId, String photoUrl) async {
    return runCatchingAsync(() async {
      await client
          .from(tableName)
          .update({'profile_photo_url': photoUrl})
          .eq('id', userId);
    });
  }

  /// Update last active timestamp
  Future<Result<void>> updateLastActive(String userId) async {
    return runCatchingAsync(() async {
      await client
          .from(tableName)
          .update({'last_active_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
    });
  }

  /// Search users by name
  Future<Result<List<AppUser>>> searchByName(String query) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Get users by IDs (batch)
  Future<Result<List<AppUser>>> getByIds(List<String> userIds) async {
    if (userIds.isEmpty) return Result.success([]);

    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .inFilter('id', userIds);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}
