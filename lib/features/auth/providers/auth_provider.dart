/// Auth Provider - State Management for Authentication
/// Uses the new clean architecture
library;

import 'package:flutter/foundation.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../core/errors/result.dart';

/// Authentication state
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthState _state = AuthState.initial;
  User? _user;
  String? _errorMessage;

  AuthProvider(this._repository) {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    _repository.authStateChanges.listen((user) {
      _user = user;
      _state = user != null ? AuthState.authenticated : AuthState.unauthenticated;
      notifyListeners();
    });

    // Check initial state
    if (_repository.isAuthenticated) {
      _user = _repository.currentUser;
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  // User shortcuts
  String get userId => _user?.id ?? '';
  String get userName => _user?.name ?? 'Guest';
  String get userEmail => _user?.email ?? '';
  String? get userPhotoUrl => _user?.photoUrl;
  UserRole get userRole => _user?.role ?? UserRole.student;

  // Role checks
  bool get isStudent => userRole == UserRole.student;
  bool get isClubAdmin => userRole == UserRole.clubAdmin;
  bool get isCouncil => userRole == UserRole.council;
  bool get isFaculty => userRole == UserRole.faculty;
  bool get canModerate => userRole.canModerate;
  bool get canCreateClub => userRole.canCreateClub;
  bool get canCreateEvent => userRole.canCreateEvent;

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Sign in with email and password
  Future<Result<User>> signIn({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.signInWithEmail(
      email: email,
      password: password,
    );

    result.fold(
      onSuccess: (user) {
        _user = user;
        _state = AuthState.authenticated;
      },
      onFailure: (error) {
        _errorMessage = error.message;
        _state = AuthState.error;
      },
    );

    notifyListeners();
    return result;
  }

  /// Sign up with email and password
  Future<Result<User>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.signUpWithEmail(
      email: email,
      password: password,
      name: name,
    );

    result.fold(
      onSuccess: (user) {
        _user = user;
        _state = AuthState.authenticated;
      },
      onFailure: (error) {
        _errorMessage = error.message;
        _state = AuthState.error;
      },
    );

    notifyListeners();
    return result;
  }

  /// Sign out
  Future<void> signOut() async {
    _state = AuthState.loading;
    notifyListeners();

    await _repository.signOut();
    
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  /// Update user profile
  Future<Result<User>> updateProfile({
    String? name,
    String? photoUrl,
    String? department,
    int? year,
    String? rollNumber,
    String? bio,
    List<String>? interests,
  }) async {
    final result = await _repository.updateProfile(
      name: name,
      photoUrl: photoUrl,
      department: department,
      year: year,
      rollNumber: rollNumber,
      bio: bio,
      interests: interests,
    );

    result.onSuccess((user) {
      _user = user;
      notifyListeners();
    });

    return result;
  }

  /// Send password reset email
  Future<Result<void>> sendPasswordReset(String email) {
    return _repository.sendPasswordResetEmail(email);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = _user != null ? AuthState.authenticated : AuthState.unauthenticated;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    // Close the auth state stream in the repository
    (_repository as AuthRepositoryImpl).dispose();
    super.dispose();
  }
}
