/// Auth Remote Data Source
/// Handles all Supabase auth operations
library;


import '../../../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../models/user_model.dart';

/// Contract for remote auth operations
abstract class AuthRemoteDataSource {
  /// Current session
  Session? get currentSession;
  
  /// Stream of auth changes
  Stream<AuthState> get authStateChanges;

  /// Sign in with email/password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email/password
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  /// Sign out
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Get user profile from database
  Future<UserModel?> getUserProfile(String userId);

  /// Update user profile in database
  Future<UserModel> updateUserProfile(String userId, Map<String, dynamic> data);

  /// Create user profile in database
  Future<UserModel> createUserProfile(UserModel user);
}

/// Implementation using Supabase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AppAuthException.invalidCredentials();
      }

      // Get or create profile
      final profile = await getUserProfile(response.user!.id);
      if (profile != null) {
        // Update last login
        return updateUserProfile(response.user!.id, {
          'last_login_at': DateTime.now().toIso8601String(),
        });
      }

      // Create profile if doesn't exist
      return createUserProfile(UserModel(
        id: response.user!.id,
        email: response.user!.email ?? email,
        name: response.user!.userMetadata?['name'] ?? email.split('@').first,
        createdAt: DateTime.now(),
      ));
    } on AuthException catch (e) {
      AppLogger.error(' Auth error: ${e.message}');
      throw AppAuthException(message: e.message, code: e.statusCode);
    }
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) {
        throw AppAuthException(message: 'Failed to create account');
      }

      // Create user profile
      return createUserProfile(UserModel(
        id: response.user!.id,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        isEmailVerified: response.user!.emailConfirmedAt != null,
      ));
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw AppAuthException.emailAlreadyInUse();
      }
      throw AppAuthException(message: e.message, code: e.statusCode);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      AppLogger.error(' Error getting user profile: $e');
      return null;
    }
  }

  @override
  Future<UserModel> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('users')
          .update(data)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      AppLogger.error(' Error updating profile: $e');
      throw DataException.operationFailed('update profile');
    }
  }

  @override
  Future<UserModel> createUserProfile(UserModel user) async {
    try {
      final response = await _client
          .from('users')
          .upsert(user.toJson())
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      AppLogger.error(' Error creating profile: $e');
      throw DataException.operationFailed('create profile');
    }
  }
}
