import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:mvgr_nexus/domain/repositories/auth_repository.dart';
import 'package:mvgr_nexus/services/supabase_club_service.dart';
import 'package:mvgr_nexus/services/supabase_event_service.dart';
import 'package:mvgr_nexus/services/supabase_storage_service.dart';
import 'package:mvgr_nexus/data/datasources/remote/auth_remote_datasource.dart';
import 'package:mvgr_nexus/data/datasources/local/auth_local_datasource.dart';
import 'package:mvgr_nexus/features/auth/providers/auth_provider.dart';

@GenerateMocks([
  supabase.SupabaseClient,
  supabase.GoTrueClient,
  supabase.User,
  AuthRepository,
  SupabaseClubService,
  SupabaseEventService,
  SupabaseStorageService,
  AuthRemoteDataSource,
  AuthLocalDataSource,
  AuthProvider,
  supabase.SupabaseQueryBuilder,
  supabase.PostgrestFilterBuilder,
  supabase.PostgrestTransformBuilder,
])
void main() {}
