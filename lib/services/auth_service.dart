/// Authentication Service for MVGR NexUs
/// Handles all authentication operations with Supabase
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../config/supabase_config.dart';
import '../config/environment.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/result.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';
import 'user_service.dart';

/// Authentication state for the app
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

/// Auth service that handles all authentication operations
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;
  AuthService._();

  AuthStatus _state = AuthStatus.initial;
  AppUser? _currentUser;
  String? _errorMessage;

  // Getters
  AuthStatus get state => _state;
  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthStatus.authenticated;
  bool get isLoading => _state == AuthStatus.loading;
  String get userId => _currentUser?.uid ?? '';
  String get userName => _currentUser?.name ?? 'Guest';

  /// Initialize auth service - call on app start
  Future<void> initialize() async {
    _state = AuthStatus.loading;
    notifyListeners();

    // Check if using mock data in dev
    if (AppConfig.current.useMockData) {
      await _initializeMockAuth();
      return;
    }

    // Listen to auth state changes
    SupabaseConfig.authStateChanges.listen(_onAuthStateChange);

    // Check current session
    final session = SupabaseConfig.currentSession;
    if (session != null) {
      await _loadUserProfile(session.user.id);
    } else {
      _state = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Initialize mock auth for development
  Future<void> _initializeMockAuth() async {
    // Use test user for development
    _currentUser = AppUser.testStudent();
    _state = AuthStatus.authenticated;
    // Sync with MockUserService
    MockUserService.setCurrentUser(_currentUser!);
    notifyListeners();
  }

  /// Handle auth state changes from Supabase
  void _onAuthStateChange(supabase.AuthState state) async {
    switch (state.event) {
      case supabase.AuthChangeEvent.signedIn:
        if (state.session?.user != null) {
          await _loadUserProfile(state.session!.user.id);
        }
        break;
      case supabase.AuthChangeEvent.signedOut:
        _currentUser = null;
        _state = AuthStatus.unauthenticated;
        // Reset MockUserService to default student on logout
        MockUserService.loginAsStudent();
        notifyListeners();
        break;
      case supabase.AuthChangeEvent.tokenRefreshed:
        // Session refreshed, user still authenticated
        break;
      case supabase.AuthChangeEvent.userUpdated:
        if (state.session?.user != null) {
          await _loadUserProfile(state.session!.user.id);
        }
        break;
      default:
        break;
    }
  }

  /// Load user profile from database
  Future<void> _loadUserProfile(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseTables.users)
          .select()
          .eq('id', userId)
          .single();

      _currentUser = AppUser.fromFirestore(response);
      _state = AuthStatus.authenticated;
      _errorMessage = null;
      
      // CRITICAL: Sync with MockUserService so screens use the right user
      MockUserService.setCurrentUser(_currentUser!);
      debugPrint('✅ User synced: ${_currentUser!.name} (${_currentUser!.role.name})');
    } catch (e) {
      // User authenticated but no profile - create one
      final supabaseUser = SupabaseConfig.currentUser;
      if (supabaseUser != null) {
        _currentUser = AppUser(
          uid: supabaseUser.id,
          email: supabaseUser.email ?? '',
          name: supabaseUser.userMetadata?['name'] ?? 'New User',
          rollNumber: '',
          department: '',
          year: 1,
          createdAt: DateTime.now(),
        );
        _state = AuthStatus.authenticated;
        
        // Sync with MockUserService
        MockUserService.setCurrentUser(_currentUser!);
        debugPrint('✅ New user synced: ${_currentUser!.name}');
      } else {
        _state = AuthStatus.unauthenticated;
      }
    }
    notifyListeners();
  }

  /// Sign up with email and password
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
    required String name,
    required String rollNumber,
    required String department,
    required int year,
  }) async {
    _state = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate college email
      if (!email.toLowerCase().endsWith('@mvgrce.edu.in') &&
          !email.toLowerCase().endsWith('@student.mvgrce.edu.in')) {
        throw AppAuthException(
          message: 'Please use your college email (@mvgrce.edu.in)',
          code: 'INVALID_EMAIL_DOMAIN',
        );
      }

      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) {
        throw AppAuthException.invalidCredentials();
      }

      // Create user profile in database
      final user = AppUser(
        uid: response.user!.id,
        email: email,
        name: name,
        rollNumber: rollNumber,
        department: department,
        year: year,
        createdAt: DateTime.now(),
      );

      await SupabaseConfig.client
          .from(SupabaseTables.users)
          .insert(user.toFirestore());

      _currentUser = user;
      _state = AuthStatus.authenticated;
      notifyListeners();
      return Result.success(user);
    } on supabase.AuthException catch (e) {
      _state = AuthStatus.unauthenticated;
      _errorMessage = _mapSupabaseAuthError(e);
      notifyListeners();
      return Result.failure(AppAuthException(message: _errorMessage!, code: e.statusCode));
    } on AppException catch (e) {
      _state = AuthStatus.unauthenticated;
      _errorMessage = e.message;
      notifyListeners();
      return Result.failure(e);
    } catch (e) {
      _state = AuthStatus.unauthenticated;
      _errorMessage = 'Sign up failed. Please try again.';
      notifyListeners();
      return Result.failure(UnknownException.fromError(e));
    }
  }

  /// Sign in with email and password
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    _state = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AppAuthException.invalidCredentials();
      }

      await _loadUserProfile(response.user!.id);
      return Result.success(_currentUser!);
    } on supabase.AuthException catch (e) {
      _state = AuthStatus.unauthenticated;
      _errorMessage = _mapSupabaseAuthError(e);
      notifyListeners();
      return Result.failure(AppAuthException(message: _errorMessage!, code: e.statusCode));
    } catch (e) {
      _state = AuthStatus.unauthenticated;
      _errorMessage = 'Sign in failed. Please try again.';
      notifyListeners();
      return Result.failure(UnknownException.fromError(e));
    }
  }

  /// Sign out
  Future<Result<void>> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
      _currentUser = null;
      _state = AuthStatus.unauthenticated;
      _errorMessage = null;
      
      // CRITICAL: Sync with MockUserService - reset to default student
      MockUserService.loginAsStudent();
      debugPrint('🚪 Signed out - MockUserService reset');
      
      notifyListeners();
      return Result.success(null);
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      return Result.failure(UnknownException.fromError(e));
    }
  }

  /// Send password reset email
  Future<Result<void>> resetPassword(String email) async {
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(email);
      return Result.success(null);
    } on supabase.AuthException catch (e) {
      return Result.failure(AppAuthException(message: _mapSupabaseAuthError(e)));
    } catch (e) {
      return Result.failure(UnknownException.fromError(e));
    }
  }

  /// Update user profile
  Future<Result<AppUser>> updateProfile({
    String? name,
    String? bio,
    String? profilePhotoUrl,
    List<String>? interests,
    List<String>? skills,
  }) async {
    if (_currentUser == null) {
      return Result.failure(AppAuthException.notLoggedIn());
    }

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        bio: bio ?? _currentUser!.bio,
        profilePhotoUrl: profilePhotoUrl ?? _currentUser!.profilePhotoUrl,
        interests: interests ?? _currentUser!.interests,
        skills: skills ?? _currentUser!.skills,
      );

      await SupabaseConfig.client
          .from(SupabaseTables.users)
          .update(updatedUser.toFirestore())
          .eq('id', _currentUser!.uid);

      _currentUser = updatedUser;
      notifyListeners();
      return Result.success(updatedUser);
    } catch (e) {
      return Result.failure(UnknownException.fromError(e));
    }
  }

  /// Map Supabase auth errors to user-friendly messages
  String _mapSupabaseAuthError(supabase.AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login') || message.contains('invalid credentials')) {
      return 'Invalid email or password';
    } else if (message.contains('email not confirmed')) {
      return 'Please verify your email before logging in';
    } else if (message.contains('user already registered')) {
      return 'An account already exists with this email';
    } else if (message.contains('password')) {
      return 'Password must be at least 6 characters';
    } else if (message.contains('rate limit')) {
      return 'Too many attempts. Please wait and try again.';
    }
    return e.message;
  }

  /// For development - switch between test users
  void switchToTestUser(UserRole role) {
    if (!AppConfig.current.useMockData) return;

    switch (role) {
      case UserRole.student:
        _currentUser = AppUser.testStudent();
        break;
      case UserRole.clubAdmin:
        _currentUser = AppUser.testStudent(name: 'Club Admin', role: UserRole.clubAdmin)
            .copyWith(uid: 'club_admin_001');
        break;
      case UserRole.council:
        _currentUser = AppUser.testStudent(name: 'Council Member', role: UserRole.council)
            .copyWith(uid: 'council_001');
        break;
      case UserRole.faculty:
        _currentUser = AppUser.testStudent(name: 'Faculty', role: UserRole.faculty)
            .copyWith(uid: 'faculty_001');
        break;
    }
    notifyListeners();
  }
}

/// Global auth service instance
final authService = AuthService.instance;
