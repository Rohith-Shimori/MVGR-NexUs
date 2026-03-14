import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interface for analytics tracking
abstract class AnalyticsService {
  /// Log a specific event with optional parameters
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});

  /// Log when a user views a screen
  Future<void> logScreenView(String screenName);

  /// Log user properties (e.g., role, club membership)
  Future<void> setUserProperty(String name, String value);
  
  /// Set the current user ID for tracking
  Future<void> setUserId(String? userId);
}

/// Implementation of AnalyticsService
/// Stores analytics events to Supabase for tracking user behavior
class AnalyticsServiceImpl implements AnalyticsService {
  final _supabase = Supabase.instance.client;
  String? _currentUserId;
  final Map<String, String> _userProperties = {};
  
  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    if (kDebugMode) {
      AppLogger.info(' [Analytics] Event: $name, Params: $parameters');
    }
    
    try {
      await _supabase.from(SupabaseTables.analyticsEvents).insert({
        'event_name': name,
        'parameters': parameters,
        'user_id': _currentUserId,
        'user_properties': _userProperties.isNotEmpty ? _userProperties : null,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Don't fail silently but also don't crash the app for analytics
      if (kDebugMode) {
        AppLogger.warning(' Analytics event failed: $e');
      }
    }
  }

  @override
  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', parameters: {'screen_name': screenName});
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    _userProperties[name] = value;
    if (kDebugMode) {
      AppLogger.info(' [Analytics] User Property: $name = $value');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    _currentUserId = userId;
    if (kDebugMode) {
      AppLogger.info(' [Analytics] Set User ID: $userId');
    }
  }
}

