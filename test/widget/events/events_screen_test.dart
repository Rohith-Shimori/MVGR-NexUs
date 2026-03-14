import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:mvgr_nexus/features/events/screens/events_screen.dart';
import 'package:mvgr_nexus/services/supabase_event_service.dart';
import 'package:mvgr_nexus/features/events/models/event_model.dart';
import 'package:mvgr_nexus/features/auth/providers/auth_provider.dart';
import 'package:mvgr_nexus/domain/entities/user.dart';
import 'dart:io';

import '../../helpers/test_helper.mocks.dart';

// Manual Mock for SupabaseEventService
class MockSupabaseEventService extends Mock implements SupabaseEventService {
  List<Event> _events = [];
  String? _error;

  @override
  List<Event> get events => _events;
  
  @override
  set events(List<Event> value) => _events = value;

  @override
  String? get error => _error;
  set error(String? value) => _error = value;

  @override
  Future<List<Event>> getEvents({String? clubId, String? category}) async {
    return _events;
  }

  @override
  Future<bool> hasRsvped(String eventId, String userId) async {
    return false;
  }

  @override
  Future<int> getRsvpCount(String eventId) async {
    return 0;
  }
  
  @override
  Future<bool> createEvent(Event event) async {
    return true;
  }
  
  @override
  Future<String?> uploadEventImage(File file) async {
    return 'https://example.com/image.jpg';
  }

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
  
  @override
  void notifyListeners() {}
}

void main() {
  late MockSupabaseEventService mockEventService;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockEventService = MockSupabaseEventService();
    mockEventService.events = [];

    mockAuthProvider = MockAuthProvider();
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

  group('EventsScreen', () {
    testWidgets('renders EventsScreen header', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<SupabaseEventService>.value(
                value: mockEventService,
              ),
            ],
            child: const EventsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Discover campus happenings'), findsOneWidget);
    });

    testWidgets('displays empty state when no events', (WidgetTester tester) async {
       // Set screen size to avoid overflow
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      
      mockEventService.events = [];

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<SupabaseEventService>.value(
                value: mockEventService,
              ),
            ],
            child: const EventsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Default filter is 'Upcoming'
      expect(find.text('No upcoming events'), findsOneWidget);
    });

    testWidgets('displays events when available', (WidgetTester tester) async {
       // Set screen size to avoid overflow
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      
      final futureEvent = Event(
        id: '1',
        title: 'Future Tech Talk',
        description: 'Description',
        clubId: 'club_1',
        clubName: 'Tech Club',
        authorId: 'user_1',
        authorName: 'Organizer',
        eventDate: DateTime.now().add(const Duration(days: 5)),
        venue: 'Auditorium',
        category: EventCategory.academic,
        createdAt: DateTime.now(),
        rsvpIds: [],
        interestedIds: [],
      );

      mockEventService.events = [futureEvent];

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ChangeNotifierProvider<SupabaseEventService>.value(
                value: mockEventService,
              ),
            ],
            child: const EventsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Future Tech Talk'), findsOneWidget);
      expect(find.text('Auditorium'), findsOneWidget);
    });
  });

  group('Event Model', () {
    test('Event has correct required fields', () {
      final event = Event(
        id: '1',
        title: 'Test Event',
        description: 'Test Description',
        clubId: 'club_1',
        clubName: 'Test Club',
        authorId: 'user_1',
        authorName: 'Author',
        eventDate: DateTime(2025, 6, 15),
        venue: 'Test Venue',
        category: EventCategory.academic,
        createdAt: DateTime.now(),
      );

      expect(event.title, 'Test Event');
      expect(event.venue, 'Test Venue');
      expect(event.category, EventCategory.academic);
    });
  });

  group('EventCategory Enum', () {
    test('all categories are defined', () {
      expect(EventCategory.values.length, 8);
    });

    test('displayName returns correct strings', () {
      expect(EventCategory.hackathon.displayName, 'Hackathon');
      expect(EventCategory.cultural.displayName, 'Cultural');
      expect(EventCategory.sports.displayName, 'Sports');
      expect(EventCategory.academic.displayName, 'Academic');
    });
  });

  group('Event Helper Methods', () {
    test('hasRSVP returns false for empty list', () {
      final event = Event(
        id: '1',
        title: 'Event',
        description: 'Desc',
        clubId: 'club_1',
        clubName: 'Club',
        authorId: 'user_1',
        authorName: 'Author',
        eventDate: DateTime.now(),
        venue: 'Venue',
        category: EventCategory.other,
        createdAt: DateTime.now(),
        rsvpIds: [],
      );

      expect(event.hasRSVP('user_123'), false);
    });

    test('hasRSVP returns true when user RSVPd', () {
      final event = Event(
        id: '1',
        title: 'Event',
        description: 'Desc',
        clubId: 'club_1',
        clubName: 'Club',
        authorId: 'user_1',
        authorName: 'Author',
        eventDate: DateTime.now(),
        venue: 'Venue',
        category: EventCategory.other,
        createdAt: DateTime.now(),
        rsvpIds: ['user_123'],
      );

      expect(event.hasRSVP('user_123'), true);
    });
  });
}
