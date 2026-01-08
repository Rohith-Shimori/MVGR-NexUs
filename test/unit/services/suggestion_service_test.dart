import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/suggestion_service.dart';
import 'package:mvgr_nexus/services/mock_data_service.dart';
import 'package:mvgr_nexus/features/clubs/models/club_model.dart';
import 'package:mvgr_nexus/features/events/models/event_model.dart';
import 'package:mvgr_nexus/features/offline_community/models/meetup_model.dart';

void main() {
  late MockDataService dataService;
  late SuggestionService suggestionService;

  setUp(() {
    dataService = MockDataService();
    suggestionService = SuggestionService(dataService);
  });

  group('SuggestionService', () {
    group('hasInterests', () {
      test('returns false for empty interests', () {
        expect(suggestionService.hasInterests([]), false);
      });

      test('returns true for non-empty interests', () {
        expect(suggestionService.hasInterests(['Programming']), true);
      });
    });

    group('getRecommendedClubs', () {
      test('returns empty for empty interests', () {
        final clubs = suggestionService.getRecommendedClubs([]);
        expect(clubs, isEmpty);
      });

      test('returns list of clubs', () {
        final clubs = suggestionService.getRecommendedClubs(['Programming']);
        expect(clubs, isA<List<Club>>());
      });

      test('respects limit parameter', () {
        final clubs = suggestionService.getRecommendedClubs(
          ['Programming', 'Music', 'Cricket'],
          limit: 3,
        );
        expect(clubs.length, lessThanOrEqualTo(3));
      });

      test('returns clubs matching technical interests', () {
        final clubs = suggestionService.getRecommendedClubs(['Programming']);
        for (final club in clubs) {
          expect(club.category, ClubCategory.technical);
        }
      });

      test('returns clubs matching cultural interests', () {
        final clubs = suggestionService.getRecommendedClubs(['Music', 'Dance']);
        for (final club in clubs) {
          expect(club.category, ClubCategory.cultural);
        }
      });

      test('returns clubs matching sports interests', () {
        final clubs = suggestionService.getRecommendedClubs(['Cricket', 'Football']);
        for (final club in clubs) {
          expect(club.category, ClubCategory.sports);
        }
      });
    });

    group('getRecommendedEvents', () {
      test('returns empty for empty interests', () {
        final events = suggestionService.getRecommendedEvents([]);
        expect(events, isEmpty);
      });

      test('returns list of events', () {
        final events = suggestionService.getRecommendedEvents(['Programming']);
        expect(events, isA<List<Event>>());
      });

      test('respects limit parameter', () {
        final events = suggestionService.getRecommendedEvents(
          ['Programming', 'Music'],
          limit: 5,
        );
        expect(events.length, lessThanOrEqualTo(5));
      });

      test('only returns future events', () {
        final events = suggestionService.getRecommendedEvents(
          ['Programming', 'Music', 'Cricket'],
        );
        final now = DateTime.now();
        for (final event in events) {
          expect(event.eventDate.isAfter(now), true);
        }
      });

      test('sorts events by date', () {
        final events = suggestionService.getRecommendedEvents(
          ['Programming', 'Music'],
        );
        if (events.length >= 2) {
          for (int i = 0; i < events.length - 1; i++) {
            expect(
              events[i].eventDate.isBefore(events[i + 1].eventDate) ||
              events[i].eventDate.isAtSameMomentAs(events[i + 1].eventDate),
              true,
            );
          }
        }
      });
    });

    group('getRecommendedMeetups', () {
      test('returns empty for empty interests', () {
        final meetups = suggestionService.getRecommendedMeetups([]);
        expect(meetups, isEmpty);
      });

      test('returns list of meetups', () {
        final meetups = suggestionService.getRecommendedMeetups(['Programming']);
        expect(meetups, isA<List<Meetup>>());
      });

      test('respects limit parameter', () {
        final meetups = suggestionService.getRecommendedMeetups(
          ['Programming', 'Gaming'],
          limit: 3,
        );
        expect(meetups.length, lessThanOrEqualTo(3));
      });

      test('only returns future meetups', () {
        final meetups = suggestionService.getRecommendedMeetups(
          ['Programming', 'E-Sports', 'Music'],
        );
        final now = DateTime.now();
        for (final meetup in meetups) {
          expect(meetup.scheduledAt.isAfter(now), true);
        }
      });
    });

    group('getAllRecommendations', () {
      test('returns SuggestionResults', () {
        final results = suggestionService.getAllRecommendations(['Programming']);
        expect(results, isA<SuggestionResults>());
      });

      test('contains clubs, events, and meetups', () {
        final results = suggestionService.getAllRecommendations(['Programming']);
        expect(results.clubs, isA<List<Club>>());
        expect(results.events, isA<List<Event>>());
        expect(results.meetups, isA<List<Meetup>>());
      });

      test('limits each category to 5', () {
        final results = suggestionService.getAllRecommendations(
          ['Programming', 'Music', 'Cricket', 'E-Sports'],
        );
        expect(results.clubs.length, lessThanOrEqualTo(5));
        expect(results.events.length, lessThanOrEqualTo(5));
        expect(results.meetups.length, lessThanOrEqualTo(5));
      });
    });

    group('interest mapping', () {
      test('Programming maps to technical clubs', () {
        final clubs = suggestionService.getRecommendedClubs(['Programming']);
        if (clubs.isNotEmpty) {
          expect(clubs.any((c) => c.category == ClubCategory.technical), true);
        }
      });

      test('Music maps to cultural clubs', () {
        final clubs = suggestionService.getRecommendedClubs(['Music']);
        if (clubs.isNotEmpty) {
          expect(clubs.any((c) => c.category == ClubCategory.cultural), true);
        }
      });

      test('Cricket maps to sports clubs', () {
        final clubs = suggestionService.getRecommendedClubs(['Cricket']);
        if (clubs.isNotEmpty) {
          expect(clubs.any((c) => c.category == ClubCategory.sports), true);
        }
      });

      test('E-Sports maps to gaming meetups', () {
        final meetups = suggestionService.getRecommendedMeetups(['E-Sports']);
        if (meetups.isNotEmpty) {
          expect(
            meetups.any((m) => m.category == MeetupCategory.gaming),
            true,
          );
        }
      });
    });
  });

  group('SuggestionResults', () {
    test('isEmpty returns true when all lists are empty', () {
      final results = SuggestionResults(
        clubs: [],
        events: [],
        meetups: [],
      );
      expect(results.isEmpty, true);
    });

    test('isEmpty returns false when any list has items', () {
      final club = Club(
        id: 'club_001',
        name: 'Test Club',
        description: 'Description',
        category: ClubCategory.technical,
        adminIds: ['admin'],
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      final results = SuggestionResults(
        clubs: [club],
        events: [],
        meetups: [],
      );
      expect(results.isEmpty, false);
    });

    test('totalCount sums all lists', () {
      final club = Club(
        id: 'club_001',
        name: 'Test Club',
        description: 'Description',
        category: ClubCategory.technical,
        adminIds: ['admin'],
        createdAt: DateTime.now(),
        createdBy: 'admin',
      );

      final results = SuggestionResults(
        clubs: [club, club],
        events: [],
        meetups: [],
      );
      expect(results.totalCount, 2);
    });
  });
}
