import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Common mocks for re-use
@GenerateMocks([
  SupabaseClient,
  SupabaseQueryBuilder, 
  PostgrestFilterBuilder,
  PostgrestTransformBuilder
])
void main() {}
