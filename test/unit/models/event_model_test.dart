import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/events/models/event_model.dart';

void main() {
  group('Event', () {
    late Event testEvent;
    late DateTime futureDate;
    late DateTime pastDate;

    setUp(() {
      futureDate = DateTime.now().add(const Duration(days: 7));
      pastDate = DateTime.now().subtract(const Duration(days: 1));
      
      testEvent = Event(
        id: 'event_001',
        title: 'Test Event',
        description: 'Event description',
        clubId: 'club_001',
        clubName: 'Test Club',
        authorId: 'author_001',
        authorName: 'Test Author',
        eventDate: futureDate,
        venue: 'Main Hall',
        venueDetails: 'Room 101',
        maxParticipants: 100,
        rsvpIds: ['user_001', 'user_002'],
        interestedIds: ['user_003', 'user_004', 'user_005'],
        category: EventCategory.workshop,
        requiresRegistration: true,
        createdAt: DateTime(2024, 1, 1),
      );
    });

    group('constructor', () {
      test('creates event with required fields', () {
        final event = Event(
          id: 'id',
          title: 'Title',
          description: 'Desc',
          authorId: 'author',
          authorName: 'Author',
          eventDate: DateTime.now(),
          venue: 'Venue',
          category: EventCategory.seminar,
          createdAt: DateTime.now(),
        );
        expect(event.id, 'id');
        expect(event.clubId, isNull); // Optional
        expect(event.rsvpIds, isEmpty); // Default
        expect(event.requiresRegistration, false); // Default
        expect(event.isOnline, false); // Default
      });
    });

    group('isPast', () {
      test('returns false for future events', () {
        expect(testEvent.isPast, false);
      });

      test('returns true for past events', () {
        final pastEvent = testEvent.copyWith(eventDate: pastDate);
        expect(pastEvent.isPast, true);
      });
    });

    group('isToday', () {
      test('returns true for events today', () {
        final todayEvent = testEvent.copyWith(eventDate: DateTime.now());
        expect(todayEvent.isToday, true);
      });

      test('returns false for future events', () {
        expect(testEvent.isToday, false);
      });

      test('returns false for past events', () {
        final pastEvent = testEvent.copyWith(eventDate: pastDate);
        expect(pastEvent.isToday, false);
      });
    });

    group('isFull', () {
      test('returns true when rsvpCount >= maxParticipants', () {
        final fullEvent = testEvent.copyWith(
          maxParticipants: 2,
          rsvpIds: ['user_001', 'user_002'],
        );
        expect(fullEvent.isFull, true);
      });

      test('returns false when rsvpCount < maxParticipants', () {
        expect(testEvent.isFull, false); // 2 rsvps, 100 max
      });

      test('returns false when maxParticipants is null (unlimited)', () {
        // copyWith doesn't work for null, so create new
        final event = Event(
          id: 'id',
          title: 'Title',
          description: 'Desc',
          authorId: 'author',
          authorName: 'Author',
          eventDate: DateTime.now(),
          venue: 'Venue',
          category: EventCategory.other,
          rsvpIds: ['a', 'b', 'c', 'd', 'e'],
          createdAt: DateTime.now(),
        );
        expect(event.isFull, false);
      });
    });

    group('rsvpCount and interestedCount', () {
      test('returns correct counts', () {
        expect(testEvent.rsvpCount, 2);
        expect(testEvent.interestedCount, 3);
      });

      test('returns 0 for empty lists', () {
        final emptyEvent = testEvent.copyWith(rsvpIds: [], interestedIds: []);
        expect(emptyEvent.rsvpCount, 0);
        expect(emptyEvent.interestedCount, 0);
      });
    });

    group('hasRSVP', () {
      test('returns true for users with rsvp', () {
        expect(testEvent.hasRSVP('user_001'), true);
        expect(testEvent.hasRSVP('user_002'), true);
      });

      test('returns false for users without rsvp', () {
        expect(testEvent.hasRSVP('user_003'), false);
        expect(testEvent.hasRSVP('unknown'), false);
      });
    });

    group('isInterested', () {
      test('returns true for interested users', () {
        expect(testEvent.isInterested('user_003'), true);
        expect(testEvent.isInterested('user_004'), true);
      });

      test('returns false for non-interested users', () {
        expect(testEvent.isInterested('user_001'), false);
        expect(testEvent.isInterested('unknown'), false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final updated = testEvent.copyWith(
          title: 'Updated Title',
          venue: 'New Venue',
        );
        expect(updated.title, 'Updated Title');
        expect(updated.venue, 'New Venue');
        expect(updated.id, testEvent.id); // Unchanged
      });

      test('preserves original values when not specified', () {
        final copy = testEvent.copyWith();
        expect(copy.id, testEvent.id);
        expect(copy.title, testEvent.title);
        expect(copy.rsvpIds, testEvent.rsvpIds);
      });
    });

    group('toFirestore', () {
      test('returns correct map structure', () {
        final map = testEvent.toFirestore();
        
        expect(map['title'], 'Test Event');
        expect(map['description'], 'Event description');
        expect(map['clubId'], 'club_001');
        expect(map['clubName'], 'Test Club');
        expect(map['authorId'], 'author_001');
        expect(map['venue'], 'Main Hall');
        expect(map['venueDetails'], 'Room 101');
        expect(map['maxParticipants'], 100);
        expect(map['rsvpIds'], ['user_001', 'user_002']);
        expect(map['category'], 'workshop');
        expect(map['requiresRegistration'], true);
        expect(map['isOnline'], false);
      });
    });

    group('testEvents', () {
      test('returns non-empty list of test events', () {
        final events = Event.testEvents;
        expect(events, isNotEmpty);
        expect(events.length, greaterThanOrEqualTo(3));
      });

      test('all test events have required fields', () {
        for (final event in Event.testEvents) {
          expect(event.id, isNotEmpty);
          expect(event.title, isNotEmpty);
          expect(event.venue, isNotEmpty);
        }
      });
    });
  });

  group('EventCategory', () {
    group('displayName', () {
      test('returns correct display names', () {
        expect(EventCategory.academic.displayName, 'Academic');
        expect(EventCategory.cultural.displayName, 'Cultural');
        expect(EventCategory.sports.displayName, 'Sports');
        expect(EventCategory.hackathon.displayName, 'Hackathon');
        expect(EventCategory.workshop.displayName, 'Workshop');
        expect(EventCategory.seminar.displayName, 'Seminar');
        expect(EventCategory.competition.displayName, 'Competition');
        expect(EventCategory.other.displayName, 'Other');
      });
    });

    group('icon', () {
      test('returns emoji for each category', () {
        expect(EventCategory.academic.icon, '📖');
        expect(EventCategory.hackathon.icon, '💻');
        expect(EventCategory.workshop.icon, '🛠️');
      });
    });

    group('iconData', () {
      test('returns IconData for each category', () {
        expect(EventCategory.academic.iconData, Icons.menu_book_rounded);
        expect(EventCategory.hackathon.iconData, Icons.code_rounded);
        expect(EventCategory.workshop.iconData, Icons.handyman_rounded);
        expect(EventCategory.seminar.iconData, Icons.mic_rounded);
      });
    });
  });

  group('Announcement', () {
    late Announcement testAnnouncement;

    setUp(() {
      testAnnouncement = Announcement(
        id: 'ann_001',
        title: 'Test Announcement',
        content: 'Announcement content',
        authorId: 'author_001',
        authorName: 'Author Name',
        authorRole: 'Faculty',
        isPinned: true,
        isUrgent: false,
        createdAt: DateTime(2024, 1, 1),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );
    });

    group('constructor', () {
      test('creates announcement with required fields', () {
        final ann = Announcement(
          id: 'id',
          title: 'Title',
          content: 'Content',
          authorId: 'author',
          authorName: 'Author',
          authorRole: 'Role',
          createdAt: DateTime.now(),
        );
        expect(ann.id, 'id');
        expect(ann.isPinned, false); // Default
        expect(ann.isUrgent, false); // Default
        expect(ann.expiresAt, isNull); // Default
      });
    });

    group('isExpired', () {
      test('returns false when expiresAt is in the future', () {
        expect(testAnnouncement.isExpired, false);
      });

      test('returns true when expiresAt is in the past', () {
        final expiredAnn = Announcement(
          id: 'id',
          title: 'Title',
          content: 'Content',
          authorId: 'author',
          authorName: 'Author',
          authorRole: 'Role',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(expiredAnn.isExpired, true);
      });

      test('returns false when expiresAt is null', () {
        final noExpiry = Announcement(
          id: 'id',
          title: 'Title',
          content: 'Content',
          authorId: 'author',
          authorName: 'Author',
          authorRole: 'Role',
          createdAt: DateTime.now(),
        );
        expect(noExpiry.isExpired, false);
      });
    });

    group('toFirestore', () {
      test('returns correct map structure', () {
        final map = testAnnouncement.toFirestore();
        
        expect(map['title'], 'Test Announcement');
        expect(map['content'], 'Announcement content');
        expect(map['authorId'], 'author_001');
        expect(map['authorRole'], 'Faculty');
        expect(map['isPinned'], true);
        expect(map['isUrgent'], false);
      });
    });

    group('testAnnouncements', () {
      test('returns non-empty list', () {
        expect(Announcement.testAnnouncements, isNotEmpty);
      });
    });
  });
}
