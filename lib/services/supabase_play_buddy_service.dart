import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/play_buddy/models/play_buddy_model.dart';

/// Supabase Service for Play Buddy / Teams feature
class SupabasePlayBuddyService extends ChangeNotifier {
  static final SupabasePlayBuddyService _instance = SupabasePlayBuddyService._internal();
  factory SupabasePlayBuddyService() => _instance;
  SupabasePlayBuddyService._internal();

  final _supabase = Supabase.instance.client;
  
  List<TeamRequest> _teams = [];
  bool _isLoading = false;
  String? _error;

  List<TeamRequest> get teams => _teams;
  // Model uses 'status' string ('open' etc). Map isActive to this logic.
  List<TeamRequest> get activeTeams => _teams.where((t) => t.status == 'open' && t.spotsLeft > 0).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all team requests
  Future<void> fetchTeams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from(SupabaseTables.teamRequests)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      _teams = (response as List).map((json) => _teamFromJson(json)).toList();
      AppLogger.success(' Fetched ${_teams.length} team requests');
    } catch (e) {
      _error = e.toString();
      AppLogger.error(' Error fetching teams: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new team request
  Future<String?> createTeam({
    required String creatorId,
    required String creatorName,
    required String title,
    String? description,
    required String category,
    String? eventName,
    DateTime? eventDate,
    int spotsTotal = 4,
    String skillLevel = 'any',
    String? requirements,
  }) async {
    try {
      final response = await _supabase.from(SupabaseTables.teamRequests).insert({
        'creator_id': creatorId,
        'creator_name': creatorName,
        'title': title,
        'description': description,
        'category': category,
        'event_name': eventName,
        'event_date': eventDate?.toIso8601String(),
        'spots_total': spotsTotal,
        'skill_level': skillLevel,
        'requirements': requirements,
      }).select().single();
      
      final teamId = response['id'] as String;
      
      // Add creator as first member
      await _supabase.from(SupabaseTables.teamMembers).insert({
        'team_id': teamId,
        'user_id': creatorId,
        'user_name': creatorName,
        'role': 'creator',
      });
      
      await fetchTeams();
      return teamId;
    } catch (e) {
      AppLogger.error(' Error creating team: $e');
      return null;
    }
  }

  /// Join a team
  Future<bool> joinTeam({
    required String teamId,
    required String userId,
    required String userName,
  }) async {
    try {
      await _supabase.from(SupabaseTables.teamMembers).insert({
        'team_id': teamId,
        'user_id': userId,
        'user_name': userName,
      });
      
      // Update spots filled
      await _supabase.rpc('increment_team_spots', params: {'team_id': teamId});
      await fetchTeams();
      return true;
    } catch (e) {
      AppLogger.error(' Error joining team: $e');
      return false;
    }
  }

  /// Leave a team
  Future<bool> leaveTeam(String teamId, String userId) async {
    try {
      await _supabase
          .from(SupabaseTables.teamMembers)
          .delete()
          .eq('team_id', teamId)
          .eq('user_id', userId);
      
      await fetchTeams();
      return true;
    } catch (e) {
      AppLogger.error(' Error leaving team: $e');
      return false;
    }
  }

  TeamRequest _teamFromJson(Map<String, dynamic> json) {
    // Map category string to Enum
    final categoryStr = json['category']?.toString() ?? 'other';
    final category = TeamCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == categoryStr.toLowerCase(),
      orElse: () => TeamCategory.other,
    );

    final isActive = json['is_active'] == true;
    
    // Map fields from DB to Model
    return TeamRequest(
      id: json['id']?.toString() ?? '',
      creatorId: json['creator_id']?.toString() ?? '',
      creatorName: json['creator_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: category,
      eventName: json['event_name']?.toString(),
      eventDate: json['event_date'] != null ? DateTime.tryParse(json['event_date'].toString()) : null,
      teamSize: json['spots_total'] as int? ?? 4,
      currentMembers: json['spots_filled'] as int? ?? 1,
      // Note: Member details not fetched in summary list, skipping arrays for now
      memberIds: [], 
      memberNames: [],
      // Map skill_level and requirements to requiredSkills list as best effort
      requiredSkills: [
        if (json['skill_level'] != null) json['skill_level'].toString(),
        if (json['requirements'] != null) json['requirements'].toString(),
      ],
      // No deadline in DB schema yet? Using event_date or now + 7 days
      deadline: json['event_date'] != null 
          ? DateTime.tryParse(json['event_date'].toString()) ?? DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
      status: isActive ? 'open' : 'closed',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Global singleton instance
final supabasePlayBuddyService = SupabasePlayBuddyService();