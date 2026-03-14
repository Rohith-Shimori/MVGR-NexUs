import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mvgr_nexus/services/favorites_service.dart';

// Generate unique IDs using incrementing counter
var _counter = 0;
String _testId(String prefix) => '${prefix}_test_${++_counter}';

void main() {
  late FavoritesService service;

  setUpAll(() async {
    // Mock SharedPreferences once
    SharedPreferences.setMockInitialValues({});
    service = FavoritesService.instance;
    await service.init();
  });

  group('FavoritesService', () {
    group('Club Favorites', () {
      test('isClubFavorite returns false for unfavorited club', () {
        final id = _testId('club');
        expect(service.isClubFavorite(id), false);
      });

      test('toggleClubFavorite adds club to favorites', () {
        final id = _testId('club');
        expect(service.isClubFavorite(id), false);
        
        service.toggleClubFavorite(id);
        expect(service.isClubFavorite(id), true);
        expect(service.favoriteClubIds, contains(id));
      });

      test('toggleClubFavorite removes club from favorites when already favorited', () {
        final id = _testId('club');
        service.toggleClubFavorite(id);
        expect(service.isClubFavorite(id), true);
        
        service.toggleClubFavorite(id);
        expect(service.isClubFavorite(id), false);
      });

      test('can have multiple favorite clubs', () {
        final id1 = _testId('club');
        final id2 = _testId('club');
        final id3 = _testId('club');
        
        service.toggleClubFavorite(id1);
        service.toggleClubFavorite(id2);
        service.toggleClubFavorite(id3);
        
        // Verify all 3 are favorites
        expect(service.isClubFavorite(id1), true);
        expect(service.isClubFavorite(id2), true);
        expect(service.isClubFavorite(id3), true);
        expect(service.favoriteClubIds, containsAll([id1, id2, id3]));
      });
    });

    group('Event Favorites', () {
      test('isEventFavorite returns false for unfavorited event', () {
        final id = _testId('event');
        expect(service.isEventFavorite(id), false);
      });

      test('toggleEventFavorite adds event to favorites', () {
        final id = _testId('event');
        expect(service.isEventFavorite(id), false);
        
        service.toggleEventFavorite(id);
        expect(service.isEventFavorite(id), true);
        expect(service.favoriteEventIds, contains(id));
      });

      test('toggleEventFavorite removes event from favorites when already favorited', () {
        final id = _testId('event');
        service.toggleEventFavorite(id);
        expect(service.isEventFavorite(id), true);
        
        service.toggleEventFavorite(id);
        expect(service.isEventFavorite(id), false);
      });

      test('can have multiple favorite events', () {
        final id1 = _testId('event');
        final id2 = _testId('event');
        final id3 = _testId('event');
        
        service.toggleEventFavorite(id1);
        service.toggleEventFavorite(id2);
        service.toggleEventFavorite(id3);
        
        // Verify all 3 are favorites
        expect(service.isEventFavorite(id1), true);
        expect(service.isEventFavorite(id2), true);
        expect(service.isEventFavorite(id3), true);
        expect(service.favoriteEventIds, containsAll([id1, id2, id3]));
      });
    });

    group('Recent Searches', () {
      test('addRecentSearch adds search query', () {
        final query = _testId('search');
        service.addRecentSearch(query);
        expect(service.recentSearches, contains(query));
      });

      test('addRecentSearch ignores empty strings', () {
        final initialCount = service.recentSearches.length;
        service.addRecentSearch('');
        service.addRecentSearch('   ');
        expect(service.recentSearches.length, initialCount);
      });

      test('recent searches are ordered with newest first', () {
        final first = _testId('first');
        final second = _testId('second');
        final third = _testId('third');
        
        service.addRecentSearch(first);
        service.addRecentSearch(second);
        service.addRecentSearch(third);
        
        expect(service.recentSearches.first, third);
      });

      test('addRecentSearch moves duplicate to end', () {
        final query1 = _testId('query1');
        final query2 = _testId('query2');
        
        service.addRecentSearch(query1);
        service.addRecentSearch(query2);
        service.addRecentSearch(query1); // Re-add query1
        
        expect(service.recentSearches.first, query1);
      });

      test('clearRecentSearches removes all searches', () {
        service.addRecentSearch(_testId('q1'));
        service.addRecentSearch(_testId('q2'));
        service.clearRecentSearches();
        
        expect(service.recentSearches, isEmpty);
      });
    });

    group('Generic Methods', () {
      test('isFavorite works for clubs', () {
        final id = _testId('club');
        service.toggleClubFavorite(id);
        expect(service.isFavorite('club', id), true);
        expect(service.isFavorite('club', _testId('other')), false);
      });

      test('isFavorite works for events', () {
        final id = _testId('event');
        service.toggleEventFavorite(id);
        expect(service.isFavorite('event', id), true);
        expect(service.isFavorite('event', _testId('other')), false);
      });

      test('isFavorite returns false for unknown type', () {
        expect(service.isFavorite('unknown', 'id'), false);
      });

      test('toggleFavorite works for clubs', () {
        final id = _testId('club');
        service.toggleFavorite('club', id);
        expect(service.isClubFavorite(id), true);
      });

      test('toggleFavorite works for events', () {
        final id = _testId('event');
        service.toggleFavorite('event', id);
        expect(service.isEventFavorite(id), true);
      });
    });

    group('ChangeNotifier', () {
      test('notifies listeners when club favorite toggled', () {
        var notified = false;
        void listener() => notified = true;
        service.addListener(listener);
        
        service.toggleClubFavorite(_testId('club'));
        expect(notified, true);
        
        service.removeListener(listener);
      });

      test('notifies listeners when event favorite toggled', () {
        var notified = false;
        void listener() => notified = true;
        service.addListener(listener);
        
        service.toggleEventFavorite(_testId('event'));
        expect(notified, true);
        
        service.removeListener(listener);
      });

      test('notifies listeners when search added', () {
        var notified = false;
        void listener() => notified = true;
        service.addListener(listener);
        
        service.addRecentSearch(_testId('search'));
        expect(notified, true);
        
        service.removeListener(listener);
      });
    });
  });
}
