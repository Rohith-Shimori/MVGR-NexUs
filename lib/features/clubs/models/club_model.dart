import 'package:flutter/material.dart';


/// Category for clubs
enum ClubCategory {
  technical,
  cultural,
  sports,
  social,
  academic,
  other;
  
  String get displayName {
    switch (this) {
      case ClubCategory.technical:
        return 'Technical';
      case ClubCategory.cultural:
        return 'Cultural';
      case ClubCategory.sports:
        return 'Sports';
      case ClubCategory.social:
        return 'Social';
      case ClubCategory.academic:
        return 'Academic';
      case ClubCategory.other:
        return 'Other';
    }
  }
  
  String get icon {
    switch (this) {
      case ClubCategory.technical:
        return '💻';
      case ClubCategory.cultural:
        return '🎭';
      case ClubCategory.sports:
        return '🏃';
      case ClubCategory.social:
        return '🤝';
      case ClubCategory.academic:
        return '📚';
      case ClubCategory.other:
        return '⭐';
    }
  }
  
  /// Material icon for premium UI
  IconData get iconData {
    switch (this) {
      case ClubCategory.technical:
        return Icons.code_rounded;
      case ClubCategory.cultural:
        return Icons.palette_rounded;
      case ClubCategory.sports:
        return Icons.sports_soccer_rounded;
      case ClubCategory.social:
        return Icons.people_rounded;
      case ClubCategory.academic:
        return Icons.school_rounded;
      case ClubCategory.other:
        return Icons.stars_rounded;
    }
  }
}

/// Club/Committee/Council model
/// NOTE: Member/admin relationships are managed via the club_members junction table
class Club {
  final String id;
  final String name;
  final String description;
  final ClubCategory category;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? contactEmail;
  final String? instagramHandle;
  final bool isApproved;
  final bool isOfficial;  // For councils and committees
  final DateTime createdAt;
  final String createdBy;
  // These are populated separately via junction table queries
  final int memberCount;
  final int adminCount;

  Club({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.logoUrl,
    this.coverImageUrl,
    this.contactEmail,
    this.instagramHandle,
    this.isApproved = false,
    this.isOfficial = false,
    required this.createdAt,
    required this.createdBy,
    this.memberCount = 0,
    this.adminCount = 0,
  });

  factory Club.fromFirestore(Map<String, dynamic> data, {String? id, int? memberCount, int? adminCount}) {
    return Club(
      id: id ?? data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: ClubCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => ClubCategory.other,
      ),
      logoUrl: data['logoUrl'],
      coverImageUrl: data['coverImageUrl'],
      contactEmail: data['contactEmail'],
      instagramHandle: data['instagramHandle'],
      isApproved: data['isApproved'] ?? false,
      isOfficial: data['isOfficial'] ?? false,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      memberCount: memberCount ?? data['member_count'] as int? ?? 0,
      adminCount: adminCount ?? data['admin_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category.name,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'contactEmail': contactEmail,
      'instagramHandle': instagramHandle,
      'isApproved': isApproved,
      'isOfficial': isOfficial,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  Club copyWith({
    String? id,
    String? name,
    String? description,
    ClubCategory? category,
    String? logoUrl,
    String? coverImageUrl,
    String? contactEmail,
    String? instagramHandle,
    bool? isApproved,
    bool? isOfficial,
    DateTime? createdAt,
    String? createdBy,
    int? memberCount,
    int? adminCount,
  }) {
    return Club(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      contactEmail: contactEmail ?? this.contactEmail,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      isApproved: isApproved ?? this.isApproved,
      isOfficial: isOfficial ?? this.isOfficial,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      memberCount: memberCount ?? this.memberCount,
      adminCount: adminCount ?? this.adminCount,
    );
  }

  /// Total members including admins (fetched via junction table)
  int get totalMembers => memberCount + adminCount;


}

/// Club post types
enum ClubPostType {
  announcement,
  event,
  recruitment,
  general;
  
  String get displayName {
    switch (this) {
      case ClubPostType.announcement:
        return 'Announcement';
      case ClubPostType.event:
        return 'Event';
      case ClubPostType.recruitment:
        return 'Recruitment';
      case ClubPostType.general:
        return 'General';
    }
  }
}

/// Post within a club
class ClubPost {
  final String id;
  final String clubId;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final ClubPostType type;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isPinned;

  ClubPost({
    required this.id,
    required this.clubId,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.type,
    this.imageUrl,
    required this.createdAt,
    this.isPinned = false,
  });

  factory ClubPost.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return ClubPost(
      id: id ?? data['id'] ?? '',
      clubId: data['clubId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      type: ClubPostType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ClubPostType.general,
      ),
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clubId': clubId,
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'content': content,
      'type': type.name,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isPinned': isPinned,
    };
  }
}
