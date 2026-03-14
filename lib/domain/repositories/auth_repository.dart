/// Auth Repository Contract
/// Defines the interface for authentication operations
library;

import '../../core/errors/result.dart';
import '../entities/user.dart';

/// Authentication repository contract
/// Implemented by AuthRepositoryImpl in data layer
abstract class AuthRepository {
  /// Current authenticated user (null if not logged in)
  User? get currentUser;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges;
  
  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Sign in with email and password
  Future<Result<User>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Result<User>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  /// Sign out current user
  Future<Result<void>> signOut();

  /// Send password reset email
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Update user profile
  Future<Result<User>> updateProfile({
    String? name,
    String? photoUrl,
    String? department,
    int? year,
    String? rollNumber,
    String? bio,
    List<String>? interests,
  });

  /// Get user by ID
  Future<Result<User>> getUserById(String userId);

  /// Refresh current user data
  Future<Result<User>> refreshUser();

  /// Check if email is already registered
  Future<Result<bool>> isEmailRegistered(String email);
}
