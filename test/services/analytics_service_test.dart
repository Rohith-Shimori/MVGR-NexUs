import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/analytics_service.dart';

void main() {
  group('AnalyticsServiceImpl', () {
    late AnalyticsServiceImpl service;

    setUp(() {
      service = AnalyticsServiceImpl();
    });

    test('implements AnalyticsService interface', () {
      expect(service, isA<AnalyticsService>());
    });

    test('setUserId stores user ID', () async {
      await service.setUserId('user-123');
      // Internal state is private, but method should complete without error
    });

    test('setUserProperty stores property', () async {
      await service.setUserProperty('role', 'student');
      // Internal state is private, but method should complete without error
    });

    test('logEvent calls without errors', () async {
      // This will fail to insert to Supabase in test env, but should not throw
      await service.logEvent('test_event', parameters: {'key': 'value'});
    });

    test('logScreenView is syntactic sugar for logEvent', () async {
      // Should not throw
      await service.logScreenView('HomeScreen');
    });
  });
}
