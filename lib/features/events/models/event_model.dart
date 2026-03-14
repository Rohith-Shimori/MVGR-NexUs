import 'package:flutter/material.dart';


/// Event categories
enum EventCategory {
  academic,
  cultural,
  sports,
  hackathon,
  workshop,
  seminar,
  competition,
  other;
  
  String get displayName {
    switch (this) {
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.cultural:
        return 'Cultural';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.hackathon:
        return 'Hackathon';
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.seminar:
        return 'Seminar';
      case EventCategory.competition:
        return 'Competition';
      case EventCategory.other:
        return 'Other';
    }
  }
  
  String get icon {
    switch (this) {
      case EventCategory.academic:
        return '📖';
      case EventCategory.cultural:
        return '🎨';
      case EventCategory.sports:
        return '🏆';
      case EventCategory.hackathon:
        return '💻';
      case EventCategory.workshop:
        return '🛠️';
      case EventCategory.seminar:
        return '🎤';
      case EventCategory.competition:
        return '🏅';
      case EventCategory.other:
        return '📅';
    }
  }
  
  /// Material icon for premium UI
  IconData get iconData {
    switch (this) {
      case EventCategory.academic:
        return Icons.menu_book_rounded;
      case EventCategory.cultural:
        return Icons.palette_rounded;
      case EventCategory.sports:
        return Icons.emoji_events_rounded;
      case EventCategory.hackathon:
        return Icons.code_rounded;
      case EventCategory.workshop:
        return Icons.handyman_rounded;
      case EventCategory.seminar:
        return Icons.mic_rounded;
      case EventCategory.competition:
        return Icons.military_tech_rounded;
      case EventCategory.other:
        return Icons.event_rounded;
    }
  }
}

/// Event model for campus events
class Event {
  final String id;
  final String title;
  final String description;
  final String? clubId;  // null for college-wide events
  final String? clubName;
  final String authorId;
  final String authorName;
  final DateTime eventDate;
  final DateTime? endDate;  // for multi-day events
  final String venue;
  final String? venueDetails;  // Room number, building, etc.
  final int? maxParticipants;
  final List<String> rsvpIds;
  final List<String> interestedIds;
  final EventCategory category;
  final String? imageUrl;
  final String? registrationLink;
  final bool requiresRegistration;
  final bool isOnline;
  final String? meetingLink;
  final DateTime createdAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    this.clubId,
    this.clubName,
    required this.authorId,
    required this.authorName,
    required this.eventDate,
    this.endDate,
    required this.venue,
    this.venueDetails,
    this.maxParticipants,
    this.rsvpIds = const [],
    this.interestedIds = const [],
    required this.category,
    this.imageUrl,
    this.registrationLink,
    this.requiresRegistration = false,
    this.isOnline = false,
    this.meetingLink,
    required this.createdAt,
  });

  factory Event.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return Event(
      id: id ?? data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      clubId: data['clubId'],
      clubName: data['clubName'],
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      eventDate: data['eventDate'] != null ? DateTime.parse(data['eventDate']) : DateTime.now(),
      endDate: data['endDate'] != null ? DateTime.parse(data['endDate']) : null,
      venue: data['venue'] ?? '',
      venueDetails: data['venueDetails'],
      maxParticipants: data['maxParticipants'],
      rsvpIds: List<String>.from(data['rsvpIds'] ?? []),
      interestedIds: List<String>.from(data['interestedIds'] ?? []),
      category: EventCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => EventCategory.other,
      ),
      imageUrl: data['imageUrl'],
      registrationLink: data['registrationLink'],
      requiresRegistration: data['requiresRegistration'] ?? false,
      isOnline: data['isOnline'] ?? false,
      meetingLink: data['meetingLink'],
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'clubId': clubId,
      'clubName': clubName,
      'authorId': authorId,
      'authorName': authorName,
      'eventDate': eventDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'venue': venue,
      'venueDetails': venueDetails,
      'maxParticipants': maxParticipants,
      'rsvpIds': rsvpIds,
      'interestedIds': interestedIds,
      'category': category.name,
      'imageUrl': imageUrl,
      'registrationLink': registrationLink,
      'requiresRegistration': requiresRegistration,
      'isOnline': isOnline,
      'meetingLink': meetingLink,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? clubId,
    String? clubName,
    String? authorId,
    String? authorName,
    DateTime? eventDate,
    DateTime? endDate,
    String? venue,
    String? venueDetails,
    int? maxParticipants,
    List<String>? rsvpIds,
    List<String>? interestedIds,
    EventCategory? category,
    String? imageUrl,
    String? registrationLink,
    bool? requiresRegistration,
    bool? isOnline,
    String? meetingLink,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      clubId: clubId ?? this.clubId,
      clubName: clubName ?? this.clubName,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      eventDate: eventDate ?? this.eventDate,
      endDate: endDate ?? this.endDate,
      venue: venue ?? this.venue,
      venueDetails: venueDetails ?? this.venueDetails,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      rsvpIds: rsvpIds ?? this.rsvpIds,
      interestedIds: interestedIds ?? this.interestedIds,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      registrationLink: registrationLink ?? this.registrationLink,
      requiresRegistration: requiresRegistration ?? this.requiresRegistration,
      isOnline: isOnline ?? this.isOnline,
      meetingLink: meetingLink ?? this.meetingLink,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPast => eventDate.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return eventDate.year == now.year && 
           eventDate.month == now.month && 
           eventDate.day == now.day;
  }
  bool get isFull => maxParticipants != null && rsvpIds.length >= maxParticipants!;
  int get rsvpCount => rsvpIds.length;
  int get interestedCount => interestedIds.length;
  bool hasRSVP(String userId) => rsvpIds.contains(userId);
  bool isInterested(String userId) => interestedIds.contains(userId);


}

/// Announcement model for college-wide announcements
class Announcement {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String authorRole;  // "Student Council", "Faculty", etc.
  final bool isPinned;
  final bool isUrgent;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? imageUrl;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    this.isPinned = false,
    this.isUrgent = false,
    required this.createdAt,
    this.expiresAt,
    this.imageUrl,
  });

  factory Announcement.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return Announcement(
      id: id ?? data['id'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorRole: data['authorRole'] ?? '',
      isPinned: data['isPinned'] ?? false,
      isUrgent: data['isUrgent'] ?? false,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
      expiresAt: data['expiresAt'] != null ? DateTime.parse(data['expiresAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'isPinned': isPinned,
      'isUrgent': isUrgent,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());


}
