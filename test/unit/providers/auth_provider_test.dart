import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mvgr_nexus/core/errors/app_exception.dart';
import 'package:mvgr_nexus/core/errors/result.dart';
import 'package:mvgr_nexus/domain/entities/user.dart';
import 'package:mvgr_nexus/features/auth/providers/auth_provider.dart';

import '../../helpers/test_helper.mocks.dart';

void main() {
  late AuthProvider authProvider;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    provideDummy(Result<void>.success(null));
    
    final tUser = User(
      id: 'dummy_id',
      email: 'dummy@example.com',
      name: 'Dummy', 
      role: UserRole.student,
      department: 'CSE',
      year: 1,
      createdAt: DateTime.now(),
    );
    provideDummy(Result<User>.success(tUser));

    mockAuthRepository = MockAuthRepository();
    
    // Stub initial state checks
    when(mockAuthRepository.authStateChanges).thenAnswer((_) => Stream.empty());
    when(mockAuthRepository.isAuthenticated).thenReturn(false);
    
    authProvider = AuthProvider(mockAuthRepository);
  });

  group('AuthProvider', () {
    final tUser = User(
      id: 'test_id',
      email: 'test@example.com',
      name: 'Test User',
      role: UserRole.student,
      department: 'CSE',
      year: 3,
      createdAt: DateTime.now(),
    );

    test('initial state should be unauthenticated when repository is not authenticated', () {
      expect(authProvider.state, AuthState.unauthenticated);
    });

    test('signIn should update state to authenticated on success', () async {
      // Arrange
      when(mockAuthRepository.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => Result.success(tUser));

      // Act
      await authProvider.signIn(email: 'test@example.com', password: 'password');

      // Assert
      expect(authProvider.state, AuthState.authenticated);
      expect(authProvider.user, tUser);
      verify(mockAuthRepository.signInWithEmail(
        email: 'test@example.com', 
        password: 'password'
      )).called(1);
    });

    test('signIn should update state to error on failure', () async {
      // Arrange
      final tError = AppAuthException.invalidCredentials();
      when(mockAuthRepository.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => Result.failure(tError));

      // Act
      await authProvider.signIn(email: 'test@example.com', password: 'password');

      // Assert
      expect(authProvider.state, AuthState.error);
      expect(authProvider.errorMessage, tError.message);
      expect(authProvider.user, null);
    });

    test('signOut should update state to unauthenticated', () async {
      // Arrange
      when(mockAuthRepository.signOut()).thenAnswer((_) async => Result.success(null));

      // Act
      await authProvider.signOut();

      // Assert
      expect(authProvider.state, AuthState.unauthenticated);
      expect(authProvider.user, null);
    });
  });
}
