/// Supabase configuration and initialization
/// Initialize this in main.dart before running the app
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'environment.dart';

/// Supabase client configuration and initialization
class SupabaseConfig {
  static SupabaseClient? _client;

  /// Initialize Supabase - call this in main() before runApp()
  static Future<void> initialize() async {
    final config = AppConfig.current;
    
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
      debug: config.enableLogging,
    );
    
    _client = Supabase.instance.client;
  }

  /// Get the Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'Supabase not initialized. Call SupabaseConfig.initialize() in main().',
      );
    }
    return _client!;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _client != null;

  /// Get current auth user
  static User? get currentUser => client.auth.currentUser;

  /// Get current session
  static Session? get currentSession => client.auth.currentSession;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Auth state changes stream
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}

/// Table names in Supabase database
class SupabaseTables {
  static const String users = 'users';
  static const String clubs = 'clubs';
  static const String clubPosts = 'club_posts';
  static const String clubJoinRequests = 'club_join_requests';
  static const String events = 'events';
  static const String eventRegistrations = 'event_registrations';
  static const String announcements = 'announcements';
  static const String forumQuestions = 'forum_questions';
  static const String forumAnswers = 'forum_answers';
  static const String vaultItems = 'vault_items';
  static const String lostFoundItems = 'lost_found_items';
  static const String lostFoundClaims = 'lost_found_claims';
  static const String studyRequests = 'study_requests';
  static const String studyMatches = 'study_matches';
  static const String teamRequests = 'team_requests';
  static const String teamJoinRequests = 'team_join_requests';
  static const String mentors = 'mentors';
  static const String mentorshipRequests = 'mentorship_requests';
  static const String meetups = 'meetups';
  static const String radioSessions = 'radio_sessions';
  static const String reports = 'reports';
}

/// Storage bucket names
class SupabaseBuckets {
  static const String profilePhotos = 'profile-photos';
  static const String clubLogos = 'club-logos';
  static const String eventImages = 'event-images';
  static const String vaultFiles = 'vault-files';
  static const String lostFoundImages = 'lost-found-images';
}
