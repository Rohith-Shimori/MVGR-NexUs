import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/core/utils/helpers.dart';

void main() {
  group('NameHelpers', () {
    group('getFirstName', () {
      test('returns first name from full name', () {
        expect(NameHelpers.getFirstName('John Doe'), 'John');
        expect(NameHelpers.getFirstName('Alice Smith Johnson'), 'Alice');
        expect(NameHelpers.getFirstName('Single'), 'Single');
      });

      test('returns "User" for null or empty name', () {
        expect(NameHelpers.getFirstName(null), 'User');
        expect(NameHelpers.getFirstName(''), 'User');
        expect(NameHelpers.getFirstName('   '), 'User');
      });

      test('handles names with extra whitespace', () {
        expect(NameHelpers.getFirstName('  John  Doe  '), 'John');
        expect(NameHelpers.getFirstName('  FirstName'), 'FirstName');
      });
    });

    group('getInitials', () {
      test('returns initials from full name', () {
        expect(NameHelpers.getInitials('John Doe'), 'JD');
        expect(NameHelpers.getInitials('Alice Smith'), 'AS');
        expect(NameHelpers.getInitials('Single'), 'S');
      });

      test('returns "?" for null or empty name', () {
        expect(NameHelpers.getInitials(null), '?');
        expect(NameHelpers.getInitials(''), '?');
        expect(NameHelpers.getInitials('   '), '?');
      });

      test('respects maxLength parameter', () {
        expect(NameHelpers.getInitials('John Doe Smith', maxLength: 3), 'JDS');
        expect(NameHelpers.getInitials('A B C D', maxLength: 2), 'AB');
        expect(NameHelpers.getInitials('One Two Three', maxLength: 1), 'O');
      });

      test('handles multiple word names', () {
        expect(NameHelpers.getInitials('Alice Bob Carol'), 'AB'); // Default max 2
        expect(NameHelpers.getInitials('X Y Z', maxLength: 3), 'XYZ');
      });
    });

    group('getAvatarChar', () {
      test('returns first character uppercase', () {
        expect(NameHelpers.getAvatarChar('John'), 'J');
        expect(NameHelpers.getAvatarChar('alice'), 'A');
        expect(NameHelpers.getAvatarChar('Test User'), 'T');
      });

      test('returns "?" for null or empty name', () {
        expect(NameHelpers.getAvatarChar(null), '?');
        expect(NameHelpers.getAvatarChar(''), '?');
        expect(NameHelpers.getAvatarChar('   '), '?');
      });
    });

    group('getDisplayName', () {
      test('returns trimmed name', () {
        expect(NameHelpers.getDisplayName('John Doe'), 'John Doe');
        expect(NameHelpers.getDisplayName('  Trimmed  '), 'Trimmed');
      });

      test('returns default fallback for null or empty name', () {
        expect(NameHelpers.getDisplayName(null), 'Unknown User');
        expect(NameHelpers.getDisplayName(''), 'Unknown User');
        expect(NameHelpers.getDisplayName('   '), 'Unknown User');
      });

      test('uses custom fallback when provided', () {
        expect(NameHelpers.getDisplayName(null, fallback: 'Guest'), 'Guest');
        expect(NameHelpers.getDisplayName('', fallback: 'Anonymous'), 'Anonymous');
      });
    });
  });

  group('Result', () {
    group('success', () {
      test('creates successful result with data', () {
        final result = Result.success('test data');
        expect(result.isSuccess, true);
        expect(result.data, 'test data');
        expect(result.error, isNull);
      });

      test('works with different types', () {
        final intResult = Result.success(42);
        expect(intResult.data, 42);

        final listResult = Result.success([1, 2, 3]);
        expect(listResult.data, [1, 2, 3]);
      });
    });

    group('failure', () {
      test('creates failed result with error', () {
        final result = Result<String>.failure('Something went wrong');
        expect(result.isSuccess, false);
        expect(result.error, 'Something went wrong');
        expect(result.data, isNull);
      });
    });

    group('when', () {
      test('calls success callback for successful result', () {
        final result = Result.success('data');
        final output = result.when(
          success: (data) => 'Got: $data',
          failure: (error) => 'Error: $error',
        );
        expect(output, 'Got: data');
      });

      test('calls failure callback for failed result', () {
        final result = Result<String>.failure('error message');
        final output = result.when(
          success: (data) => 'Got: $data',
          failure: (error) => 'Error: $error',
        );
        expect(output, 'Error: error message');
      });
    });
  });

  group('ErrorHandler', () {
    group('getUserMessage', () {
      test('returns user-friendly message for FormatException', () {
        final message = ErrorHandler.getUserMessage(const FormatException());
        expect(message, contains('Invalid data format'));
      });

      test('returns user-friendly message for ArgumentError', () {
        final message = ErrorHandler.getUserMessage(ArgumentError('test'));
        expect(message, contains('Invalid input'));
      });

      test('returns network error message for network-related errors', () {
        final message = ErrorHandler.getUserMessage(Exception('network error'));
        expect(message.toLowerCase(), contains('network'));
      });

      test('returns generic message for unknown errors', () {
        final message = ErrorHandler.getUserMessage(Exception('random error'));
        expect(message, contains('Something went wrong'));
      });
    });

    group('safeExecuteSync', () {
      test('returns success result when operation succeeds', () {
        final result = ErrorHandler.safeExecuteSync(() => 'success');
        expect(result.isSuccess, true);
        expect(result.data, 'success');
      });

      test('returns failure result when operation throws', () {
        final result = ErrorHandler.safeExecuteSync<String>(() {
          throw const FormatException('test error');
        });
        expect(result.isSuccess, false);
        expect(result.error, isNotNull);
      });
    });

    group('safeExecute (async)', () {
      test('returns success result for successful async operation', () async {
        final result = await ErrorHandler.safeExecute(() async => 'async success');
        expect(result.isSuccess, true);
        expect(result.data, 'async success');
      });

      test('returns failure result when async operation throws', () async {
        final result = await ErrorHandler.safeExecute<String>(() async {
          throw Exception('async error');
        });
        expect(result.isSuccess, false);
        expect(result.error, isNotNull);
      });
    });
  });
}
