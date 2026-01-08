/// Environment configuration for MVGR NexUs
/// Supports dev, staging, and production environments
library;
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
  final bool useMockData;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.enableLogging,
    required this.enableAnalytics,
    required this.useMockData,
  });

  /// Development configuration
  static const dev = AppConfig(
    environment: Environment.dev,
    supabaseUrl: 'https://xbffcwomhznvmjszmlvl.supabase.co', // Replace with actual URL
    supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhiZmZjd29taHpudm1qc3ptbHZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3Njk0NDAsImV4cCI6MjA4MzM0NTQ0MH0.Xt_gpZ8b58vK5aRM7oZFE2_m1jt0Zsw6U4P_lrbFMKs', // Replace with actual key
    enableLogging: true,
    enableAnalytics: false,
    useMockData: false, // Use real Supabase auth and data
  );

  /// Staging configuration
  static const staging = AppConfig(
    environment: Environment.staging,
    supabaseUrl: 'YOUR_STAGING_SUPABASE_URL',
    supabaseAnonKey: 'YOUR_STAGING_SUPABASE_ANON_KEY',
    enableLogging: true,
    enableAnalytics: true,
    useMockData: false,
  );

  /// Production configuration
  static const prod = AppConfig(
    environment: Environment.prod,
    supabaseUrl: 'YOUR_PROD_SUPABASE_URL',
    supabaseAnonKey: 'YOUR_PROD_SUPABASE_ANON_KEY',
    enableLogging: false,
    enableAnalytics: true,
    useMockData: false,
  );

  /// Get config for current environment
  static AppConfig get current {
    switch (Environment.current) {
      case Environment.prod:
        return prod;
      case Environment.staging:
        return staging;
      case Environment.dev:
        return dev;
    }
  }
}
