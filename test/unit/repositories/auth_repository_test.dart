import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mvgr_nexus/core/errors/app_exception.dart';
import 'package:mvgr_nexus/data/repositories/auth_repository_impl.dart';
import 'package:mvgr_nexus/data/models/user_model.dart';

import '../../helpers/test_helper.mocks.dart';

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    
    // Stub authStateChanges stream for initialization
    when(mockRemoteDataSource.authStateChanges).thenAnswer((_) => Stream.empty());
    when(mockLocalDataSource.getCachedUser()).thenAnswer((_) async => null);

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  tearDown(() {
    repository.dispose();
  });

  group('AuthRepositoryImpl', () {
    final tUserModel = UserModel(
      id: 'test_id',
      email: 'test@example.com',
      name: 'Test User',
      role: 'student',
      department: 'CSE',
      year: 3,
      createdAt: DateTime.now(),
    );
    final tUser = tUserModel.toEntity();

    test('signInWithEmail should return User when successful', () async {
      // Arrange
      when(mockRemoteDataSource.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => tUserModel);
      
      when(mockLocalDataSource.cacheUser(any)).thenAnswer((_) async => {});

      // Act
      final result = await repository.signInWithEmail(
        email: 'test@example.com',
        password: 'password',
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.valueOrNull, equals(tUser));
      verify(mockRemoteDataSource.signInWithEmail(
        email: 'test@example.com',
        password: 'password',
      )).called(1);
      verify(mockLocalDataSource.cacheUser(tUserModel)).called(1);
    });

    test('signInWithEmail should return Failure when exception occurs', () async {
      // Arrange
      when(mockRemoteDataSource.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(AppAuthException.invalidCredentials());

      // Act
      final result = await repository.signInWithEmail(
        email: 'test@example.com',
        password: 'password',
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, isA<AppAuthException>());
    });

    test('signOut should clear cache and return success', () async {
      // Arrange
      when(mockRemoteDataSource.signOut()).thenAnswer((_) async => {});
      when(mockLocalDataSource.clearCache()).thenAnswer((_) async => {});

      // Act
      final result = await repository.signOut();

      // Assert
      expect(result.isSuccess, true);
      verify(mockRemoteDataSource.signOut()).called(1);
      verify(mockLocalDataSource.clearCache()).called(1);
    });
  });
}
