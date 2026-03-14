import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/offline_community/models/meetup_model.dart';

/// Supabase Service for Meetups feature
class SupabaseMeetupsService extends ChangeNotifier {
  static final SupabaseMeetupsService _instance = SupabaseMeetupsService._internal();
  factory SupabaseMeetupsService() => _instance;
  SupabaseMeetupsService._internal();

  final _supabase = Supabase.instance.client;
  
  List<Meetup> _meetups = [];
  bool _isLoading = false;
  String? _error;

  List<Meetup> get meetups => _meetups;
  // Use a string comparison if status is a string in the model, or check boolean active
  List<Meetup> get upcomingMeetups => _meetups.where((m) => m.isActive && !m.isPast).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all meetups
  Future<void> fetchMeetups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from(SupabaseTables.meetups)
          .select()
          .gte('date_time', DateTime.now().toIso8601String())
          .order('date_time', ascending: true);

      _meetups = (response as List).map((json) => _meetupFromJson(json)).toList();
      AppLogger.success(' Fetched ${_meetups.length} meetups');
    } catch (e) {
      _error = e.toString();
      AppLogger.error(' Error fetching meetups: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new meetup
  Future<String?> createMeetup({
    required String creatorId,
    required String creatorName,
    required String title,
    String? description,
    required String category,
    required String venue,
    String? venueDetails,
    required DateTime dateTime,
    DateTime? endTime,
    int? maxParticipants,
    String? imageUrl,
  }) async {
    try {
      final response = await _supabase.from(SupabaseTables.meetups).insert({
        'creator_id': creatorId,
        'creator_name': creatorName,
        'title': title,
        'description': description,
        'category': category,
        'venue': venue,
        'venue_details': venueDetails,
        'date_time': dateTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'max_participants': maxParticipants,
        'image_url': imageUrl,
      }).select().single();
      
      final meetupId = response['id'] as String;
      
      // Add creator as participant
      await _supabase.from(SupabaseTables.meetupParticipants).insert({
        'meetup_id': meetupId,
        'user_id': creatorId,
        'user_name': creatorName,
        'status': 'going',
      });
      
      await fetchMeetups();
      return meetupId;
    } catch (e) {
      AppLogger.error(' Error creating meetup: $e');
      return null;
    }
  }

  /// Join a meetup
  Future<bool> joinMeetup({
    required String meetupId,
    required String userId,
    required String userName,
    String status = 'going',
  }) async {
    try {
      await _supabase.from(SupabaseTables.meetupParticipants).upsert({
        'meetup_id': meetupId,
        'user_id': userId,
        'user_name': userName,
        'status': status,
      });
      await fetchMeetups();
      return true;
    } catch (e) {
      AppLogger.error(' Error joining meetup: $e');
      return false;
    }
  }

  /// Leave a meetup
  Future<bool> leaveMeetup(String meetupId, String userId) async {
    try {
      await _supabase
          .from(SupabaseTables.meetupParticipants)
          .delete()
          .eq('meetup_id', meetupId)
          .eq('user_id', userId);
      await fetchMeetups();
      return true;
    } catch (e) {
      AppLogger.error(' Error leaving meetup: $e');
      return false;
    }
  }

  /// Cancel a meetup
  Future<bool> cancelMeetup(String meetupId) async {
    try {
      await _supabase.from(SupabaseTables.meetups).update({
        'status': 'cancelled',
      }).eq('id', meetupId);
      await fetchMeetups();
      return true;
    } catch (e) {
      AppLogger.error(' Error cancelling meetup: $e');
      return false;
    }
  }

  Meetup _meetupFromJson(Map<String, dynamic> json) {
    // Map string category to Enum
    final categoryStr = json['category']?.toString() ?? 'other';
    final category = MeetupCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == categoryStr.toLowerCase(),
      orElse: () => MeetupCategory.other,
    );

    // Map fields from DB to Model
    return Meetup(
      id: json['id']?.toString() ?? '',
      organizerId: json['creator_id']?.toString() ?? '',
      organizerName: json['creator_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: category,
      venue: json['venue']?.toString() ?? '',
      venueDetails: json['venue_details']?.toString(),
      scheduledAt: DateTime.tryParse(json['date_time']?.toString() ?? '') ?? DateTime.now(),
      duration: _calculateDuration(json['date_time'], json['end_time']),
      maxParticipants: json['max_participants'] as int?,
      // Note: current_participants is in JSON if using a view, or we might need to fetch separately. 
      // The model uses list<String> participantIds. 
      // For now, we assume simple mapping and might lose participant detail if not fetched.
      // Ideally we would fetch participants too.
      // But matching the MODEL from `meetup_model.dart`:
      // `participantIds` is List<String>.
      // The DB query `select()` doesn't join participants by default.
      // We'll leave participantIds empty for now unless we change query.
      participantIds: [], 
      isActive: (json['status']?.toString() ?? 'upcoming') != 'cancelled',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Duration _calculateDuration(dynamic startStr, dynamic endStr) {
    if (startStr == null || endStr == null) return const Duration(hours: 2);
    final start = DateTime.tryParse(startStr.toString());
    final end = DateTime.tryParse(endStr.toString());
    if (start != null && end != null) {
      return end.difference(start);
    }
    return const Duration(hours: 2);
  }
}

/// Global singleton instance
final supabaseMeetupsService = SupabaseMeetupsService();