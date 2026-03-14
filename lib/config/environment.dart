/// Environment configuration for MVGR NexUs
/// Supports dev, staging, and production environments
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Environment {
  dev,
  staging,
  prod;

  /// Get current environment from compile-time constant or default to dev
  static Environment get current {
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (envString) {
      case 'prod':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.dev;
    }
  }

  bool get isDev => this == Environment.dev;
  bool get isStaging => this == Environment.staging;
  bool get isProd => this == Environment.prod;
  bool get isDebug => this == Environment.dev || this == Environment.staging;
}

/// App configuration that varies by environment
class AppConfig {
  final Environment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableLogging;
  final bool enableAnalytics;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.enableLogging,
    required this.enableAnalytics,
  });

  /// Development configuration - loads from .env with dart-define fallback
  static AppConfig get dev => AppConfig(
    environment: Environment.dev,
    supabaseUrl: dotenv.env['SUPABASE_URL'] ?? 
        const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
    supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 
        const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
    enableLogging: true,
    enableAnalytics: false,
  );

  /// Staging configuration - loads from .env with dart-define fallback
  static AppConfig get staging => AppConfig(
    environment: Environment.staging,
    supabaseUrl: dotenv.env['SUPABASE_URL'] ?? 
        const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
    supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 
        const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
    enableLogging: true,
    enableAnalytics: true,
  );

  /// Production configuration - uses dart-define (no .env in production)
  static AppConfig get prod => AppConfig(
    environment: Environment.prod,
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
    enableLogging: false,
    enableAnalytics: true,
  );

  /// Get config for current environment with validation
  static AppConfig get current {
    final config = switch (Environment.current) {
      Environment.prod => prod,
      Environment.staging => staging,
      Environment.dev => dev,
    };
    
    // Fail fast if credentials are missing
    if (config.supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }
    if (config.supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }
    
    return config;
  }
}

