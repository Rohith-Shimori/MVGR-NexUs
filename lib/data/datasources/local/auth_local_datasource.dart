/// Auth Local Data Source
/// Handles local caching of auth state
library;

import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import 'dart:convert';

/// Contract for local auth operations
abstract class AuthLocalDataSource {
  /// Get cached user
  Future<UserModel?> getCachedUser();

  /// Cache user locally
  Future<void> cacheUser(UserModel user);

  /// Clear cached user
  Future<void> clearCache();

  /// Check if user is cached
  Future<bool> hasCachedUser();
}

/// Implementation using SharedPreferences
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _userKey = 'cached_user';

  @override
  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_userKey);
    if (json == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  @override
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  @override
  Future<bool> hasCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }
}
