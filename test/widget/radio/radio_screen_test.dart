import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:mvgr_nexus/features/radio/screens/radio_screen.dart';
import 'package:mvgr_nexus/services/supabase_radio_service.dart';
import 'package:mvgr_nexus/features/auth/providers/auth_provider.dart';
import 'package:mvgr_nexus/domain/entities/user.dart';
import 'package:mvgr_nexus/services/audio_service.dart';

import '../../helpers/test_helper.mocks.dart';

// Manual Mock for SupabaseRadioService
class MockSupabaseRadioService extends Mock implements SupabaseRadioService {
  List<RadioTrack> _approvedTracks = [];
  Set<String> _likedTrackIds = {};
  bool _isLoading = false;

  @override
  List<RadioTrack> get approvedTracks => _approvedTracks;
  set approvedTracks(List<RadioTrack> value) => _approvedTracks = value;

  @override
  Set<String> get likedTrackIds => _likedTrackIds;
  set likedTrackIds(Set<String> value) => _likedTrackIds = value;

  @override
  bool get isLoading => _isLoading;
  set isLoading(bool value) => _isLoading = value;

  @override
  Future<void> fetchTracks() async {}

  @override
  Future<void> fetchLikedTracks(String userId) async {}

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void notifyListeners() {}

  @override
  bool get hasListeners => false;
}

// Manual Mock for AudioService
class MockAudioService extends Mock implements AudioService {
  bool _isPlaying = false;
  String? _currentTrackTitle;
  
  @override
  bool get isPlaying => _isPlaying;
  set isPlaying(bool value) => _isPlaying = value;

  @override
  String? get currentTrackTitle => _currentTrackTitle;
  set currentTrackTitle(String? value) => _currentTrackTitle = value;

  @override
  Future<void> pause() async {}
  
  @override
  Future<void> playFromUrl(String url, {String? title, String? artist}) async {}
  
  @override
  void addListener(VoidCallback listener) {}
  
  @override
  void removeListener(VoidCallback listener) {}
  
  @override
  void notifyListeners() {}
  
  @override
  bool get hasListeners => false;
}

void main() {
  late MockSupabaseRadioService mockRadioService;
  late MockAudioService mockAudioService;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockRadioService = MockSupabaseRadioService();
    // Default values
    mockRadioService.approvedTracks = [];
    mockRadioService.likedTrackIds = {};
    mockRadioService.isLoading = false;

    mockAudioService = MockAudioService();
    mockAudioService.isPlaying = false;
    mockAudioService.currentTrackTitle = null;

    mockAuthProvider = MockAuthProvider();
    // ... auth setup ...
    final testUser = User(
      id: 'user_123',
      email: 'test@example.com',
      name: 'Test User',
      role: UserRole.student,
      department: 'CSE',
      year: 3,
      createdAt: DateTime.now(),
    );

    when(mockAuthProvider.user).thenReturn(testUser);
    when(mockAuthProvider.isLoading).thenReturn(false);
    when(mockAuthProvider.isAuthenticated).thenReturn(true);
    when(mockAuthProvider.addListener(any)).thenReturn(null);
    when(mockAuthProvider.removeListener(any)).thenReturn(null);
  });


  group('RadioScreen', () {
    testWidgets('renders RadioScreen header', (WidgetTester tester) async {
      // Set screen size to avoid overflow
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Arrange
      mockRadioService.approvedTracks = [];
      mockRadioService.isLoading = false;
      mockRadioService.likedTrackIds = {};


      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<SupabaseRadioService>.value(
                value: mockRadioService,
              ),
              ChangeNotifierProvider<AudioService>.value(
                value: mockAudioService,
              ),
              ChangeNotifierProvider<AudioService>.value(
                value: mockAudioService,
              ),
            ],
            child: const RadioScreen(),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.text('MVGR Radio'), findsOneWidget);
    });

    testWidgets('displays empty state when no tracks', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Arrange
      mockRadioService.approvedTracks = [];
      mockRadioService.isLoading = false;
      mockRadioService.likedTrackIds = {};


      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<SupabaseRadioService>.value(
                value: mockRadioService,
              ),
              ChangeNotifierProvider<AudioService>.value(
                value: mockAudioService,
              ),
            ],
            child: const RadioScreen(),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.text('No tracks available'), findsOneWidget);
      expect(find.byIcon(Icons.music_off), findsOneWidget);
    });

    testWidgets('displays tracks when available', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Arrange
      final tracks = [
        RadioTrack(
          id: '1',
          title: 'Campus Beats',
          artist: 'DJ Student',
          audioUrl: 'url',
          uploadedBy: 'user_1',
          createdAt: DateTime.now(),
        ),
      ];

      mockRadioService.approvedTracks = tracks;
      mockRadioService.isLoading = false;
      mockRadioService.likedTrackIds = {};


      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<SupabaseRadioService>.value(
                value: mockRadioService,
              ),
              ChangeNotifierProvider<AudioService>.value(
                value: mockAudioService,
              ),
            ],
            child: const RadioScreen(),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.text('Campus Beats'), findsOneWidget);
      expect(find.text('DJ Student'), findsOneWidget);
    });

    testWidgets('shows loading state', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Arrange
      mockRadioService.approvedTracks = [];
      mockRadioService.isLoading = true;
      mockRadioService.likedTrackIds = {};


      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<SupabaseRadioService>.value(
                value: mockRadioService,
              ),
              ChangeNotifierProvider<AudioService>.value(
                value: mockAudioService,
              ),
            ],
            child: const RadioScreen(),
          ),
        ),
      );

      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
