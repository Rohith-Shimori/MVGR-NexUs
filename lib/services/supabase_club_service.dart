import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../features/clubs/models/club_model.dart';

/// Production-ready Supabase service for Clubs
/// Uses proper junction table (club_members) for membership
class SupabaseClubService extends ChangeNotifier {
  static final SupabaseClubService _instance = SupabaseClubService._internal();
  static SupabaseClubService get instance => _instance;
  factory SupabaseClubService() => _instance;
  SupabaseClubService._internal();

  final _supabase = Supabase.instance.client;
  
  List<Club> _clubs = [];
  bool _isLoading = false;
  String? _error;

  List<Club> get clubs => _clubs;
  List<Club> get approvedClubs => _clubs.where((c) => c.isApproved).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all clubs from Supabase
  Future<void> fetchClubs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('clubs')
          .select()
          .order('created_at', ascending: false);

      _clubs = (response as List).map((json) => _clubFromJson(json)).toList();
      debugPrint('✅ Fetched ${_clubs.length} clubs from Supabase');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error fetching clubs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get club by ID
  Club? getClubById(String id) {
    try {
      return _clubs.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get clubs where user is a member (using junction table)
  Future<List<Club>> getMyClubs(String userId) async {
    try {
      // Query club_members junction table to find user's clubs
      final membershipResponse = await _supabase
          .from('club_members')
          .select('club_id')
          .eq('user_id', userId);

      final clubIds = (membershipResponse as List)
          .map((m) => m['club_id'] as String)
          .toList();

      if (clubIds.isEmpty) return [];

      // Fetch those clubs
      final clubsResponse = await _supabase
          .from('clubs')
          .select()
          .inFilter('id', clubIds);

      return (clubsResponse as List).map((json) => _clubFromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting my clubs: $e');
      return [];
    }
  }

  /// Get clubs where user is an admin
  Future<List<Club>> getAdminClubs(String userId) async {
    try {
      final membershipResponse = await _supabase
          .from('club_members')
          .select('club_id')
          .eq('user_id', userId)
          .inFilter('role', ['admin', 'owner']);

      final clubIds = (membershipResponse as List)
          .map((m) => m['club_id'] as String)
          .toList();

      if (clubIds.isEmpty) return [];

      final clubsResponse = await _supabase
          .from('clubs')
          .select()
          .inFilter('id', clubIds);

      return (clubsResponse as List).map((json) => _clubFromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting admin clubs: $e');
      return [];
    }
  }

  /// Check if user is a member of a club
  Future<bool> isMember(String clubId, String userId) async {
    try {
      final response = await _supabase
          .from('club_members')
          .select('id')
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('❌ Error checking membership: $e');
      return false;
    }
  }

  /// Check if user is an admin of a club
  Future<bool> isAdmin(String clubId, String userId) async {
    try {
      final response = await _supabase
          .from('club_members')
          .select('id')
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .inFilter('role', ['admin', 'owner'])
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
      return false;
    }
  }

  /// Join a club (insert into junction table)
  Future<bool> joinClub(String clubId, String userId, String userName) async {
    try {
      await _supabase.from('club_members').insert({
        'club_id': clubId,
        'user_id': userId,
        'user_name': userName,
        'role': 'member',
      });
      debugPrint('✅ User joined club: $clubId');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error joining club: $e');
      return false;
    }
  }

  /// Leave a club (delete from junction table)
  Future<bool> leaveClub(String clubId, String userId) async {
    try {
      await _supabase
          .from('club_members')
          .delete()
          .eq('club_id', clubId)
          .eq('user_id', userId);
      debugPrint('✅ User left club: $clubId');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error leaving club: $e');
      return false;
    }
  }

  /// Get member count for a club
  Future<int> getMemberCount(String clubId) async {
    try {
      final response = await _supabase
          .from('club_members')
          .select('id')
          .eq('club_id', clubId);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Create a new club
  Future<String?> createClub({
    required String name,
    required String description,
    required String category,
    required String creatorId,
    String? logoUrl,
    String? coverImageUrl,
    String? contactEmail,
    String? instagramHandle,
  }) async {
    try {
      // Insert club
      final clubResponse = await _supabase.from('clubs').insert({
        'name': name,
        'description': description,
        'category': category,
        'logo_url': logoUrl,
        'cover_image_url': coverImageUrl,
        'contact_email': contactEmail,
        'instagram_handle': instagramHandle,
        'is_approved': false,
        'is_official': false,
        'created_by': creatorId,
      }).select().single();

      final clubId = clubResponse['id'] as String;

      // Add creator as owner in junction table
      await _supabase.from('club_members').insert({
        'club_id': clubId,
        'user_id': creatorId,
        'role': 'owner',
      });

      debugPrint('✅ Club created: $name');
      await fetchClubs(); // Refresh list
      return clubId;
    } catch (e) {
      debugPrint('❌ Error creating club: $e');
      return null;
    }
  }

  /// Update a club
  Future<bool> updateClub(String clubId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('clubs').update(updates).eq('id', clubId);
      debugPrint('✅ Club updated: $clubId');
      await fetchClubs();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating club: $e');
      return false;
    }
  }

  /// Delete a club
  Future<bool> deleteClub(String clubId) async {
    try {
      await _supabase.from('clubs').delete().eq('id', clubId);
      debugPrint('✅ Club deleted: $clubId');
      await fetchClubs();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting club: $e');
      return false;
    }
  }

  /// Convert JSON to Club model
  Club _clubFromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: ClubCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ClubCategory.other,
      ),
      adminIds: [], // Not used with junction tables
      memberIds: [], // Not used with junction tables
      logoUrl: json['logo_url']?.toString(),
      coverImageUrl: json['cover_image_url']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      instagramHandle: json['instagram_handle']?.toString(),
      isApproved: json['is_approved'] == true,
      isOfficial: json['is_official'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      createdBy: json['created_by']?.toString() ?? '',
    );
  }
}

/// Global singleton instance
final supabaseClubService = SupabaseClubService.instance;
