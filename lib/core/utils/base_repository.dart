/// Base Repository
/// Common functionality for all repositories
library;

import '../errors/result.dart';
import '../errors/app_exception.dart';

/// Base class for all repositories
/// Provides common error handling and utility methods
abstract class BaseRepository {
  /// Execute an async operation and wrap result
  Future<Result<T>> execute<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      return Result.success(result);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      return Result.failure(UnknownException.fromError(e, stackTrace));
    }
  }

  /// Execute an async operation that returns void
  Future<Result<void>> executeVoid(Future<void> Function() operation) async {
    try {
      await operation();
      return Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      return Result.failure(UnknownException.fromError(e, stackTrace));
    }
  }
}
