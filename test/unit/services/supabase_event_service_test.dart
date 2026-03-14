import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/supabase_event_service.dart';
import 'package:mvgr_nexus/features/events/models/event_model.dart';
// Note: We don't need extensive mocks for logic tests using the visibleForTesting setter

void main() {
  late SupabaseEventService service;

  setUp(() {
    service = SupabaseEventService();
    // Reset data
    service.events = [];
  });

  group('SupabaseEventService Logic', () {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final yesterday = now.subtract(const Duration(days: 1));

    final upcomingEvent = Event(
      id: '1',
      title: 'Upcoming',
      description: '...',
      eventDate: tomorrow,
      authorId: 'u1',
      authorName: 'Test Author',
      venue: 'Test Venue',
      category: EventCategory.academic,
      createdAt: now,
      rsvpIds: [], 
      interestedIds: [],
    );

    final pastEvent = Event(
      id: '2',
      title: 'Past',
      description: '...',
      eventDate: yesterday,
      authorId: 'u1',
      authorName: 'Test Author',
      venue: 'Test Venue',
      category: EventCategory.cultural,
      createdAt: now,
      rsvpIds: [],
      interestedIds: [],
    );

    test('events getter returns set events', () {
      service.events = [upcomingEvent, pastEvent];
      expect(service.events.length, 2);
    });

    // Note: getEvents in the service currently fetches from DB and THEN updates cache.
    // It filters at the DB level.
    // So we can't test filtering logic via the cache unless we refactor logic to be in Dart.
    // However, getUserEvents logic relies on fetching as well.
    
    // Logic we CAN test:
    // - State updates
    // - Helper methods if any (mostly in model)
    
    // Actually, unlike ClubService which had simple "getById" that relied on cache,
    // EventService methods mostly hit the network directly.
    // This highlights that the "Logic" is mostly in the DB query or the Model.
    // The Model tests (which we ran and passed) already cover 'isPast', 'isToday', etc.
    
    // So for EventService, purely logic tests are thin without mocking the client chain.
    // But we can verify the cache update mechanism works as expected.
    
    test('cache update notifies listeners', () {
      bool notified = false;
      service.addListener(() => notified = true);
      
      service.events = [upcomingEvent];
      
      expect(notified, isTrue);
      expect(service.events.first.title, 'Upcoming');
    });
  });
}
