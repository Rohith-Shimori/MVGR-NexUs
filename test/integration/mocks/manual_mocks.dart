import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mvgr_nexus/features/auth/providers/auth_provider.dart';
import 'package:mvgr_nexus/services/supabase_event_service.dart';
import 'package:mvgr_nexus/services/supabase_radio_service.dart';
import 'package:mvgr_nexus/services/audio_service.dart';
import 'package:mvgr_nexus/features/events/models/event_model.dart';
import 'package:mvgr_nexus/domain/entities/user.dart';
import 'package:mvgr_nexus/services/supabase_club_service.dart';
import 'package:mvgr_nexus/services/supabase_announcement_service.dart';
import 'package:mvgr_nexus/services/supabase_vault_service.dart';
import 'package:mvgr_nexus/services/supabase_forum_service.dart';
import 'package:mvgr_nexus/services/supabase_meetups_service.dart';
import 'package:mvgr_nexus/services/favorites_service.dart';
import 'package:mvgr_nexus/features/clubs/models/club_model.dart';

// Mock AuthProvider
class MockAuthProvider extends Mock implements AuthProvider {
  User? _user;
  final bool _isLoading = false;
  
  @override
  User? get user => _user;
  set user(User? value) => _user = value;

  @override
  bool get isAuthenticated => _user != null;

  @override
  bool get isLoading => _isLoading;

  @override
  String get userName => _user?.name ?? 'Guest';

  @override
  String get userId => _user?.id ?? '';

  @override
  void addListener(VoidCallback listener) {
    super.noSuchMethod(Invocation.method(#addListener, [listener]));
  }

  @override
  void removeListener(VoidCallback listener) {
    super.noSuchMethod(Invocation.method(#removeListener, [listener]));
  }
}

// Manual Mock for SupabaseEventService
class MockSupabaseEventService extends Mock implements SupabaseEventService {
  List<Event> _events = [];
  
  @override
  List<Event> get events => _events;
  @override
  set events(List<Event> value) => _events = value;

  @override
  Future<List<Event>> getEvents({String? clubId, String? category}) async {
    return _events;
  }
  
  @override
  Future<int> getRsvpCount(String eventId) async => 0;

  @override
  Future<bool> hasRsvped(String eventId, String userId) async => false;

  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

// Manual Mock for SupabaseRadioService
class MockSupabaseRadioService extends Mock implements SupabaseRadioService {
  List<RadioTrack> _tracks = [];
  final bool _isLoading = false;

  @override
  List<RadioTrack> get tracks => _tracks;
  set tracks(List<RadioTrack> value) => _tracks = value;

  @override
  List<RadioTrack> get approvedTracks => _tracks; // Mock behavior: all are approved

  @override
  Set<String> get likedTrackIds => {};

  @override
  bool get isLoading => _isLoading;

  @override
  Future<void> fetchTracks() async {}

  @override
  Future<void> fetchLikedTracks(String userId) async {}

  @override
  Future<bool> toggleLike(String trackId, String userId) async => true;

  @override
  Future<void> incrementPlayCount(String trackId) async {}

  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

// Manual Mock for AudioService
class MockAudioService extends Mock implements AudioService {
  bool _isPlaying = false;
  AudioTrack? _currentTrack;
  final Duration _position = Duration.zero;
  final Duration _duration = Duration.zero;

  @override
  bool get isPlaying => _isPlaying;
  
  @override
  AudioTrack? get currentTrack => _currentTrack;
  
  @override
  Duration get position => _position;
  
  @override
  Duration get duration => _duration;
  
  @override
  String? get currentTrackTitle => _currentTrack?.name;

  @override
  Future<void> playTrack(AudioTrack track) async {
    _currentTrack = track;
    _isPlaying = true;
  }

  @override
  Future<void> playFromUrl(String url, {String? title, String? artist}) async {
    _currentTrack = AudioTrack(
       id: 'mock_id', 
       name: title ?? 'Unknown', 
       artistName: artist ?? 'Unknown', 
       assetPath: url
    );
    _isPlaying = true;
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
  }

  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

// --- Additional Mocks for Hermetic Testing ---

class MockSupabaseClubService extends Mock implements SupabaseClubService {
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  Future<void> fetchClubs() async {}
  
  final List<Club> _clubs = [];
  @override
  List<Club> get clubs => _clubs;
  
  @override 
  List<Club> get approvedClubs => _clubs;
}

class MockSupabaseAnnouncementService extends Mock implements SupabaseAnnouncementService {
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  Future<void> fetchAnnouncements() async {}
  
  @override
  List<Announcement> get announcements => [];
}

class MockSupabaseVaultService extends Mock implements SupabaseVaultService {
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class MockSupabaseForumService extends Mock implements SupabaseForumService {
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class MockSupabaseMeetupsService extends Mock implements SupabaseMeetupsService {
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class MockFavoritesService extends Mock implements FavoritesService {
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  Set<String> get favoriteClubs => {};
  Set<String> get favoriteEvents => {};
  @override 
  bool isClubFavorite(String id) => false;
  @override
  bool isEventFavorite(String id) => false;
}
