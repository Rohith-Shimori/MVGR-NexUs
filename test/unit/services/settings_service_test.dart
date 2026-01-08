import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/settings_service.dart';

/// Note: SettingsService is a singleton that auto-saves to SharedPreferences,
/// which makes unit testing complex. These tests focus on the enum and pure
/// logic tests. Integration/widget tests would be needed for full SettingsService
/// testing with proper mocking.

void main() {
  group('AppThemeMode', () {
    test('has system value', () {
      expect(AppThemeMode.system, isA<AppThemeMode>());
    });

    test('has light value', () {
      expect(AppThemeMode.light, isA<AppThemeMode>());
    });

    test('has dark value', () {
      expect(AppThemeMode.dark, isA<AppThemeMode>());
    });

    test('displayName returns System for system mode', () {
      expect(AppThemeMode.system.displayName, 'System');
    });

    test('displayName returns Light for light mode', () {
      expect(AppThemeMode.light.displayName, 'Light');
    });

    test('displayName returns Dark for dark mode', () {
      expect(AppThemeMode.dark.displayName, 'Dark');
    });

    test('values contains all modes', () {
      expect(AppThemeMode.values.length, 3);
      expect(AppThemeMode.values, contains(AppThemeMode.system));
      expect(AppThemeMode.values, contains(AppThemeMode.light));
      expect(AppThemeMode.values, contains(AppThemeMode.dark));
    });
  });

  group('SettingsService instance', () {
    test('instance returns singleton', () {
      final instance1 = SettingsService.instance;
      final instance2 = SettingsService.instance;
      expect(identical(instance1, instance2), true);
    });
  });
}
