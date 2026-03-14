import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mvgr_nexus/main.dart';
import 'package:mvgr_nexus/features/auth/providers/auth_provider.dart';
import 'package:mvgr_nexus/services/supabase_event_service.dart';
import 'package:mvgr_nexus/services/supabase_radio_service.dart';
import 'package:mvgr_nexus/services/audio_service.dart';
import 'package:mvgr_nexus/features/events/models/event_model.dart';
import 'package:mvgr_nexus/domain/entities/user.dart';
import 'package:mvgr_nexus/core/theme/app_theme.dart';
import 'package:get_it/get_it.dart';
import 'package:mvgr_nexus/services/analytics_service.dart' as analytics_svc;

// Import our manual mocks
import 'mocks/manual_mocks.dart';

// Services needed for injection
import 'package:mvgr_nexus/services/supabase_club_service.dart';
import 'package:mvgr_nexus/services/supabase_announcement_service.dart';
import 'package:mvgr_nexus/services/supabase_vault_service.dart';
import 'package:mvgr_nexus/services/supabase_forum_service.dart';
import 'package:mvgr_nexus/services/supabase_meetups_service.dart';
import 'package:mvgr_nexus/services/favorites_service.dart';

// Screen imports
import 'package:mvgr_nexus/features/events/screens/events_screen.dart';
import 'package:mvgr_nexus/features/radio/screens/radio_screen.dart';

void main() {
  // Standard widget test binding is sufficient for hermetic tests
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthProvider mockAuthProvider;
  late MockSupabaseEventService mockEventService;
  late MockSupabaseRadioService mockRadioService;
  late MockAudioService mockAudioService;

  setUp(() {
    // Setup Mocks
    mockAuthProvider = MockAuthProvider();
    mockEventService = MockSupabaseEventService();
    mockRadioService = MockSupabaseRadioService();
    mockAudioService = MockAudioService();

    // Setup Test User
    final testUser = User(
      id: 'test_user_1',
      email: 'test@example.com',
      name: 'Integration Tester',
      role: UserRole.student,
      department: 'CSE',
      year: 3,
      createdAt: DateTime.now(),
    );

    mockAuthProvider.user = testUser;
    
    // Setup Service Data
    mockEventService.events = [
      Event(
        id: '1',
        title: 'Integration Event',
        description: 'Testing E2E Flow',
        clubId: 'c1',
        authorId: 'a1', 
        authorName: 'Admin',
        eventDate: DateTime.now().add(const Duration(days: 1)),
        venue: 'Lab 1',
        category: EventCategory.academic,
        createdAt: DateTime.now(),
        rsvpIds: [], 
      ),
    ];

    mockRadioService.tracks = [
      RadioTrack(
        id: 't1',
        title: 'Test Track',
        artist: 'Tester',
        audioUrl: 'https://example.com/audio.mp3',
        coverUrl: 'https://example.com/thumb.jpg',
        durationSeconds: 200,
        uploadedBy: 'a1',
        createdAt: DateTime.now(),
      ),
    ];

    // Register Analytics if needed (HomeScreen uses it via GetIt)
    if (!GetIt.instance.isRegistered<analytics_svc.AnalyticsService>()) {
      GetIt.instance.registerSingleton<analytics_svc.AnalyticsService>(
        analytics_svc.AnalyticsServiceImpl(),
      );
    }
  });

  testWidgets('E2E Navigation Flow: Home -> Events -> Radio', (tester) async {
    // Build the app with injected mocks
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<SupabaseEventService>.value(value: mockEventService),
          ChangeNotifierProvider<SupabaseRadioService>.value(value: mockRadioService),
          ChangeNotifierProvider<AudioService>.value(value: mockAudioService),
          
          // Provide legitimate or dummy implementations for other services to prevent ProviderNotFoundException
          ChangeNotifierProvider<SupabaseClubService>.value(value: MockSupabaseClubService()),
          ChangeNotifierProvider<SupabaseAnnouncementService>.value(value: MockSupabaseAnnouncementService()),
          ChangeNotifierProvider<SupabaseVaultService>.value(value: MockSupabaseVaultService()),
          ChangeNotifierProvider<SupabaseForumService>.value(value: MockSupabaseForumService()),
          ChangeNotifierProvider<SupabaseMeetupsService>.value(value: MockSupabaseMeetupsService()),
          ChangeNotifierProvider<FavoritesService>.value(value: MockFavoritesService()),
        ],
        child: MaterialApp(
          title: 'Integration Test App',
          theme: lightTheme,
          home: const MainNavigationScreen(),
          // Define routes used by navigation
          routes: {
            '/events': (context) => const EventsScreen(), // Uses SupabaseEventService
            '/radio': (context) => const RadioScreen(),   // Uses SupabaseRadioService & AudioService
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Home Screen
    expect(find.text('Home'), findsWidgets); // Bottom nav label and possibly title
    
    // 2. Navigate to Explore -> Events
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();
    
    // 3. Verify Events Screen
    try {
      expect(find.text('Events'), findsOneWidget); // Header title
      expect(find.text('Integration Event'), findsOneWidget); // Mocked data
    } catch (e) {
      // Debug print if fails
      debugPrint('Events screen items not found. Tree dump:');
      // debugDumpApp(); // Optional for debugging
      rethrow;
    }
    
    // 4. Navigate Back
    await tester.pageBack();
    await tester.pumpAndSettle();
    
    // 5. Navigate to Tools -> Radio
    await tester.tap(find.byIcon(Icons.construction_outlined)); // Tap icon to be safe
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Campus Radio'));
    await tester.pumpAndSettle();
    
    // 6. Verify Radio Screen
    expect(find.text('MVGR Radio'), findsOneWidget); // Correct title
    expect(find.text('Test Track'), findsOneWidget); // Mocked data
    
    // 7. Verify Play Inteaction (Mocked)
    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pump();
    
    // Verify play interaction triggered mock state change if possible/needed
  });
}
