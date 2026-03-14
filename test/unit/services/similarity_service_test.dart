import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/similarity_service.dart';

void main() {
  group('SimilarityService', () {
    group('tokenize', () {
      test('converts text to lowercase', () {
        final tokens = SimilarityService.tokenize('Hello World');
        expect(tokens.every((t) => t == t.toLowerCase()), true);
      });

      test('removes punctuation', () {
        final tokens = SimilarityService.tokenize('Hello, World!');
        expect(tokens.any((t) => t.contains(',')), false);
        expect(tokens.any((t) => t.contains('!')), false);
      });

      test('splits on whitespace', () {
        final tokens = SimilarityService.tokenize('flutter dart programming');
        expect(tokens, contains('flutter'));
        expect(tokens, contains('dart'));
        expect(tokens, contains('programming'));
      });

      test('removes short words', () {
        final tokens = SimilarityService.tokenize('I am a programmer');
        expect(tokens.any((t) => t.length <= 2), false);
      });

      test('removes stop words', () {
        final tokens = SimilarityService.tokenize('the quick brown fox');
        expect(tokens, isNot(contains('the')));
      });

      test('keeps meaningful words', () {
        final tokens = SimilarityService.tokenize('machine learning algorithms');
        expect(tokens, contains('machine'));
        expect(tokens, contains('learning'));
        expect(tokens, contains('algorithms'));
      });
    });

    group('termFrequency', () {
      test('returns empty map for empty tokens', () {
        final tf = SimilarityService.termFrequency([]);
        expect(tf, isEmpty);
      });

      test('calculates frequency correctly', () {
        final tokens = ['hello', 'world', 'hello'];
        final tf = SimilarityService.termFrequency(tokens);
        expect(tf['hello'], closeTo(2/3, 0.01));
        expect(tf['world'], closeTo(1/3, 0.01));
      });

      test('single word has frequency 1', () {
        final tokens = ['hello'];
        final tf = SimilarityService.termFrequency(tokens);
        expect(tf['hello'], 1.0);
      });
    });

    group('inverseDocumentFrequency', () {
      test('calculates IDF for multiple documents', () {
        final docs = [
          ['machine', 'learning'],
          ['machine', 'code'],
          ['deep', 'learning'],
        ];
        final idf = SimilarityService.inverseDocumentFrequency(docs);
        
        // 'machine' appears in 2 docs
        // 'deep' appears in 1 doc (rarer, higher IDF)
        expect(idf['deep']!, greaterThan(idf['machine']!));
      });

      test('returns empty for empty documents', () {
        final idf = SimilarityService.inverseDocumentFrequency([]);
        expect(idf, isEmpty);
      });
    });

    group('cosineSimilarity', () {
      test('returns 0 for empty vectors', () {
        expect(SimilarityService.cosineSimilarity({}, {}), 0);
        expect(SimilarityService.cosineSimilarity({'a': 1.0}, {}), 0);
      });

      test('returns 1 for identical vectors', () {
        final vec = {'a': 0.5, 'b': 0.5};
        final similarity = SimilarityService.cosineSimilarity(vec, vec);
        expect(similarity, closeTo(1.0, 0.01));
      });

      test('returns 0 for orthogonal vectors', () {
        final vec1 = {'a': 1.0};
        final vec2 = {'b': 1.0};
        final similarity = SimilarityService.cosineSimilarity(vec1, vec2);
        expect(similarity, closeTo(0, 0.01));
      });

      test('returns value between 0 and 1 for similar vectors', () {
        final vec1 = {'a': 0.5, 'b': 0.5, 'c': 0.0};
        final vec2 = {'a': 0.3, 'b': 0.7, 'd': 0.2};
        final similarity = SimilarityService.cosineSimilarity(vec1, vec2);
        expect(similarity, greaterThan(0));
        expect(similarity, lessThanOrEqualTo(1));
      });
    });

    group('keywordOverlap', () {
      test('returns 0 for empty texts', () {
        expect(SimilarityService.keywordOverlap('', ''), 0);
        expect(SimilarityService.keywordOverlap('hello', ''), 0);
      });

      test('returns 1 for identical texts', () {
        final overlap = SimilarityService.keywordOverlap(
          'machine learning algorithms',
          'machine learning algorithms',
        );
        expect(overlap, 1.0);
      });

      test('returns 0 for completely different texts', () {
        final overlap = SimilarityService.keywordOverlap(
          'apple banana orange',
          'computer programming code',
        );
        expect(overlap, 0);
      });

      test('returns partial overlap for similar texts', () {
        final overlap = SimilarityService.keywordOverlap(
          'machine learning python',
          'machine learning tensorflow',
        );
        expect(overlap, greaterThan(0));
        expect(overlap, lessThan(1));
      });
    });

    group('tfidfVector', () {
      test('returns empty for empty tokens', () {
        final vec = SimilarityService.tfidfVector([], {'a': 1.0});
        expect(vec, isEmpty);
      });

      test('multiplies TF by IDF', () {
        final tokens = ['hello', 'world'];
        final idf = {'hello': 2.0, 'world': 1.0};
        final vec = SimilarityService.tfidfVector(tokens, idf);
        
        // TF for each is 0.5, so TF-IDF = 0.5 * IDF
        expect(vec['hello'], closeTo(0.5 * 2.0, 0.01));
        expect(vec['world'], closeTo(0.5 * 1.0, 0.01));
      });
    });

    group('findSimilar', () {
      test('returns empty for empty items', () {
        final results = SimilarityService.findSimilar<String>(
          query: 'test',
          items: [],
          getText: (s) => s,
        );
        expect(results, isEmpty);
      });

      test('returns empty for empty query', () {
        final results = SimilarityService.findSimilar<String>(
          query: '',
          items: ['hello', 'world'],
          getText: (s) => s,
        );
        expect(results, isEmpty);
      });

      test('finds similar items', () {
        final items = [
          'machine learning python programming',
          'cooking recipes food',
          'deep learning neural networks',
        ];
        final results = SimilarityService.findSimilar<String>(
          query: 'machine learning algorithms',
          items: items,
          getText: (s) => s,
          threshold: 0.0,
        );
        
        expect(results.isNotEmpty, true);
      });

      test('respects limit parameter', () {
        final items = List.generate(20, (i) => 'item $i machine');
        final results = SimilarityService.findSimilar<String>(
          query: 'machine',
          items: items,
          getText: (s) => s,
          threshold: 0.0,
          limit: 5,
        );
        expect(results.length, lessThanOrEqualTo(5));
      });

      test('sorts by score descending', () {
        final results = SimilarityService.findSimilar<String>(
          query: 'test',
          items: ['test item one', 'test item two', 'random stuff'],
          getText: (s) => s,
          threshold: 0.0,
        );
        
        if (results.length >= 2) {
          expect(results.first.score, greaterThanOrEqualTo(results.last.score));
        }
      });
    });
  });

  group('SimilarityResult', () {
    test('percentage rounds correctly', () {
      final result = SimilarityResult(item: 'test', score: 0.857);
      expect(result.percentage, 86);
    });

    test('percentage is 0 for 0 score', () {
      final result = SimilarityResult(item: 'test', score: 0.0);
      expect(result.percentage, 0);
    });

    test('percentage is 100 for 1.0 score', () {
      final result = SimilarityResult(item: 'test', score: 1.0);
      expect(result.percentage, 100);
    });
  });
}
