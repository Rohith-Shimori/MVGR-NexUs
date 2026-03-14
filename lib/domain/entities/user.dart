/// User Entity - Pure domain object
/// No dependencies on external libraries
library;

/// User role in the system
enum UserRole {
  student('Student'),
  clubAdmin('Club Admin'),
  council('Student Council'),
  faculty('Faculty');

  final String displayName;
  const UserRole(this.displayName);

  /// Permission checks
  bool get canModerate => this == council || this == faculty;
  bool get canCreateClub => this != student;
  bool get canCreateEvent => this != student;
  bool get canApproveContent => this == council || this == faculty;
  bool get canPostAnnouncement => this == council || this == faculty;
  bool get isFaculty => this == faculty;
}

/// User entity - core domain object
class User {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final UserRole role;
  final String? department;
  final int? year;
  final String? rollNumber;
  final String? bio;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;
  final bool isProfileComplete;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.role = UserRole.student,
    this.department,
    this.year,
    this.rollNumber,
    this.bio,
    this.interests = const [],
    required this.createdAt,
    this.lastLoginAt,
    this.isEmailVerified = false,
    this.isProfileComplete = false,
  });

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    UserRole? role,
    String? department,
    int? year,
    String? rollNumber,
    String? bio,
    List<String>? interests,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    bool? isProfileComplete,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      department: department ?? this.department,
      year: year ?? this.year,
      rollNumber: rollNumber ?? this.rollNumber,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }

  /// Check if user has completed required profile fields
  bool get hasCompleteProfile =>
      name.isNotEmpty &&
      department != null &&
      year != null &&
      rollNumber != null &&
      interests.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id: $id, name: $name, role: ${role.displayName})';
}
