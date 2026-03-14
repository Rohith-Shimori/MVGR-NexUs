import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mvgr_nexus/services/supabase_club_service.dart';
import 'package:mvgr_nexus/features/clubs/models/club_model.dart';
import 'supabase_club_service_test.mocks.dart';

@GenerateMocks([SupabaseClient])
void main() {
  late SupabaseClubService service;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    service = SupabaseClubService.instance;
    service.client = mockSupabaseClient;
    // Reset data
    service.clubs = [];
  });

  group('SupabaseClubService Logic', () {
    final testClub1 = Club(
      id: '1',
      name: 'Tech Club',
      description: 'Tech stuff',
      category: ClubCategory.technical,
      memberCount: 0,
      adminCount: 0,
      isApproved: true,
      createdAt: DateTime.now(),
      createdBy: 'user1',
    );

    final testClub2 = Club(
      id: '2',
      name: 'Dance Club',
      description: 'Dance stuff',
      category: ClubCategory.cultural,
      memberCount: 0,
      adminCount: 0,
      isApproved: false, // Not approved
      createdAt: DateTime.now(),
      createdBy: 'user2',
    );

    test('getClubById returns correct club', () {
      service.clubs = [testClub1, testClub2];
      
      final result = service.getClubById('1');
      expect(result, isNotNull);
      expect(result!.name, 'Tech Club');
    });

    test('getClubById returns null for unknown id', () {
      service.clubs = [testClub1];
      
      final result = service.getClubById('999');
      expect(result, isNull);
    });

    test('approvedClubs returns only approved clubs', () {
      service.clubs = [testClub1, testClub2];
      
      final result = service.approvedClubs;
      expect(result.length, 1);
      expect(result.first.id, '1');
      expect(result.any((c) => c.id == '2'), isFalse);
    });

    test('clubs getter returns all clubs', () {
      service.clubs = [testClub1, testClub2];
      expect(service.clubs.length, 2);
    });
  });
}
