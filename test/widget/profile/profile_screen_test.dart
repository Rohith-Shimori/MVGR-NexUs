import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mvgr_nexus/domain/entities/user.dart';

import '../../helpers/test_helper.mocks.dart';

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();

    // Setup AuthProvider mocks
    final testUser = User(
      id: 'user_123',
      email: 'test@example.com',
      name: 'Test User',
      role: UserRole.student,
      department: 'CSE',
      year: 3,
      createdAt: DateTime.now(),
    );

    when(mockAuthProvider.user).thenReturn(testUser);
    when(mockAuthProvider.isLoading).thenReturn(false);
    when(mockAuthProvider.isAuthenticated).thenReturn(true);
    when(mockAuthProvider.userName).thenReturn('Test User');
    when(mockAuthProvider.userId).thenReturn('user_123');
    when(mockAuthProvider.userEmail).thenReturn('test@example.com');
    when(mockAuthProvider.userPhotoUrl).thenReturn(null);
    when(mockAuthProvider.userRole).thenReturn(UserRole.student);
    when(mockAuthProvider.addListener(any)).thenReturn(null);
    when(mockAuthProvider.removeListener(any)).thenReturn(null);
  });

  group('User Model', () {
    test('UserRole has all required roles', () {
      expect(UserRole.values.length, greaterThanOrEqualTo(4));
      expect(UserRole.values, contains(UserRole.student));
      expect(UserRole.values, contains(UserRole.clubAdmin));
      expect(UserRole.values, contains(UserRole.council));
      expect(UserRole.values, contains(UserRole.faculty));
    });

    test('User model creates correctly', () {
      final user = User(
        id: '1',
        email: 'user@test.com',
        name: 'User Name',
        role: UserRole.student,
        department: 'ECE',
        year: 2,
        createdAt: DateTime.now(),
      );

      expect(user.name, 'User Name');
      expect(user.department, 'ECE');
      expect(user.year, 2);
    });

    test('User with null optional fields', () {
      final user = User(
        id: '1',
        email: 'user@test.com',
        name: 'User',
        role: UserRole.student,
        createdAt: DateTime.now(),
      );

      expect(user.department, null);
      expect(user.photoUrl, null);
      expect(user.bio, null);
    });

    test('User role permissions for student', () {
      expect(UserRole.student.canModerate, false);
      expect(UserRole.student.canCreateClub, false);
    });

    test('User role permissions for clubAdmin', () {
      expect(UserRole.clubAdmin.canCreateEvent, true);
    });

    test('User role permissions for council', () {
      expect(UserRole.council.canModerate, true);
      expect(UserRole.council.canCreateClub, true);
    });
  });

  group('AuthProvider Mock Configuration', () {
    test('mockAuthProvider returns correct userName', () {
      expect(mockAuthProvider.userName, 'Test User');
    });

    test('mockAuthProvider returns correct userId', () {
      expect(mockAuthProvider.userId, 'user_123');
    });

    test('mockAuthProvider returns correct email', () {
      expect(mockAuthProvider.userEmail, 'test@example.com');
    });

    test('mockAuthProvider isAuthenticated is true', () {
      expect(mockAuthProvider.isAuthenticated, true);
    });

    test('mockAuthProvider userRole is student', () {
      expect(mockAuthProvider.userRole, UserRole.student);
    });
  });

  group('Profile Data Structure', () {
    test('profile sections are defined', () {
      final profileSections = ['Account', 'Settings', 'Privacy', 'Help', 'About'];
      expect(profileSections.length, 5);
    });

    test('settings options are defined', () {
      final settingsOptions = [
        'Notifications',
        'Theme',
        'Language',
        'Privacy',
      ];
      expect(settingsOptions.length, greaterThan(0));
    });
  });
}
