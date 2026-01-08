/// Base Repository - Foundation for all feature repositories
/// Provides common CRUD operations with error handling
library;

import '../core/errors/result.dart';
import '../config/supabase_config.dart';
import '../config/environment.dart';

/// Base class for all repositories
/// Provides common error handling and Supabase access
abstract class BaseRepository<T> {
  /// Table name in Supabase
  String get tableName;

  /// Convert model to map for database
  Map<String, dynamic> toJson(T model);

  /// Convert map from database to model
  T fromJson(Map<String, dynamic> json);

  /// Get ID from model
  String getId(T model);

  /// Check if using mock data
  bool get useMockData => AppConfig.current.useMockData;

  /// Get Supabase client (returns dynamic to avoid compile-time issues when mock)
  dynamic get client => SupabaseConfig.client;

  /// Get all items
  Future<Result<List<T>>> getAll() async {
    return runCatchingAsync(() async {
      final response = await client.from(tableName).select();
      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Get item by ID
  Future<Result<T?>> getById(String id) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return fromJson(response as Map<String, dynamic>);
    });
  }

  /// Get items by field value
  Future<Result<List<T>>> getByField(String field, dynamic value) async {
    return runCatchingAsync(() async {
      final response = await client
          .from(tableName)
          .select()
          .eq(field, value);

      return (response as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Create new item
  Future<Result<T>> create(T model) async {
    return runCatchingAsync(() async {
      final data = toJson(model);
      await client.from(tableName).insert(data);
      return model;
    });
  }

  /// Update existing item
  Future<Result<T>> update(T model) async {
    return runCatchingAsync(() async {
      final data = toJson(model);
      final id = getId(model);
      await client.from(tableName).update(data).eq('id', id);
      return model;
    });
  }

  /// Delete item by ID
  Future<Result<void>> delete(String id) async {
    return runCatchingAsync(() async {
      await client.from(tableName).delete().eq('id', id);
    });
  }

  /// Upsert (insert or update)
  Future<Result<T>> upsert(T model) async {
    return runCatchingAsync(() async {
      final data = toJson(model);
      await client.from(tableName).upsert(data);
      return model;
    });
  }

  /// Stream of all items (real-time updates)
  Stream<List<T>> streamAll() {
    return client
        .from(tableName)
        .stream(primaryKey: ['id'])
        .map((data) => (data as List).map((e) => fromJson(e as Map<String, dynamic>)).toList());
  }

  /// Stream items by field value
  Stream<List<T>> streamByField(String field, dynamic value) {
    return client
        .from(tableName)
        .stream(primaryKey: ['id'])
        .eq(field, value)
        .map((data) => (data as List).map((e) => fromJson(e as Map<String, dynamic>)).toList());
  }
}
