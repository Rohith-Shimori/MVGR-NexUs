import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../features/events/models/event_model.dart';

/// Production-ready Supabase service for Events
/// Uses proper junction table (event_rsvps) for RSVPs
class SupabaseEventService extends ChangeNotifier {
  static final SupabaseEventService _instance = SupabaseEventService._internal();
  static SupabaseEventService get instance => _instance;
  factory SupabaseEventService() => _instance;
  SupabaseEventService._internal();

  final _supabase = Supabase.instance.client;
  
  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  List<Event> get upcomingEvents => _events
      .where((e) => e.eventDate.isAfter(DateTime.now()))
      .toList()
    ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  List<Event> get pastEvents => _events
      .where((e) => e.eventDate.isBefore(DateTime.now()))
      .toList()
    ..sort((a, b) => b.eventDate.compareTo(a.eventDate));
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all events from Supabase
  Future<void> fetchEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('events')
          .select()
          .order('event_date', ascending: true);

      _events = (response as List).map((json) => _eventFromJson(json)).toList();
      debugPrint('✅ Fetched ${_events.length} events from Supabase');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error fetching events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get event by ID
  Event? getEventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get events user has RSVP'd to (using junction table)
  Future<List<Event>> getMyEvents(String userId) async {
    try {
      final rsvpResponse = await _supabase
          .from('event_rsvps')
          .select('event_id')
          .eq('user_id', userId)
          .inFilter('status', ['going', 'interested']);

      final eventIds = (rsvpResponse as List)
          .map((r) => r['event_id'] as String)
          .toList();

      if (eventIds.isEmpty) return [];

      final eventsResponse = await _supabase
          .from('events')
          .select()
          .inFilter('id', eventIds)
          .order('event_date', ascending: true);

      return (eventsResponse as List).map((json) => _eventFromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting my events: $e');
      return [];
    }
  }

  /// Check if user has RSVP'd to an event
  Future<bool> hasRsvp(String eventId, String userId) async {
    try {
      final response = await _supabase
          .from('event_rsvps')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('❌ Error checking RSVP: $e');
      return false;
    }
  }

  /// Get RSVP status for a user
  Future<String?> getRsvpStatus(String eventId, String userId) async {
    try {
      final response = await _supabase
          .from('event_rsvps')
          .select('status')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();
      
      return response?['status'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// RSVP to an event (insert into junction table)
  Future<bool> rsvpEvent({
    required String eventId,
    required String userId,
    required String userName,
    String status = 'going',
    Map<String, dynamic>? formResponses,
  }) async {
    try {
      await _supabase.from('event_rsvps').upsert({
        'event_id': eventId,
        'user_id': userId,
        'user_name': userName,
        'status': status,
        'form_responses': formResponses,
      });
      debugPrint('✅ RSVP added: $eventId');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error adding RSVP: $e');
      return false;
    }
  }

  /// Remove RSVP from an event
  Future<bool> removeRsvp(String eventId, String userId) async {
    try {
      await _supabase
          .from('event_rsvps')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      debugPrint('✅ RSVP removed: $eventId');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error removing RSVP: $e');
      return false;
    }
  }

  /// Get RSVP count for an event
  Future<int> getRsvpCount(String eventId) async {
    try {
      final response = await _supabase
          .from('event_rsvps')
          .select('id')
          .eq('event_id', eventId)
          .eq('status', 'going');
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get all RSVPs for an event (for event organizer)
  Future<List<Map<String, dynamic>>> getEventRsvps(String eventId) async {
    try {
      final response = await _supabase
          .from('event_rsvps')
          .select()
          .eq('event_id', eventId)
          .order('rsvp_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting event RSVPs: $e');
      return [];
    }
  }

  /// Check in an attendee
  Future<bool> checkInAttendee(String eventId, String userId) async {
    try {
      await _supabase
          .from('event_rsvps')
          .update({
            'status': 'checked_in',
            'checked_in_at': DateTime.now().toIso8601String(),
          })
          .eq('event_id', eventId)
          .eq('user_id', userId);
      debugPrint('✅ Attendee checked in');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking in: $e');
      return false;
    }
  }

  /// Create a new event
  Future<String?> createEvent({
    required String title,
    required String description,
    required String authorId,
    required String authorName,
    required DateTime eventDate,
    required String venue,
    required String category,
    String? clubId,
    String? clubName,
    DateTime? endDate,
    String? imageUrl,
    String? registrationLink,
    bool requiresRegistration = false,
    bool isOnline = false,
    String? meetingLink,
    int? maxCapacity,
  }) async {
    try {
      final response = await _supabase.from('events').insert({
        'title': title,
        'description': description,
        'author_id': authorId,
        'author_name': authorName,
        'event_date': eventDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'venue': venue,
        'category': category,
        'club_id': clubId,
        'club_name': clubName,
        'image_url': imageUrl,
        'registration_link': registrationLink,
        'requires_registration': requiresRegistration,
        'is_online': isOnline,
        'meeting_link': meetingLink,
        'max_capacity': maxCapacity,
      }).select().single();

      debugPrint('✅ Event created: $title');
      await fetchEvents();
      return response['id'] as String;
    } catch (e) {
      debugPrint('❌ Error creating event: $e');
      return null;
    }
  }

  /// Update an event
  Future<bool> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('events').update(updates).eq('id', eventId);
      debugPrint('✅ Event updated: $eventId');
      await fetchEvents();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating event: $e');
      return false;
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);
      debugPrint('✅ Event deleted: $eventId');
      await fetchEvents();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting event: $e');
      return false;
    }
  }

  /// Convert JSON to Event model
  Event _eventFromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      clubId: json['club_id']?.toString(),
      clubName: json['club_name']?.toString(),
      authorId: json['author_id']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? '',
      eventDate: DateTime.tryParse(json['event_date']?.toString() ?? '') ?? DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'].toString()) : null,
      venue: json['venue']?.toString() ?? '',
      venueDetails: json['venue_details']?.toString(),
      maxParticipants: json['max_capacity'] as int?,
      rsvpIds: [], // Not used with junction tables
      interestedIds: [], // Not used with junction tables
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
    );
  }
}

/// Global singleton instance
final supabaseEventService = SupabaseEventService.instance;
