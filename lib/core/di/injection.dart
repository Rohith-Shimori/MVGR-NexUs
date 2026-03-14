/// Dependency Injection Setup
/// Uses GetIt for service location
library;

import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Data Sources
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/local/auth_local_datasource.dart';

// Repositories
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

// Providers
import '../../features/auth/providers/auth_provider.dart';

// Services
import '../../services/analytics_service.dart';

/// Global service locator
final sl = GetIt.instance;

/// Initialize all dependencies
/// Call this in main() before runApp()
Future<void> initDependencies() async {
  // ═══════════════════════════════════════════════════════════════
  // CORE
  // ═══════════════════════════════════════════════════════════════
  
  // Supabase Client
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Analytics
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsServiceImpl());

  // ═══════════════════════════════════════════════════════════════
  // DATA SOURCES
  // ═══════════════════════════════════════════════════════════════
  
  // Remote
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  
  // Local
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );

  // ═══════════════════════════════════════════════════════════════
  // REPOSITORIES
  // ═══════════════════════════════════════════════════════════════
  
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // ═══════════════════════════════════════════════════════════════
  // PROVIDERS (State Management)
  // ═══════════════════════════════════════════════════════════════
  
  // Using factory so each widget tree gets fresh instance if needed
  // Or registerSingleton if you want app-wide single instance
  sl.registerLazySingleton<AuthProvider>(
    () => AuthProvider(sl()),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await sl.reset();
}
