
import '../core/constants/app_constants.dart';

/// User model representing a student, club admin, council member, or faculty
class AppUser {
  final String uid;
  final String email;
  final String name;
  final String rollNumber;
  final String department;
  final int year;
  final UserRole role;
  final List<String> clubIds;
  final List<String> interests;
  final List<String> skills;
  final String? profilePhotoUrl;
  final String? bio;
  final String? phoneNumber;
  final String? backgroundType; // 'color', 'gradient', or 'image'
  final int? backgroundColorValue; // Color value for solid/gradient
  final String? backgroundImageUrl; // URL for image backgrounds
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.rollNumber,
    required this.department,
    required this.year,
    this.role = UserRole.student,
    this.clubIds = const [],
    this.interests = const [],
    this.skills = const [],
    this.profilePhotoUrl,
    this.bio,
    this.phoneNumber,
    this.backgroundType,
    this.backgroundColorValue,
    this.backgroundImageUrl,
    this.isVerified = false,
    required this.createdAt,
    this.lastActiveAt,
  });

  /// Create from Firestore document
  factory AppUser.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return AppUser(
      uid: id ?? data['id'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      rollNumber: data['rollNumber'] ?? '',
      department: data['department'] ?? '',
      year: data['year'] ?? 1,
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => UserRole.student,
      ),
      clubIds: List<String>.from(data['clubIds'] ?? []),
      interests: List<String>.from(data['interests'] ?? []),
      skills: List<String>.from(data['skills'] ?? []),
      profilePhotoUrl: data['profilePhotoUrl'],
      bio: data['bio'],
      phoneNumber: data['phoneNumber'],
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
      lastActiveAt: data['lastActiveAt'] != null ? DateTime.parse(data['lastActiveAt']) : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'rollNumber': rollNumber,
      'department': department,
      'year': year,
      'role': role.name,
      'clubIds': clubIds,
      'interests': interests,
      'skills': skills,
      'profilePhotoUrl': profilePhotoUrl,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'backgroundType': backgroundType,
      'backgroundColorValue': backgroundColorValue,
      'backgroundImageUrl': backgroundImageUrl,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? rollNumber,
    String? department,
    int? year,
    UserRole? role,
    List<String>? clubIds,
    List<String>? interests,
    List<String>? skills,
    String? profilePhotoUrl,
    String? bio,
    String? phoneNumber,
    String? backgroundType,
    int? backgroundColorValue,
    String? backgroundImageUrl,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      department: department ?? this.department,
      year: year ?? this.year,
      role: role ?? this.role,
      clubIds: clubIds ?? this.clubIds,
      interests: interests ?? this.interests,
      skills: skills ?? this.skills,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  /// Get display name with role indicator
  String get displayNameWithRole => '$name (${role.displayName})';

  /// Check if user is admin of a specific club
  bool isClubAdmin(String clubId) => clubIds.contains(clubId);

  /// Empty/anonymous user for testing
  static AppUser get empty => AppUser(
    uid: '',
    email: '',
    name: 'Anonymous',
    rollNumber: '',
    department: '',
    year: 0,
    createdAt: DateTime.now(),
  );

  /// Test user for development (before auth is implemented)
  static AppUser testStudent({String? name, UserRole? role}) => AppUser(
    uid: 'test_student_001',
    email: 'student@mvgrce.edu.in',
    name: name ?? 'Test Student',
    rollNumber: '21BCE7100',
    department: 'Computer Science',
    year: 3,
    role: role ?? UserRole.student,
    isVerified: true,
    createdAt: DateTime.now(),
  );
}
