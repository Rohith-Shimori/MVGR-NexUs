import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/mock_data_service.dart';
import 'package:mvgr_nexus/features/events/models/event_model.dart';

void main() {
  group('MockDataService - Events', () {
    late MockDataService service;

    setUp(() {
      service = MockDataService();
    });

    group('events getter', () {
      test('returns list of events', () {
        expect(service.events, isNotEmpty);
      });

      test('returns unmodifiable list', () {
        expect(() => service.events.add(Event.testEvents.first), throwsUnsupportedError);
      });
    });

    group('upcomingEvents getter', () {
      test('returns only future events', () {
        final upcoming = service.upcomingEvents;
        for (final event in upcoming) {
          expect(event.isPast, false);
        }
      });

      test('returns events sorted by date (earliest first)', () {
        final upcoming = service.upcomingEvents;
        for (var i = 0; i < upcoming.length - 1; i++) {
          expect(
            upcoming[i].eventDate.isBefore(upcoming[i + 1].eventDate) ||
            upcoming[i].eventDate.isAtSameMomentAs(upcoming[i + 1].eventDate),
            true,
          );
        }
      });
    });

    group('pastEvents getter', () {
      test('returns only past events sorted by date (latest first)', () {
        // Add a past event for testing
        service.addEvent(Event(
          id: 'past_event_test',
          title: 'Past Event',
          description: 'Desc',
          authorId: 'author',
          authorName: 'Author',
          eventDate: DateTime.now().subtract(const Duration(days: 5)),
          venue: 'Venue',
          category: EventCategory.other,
          createdAt: DateTime.now(),
        ));
        
        final past = service.pastEvents;
        for (final event in past) {
          expect(event.isPast, true);
        }
      });
    });

    group('getEventById', () {
      test('returns event when it exists', () {
        final testEvent = service.events.first;
        final found = service.getEventById(testEvent.id);
        expect(found, isNotNull);
        expect(found!.id, testEvent.id);
      });

      test('returns null when event does not exist', () {
        final found = service.getEventById('non_existent_event');
        expect(found, isNull);
      });
    });

    group('addEvent', () {
      test('adds event to list', () {
        final initialCount = service.events.length;
        final newEvent = Event(
          id: 'new_event_${DateTime.now().millisecondsSinceEpoch}',
          title: 'New Test Event',
          description: 'Description',
          authorId: 'author_001',
          authorName: 'Author',
          eventDate: DateTime.now().add(const Duration(days: 10)),
          venue: 'Test Venue',
          category: EventCategory.workshop,
          createdAt: DateTime.now(),
        );
        
        service.addEvent(newEvent);
        
        expect(service.events.length, initialCount + 1);
        expect(service.getEventById(newEvent.id), isNotNull);
      });
    });

    group('updateEvent', () {
      test('updates existing event', () {
        final event = service.events.first;
        final updatedEvent = event.copyWith(title: 'Updated Event Title');
        
        service.updateEvent(updatedEvent);
        
        final found = service.getEventById(event.id);
        expect(found!.title, 'Updated Event Title');
      });
    });

    group('deleteEvent', () {
      test('removes event from list', () {
        final eventToDelete = Event(
          id: 'event_to_delete',
          title: 'Delete Me',
          description: 'Will be deleted',
          authorId: 'author',
          authorName: 'Author',
          eventDate: DateTime.now().add(const Duration(days: 1)),
          venue: 'Venue',
          category: EventCategory.other,
          createdAt: DateTime.now(),
        );
        service.addEvent(eventToDelete);
        expect(service.getEventById('event_to_delete'), isNotNull);
        
        service.deleteEvent('event_to_delete');
        
        expect(service.getEventById('event_to_delete'), isNull);
      });
    });

    group('rsvpEvent', () {
      test('adds userId to rsvpIds', () {
        final event = service.events.first;
        final userId = 'rsvp_test_user_${DateTime.now().millisecondsSinceEpoch}';
        
        service.rsvpEvent(event.id, userId);
        
        final updatedEvent = service.getEventById(event.id)!;
        expect(updatedEvent.hasRSVP(userId), true);
      });

      test('does not add duplicate RSVP', () {
        final event = service.events.first;
        final userId = 'duplicate_rsvp_user';
        
        service.rsvpEvent(event.id, userId);
        final countAfterFirst = service.getEventById(event.id)!.rsvpCount;
        
        service.rsvpEvent(event.id, userId);
        final countAfterSecond = service.getEventById(event.id)!.rsvpCount;
        
        expect(countAfterSecond, countAfterFirst);
      });
    });

    group('removeRsvp', () {
      test('removes userId from rsvpIds', () {
        final event = service.events.first;
        final userId = 'remove_rsvp_user';
        
        service.rsvpEvent(event.id, userId);
        expect(service.getEventById(event.id)!.hasRSVP(userId), true);
        
        service.removeRsvp(event.id, userId);
        
        expect(service.getEventById(event.id)!.hasRSVP(userId), false);
      });
    });

    group('getMyEvents', () {
      test('returns upcoming events user has RSVP to', () {
        final event = service.upcomingEvents.first;
        final userId = 'my_events_user';
        
        service.rsvpEvent(event.id, userId);
        
        final myEvents = service.getMyEvents(userId);
        expect(myEvents.any((e) => e.id == event.id), true);
        for (final e in myEvents) {
          expect(e.isPast, false);
          expect(e.hasRSVP(userId), true);
        }
      });
    });

    group('Event Registration', () {
      test('rsvpWithDetails creates registration', () {
        final event = service.events.first;
        
        final registration = service.rsvpWithDetails(
          eventId: event.id,
          eventTitle: event.title,
          userId: 'reg_user_test',
          userName: 'Registration User',
          formResponses: {'field1': 'value1'},
        );
        
        expect(registration.eventId, event.id);
        expect(registration.userId, 'reg_user_test');
        expect(registration.formResponses, {'field1': 'value1'});
      });

      test('getEventAttendees returns registrations for event', () {
        final event = service.events.first;
        
        service.rsvpWithDetails(
          eventId: event.id,
          eventTitle: event.title,
          userId: 'attendee_1',
          userName: 'Attendee 1',
        );
        service.rsvpWithDetails(
          eventId: event.id,
          eventTitle: event.title,
          userId: 'attendee_2',
          userName: 'Attendee 2',
        );
        
        final attendees = service.getEventAttendees(event.id);
        expect(attendees.length, greaterThanOrEqualTo(2));
      });

      test('getEventRegistration returns specific registration', () {
        final event = service.events.first;
        
        service.rsvpWithDetails(
          eventId: event.id,
          eventTitle: event.title,
          userId: 'specific_reg_user',
          userName: 'Specific User',
        );
        
        final registration = service.getEventRegistration(event.id, 'specific_reg_user');
        expect(registration, isNotNull);
        expect(registration!.userId, 'specific_reg_user');
      });

      test('getEventRegistration returns null for non-registered user', () {
        final event = service.events.first;
        final registration = service.getEventRegistration(event.id, 'non_registered_user');
        expect(registration, isNull);
      });

      test('checkInAttendee updates status', () {
        final event = service.events.first;
        
        service.rsvpWithDetails(
          eventId: event.id,
          eventTitle: event.title,
          userId: 'checkin_user',
          userName: 'Check In User',
        );
        
        service.checkInAttendee(event.id, 'checkin_user');
        
        final registration = service.getEventRegistration(event.id, 'checkin_user');
        expect(registration!.isCheckedIn, true);
      });

      test('getEventStats returns correct counts', () {
        final event = service.events.first;
        
        service.rsvpWithDetails(
          eventId: event.id,
          eventTitle: event.title,
          userId: 'stats_user_1',
          userName: 'Stats User 1',
        );
        service.rsvpWithDetails(
          eventId: event.id,
          eventTitle: event.title,
          userId: 'stats_user_2',
          userName: 'Stats User 2',
        );
        service.checkInAttendee(event.id, 'stats_user_1');
        
        final stats = service.getEventStats(event.id);
        expect(stats['total'], greaterThanOrEqualTo(2));
        expect(stats['checkedIn'], greaterThanOrEqualTo(1));
      });
    });

    group('Announcements', () {
      test('announcements getter returns list', () {
        expect(service.announcements, isNotEmpty);
      });

      test('activeAnnouncements filters out expired', () {
        final active = service.activeAnnouncements;
        for (final ann in active) {
          expect(ann.isExpired, false);
        }
      });

      test('addAnnouncement adds to list', () {
        final countBefore = service.announcements.length;
        
        service.addAnnouncement(Announcement(
          id: 'new_ann_${DateTime.now().millisecondsSinceEpoch}',
          title: 'New Announcement',
          content: 'Content',
          authorId: 'author',
          authorName: 'Author',
          authorRole: 'Faculty',
          createdAt: DateTime.now(),
        ));
        
        expect(service.announcements.length, countBefore + 1);
      });

      test('updateAnnouncement updates existing', () {
        final ann = service.announcements.first;
        final updatedAnn = Announcement(
          id: ann.id,
          title: 'Updated Title',
          content: ann.content,
          authorId: ann.authorId,
          authorName: ann.authorName,
          authorRole: ann.authorRole,
          createdAt: ann.createdAt,
        );
        
        service.updateAnnouncement(updatedAnn);
        
        final found = service.announcements.firstWhere((a) => a.id == ann.id);
        expect(found.title, 'Updated Title');
      });

      test('deleteAnnouncement removes from list', () {
        service.addAnnouncement(Announcement(
          id: 'ann_to_delete',
          title: 'Delete Me',
          content: 'Content',
          authorId: 'author',
          authorName: 'Author',
          authorRole: 'Role',
          createdAt: DateTime.now(),
        ));
        
        service.deleteAnnouncement('ann_to_delete');
        
        expect(service.announcements.any((a) => a.id == 'ann_to_delete'), false);
      });

      test('getRelevantAnnouncements returns ranked list', () {
        final relevant = service.getRelevantAnnouncements(limit: 5);
        expect(relevant.length, lessThanOrEqualTo(5));
      });
    });
  });
}
