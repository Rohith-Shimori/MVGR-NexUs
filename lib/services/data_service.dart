import 'package:flutter/foundation.dart';
import 'mock_data_service.dart';
import 'supabase_data_service.dart';

/// Service provider that allows switching between Mock and Supabase data services
/// 
/// Usage:
/// ```dart
/// // Get the current service (works with either Mock or Supabase)
/// final service = DataService.instance;
/// 
/// // Switch to Supabase (call once at app startup)
/// DataService.useSupabase();
/// ```
class DataService {
  static ChangeNotifier? _instance;
  static bool _useSupabase = false;
  
  /// Get the current data service instance
  /// Returns MockDataService by default, or SupabaseDataService if useSupabase() was called
  static ChangeNotifier get instance {
    _instance ??= _useSupabase 
        ? SupabaseDataService() 
        : MockDataService();
    return _instance!;
  }
  
  /// Get as MockDataService (for backward compatibility)
  static MockDataService get mock {
    if (_useSupabase) {
      throw StateError('Cannot access MockDataService when using Supabase. Use DataService.instance instead.');
    }
    return instance as MockDataService;
  }
  
  /// Get as SupabaseDataService
  static SupabaseDataService get supabase {
    if (!_useSupabase) {
      throw StateError('Supabase not enabled. Call DataService.useSupabase() first.');
    }
    return instance as SupabaseDataService;
  }
  
  /// Switch to using Supabase for real data
  /// Call this once at app startup (before any screens load)
  static void useSupabase() {
    if (_instance != null) {
      debugPrint('Warning: DataService already initialized. Call useSupabase() before accessing instance.');
    }
    _useSupabase = true;
    _instance = null; // Reset so next access creates SupabaseDataService
  }
  
  /// Switch to using MockDataService (for testing/demo)
  static void useMock() {
    _useSupabase = false;
    _instance = null;
  }
  
  /// Check if currently using Supabase
  static bool get isUsingSupabase => _useSupabase;
  
  /// Reset for testing
  @visibleForTesting
  static void reset() {
    _instance = null;
    _useSupabase = false;
  }
}
