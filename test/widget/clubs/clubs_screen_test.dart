import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:mvgr_nexus/features/clubs/screens/clubs_screen.dart';
import 'package:mvgr_nexus/features/clubs/models/club_model.dart';
import 'package:mvgr_nexus/services/supabase_club_service.dart';
import 'package:mvgr_nexus/features/auth/providers/auth_provider.dart';

import '../../helpers/test_helper.mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuthProvider = MockAuthProvider();

    // Setup AuthProvider mocks
    when(mockAuthProvider.user).thenReturn(null); // Guest
    when(mockAuthProvider.isLoading).thenReturn(false);
    when(mockAuthProvider.isAuthenticated).thenReturn(false);
    when(mockAuthProvider.addListener(any)).thenReturn(null);
    when(mockAuthProvider.removeListener(any)).thenReturn(null);

    // Setup ClubService singleton with mock client
    SupabaseClubService.instance.client = mockSupabaseClient;
    // Reset data
    SupabaseClubService.instance.clubs = [];

    // Setup ClubService singleton
    // We pre-fill the clubs cache to avoid mocking the complex Supabase network chain
    // ClubsScreen check: if (clubs.isEmpty) fetchClubs()
    // Since it's not empty, it won't call fetch, so we don't need to mock .from().select()...
    SupabaseClubService.instance.client = mockSupabaseClient;
  });

  testWidgets('ClubsScreen fetches and lists clubs', (WidgetTester tester) async {
    // Arrange Data
    final tClubs = [
      Club(
        id: '1',
        name: 'Test Club A',
        description: 'Desc A',
        category: ClubCategory.technical,
        memberCount: 0,
        adminCount: 0,
        isApproved: true,
        createdAt: DateTime.now(),
        createdBy: 'user1',
      ),
      Club(
        id: '2',
        name: 'Test Club B',
        description: 'Desc B',
        category: ClubCategory.cultural,
        memberCount: 0,
        adminCount: 0,
        isApproved: true,
        createdAt: DateTime.now(),
        createdBy: 'user2',
      ),
    ];
    
    // Pre-fill Service Cache
    SupabaseClubService.instance.clubs = tClubs;
    
    // We don't need to mock mockSupabaseClient.from(...) because it won't be called.
  
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ],
          child: const ClubsScreen(),
        ),
      ),
    );

    // Act
    await tester.pump(); // trigger build

    // Assert
    expect(find.text('Test Club A'), findsOneWidget);
    expect(find.text('Test Club B'), findsOneWidget);
  });
}
