import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/analytics_service.dart';

void main() {
  late AnalyticsServiceImpl service;

  setUp(() {
    service = AnalyticsServiceImpl();
  });

  group('AnalyticsServiceImpl', () {
    group('logEvent', () {
      test('logs event without parameters', () async {
        // Should complete without error
        await expectLater(
          service.logEvent('test_event'),
          completes,
        );
      });

      test('logs event with parameters', () async {
        await expectLater(
          service.logEvent('test_event', parameters: {
            'key1': 'value1',
            'key2': 42,
            'key3': true,
          }),
          completes,
        );
      });

      test('handles empty event name', () async {
        await expectLater(
          service.logEvent(''),
          completes,
        );
      });

      test('handles null parameters', () async {
        await expectLater(
          service.logEvent('test_event', parameters: null),
          completes,
        );
      });
    });

    group('logScreenView', () {
      test('logs screen view', () async {
        await expectLater(
          service.logScreenView('HomeScreen'),
          completes,
        );
      });

      test('handles empty screen name', () async {
        await expectLater(
          service.logScreenView(''),
          completes,
        );
      });

      test('logs various screen names', () async {
        final screens = ['LoginScreen', 'ProfileScreen', 'ClubsScreen', 'EventsScreen'];
        for (final screen in screens) {
          await expectLater(
            service.logScreenView(screen),
            completes,
          );
        }
      });
    });

    group('setUserProperty', () {
      test('sets user property', () async {
        await expectLater(
          service.setUserProperty('role', 'student'),
          completes,
        );
      });

      test('sets multiple user properties', () async {
        await service.setUserProperty('role', 'student');
        await service.setUserProperty('department', 'CSE');
        await service.setUserProperty('year', '3');
        // All should complete without error
        expect(true, true);
      });

      test('handles empty property name and value', () async {
        await expectLater(
          service.setUserProperty('', ''),
          completes,
        );
      });
    });

    group('setUserId', () {
      test('sets user ID', () async {
        await expectLater(
          service.setUserId('user_123'),
          completes,
        );
      });

      test('handles null user ID (logout)', () async {
        await expectLater(
          service.setUserId(null),
          completes,
        );
      });

      test('handles empty user ID', () async {
        await expectLater(
          service.setUserId(''),
          completes,
        );
      });
    });
  });
}
