/// Result type for type-safe error handling
/// Inspired by Rust's Result and functional programming patterns
library;

import 'app_exception.dart';

/// A type that represents either a success value or a failure
/// Use this instead of throwing exceptions for expected error cases
sealed class Result<T> {
  const Result();

  /// Create a success result
  factory Result.success(T value) = Success<T>;

  /// Create a failure result
  factory Result.failure(AppException error) = Failure<T>;

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Get value if success, null otherwise
  T? get valueOrNull => isSuccess ? (this as Success<T>).value : null;

  /// Get error if failure, null otherwise
  AppException? get errorOrNull => isFailure ? (this as Failure<T>).error : null;

  /// Get value or throw the error
  T get valueOrThrow {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    throw (this as Failure<T>).error;
  }

  /// Get value or return default
  T valueOr(T defaultValue) {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    }
    return defaultValue;
  }

  /// Transform the success value
  Result<R> map<R>(R Function(T value) transform) {
    if (this is Success<T>) {
      return Result.success(transform((this as Success<T>).value));
    }
    return Result.failure((this as Failure<T>).error);
  }

  /// Transform the success value with a function that returns Result
  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    if (this is Success<T>) {
      return transform((this as Success<T>).value);
    }
    return Result.failure((this as Failure<T>).error);
  }

  /// Transform the error
  Result<T> mapError(AppException Function(AppException error) transform) {
    if (this is Failure<T>) {
      return Result.failure(transform((this as Failure<T>).error));
    }
    return this;
  }

  /// Handle both cases
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppException error) onFailure,
  }) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).value);
    }
    return onFailure((this as Failure<T>).error);
  }

  /// Execute callback if success
  Result<T> onSuccess(void Function(T value) callback) {
    if (this is Success<T>) {
      callback((this as Success<T>).value);
    }
    return this;
  }

  /// Execute callback if failure
  Result<T> onFailure(void Function(AppException error) callback) {
    if (this is Failure<T>) {
      callback((this as Failure<T>).error);
    }
    return this;
  }
}

/// Success case of Result
class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Failure case of Result
class Failure<T> extends Result<T> {
  final AppException error;

  const Failure(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && runtimeType == other.runtimeType && error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure(${error.message})';
}

/// Extension to wrap async operations in Result
extension ResultExtension<T> on Future<T> {
  /// Wrap a Future in a Result, catching any exceptions
  Future<Result<T>> toResult() async {
    try {
      final value = await this;
      return Result.success(value);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      return Result.failure(UnknownException.fromError(e, stackTrace));
    }
  }
}

/// Helper to run a function and wrap in Result
Result<T> runCatching<T>(T Function() block) {
  try {
    return Result.success(block());
  } on AppException catch (e) {
    return Result.failure(e);
  } catch (e, stackTrace) {
    return Result.failure(UnknownException.fromError(e, stackTrace));
  }
}

/// Helper to run an async function and wrap in Result
Future<Result<T>> runCatchingAsync<T>(Future<T> Function() block) async {
  try {
    return Result.success(await block());
  } on AppException catch (e) {
    return Result.failure(e);
  } catch (e, stackTrace) {
    return Result.failure(UnknownException.fromError(e, stackTrace));
  }
}
