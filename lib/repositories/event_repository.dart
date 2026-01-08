/// Event Repository - Handles all event-related data operations
library;

import '../core/errors/result.dart';
import '../features/events/models/event_model.dart';
import '../models/event_registration_model.dart';
import '../config/supabase_config.dart';
import 'base_repository.dart';

/// Helper to build Event from JSON map
Event _eventFromJson(Map<String, dynamic> json) {
  return Event(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    clubId: json['clubId'] ?? json['club_id'],
    clubName: json['clubName'] ?? json['club_name'],
    authorId: json['authorId'] ?? json['author_id'] ?? '',
    authorName: json['authorName'] ?? json['author_name'] ?? '',
    eventDate: _parseDateTime(json['eventDate'] ?? json['event_date']),
    endDate: json['endDate'] != null || json['end_date'] != null 
        ? _parseDateTime(json['endDate'] ?? json['end_date']) 
        : null,
    venue: json['venue'] ?? '',
    venueDetails: json['venueDetails'] ?? json['venue_details'],
    maxParticipants: json['maxParticipants'] ?? json['max_participants'],
    rsvpIds: List<String>.from(json['rsvpIds'] ?? json['rsvp_ids'] ?? []),
    interestedIds: List<String>.from(json['interestedIds'] ?? json['interested_ids'] ?? []),
    category: EventCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => EventCategory.other,
    ),
    imageUrl: json['imageUrl'] ?? json['image_url'],
    registrationLink: json['registrationLink'] ?? json['registration_link'],
    requiresRegistration: json['requiresRegistration'] ?? json['requires_registration'] ?? false,
    isOnline: json['isOnline'] ?? json['is_online'] ?? false,
    meetingLink: json['meetingLink'] ?? json['meeting_link'],
    createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
  );
}

/// Helper to build EventRegistration from JSON map
EventRegistration _registrationFromJson(Map<String, dynamic> json) {
  return EventRegistration(
    id: json['id'] ?? '',
    eventId: json['eventId'] ?? json['event_id'] ?? '',
    eventTitle: json['eventTitle'] ?? json['event_title'] ?? '',
    userId: json['userId'] ?? json['user_id'] ?? '',
    userName: json['userName'] ?? json['user_name'] ?? '',
    status: RegistrationStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => RegistrationStatus.registered,
    ),
    registeredAt: _parseDateTime(json['registeredAt'] ?? json['registered_at']),
    checkedInAt: json['checkedInAt'] != null || json['checked_in_at'] != null
        ? _parseDateTime(json['checkedInAt'] ?? json['checked_in_at']) 
        : null,
    formResponses: json['formResponses'] ?? json['form_responses'] != null 
        ? Map<String, dynamic>.from(json['formResponses'] ?? json['form_responses']) 
        : null,
  );
}

/// Helper to build Announcement from JSON map
Announcement _announcementFromJson(Map<String, dynamic> json) {
  return Announcement(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    authorId: json['authorId'] ?? json['author_id'] ?? '',
    authorName: json['authorName'] ?? json['author_name'] ?? '',
    authorRole: json['authorRole'] ?? json['author_role'] ?? '',
    isPinned: json['isPinned'] ?? json['is_pinned'] ?? false,
    isUrgent: json['isUrgent'] ?? json['is_urgent'] ?? false,
    createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
    expiresAt: json['expiresAt'] != null || json['expires_at'] != null 
        ? _parseDateTime(json['expiresAt'] ?? json['expires_at']) 
        : null,
  );
}

/// Parse DateTime from various formats
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

/// Repository for Event operations
class EventRepository extends BaseRepository<Event> {
  @override
  String get tableName => SupabaseTables.events;

  @override
  Map<String, dynamic> toJson(Event model) => model.toFirestore();

  @override
  Event fromJson(Map<String, dynamic> json) => _eventFromJson(json);

  @override
  String getId(Event model) => model.id;

  /// Get upcoming events
  Future<Result<List<Event>>> getUpcoming() async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .gte('eventDate', DateTime.now().toIso8601String())
          .order('eventDate', ascending: true);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Get past events
  Future<Result<List<Event>>> getPast() async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .lt('eventDate', DateTime.now().toIso8601String())
          .order('eventDate', ascending: false);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Get events by category
  Future<Result<List<Event>>> getByCategory(EventCategory category) async {
    return getByField('category', category.name);
  }

  /// Get events by club
  Future<Result<List<Event>>> getByClub(String clubId) async {
    return getByField('clubId', clubId);
  }

  /// Search events by title
  Future<Result<List<Event>>> searchByTitle(String query) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .ilike('title', '%$query%');

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}

/// Repository for Event Registrations
class EventRegistrationRepository extends BaseRepository<EventRegistration> {
  @override
  String get tableName => SupabaseTables.eventRegistrations;

  @override
  Map<String, dynamic> toJson(EventRegistration model) => model.toFirestore();

  @override
  EventRegistration fromJson(Map<String, dynamic> json) => _registrationFromJson(json);

  @override
  String getId(EventRegistration model) => model.id;

  /// Get registrations for event
  Future<Result<List<EventRegistration>>> getEventAttendees(String eventId) async {
    return getByField('eventId', eventId);
  }

  /// Get user's registration for an event
  Future<Result<EventRegistration?>> getUserRegistration(String eventId, String userId) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .eq('eventId', eventId)
          .eq('userId', userId)
          .maybeSingle();

      if (response == null) return null;
      return fromJson(response as Map<String, dynamic>);
    });
  }

  /// Check in attendee
  Future<Result<void>> checkIn(String eventId, String userId) async {
    return runCatchingAsync(() async {
      await client.from(tableName).update({
        'status': RegistrationStatus.checkedIn.name,
        'checkedInAt': DateTime.now().toIso8601String(),
      }).eq('eventId', eventId).eq('userId', userId);
    });
  }
}

/// Repository for Announcements
class AnnouncementRepository extends BaseRepository<Announcement> {
  @override
  String get tableName => SupabaseTables.announcements;

  @override
  Map<String, dynamic> toJson(Announcement model) => model.toFirestore();

  @override
  Announcement fromJson(Map<String, dynamic> json) => _announcementFromJson(json);

  @override
  String getId(Announcement model) => model.id;

  /// Get active announcements
  Future<Result<List<Announcement>>> getActive() async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .order('isPinned', ascending: false)
          .order('createdAt', ascending: false);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }
}
