import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for Mentor
class Mentor {
  final String id;
  final String userId;
  final String name;
  final String? bio;
  final String? profileImageUrl;
  final String mentorType;
  final List<String> expertise;
  final String? company;
  final String? position;
  final String? linkedinUrl;
  final String? availability;
  final int sessionDurationMinutes;
  final bool isAvailable;
  final double rating;
  final int totalSessions;
  final DateTime createdAt;

  Mentor({
    required this.id,
    required this.userId,
    required this.name,
    this.bio,
    this.profileImageUrl,
    required this.mentorType,
    this.expertise = const [],
    this.company,
    this.position,
    this.linkedinUrl,
    this.availability,
    this.sessionDurationMinutes = 30,
    this.isAvailable = true,
    this.rating = 0,
    this.totalSessions = 0,
    required this.createdAt,
  });
}

/// Model for Mentorship Session
class MentorshipSession {
  final String id;
  final String mentorId;
  final String menteeId;
  final String menteeName;
  final String topic;
  final String? description;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status;
  final String? meetingLink;
  final String? notes;
  final int? rating;
  final String? feedback;
  final DateTime createdAt;

  MentorshipSession({
    required this.id,
    required this.mentorId,
    required this.menteeId,
    required this.menteeName,
    required this.topic,
    this.description,
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.status = 'pending',
    this.meetingLink,
    this.notes,
    this.rating,
    this.feedback,
    required this.createdAt,
  });
}

/// Supabase Service for Mentorship feature
class SupabaseMentorshipService extends ChangeNotifier {
  static final SupabaseMentorshipService _instance = SupabaseMentorshipService._internal();
  factory SupabaseMentorshipService() => _instance;
  SupabaseMentorshipService._internal();

  final _supabase = Supabase.instance.client;
  
  List<Mentor> _mentors = [];
  List<MentorshipSession> _sessions = [];
  bool _isLoading = false;
  String? _error;

  List<Mentor> get mentors => _mentors;
  List<Mentor> get availableMentors => _mentors.where((m) => m.isAvailable).toList();
  List<MentorshipSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all mentors
  Future<void> fetchMentors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from(SupabaseTables.mentors)
          .select()
          .eq('is_available', true)
          .order('rating', ascending: false);

      _mentors = (response as List).map((json) => _mentorFromJson(json)).toList();
      AppLogger.success(' Fetched ${_mentors.length} mentors');
    } catch (e) {
      _error = e.toString();
      AppLogger.error(' Error fetching mentors: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch sessions for a user (as mentee)
  Future<void> fetchMySessions(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.mentorshipSessions)
          .select()
          .eq('mentee_id', userId)
          .order('scheduled_at', ascending: true);

      _sessions = (response as List).map((json) => _sessionFromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      AppLogger.error(' Error fetching sessions: $e');
    }
  }

  /// Book a session with a mentor
  Future<bool> bookSession({
    required String mentorId,
    required String menteeId,
    required String menteeName,
    required String topic,
    String? description,
    required DateTime scheduledAt,
    int durationMinutes = 30,
  }) async {
    try {
      await _supabase.from(SupabaseTables.mentorshipSessions).insert({
        'mentor_id': mentorId,
        'mentee_id': menteeId,
        'mentee_name': menteeName,
        'topic': topic,
        'description': description,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration_minutes': durationMinutes,
      });
      await fetchMySessions(menteeId);
      return true;
    } catch (e) {
      AppLogger.error(' Error booking session: $e');
      return false;
    }
  }

  /// Confirm a session (mentor action)
  Future<bool> confirmSession(String sessionId, String? meetingLink) async {
    try {
      await _supabase.from(SupabaseTables.mentorshipSessions).update({
        'status': 'confirmed',
        'meeting_link': meetingLink,
      }).eq('id', sessionId);
      return true;
    } catch (e) {
      AppLogger.error(' Error confirming session: $e');
      return false;
    }
  }

  /// Complete a session and add feedback
  Future<bool> completeSession({
    required String sessionId,
    String? notes,
    int? rating,
    String? feedback,
  }) async {
    try {
      await _supabase.from(SupabaseTables.mentorshipSessions).update({
        'status': 'completed',
        'notes': notes,
        'rating': rating,
        'feedback': feedback,
      }).eq('id', sessionId);
      return true;
    } catch (e) {
      AppLogger.error(' Error completing session: $e');
      return false;
    }
  }

  /// Cancel a session
  Future<bool> cancelSession(String sessionId) async {
    try {
      await _supabase.from(SupabaseTables.mentorshipSessions).update({
        'status': 'cancelled',
      }).eq('id', sessionId);
      return true;
    } catch (e) {
      AppLogger.error(' Error cancelling session: $e');
      return false;
    }
  }

  /// Register as a mentor
  Future<bool> registerAsMentor({
    required String userId,
    required String name,
    String? bio,
    String? profileImageUrl,
    required String mentorType,
    List<String> expertise = const [],
    String? company,
    String? position,
    String? linkedinUrl,
    String? availability,
    int sessionDurationMinutes = 30,
  }) async {
    try {
      await _supabase.from(SupabaseTables.mentors).insert({
        'user_id': userId,
        'name': name,
        'bio': bio,
        'profile_image_url': profileImageUrl,
        'mentor_type': mentorType,
        'expertise': expertise,
        'company': company,
        'position': position,
        'linkedin_url': linkedinUrl,
        'availability': availability,
        'session_duration_minutes': sessionDurationMinutes,
      });
      await fetchMentors();
      return true;
    } catch (e) {
      AppLogger.error(' Error registering as mentor: $e');
      return false;
    }
  }

  Mentor _mentorFromJson(Map<String, dynamic> json) {
    return Mentor(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bio: json['bio']?.toString(),
      profileImageUrl: json['profile_image_url']?.toString(),
      mentorType: json['mentor_type']?.toString() ?? 'senior',
      expertise: List<String>.from(json['expertise'] ?? []),
      company: json['company']?.toString(),
      position: json['position']?.toString(),
      linkedinUrl: json['linkedin_url']?.toString(),
      availability: json['availability']?.toString(),
      sessionDurationMinutes: json['session_duration_minutes'] as int? ?? 30,
      isAvailable: json['is_available'] == true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  MentorshipSession _sessionFromJson(Map<String, dynamic> json) {
    return MentorshipSession(
      id: json['id']?.toString() ?? '',
      mentorId: json['mentor_id']?.toString() ?? '',
      menteeId: json['mentee_id']?.toString() ?? '',
      menteeName: json['mentee_name']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      description: json['description']?.toString(),
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? '') ?? DateTime.now(),
      durationMinutes: json['duration_minutes'] as int? ?? 30,
      status: json['status']?.toString() ?? 'pending',
      meetingLink: json['meeting_link']?.toString(),
      notes: json['notes']?.toString(),
      rating: json['rating'] as int?,
      feedback: json['feedback']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Global singleton instance
final supabaseMentorshipService = SupabaseMentorshipService();