import 'dart:io';
import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/events/models/event_model.dart';

/// Service for managing events via Supabase
class SupabaseEventService extends ChangeNotifier {
  static final SupabaseEventService _instance = SupabaseEventService._internal();
  factory SupabaseEventService() => _instance;
  SupabaseEventService._internal();

  SupabaseClient? _clientOverride;
  SupabaseClient get _supabase => _clientOverride ?? Supabase.instance.client;

  @visibleForTesting
  set client(SupabaseClient client) => _clientOverride = client;
  
  List<Event> _events = [];
  
  /// Get cached events list
  List<Event> get events => _events;

  @visibleForTesting
  set events(List<Event> value) {
    _events = value;
    notifyListeners();
  }

  /// Get formatted error message
  String? get error => _error;
  String? _error;

  /// Get all events, optionally filtered
  Future<List<Event>> getEvents({String? clubId, String? category}) async {
    try {
      var query = _supabase.from(SupabaseTables.events).select();

      if (clubId != null) {
        query = query.eq('club_id', clubId);
      }
      
      if (category != null) {
        query = query.eq('category', category);
      }

      // Order by date
      final response = await query.order('event_date', ascending: true);
      
      final fetchedEvents = (response as List).map((json) => _eventFromJson(json)).toList();
      
      // Update cache if no filters applied
      if (clubId == null && category == null) {
        _events = fetchedEvents;
        notifyListeners();
      }
      
      return fetchedEvents;
    } catch (e) {
      AppLogger.error(' Error fetching events: $e');
      _error = 'Failed to fetch events';
      return [];
    }
  }

  /// Get single event by ID
  Future<Event?> getEventById(String id) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.events)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return _eventFromJson(response);
    } catch (e) {
      AppLogger.error(' Error fetching event $id: $e');
      return null;
    }
  }

  /// Create a new event
  Future<bool> createEvent(Event event) async {
    try {
      final data = _eventToJson(event);
      // Remove ID to let DB generate it
      data.remove('id');
      
      await _supabase.from(SupabaseTables.events).insert(data);
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error creating event: $e');
      _error = e.toString();
      return false;
    }
  }

  /// Update an existing event
  Future<bool> updateEvent(Event event) async {
    try {
      final data = _eventToJson(event);
      data.remove('id'); // ID cannot be updated
      data.remove('created_at'); // CreatedAt cannot be updated
      
      await _supabase
          .from(SupabaseTables.events)
          .update(data)
          .eq('id', event.id);
      
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error updating event: $e');
      _error = e.toString();
      return false;
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _supabase
          .from(SupabaseTables.events)
          .delete()
          .eq('id', eventId);
      
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error deleting event: $e');
      return false;
    }
  }

  /// Upload event image
  Future<String?> uploadEventImage(File file) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = fileName;

      await _supabase.storage.from(SupabaseTables.events).upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final imageUrl = _supabase.storage.from(SupabaseTables.events).getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      AppLogger.error(' Error uploading event image: $e');
      return null;
    }
  }

  /// RSVP to an event
  Future<bool> rsvpToEvent(String eventId, String userId, {String status = 'going'}) async {
    try {
      await _supabase.from(SupabaseTables.eventRsvps).upsert({
        'event_id': eventId,
        'user_id': userId,
        'status': status,
      });
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error RSVPing: $e');
      return false;
    }
  }

  /// Cancel RSVP
  Future<bool> cancelRsvp(String eventId, String userId) async {
    try {
      await _supabase
          .from(SupabaseTables.eventRsvps)
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error canceling RSVP: $e');
      return false;
    }
  }

  /// Check if user has RSVPed
  Future<bool> hasRsvped(String eventId, String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.eventRsvps)
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Get RSVP count
  Future<int> getRsvpCount(String eventId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.eventRsvps)
          .count()
          .eq('event_id', eventId)
          .eq('status', 'going');
      return response;
    } catch (e) {
      return 0;
    }
  }

  /// Get events user has RSVPed to
  Future<List<Event>> getUserEvents(String userId, {bool isPast = false}) async {
    try {
      // Get event IDs from RSVP
      final rsvpResponse = await _supabase
          .from(SupabaseTables.eventRsvps)
          .select('event_id')
          .eq('user_id', userId)
          .eq('status', 'going');
          
      final eventIds = (rsvpResponse as List).map((r) => r['event_id'] as String).toList();
      
      if (eventIds.isEmpty) return [];

      // Fetch events
      var query = _supabase.from(SupabaseTables.events).select().inFilter('id', eventIds);
      
      if (isPast) {
        query = query.lt('event_date', DateTime.now().toIso8601String());
      } else {
        query = query.gte('event_date', DateTime.now().toIso8601String());
      }

      final response = await query.order('event_date', ascending: !isPast); // Ascending for upcoming, descending might be better for past but typically lists are cronological or reverse.
      // Actually standard is upcoming: nearest first (asc). Past: most recent first (desc).
      // But query.order only takes one direction. 
      // Let's stick to simple sort for now or handle in memory if tricky.
      // Applying order directly.
      
      return (response as List).map((json) => _eventFromJson(json)).toList();
    } catch (e) {
      AppLogger.error(' Error fetching user events: $e');
      return [];
    }
  }

  // Helpers

  Event _eventFromJson(Map<String, dynamic> json) {
  return Event(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    clubId: json['club_id']?.toString(),
    clubName: json['club_name']?.toString(),
    authorId: json['author_id']?.toString() ?? '',
    authorName: json['author_name']?.toString() ?? 'Organizer',
    eventDate: DateTime.tryParse(json['event_date']?.toString() ?? '') ?? DateTime.now(),
    endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'].toString()) : null,
    venue: json['venue']?.toString() ?? '',
    venueDetails: json['venue_details']?.toString(),
    maxParticipants: json['max_participants'] as int?,
    category: EventCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => EventCategory.other,
    ),
    imageUrl: json['image_url']?.toString(),
    registrationLink: json['registration_link']?.toString(),
    requiresRegistration: json['requires_registration'] == true,
    isOnline: json['is_online'] == true,
    meetingLink: json['meeting_link']?.toString(),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    rsvpIds: List<String>.from(json['rsvp_ids'] ?? []),
    interestedIds: List<String>.from(json['interested_ids'] ?? []),
  );
}

  Map<String, dynamic> _eventToJson(Event event) {
    return {
      'id': event.id.isEmpty ? null : event.id,
      'title': event.title,
      'description': event.description,
      'club_id': event.clubId,
      'club_name': event.clubName,
      'author_id': event.authorId,
      'author_name': event.authorName,
      'event_date': event.eventDate.toIso8601String(),
      'end_date': event.endDate?.toIso8601String(),
      'venue': event.venue,
      'venue_details': event.venueDetails,
      'max_participants': event.maxParticipants,
      'category': event.category.name,
      'image_url': event.imageUrl,
      'registration_link': event.registrationLink,
      'requires_registration': event.requiresRegistration,
      'is_online': event.isOnline,
      'meeting_link': event.meetingLink,
    };
  }
}

final supabaseEventService = SupabaseEventService();
