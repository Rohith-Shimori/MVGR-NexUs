/// Auth Repository Implementation
/// Coordinates between remote and local data sources
library;

import 'dart:async';
import '../../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../core/errors/app_exception.dart';
import '../../core/errors/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../datasources/local/auth_local_datasource.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  User? _currentUser;
  final _authStateController = StreamController<User?>.broadcast();

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  }) {
    _init();
  }

  void _init() {
    // Listen to Supabase auth changes
    remoteDataSource.authStateChanges.listen((state) async {
      switch (state.event) {
        case supabase.AuthChangeEvent.signedIn:
          if (state.session?.user != null) {
            await _loadUser(state.session!.user.id);
          }
          break;
        case supabase.AuthChangeEvent.signedOut:
          _currentUser = null;
          await localDataSource.clearCache();
          _authStateController.add(null);
          break;
        case supabase.AuthChangeEvent.tokenRefreshed:
          // Session refreshed, user still valid
          break;
        default:
          break;
      }
    });

    // Load cached user on init
    _loadCachedUser();
  }

  Future<void> _loadCachedUser() async {
    final cached = await localDataSource.getCachedUser();
    if (cached != null) {
      _currentUser = cached.toEntity();
      _authStateController.add(_currentUser);
    }
  }

  Future<void> _loadUser(String userId) async {
    try {
      final profile = await remoteDataSource.getUserProfile(userId);
      if (profile != null) {
        _currentUser = profile.toEntity();
        await localDataSource.cacheUser(profile);
        _authStateController.add(_currentUser);
      }
    } catch (e) {
      AppLogger.error(' Error loading user: $e');
    }
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  bool get isAuthenticated => _currentUser != null && remoteDataSource.currentSession != null;

  @override
  Future<Result<User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      _currentUser = userModel.toEntity();
      await localDataSource.cacheUser(userModel);
      _authStateController.add(_currentUser);
      return Result.success(_currentUser!);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(UnknownException.fromError(e));
    }
  }

  @override
  Future<Result<User>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userModel = await remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      _currentUser = userModel.toEntity();
      await localDataSource.cacheUser(userModel);
      _authStateController.add(_currentUser);
      return Result.success(_currentUser!);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(UnknownException.fromError(e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      _currentUser = null;
      await localDataSource.clearCache();
      _authStateController.add(null);
      return Result.success(null);
    } catch (e) {
      return Result.failure(UnknownException.fromError(e));
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return Result.success(null);
    } catch (e) {
      return Result.failure(UnknownException.fromError(e));
    }
  }

  @override
  Future<Result<User>> updateProfile({
    String? name,
    String? photoUrl,
    String? department,
    int? year,
    String? rollNumber,
    String? bio,
    List<String>? interests,
  }) async {
    if (_currentUser == null) {
      return Result.failure(AppAuthException.notLoggedIn());
    }

    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (photoUrl != null) data['photo_url'] = photoUrl;
      if (department != null) data['department'] = department;
      if (year != null) data['year'] = year;
      if (rollNumber != null) data['roll_number'] = rollNumber;
      if (bio != null) data['bio'] = bio;
      if (interests != null) data['interests'] = interests;

      final updated = await remoteDataSource.updateUserProfile(
        _currentUser!.id,
        data,
      );
      _currentUser = updated.toEntity();
      await localDataSource.cacheUser(updated);
      _authStateController.add(_currentUser);
      return Result.success(_currentUser!);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(UnknownException.fromError(e));
    }
  }

  @override
  Future<Result<User>> getUserById(String userId) async {
    try {
      final profile = await remoteDataSource.getUserProfile(userId);
      if (profile == null) {
        return Result.failure(DataException.notFound('User'));
      }
      return Result.success(profile.toEntity());
    } catch (e) {
      return Result.failure(UnknownException.fromError(e));
    }
  }

  @override
  Future<Result<User>> refreshUser() async {
    if (_currentUser == null) {
      return Result.failure(AppAuthException.notLoggedIn());
    }
    return getUserById(_currentUser!.id);
  }

  @override
  Future<Result<bool>> isEmailRegistered(String email) async {
    // Supabase doesn't have a direct way to check this
    // Would need custom RPC or try/catch signup
    return Result.success(false);
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
