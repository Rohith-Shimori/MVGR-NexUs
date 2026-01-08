import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/ranking_service.dart';

void main() {
  group('RankingService', () {
    group('calculateWeightedScore', () {
      test('returns 0 for empty factors', () {
        final result = RankingService.calculateWeightedScore({}, {'a': 1.0});
        expect(result, 0);
      });

      test('returns 0 for empty weights', () {
        final result = RankingService.calculateWeightedScore({'a': 50}, {});
        expect(result, 0);
      });

      test('calculates simple weighted average', () {
        final factors = {'factor1': 100.0, 'factor2': 0.0};
        final weights = {'factor1': 0.5, 'factor2': 0.5};
        final result = RankingService.calculateWeightedScore(factors, weights);
        expect(result, 50.0);
      });

      test('applies different weights correctly', () {
        final factors = {'recency': 100.0, 'upvotes': 50.0};
        final weights = {'recency': 0.8, 'upvotes': 0.2};
        final result = RankingService.calculateWeightedScore(factors, weights);
        // (100 * 0.8 + 50 * 0.2) / (0.8 + 0.2) = (80 + 10) / 1 = 90
        expect(result, 90.0);
      });

      test('ignores factors without weights', () {
        final factors = {'a': 100.0, 'b': 50.0, 'c': 0.0};
        final weights = {'a': 1.0}; // Only weight for 'a'
        final result = RankingService.calculateWeightedScore(factors, weights);
        expect(result, 100.0);
      });

      test('handles all zero weights', () {
        final factors = {'a': 100.0};
        final weights = {'a': 0.0};
        final result = RankingService.calculateWeightedScore(factors, weights);
        expect(result, 0);
      });
    });

    group('recencyScore', () {
      test('returns 1 for current time', () {
        final score = RankingService.recencyScore(DateTime.now());
        expect(score, closeTo(1.0, 0.01));
      });

      test('returns approximately 0.5 after one half-life', () {
        final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
        final score = RankingService.recencyScore(oneWeekAgo);
        expect(score, closeTo(0.5, 0.05));
      });

      test('returns lower score for older timestamps', () {
        final recent = DateTime.now().subtract(const Duration(days: 1));
        final old = DateTime.now().subtract(const Duration(days: 30));
        
        final recentScore = RankingService.recencyScore(recent);
        final oldScore = RankingService.recencyScore(old);
        
        expect(recentScore, greaterThan(oldScore));
      });

      test('respects custom half-life', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        final score = RankingService.recencyScore(
          twoDaysAgo,
          halfLife: const Duration(days: 2),
        );
        expect(score, closeTo(0.5, 0.05));
      });
    });

    group('upvoteScore', () {
      test('returns 0 for 0 upvotes', () {
        expect(RankingService.upvoteScore(0), 0);
      });

      test('returns 0 for negative upvotes', () {
        expect(RankingService.upvoteScore(-5), 0);
      });

      test('returns linear score below threshold', () {
        expect(RankingService.upvoteScore(5), 0.5); // 5/10
        expect(RankingService.upvoteScore(10), 1.0); // 10/10
      });

      test('returns logarithmic score above threshold', () {
        final score20 = RankingService.upvoteScore(20);
        final score100 = RankingService.upvoteScore(100);
        
        expect(score20, greaterThan(1.0));
        expect(score100, greaterThan(score20));
      });

      test('respects custom threshold', () {
        final score = RankingService.upvoteScore(5, threshold: 5);
        expect(score, 1.0);
      });
    });

    group('normalize', () {
      test('returns 50 when min equals max', () {
        expect(RankingService.normalize(5, 5, 5), 50);
      });

      test('returns 0 for min value', () {
        expect(RankingService.normalize(0, 0, 100), 0);
      });

      test('returns 100 for max value', () {
        expect(RankingService.normalize(100, 0, 100), 100);
      });

      test('returns 50 for middle value', () {
        expect(RankingService.normalize(50, 0, 100), 50);
      });

      test('handles negative ranges', () {
        expect(RankingService.normalize(0, -100, 100), 50);
      });
    });

    group('levenshteinDistance', () {
      test('returns 0 for identical strings', () {
        expect(RankingService.levenshteinDistance('hello', 'hello'), 0);
      });

      test('returns length of s2 when s1 is empty', () {
        expect(RankingService.levenshteinDistance('', 'hello'), 5);
      });

      test('returns length of s1 when s2 is empty', () {
        expect(RankingService.levenshteinDistance('hello', ''), 5);
      });

      test('counts single character difference', () {
        expect(RankingService.levenshteinDistance('cat', 'hat'), 1);
      });

      test('handles additions correctly', () {
        expect(RankingService.levenshteinDistance('cat', 'cats'), 1);
      });

      test('handles deletions correctly', () {
        expect(RankingService.levenshteinDistance('cats', 'cat'), 1);
      });

      test('is case insensitive', () {
        expect(RankingService.levenshteinDistance('Hello', 'hello'), 0);
      });
    });

    group('fuzzyMatchScore', () {
      test('returns 0 for empty query', () {
        expect(RankingService.fuzzyMatchScore('', 'target'), 0);
      });

      test('returns 0 for empty target', () {
        expect(RankingService.fuzzyMatchScore('query', ''), 0);
      });

      test('returns 100 for exact match', () {
        expect(RankingService.fuzzyMatchScore('hello', 'hello'), 100);
      });

      test('returns high score for similar strings', () {
        final score = RankingService.fuzzyMatchScore('hello', 'helo');
        expect(score, greaterThan(70));
      });

      test('returns low score for different strings', () {
        final score = RankingService.fuzzyMatchScore('apple', 'orange');
        expect(score, lessThan(50));
      });
    });

    group('rankByRelevance', () {
      test('returns empty list for empty input', () {
        final result = RankingService.rankByRelevance<String>(
          items: [],
          getFactors: (_) => {},
          weights: {'a': 1.0},
        );
        expect(result, isEmpty);
      });

      test('ranks items by score descending', () {
        final items = ['low', 'high', 'medium'];
        final result = RankingService.rankByRelevance<String>(
          items: items,
          getFactors: (item) {
            switch (item) {
              case 'high': return {'score': 100.0};
              case 'medium': return {'score': 50.0};
              default: return {'score': 0.0};
            }
          },
          weights: {'score': 1.0},
        );

        expect(result[0].item, 'high');
        expect(result[1].item, 'medium');
        expect(result[2].item, 'low');
      });

      test('can rank ascending when specified', () {
        final items = ['high', 'low'];
        final result = RankingService.rankByRelevance<String>(
          items: items,
          getFactors: (item) => {'score': item == 'high' ? 100.0 : 0.0},
          weights: {'score': 1.0},
          descending: false,
        );

        expect(result[0].item, 'low');
        expect(result[1].item, 'high');
      });
    });

    group('fuzzySearch', () {
      test('returns empty for no matches', () {
        final result = RankingService.fuzzySearch<String>(
          query: 'xyz',
          items: ['apple', 'banana'],
          getText: (s) => s,
          threshold: 80,
        );
        expect(result, isEmpty);
      });

      test('finds exact matches', () {
        final result = RankingService.fuzzySearch<String>(
          query: 'apple',
          items: ['apple', 'banana', 'apricot'],
          getText: (s) => s,
        );
        expect(result.isNotEmpty, true);
        expect(result.first.item, 'apple');
      });

      test('respects limit parameter', () {
        final items = List.generate(20, (i) => 'item$i');
        final result = RankingService.fuzzySearch<String>(
          query: 'item',
          items: items,
          getText: (s) => s,
          threshold: 0,
          limit: 5,
        );
        expect(result.length, lessThanOrEqualTo(5));
      });
    });

    group('scheduleOverlapScore', () {
      test('returns 0 for empty schedules', () {
        expect(RankingService.scheduleOverlapScore([], []), 0);
        expect(
          RankingService.scheduleOverlapScore(
            [const TimeSlot(day: 0, startHour: 9, endHour: 17)],
            [],
          ),
          0,
        );
      });

      test('returns 100 for identical schedules', () {
        final schedule = [const TimeSlot(day: 0, startHour: 9, endHour: 17)];
        final score = RankingService.scheduleOverlapScore(schedule, schedule);
        expect(score, 100);
      });

      test('returns 0 for non-overlapping schedules', () {
        final schedule1 = [const TimeSlot(day: 0, startHour: 9, endHour: 12)];
        final schedule2 = [const TimeSlot(day: 0, startHour: 14, endHour: 17)];
        final score = RankingService.scheduleOverlapScore(schedule1, schedule2);
        expect(score, 0);
      });

      test('calculates partial overlap', () {
        final schedule1 = [const TimeSlot(day: 0, startHour: 9, endHour: 13)];
        final schedule2 = [const TimeSlot(day: 0, startHour: 11, endHour: 15)];
        final score = RankingService.scheduleOverlapScore(schedule1, schedule2);
        expect(score, greaterThan(0));
        expect(score, lessThan(100));
      });
    });
  });

  group('RankedItem', () {
    test('scorePercent rounds correctly', () {
      final item = RankedItem(item: 'test', score: 85.7, factors: {});
      expect(item.scorePercent, 86);
    });
  });

  group('TimeSlot', () {
    test('dayName returns correct day', () {
      expect(const TimeSlot(day: 0, startHour: 9, endHour: 17).dayName, 'Mon');
      expect(const TimeSlot(day: 4, startHour: 9, endHour: 17).dayName, 'Fri');
      expect(const TimeSlot(day: 6, startHour: 9, endHour: 17).dayName, 'Sun');
    });

    test('timeRange formats correctly', () {
      final slot = const TimeSlot(day: 0, startHour: 9, endHour: 17);
      expect(slot.timeRange, '9:00 - 17:00');
    });
  });
}
