import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/study_buddy/models/study_buddy_model.dart';

/// Supabase Service for Study Buddy feature
class SupabaseStudyBuddyService extends ChangeNotifier {
  static final SupabaseStudyBuddyService _instance = SupabaseStudyBuddyService._internal();
  factory SupabaseStudyBuddyService() => _instance;
  SupabaseStudyBuddyService._internal();

  final _supabase = Supabase.instance.client;
  
  List<StudyRequest> _requests = [];
  bool _isLoading = false;
  String? _error;

  List<StudyRequest> get requests => _requests;
  List<StudyRequest> get activeRequests => _requests.where((r) => r.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all study requests
  Future<void> fetchRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from(SupabaseTables.studyRequests)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      _requests = (response as List).map((json) => _requestFromJson(json)).toList();
      AppLogger.success('Fetched ${_requests.length} study requests');
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error fetching study requests', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new study request
  Future<bool> createRequest({
    required String userId,
    required String userName,
    required String subject,
    required String topic,
    String? description,
    StudyMode preferredMode = StudyMode.inPerson,
    String? preferredTime,
    String skillLevel = 'intermediate',
    int maxGroupSize = 4,
    String? location,
  }) async {
    try {
      await _supabase.from(SupabaseTables.studyRequests).insert({
        'user_id': userId,
        'user_name': userName,
        'subject': subject,
        'topic': topic,
        'description': description,
        'preferred_mode': preferredMode.name,
        'preferred_time': preferredTime,
        'skill_level': skillLevel,
        'max_group_size': maxGroupSize,
        'location': location,
      });
      await fetchRequests();
      return true;
    } catch (e) {
      AppLogger.error('Error creating study request', e);
      return false;
    }
  }

  /// Respond to a study request
  Future<bool> respondToRequest({
    required String requestId,
    required String responderId,
    required String responderName,
    String? message,
  }) async {
    try {
      await _supabase.from(SupabaseTables.studyRequestResponses).insert({
        'request_id': requestId,
        'responder_id': responderId,
        'responder_name': responderName,
        'message': message,
      });
      return true;
    } catch (e) {
      AppLogger.error('Error responding to request', e);
      return false;
    }
  }

  /// Delete a study request
  Future<bool> deleteRequest(String requestId) async {
    try {
      await _supabase.from(SupabaseTables.studyRequests).delete().eq('id', requestId);
      await fetchRequests();
      return true;
    } catch (e) {
      AppLogger.error('Error deleting request', e);
      return false;
    }
  }

  StudyRequest _requestFromJson(Map<String, dynamic> json) {
    // Map preferredMode string to Enum
    final modeStr = json['preferred_mode']?.toString() ?? 'hybrid';
    final preferredMode = StudyMode.values.firstWhere(
      (m) => m.name == modeStr || m.displayName.toLowerCase() == modeStr.toLowerCase(),
      orElse: () => StudyMode.hybrid,
    );

    // Map isActive boolean to RequestStatus Enum
    final isActive = json['is_active'] == true;
    final status = isActive ? RequestStatus.active : RequestStatus.cancelled;

    return StudyRequest(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      preferredMode: preferredMode,
      preferredLocation: json['location']?.toString(), // Mapped from 'location'
      availableDays: [], // Not stored in simple migration yet
      preferredTime: json['preferred_time']?.toString(),
      status: status,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 14)),
    );
  }
}

/// Global singleton instance
final supabaseStudyBuddyService = SupabaseStudyBuddyService();