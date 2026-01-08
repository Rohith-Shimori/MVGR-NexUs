import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mvgr_nexus/services/mock_data_service.dart';
import 'package:mvgr_nexus/services/user_service.dart';
import 'package:mvgr_nexus/features/clubs/widgets/club_widgets.dart';
import 'package:mvgr_nexus/features/clubs/models/club_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createWidgetUnderTest(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => MockDataService(),
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('CategoryChip', () {
    testWidgets('renders label text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              label: 'Technical',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );
      
      expect(find.text('Technical'), findsOneWidget);
    });

    testWidgets('renders with icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              label: 'Music',
              icon: '🎵',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );
      
      expect(find.text('🎵'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              label: 'Test',
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      
      await tester.tap(find.text('Test'));
      expect(tapped, true);
    });

    testWidgets('shows selected state styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              label: 'Selected',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );
      
      // Widget should render without errors when selected
      expect(find.text('Selected'), findsOneWidget);
    });
  });

  group('ClubCard', () {
    final testClub = Club(
      id: 'test_club',
      name: 'Test Club',
      description: 'This is a test club description',
      category: ClubCategory.technical,
      adminIds: ['admin_1'],
      memberIds: ['admin_1', 'member_1'],
      createdAt: DateTime.now(),
      createdBy: 'admin_1',
      isApproved: true,
    );

    testWidgets('renders club name', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(child: ClubCard(club: testClub)),
      ));
      await tester.pump();
      
      expect(find.text('Test Club'), findsOneWidget);
    });

    testWidgets('renders club description', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(child: ClubCard(club: testClub)),
      ));
      await tester.pump();
      
      expect(find.textContaining('test club description'), findsOneWidget);
    });

    testWidgets('shows category name', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(child: ClubCard(club: testClub)),
      ));
      await tester.pump();
      
      expect(find.text('Technical'), findsOneWidget);
    });

    testWidgets('shows member count', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(child: ClubCard(club: testClub)),
      ));
      await tester.pump();
      
      expect(find.textContaining('members'), findsOneWidget);
    });

    testWidgets('shows verified badge for official clubs', (WidgetTester tester) async {
      final officialClub = Club(
        id: 'official_club',
        name: 'Official Club',
        description: 'Desc',
        category: ClubCategory.technical,
        adminIds: ['admin'],
        memberIds: [],
        createdAt: DateTime.now(),
        createdBy: 'admin',
        isOfficial: true,
      );
      
      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(child: ClubCard(club: officialClub)),
      ));
      await tester.pump();
      
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(
          child: ClubCard(
            club: testClub,
            onTap: () => tapped = true,
          ),
        ),
      ));
      await tester.pump();
      
      await tester.tap(find.byType(ClubCard));
      await tester.pump();
      expect(tapped, true);
    });
  });

  group('ClubStat', () {
    testWidgets('renders value and label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClubStat(value: '42', label: 'Members'),
          ),
        ),
      );
      
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Members'), findsOneWidget);
    });
  });

  group('ContactRow', () {
    testWidgets('renders icon and value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactRow(
              icon: Icons.email,
              value: 'test@example.com',
            ),
          ),
        ),
      );
      
      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });

  group('ClubEmptyState', () {
    testWidgets('renders icon, title, and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClubEmptyState(
              icon: Icons.group_off,
              title: 'No Clubs',
              subtitle: 'Join a club to get started',
            ),
          ),
        ),
      );
      
      expect(find.byIcon(Icons.group_off), findsOneWidget);
      expect(find.text('No Clubs'), findsOneWidget);
      expect(find.text('Join a club to get started'), findsOneWidget);
    });
  });

  group('ClubEmptyCard', () {
    testWidgets('renders message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClubEmptyCard(message: 'No posts yet'),
          ),
        ),
      );
      
      expect(find.text('No posts yet'), findsOneWidget);
    });
  });

  group('PostCard', () {
    final testPost = ClubPost(
      id: 'post_1',
      clubId: 'club_1',
      authorId: 'author_1',
      authorName: 'Author',
      title: 'Test Post Title',
      content: 'This is the post content',
      type: ClubPostType.announcement,
      createdAt: DateTime.now(),
    );

    testWidgets('renders post title', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(child: PostCard(post: testPost)),
      ));
      await tester.pump();
      
      expect(find.text('Test Post Title'), findsOneWidget);
    });

    testWidgets('renders post content', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(child: PostCard(post: testPost)),
      ));
      await tester.pump();
      
      expect(find.text('This is the post content'), findsOneWidget);
    });

    testWidgets('shows post type badge', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(child: PostCard(post: testPost)),
      ));
      await tester.pump();
      
      expect(find.text('Announcement'), findsOneWidget);
    });

    testWidgets('shows more menu button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(child: PostCard(post: testPost)),
      ));
      await tester.pump();
      
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('shows Apply Now button for recruitment posts', (WidgetTester tester) async {
      final recruitmentPost = ClubPost(
        id: 'post_recruit',
        clubId: 'club_1',
        authorId: 'author_1',
        authorName: 'Author',
        title: 'We are hiring!',
        content: 'Join our team',
        type: ClubPostType.recruitment,
        createdAt: DateTime.now(),
      );
      
      await tester.pumpWidget(createWidgetUnderTest(
        SingleChildScrollView(child: PostCard(post: recruitmentPost)),
      ));
      await tester.pump();
      
      expect(find.text('Apply Now'), findsOneWidget);
    });
  });

  group('MemberButton', () {
    testWidgets('shows Member badge when user is member', (WidgetTester tester) async {
      final club = Club(
        id: 'club_member',
        name: 'Club',
        description: 'Desc',
        category: ClubCategory.technical,
        adminIds: [],
        memberIds: [MockUserService.currentUser.uid],
        createdAt: DateTime.now(),
        createdBy: 'creator',
      );
      
      await tester.pumpWidget(createWidgetUnderTest(
        MemberButton(club: club, isMember: true),
      ));
      await tester.pump();
      
      expect(find.text('Member'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('shows Request to Join when not member', (WidgetTester tester) async {
      final club = Club(
        id: 'club_not_member',
        name: 'Club',
        description: 'Desc',
        category: ClubCategory.technical,
        adminIds: [],
        memberIds: [],
        createdAt: DateTime.now(),
        createdBy: 'creator',
        isApproved: true,
      );
      
      await tester.pumpWidget(createWidgetUnderTest(
        MemberButton(club: club, isMember: false),
      ));
      await tester.pump();
      
      expect(find.text('Request to Join'), findsOneWidget);
    });
  });

  group('CreateClubSheet', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        const CreateClubSheet(),
      ));
      await tester.pump();
      
      expect(find.byType(CreateClubSheet), findsOneWidget);
    });

    testWidgets('shows Create Club title', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        const SingleChildScrollView(child: CreateClubSheet()),
      ));
      await tester.pumpAndSettle();
      
      expect(find.text('Create Club'), findsAtLeast(1));
    });

    testWidgets('has name and description fields', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        const SingleChildScrollView(child: CreateClubSheet()),
      ));
      await tester.pumpAndSettle();
      
      expect(find.text('Club Name'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });
  });
}
