import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/core/utils/extensions.dart';

void main() {
  group('DateTimeExtensions', () {
    group('formattedDate', () {
      test('formats date correctly', () {
        final date = DateTime(2024, 12, 25);
        expect(date.formattedDate, 'Dec 25, 2024');
      });
    });

    group('formattedTime', () {
      test('formats AM time correctly', () {
        final time = DateTime(2024, 1, 1, 10, 30);
        expect(time.formattedTime, '10:30 AM');
      });

      test('formats PM time correctly', () {
        final time = DateTime(2024, 1, 1, 14, 45);
        expect(time.formattedTime, '2:45 PM');
      });
    });

    group('timeAgo', () {
      test('returns Just now for recent timestamps', () {
        final now = DateTime.now().subtract(const Duration(seconds: 30));
        expect(now.timeAgo, 'Just now');
      });

      test('returns minutes ago for short durations', () {
        final past = DateTime.now().subtract(const Duration(minutes: 5));
        expect(past.timeAgo, '5 minutes ago');
      });

      test('returns singular minute for 1 minute', () {
        final past = DateTime.now().subtract(const Duration(minutes: 1));
        expect(past.timeAgo, '1 minute ago');
      });

      test('returns hours ago for longer durations', () {
        final past = DateTime.now().subtract(const Duration(hours: 3));
        expect(past.timeAgo, '3 hours ago');
      });

      test('returns Yesterday for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(hours: 30));
        expect(yesterday.timeAgo, 'Yesterday');
      });

      test('returns days ago for recent past', () {
        final past = DateTime.now().subtract(const Duration(days: 5));
        expect(past.timeAgo, '5 days ago');
      });

      test('returns weeks ago for weeks past', () {
        final past = DateTime.now().subtract(const Duration(days: 14));
        expect(past.timeAgo, '2 weeks ago');
      });
    });

    group('isToday', () {
      test('returns true for today', () {
        expect(DateTime.now().isToday, true);
      });

      test('returns false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(yesterday.isToday, false);
      });
    });

    group('isTomorrow', () {
      test('returns true for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(tomorrow.isTomorrow, true);
      });

      test('returns false for today', () {
        expect(DateTime.now().isTomorrow, false);
      });
    });

    group('isPast', () {
      test('returns true for past dates', () {
        final past = DateTime.now().subtract(const Duration(days: 1));
        expect(past.isPast, true);
      });

      test('returns false for future dates', () {
        final future = DateTime.now().add(const Duration(days: 1));
        expect(future.isPast, false);
      });
    });

    group('isFuture', () {
      test('returns true for future dates', () {
        final future = DateTime.now().add(const Duration(days: 1));
        expect(future.isFuture, true);
      });

      test('returns false for past dates', () {
        final past = DateTime.now().subtract(const Duration(days: 1));
        expect(past.isFuture, false);
      });
    });

    group('startOfDay', () {
      test('returns midnight of the same day', () {
        final date = DateTime(2024, 6, 15, 14, 30, 45);
        expect(date.startOfDay, DateTime(2024, 6, 15));
      });
    });

    group('endOfDay', () {
      test('returns end of day', () {
        final date = DateTime(2024, 6, 15, 10, 0);
        expect(date.endOfDay, DateTime(2024, 6, 15, 23, 59, 59));
      });
    });
  });

  group('StringExtensions', () {
    group('capitalize', () {
      test('capitalizes first letter', () {
        expect('hello'.capitalize, 'Hello');
      });

      test('returns empty string for empty input', () {
        expect(''.capitalize, '');
      });

      test('handles already capitalized', () {
        expect('Hello'.capitalize, 'Hello');
      });
    });

    group('titleCase', () {
      test('capitalizes each word', () {
        expect('hello world'.titleCase, 'Hello World');
      });

      test('returns empty string for empty input', () {
        expect(''.titleCase, '');
      });
    });

    group('initials', () {
      test('returns two letters for two words', () {
        expect('John Doe'.initials, 'JD');
      });

      test('returns two letters for single word', () {
        expect('John'.initials, 'JO');
      });

      test('returns empty for empty string', () {
        expect(''.initials, '');
      });

      test('handles short single word', () {
        expect('J'.initials, 'J');
      });
    });

    group('isValidEmail', () {
      test('returns true for valid email', () {
        expect('test@example.com'.isValidEmail, true);
      });

      test('returns false for invalid email', () {
        expect('invalid-email'.isValidEmail, false);
      });

      test('returns false for empty string', () {
        expect(''.isValidEmail, false);
      });
    });

    group('isCollegeEmail', () {
      test('returns true for mvgrce.edu.in email', () {
        expect('student@mvgrce.edu.in'.isCollegeEmail, true);
      });

      test('returns true for student.mvgrce.edu.in email', () {
        expect('test@student.mvgrce.edu.in'.isCollegeEmail, true);
      });

      test('returns false for other emails', () {
        expect('test@gmail.com'.isCollegeEmail, false);
      });
    });

    group('truncate', () {
      test('truncates long strings', () {
        expect('This is a long string'.truncate(10), 'This is...');
      });

      test('returns original if shorter than max', () {
        expect('Short'.truncate(10), 'Short');
      });

      test('handles exact length', () {
        expect('1234567890'.truncate(10), '1234567890');
      });
    });

    group('stripHtml', () {
      test('removes HTML tags', () {
        expect('<p>Hello</p>'.stripHtml, 'Hello');
      });

      test('handles multiple tags', () {
        expect('<div><span>Hello</span> World</div>'.stripHtml, 'Hello World');
      });
    });
  });

  group('ListExtensions', () {
    group('getOrNull', () {
      test('returns element at valid index', () {
        expect([1, 2, 3].getOrNull(1), 2);
      });

      test('returns null for negative index', () {
        expect([1, 2, 3].getOrNull(-1), null);
      });

      test('returns null for index out of bounds', () {
        expect([1, 2, 3].getOrNull(5), null);
      });
    });

    group('chunk', () {
      test('splits list into chunks', () {
        expect([1, 2, 3, 4, 5].chunk(2), [
          [1, 2],
          [3, 4],
          [5]
        ]);
      });

      test('handles exact division', () {
        expect([1, 2, 3, 4].chunk(2), [
          [1, 2],
          [3, 4]
        ]);
      });

      test('handles empty list', () {
        expect(<int>[].chunk(2), <List<int>>[]);
      });
    });
  });

  group('NumberExtensions', () {
    group('compact', () {
      test('formats thousands as K', () {
        expect(1500.compact, '1.5K');
      });

      test('formats millions as M', () {
        expect(2500000.compact, '2.5M');
      });

      test('returns number for small values', () {
        expect(500.compact, '500');
      });
    });

    group('fileSize', () {
      test('formats bytes correctly', () {
        expect(500.fileSize, '500 B');
      });

      test('formats kilobytes correctly', () {
        expect(1536.fileSize, '1.50 KB');
      });

      test('formats megabytes correctly', () {
        expect(5242880.fileSize, '5.00 MB');
      });

      test('formats gigabytes correctly', () {
        expect(2147483648.fileSize, '2.00 GB');
      });
    });
  });
}
