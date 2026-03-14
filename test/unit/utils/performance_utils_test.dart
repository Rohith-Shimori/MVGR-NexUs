import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/core/utils/performance_utils.dart';

void main() {
  group('Debouncer', () {
    test('creates debouncer with default delay', () {
      final debouncer = Debouncer();
      expect(debouncer.milliseconds, 300);
    });

    test('creates debouncer with custom delay', () {
      final debouncer = Debouncer(milliseconds: 500);
      expect(debouncer.milliseconds, 500);
    });

    test('run executes action after delay', () async {
      final debouncer = Debouncer(milliseconds: 100);
      var executed = false;
      
      debouncer.run(() => executed = true);
      
      // Not executed immediately
      expect(executed, false);
      
      // Wait for debounce delay
      await Future.delayed(const Duration(milliseconds: 150));
      expect(executed, true);
    });

    test('cancel prevents action from executing', () async {
      final debouncer = Debouncer(milliseconds: 100);
      var executed = false;
      
      debouncer.run(() => executed = true);
      debouncer.cancel();
      
      // Wait for debounce delay
      await Future.delayed(const Duration(milliseconds: 150));
      expect(executed, false);
    });

    test('subsequent run cancels previous action', () async {
      final debouncer = Debouncer(milliseconds: 100);
      var firstExecuted = false;
      var secondExecuted = false;
      
      debouncer.run(() => firstExecuted = true);
      
      // Quick second call replaces first
      await Future.delayed(const Duration(milliseconds: 50));
      debouncer.run(() => secondExecuted = true);
      
      // Wait for debounce delay
      await Future.delayed(const Duration(milliseconds: 150));
      
      expect(firstExecuted, false);
      expect(secondExecuted, true);
    });
  });

  group('Memoizer', () {
    test('caches computation result', () {
      var computationCount = 0;
      final memoizer = Memoizer<int, int>((input) {
        computationCount++;
        return input * 2;
      });

      // First call computes
      expect(memoizer.call(5), 10);
      expect(computationCount, 1);
      
      // Second call with same input uses cache
      expect(memoizer.call(5), 10);
      expect(computationCount, 1); // Still 1, not recomputed
    });

    test('computes for different inputs', () {
      var computationCount = 0;
      final memoizer = Memoizer<int, int>((input) {
        computationCount++;
        return input * input;
      });

      expect(memoizer.call(3), 9);
      expect(memoizer.call(4), 16);
      expect(memoizer.call(5), 25);
      expect(computationCount, 3);
      
      // Cached calls
      expect(memoizer.call(3), 9);
      expect(memoizer.call(4), 16);
      expect(computationCount, 3); // Still 3
    });

    test('clear removes all cached results', () {
      var computationCount = 0;
      final memoizer = Memoizer<String, int>((input) {
        computationCount++;
        return input.length;
      });

      expect(memoizer.call('hello'), 5);
      expect(computationCount, 1);
      
      // Clear cache
      memoizer.clear();
      
      // Recomputes after clear
      expect(memoizer.call('hello'), 5);
      expect(computationCount, 2);
    });

    test('works with string keys', () {
      final memoizer = Memoizer<String, String>((input) => input.toUpperCase());

      expect(memoizer.call('hello'), 'HELLO');
      expect(memoizer.call('world'), 'WORLD');
      expect(memoizer.call('hello'), 'HELLO'); // Cached
    });

    test('handles null computation results', () {
      final memoizer = Memoizer<int, String?>((input) {
        if (input < 0) return null;
        return 'positive';
      });

      expect(memoizer.call(-1), null);
      expect(memoizer.call(1), 'positive');
      expect(memoizer.call(-1), null); // Cached null
    });

    test('expensive computation is only run once', () {
      var expensiveCount = 0;
      final memoizer = Memoizer<int, int>((input) {
        expensiveCount++;
        // Simulate expensive computation
        var sum = 0;
        for (var i = 0; i < input; i++) {
          sum += i;
        }
        return sum;
      });

      expect(memoizer.call(1000), isNotNull);
      expect(expensiveCount, 1);
      
      // Multiple calls, still only one computation
      for (var i = 0; i < 10; i++) {
        memoizer.call(1000);
      }
      expect(expensiveCount, 1);
    });
  });

  group('Debouncer Integration', () {
    test('debouncer for search optimization', () async {
      final debouncer = Debouncer(milliseconds: 200);
      final searchResults = <String>[];
      
      // Simulate rapid search input
      void search(String query) {
        debouncer.run(() => searchResults.add(query));
      }
      
      search('h');
      await Future.delayed(const Duration(milliseconds: 50));
      search('he');
      await Future.delayed(const Duration(milliseconds: 50));
      search('hel');
      await Future.delayed(const Duration(milliseconds: 50));
      search('hello');
      
      // Only final search should execute
      await Future.delayed(const Duration(milliseconds: 250));
      expect(searchResults, ['hello']);
    });
  });

  group('Memoizer Integration', () {
    test('memoize fibonacci', () {
      // Create memoized fibonacci
      late Memoizer<int, int> fib;
      fib = Memoizer<int, int>((n) {
        if (n <= 1) return n;
        return fib.call(n - 1) + fib.call(n - 2);
      });

      expect(fib.call(0), 0);
      expect(fib.call(1), 1);
      expect(fib.call(10), 55);
      expect(fib.call(15), 610);
    });

    test('memoize factorial', () {
      late Memoizer<int, int> factorial;
      factorial = Memoizer<int, int>((n) {
        if (n <= 1) return 1;
        return n * factorial.call(n - 1);
      });

      expect(factorial.call(0), 1);
      expect(factorial.call(5), 120);
      expect(factorial.call(10), 3628800);
    });
  });
}
