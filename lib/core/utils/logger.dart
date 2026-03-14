/// Application Logger
/// Provides conditional logging that only outputs in debug mode
library;

import 'package:flutter/foundation.dart';

/// Centralized logging utility for the app
class AppLogger {
  /// Log debug messages (general information)
  static void debug(String message) {
    if (kDebugMode) debugPrint('🔍 $message');
  }
  
  /// Log info messages (important information)
  static void info(String message) {
    if (kDebugMode) debugPrint('ℹ️ $message');
  }
  
  /// Log success messages (operation completed)
  static void success(String message) {
    if (kDebugMode) debugPrint('✅ $message');
  }
  
  /// Log warning messages (potential issues)
  static void warning(String message) {
    if (kDebugMode) debugPrint('⚠️ $message');
  }
  
  /// Log error messages (failures)
  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('❌ $message${error != null ? ': $error' : ''}');
    }
  }
  
  /// Log network/API related messages
  static void network(String message) {
    if (kDebugMode) debugPrint('🌐 $message');
  }
  
  /// Log analytics events
  static void analytics(String event, {Map<String, dynamic>? params}) {
    if (kDebugMode) {
      debugPrint('📊 [Analytics] $event${params != null ? ', Params: $params' : ''}');
    }
  }
}
