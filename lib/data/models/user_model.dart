/// User Model (DTO)
/// Handles JSON serialization and conversion to/from entity
library;

import '../../domain/entities/user.dart';

/// User data transfer object
/// Used for serialization to/from Supabase
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String role;
  final String? department;
  final int? year;
  final String? rollNumber;
  final String? bio;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.role = 'student',
    this.department,
    this.year,
    this.rollNumber,
    this.bio,
    this.interests = const [],
    required this.createdAt,
    this.lastLoginAt,
    this.isEmailVerified = false,
  });

  /// Create from Supabase JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? '',
      photoUrl: json['profile_photo_url']?.toString() ?? json['photo_url']?.toString() ?? json['avatar_url']?.toString(),
      role: json['role']?.toString() ?? 'student',
      department: json['department']?.toString(),
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? ''),
      rollNumber: json['roll_number']?.toString(),
      bio: json['bio']?.toString(),
      interests: (json['interests'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      lastLoginAt: json['last_login_at'] != null 
          ? DateTime.tryParse(json['last_login_at'].toString()) 
          : null,
      isEmailVerified: json['email_verified'] == true,
    );
  }

  /// Convert to JSON for Supabase
  /// Note: Only include fields that exist in the database schema
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'email': email,
      'name': name,
      'role': role,
    };
    
    // Only include optional fields if they have values
    if (photoUrl != null) json['profile_photo_url'] = photoUrl;
    if (department != null) json['department'] = department;
    if (year != null) json['year'] = year;
    if (rollNumber != null) json['roll_number'] = rollNumber;
    if (bio != null) json['bio'] = bio;
    if (interests.isNotEmpty) json['interests'] = interests;
    
    return json;
  }


  /// Convert to domain entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      photoUrl: photoUrl,
      role: _parseRole(role),
      department: department,
      year: year,
      rollNumber: rollNumber,
      bio: bio,
      interests: interests,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      isEmailVerified: isEmailVerified,
      isProfileComplete: name.isNotEmpty && department != null && year != null,
    );
  }

  /// Create from domain entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      photoUrl: user.photoUrl,
      role: user.role.name,
      department: user.department,
      year: user.year,
      rollNumber: user.rollNumber,
      bio: user.bio,
      interests: user.interests,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      isEmailVerified: user.isEmailVerified,
    );
  }

  /// Parse role string to enum
  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'clubadmin':
      case 'club_admin':
        return UserRole.clubAdmin;
      case 'council':
        return UserRole.council;
      case 'faculty':
        return UserRole.faculty;
      default:
        return UserRole.student;
    }
  }
}
