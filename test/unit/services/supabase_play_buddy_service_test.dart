import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/play_buddy/models/play_buddy_model.dart';

void main() {
  group('TeamCategory Enum', () {
    test('all categories are defined', () {
      expect(TeamCategory.values.length, 7);
    });

    test('displayName returns correct string', () {
      expect(TeamCategory.hackathon.displayName, 'Hackathon');
      expect(TeamCategory.sports.displayName, 'Sports');
      expect(TeamCategory.esports.displayName, 'E-Sports/Gaming');
      expect(TeamCategory.cultural.displayName, 'Cultural');
      expect(TeamCategory.academic.displayName, 'Academic Competition');
    });

    test('icon returns emoji', () {
      for (final category in TeamCategory.values) {
        expect(category.icon, isNotEmpty);
      }
    });

    test('iconData returns non-null icon', () {
      for (final category in TeamCategory.values) {
        expect(category.iconData, isNotNull);
      }
    });
  });

  group('TeamRequest Model', () {
    test('creates team with required fields', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'John Doe',
        title: 'Hackathon Team',
        description: 'Looking for teammates',
        category: TeamCategory.hackathon,
        teamSize: 4,
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      expect(team.id, '1');
      expect(team.title, 'Hackathon Team');
      expect(team.category, TeamCategory.hackathon);
      expect(team.teamSize, 4);
    });

    test('creates hackathon team with event details', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'User',
        title: 'SIH 2025 Team',
        description: 'Need ML engineers',
        category: TeamCategory.hackathon,
        eventName: 'Smart India Hackathon 2025',
        eventUrl: 'https://sih.gov.in',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        teamSize: 6,
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      expect(team.eventName, 'Smart India Hackathon 2025');
      expect(team.eventUrl, isNotEmpty);
      expect(team.eventDate, isNotNull);
    });

    test('creates sports team', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'Captain',
        title: 'Football Team',
        description: 'Looking for players',
        category: TeamCategory.sports,
        eventName: 'Inter-College Football',
        teamSize: 11,
        deadline: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now(),
      );

      expect(team.category, TeamCategory.sports);
      expect(team.teamSize, 11);
    });

    test('creates esports team with skill requirements', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'Gamer',
        title: 'Valorant Squad',
        description: 'Diamond+ only',
        category: TeamCategory.esports,
        teamSize: 5,
        requiredSkills: ['Diamond+', 'Team Player', 'Mic Required'],
        deadline: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
      );

      expect(team.category, TeamCategory.esports);
      expect(team.requiredSkills, contains('Diamond+'));
    });

    test('team with existing members', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'Creator',
        title: 'Team with Members',
        description: 'Partially filled',
        category: TeamCategory.project,
        teamSize: 5,
        currentMembers: 3,
        memberIds: ['user_2', 'user_3'],
        memberNames: ['Alice', 'Bob'],
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      expect(team.currentMembers, 3);
      expect(team.memberIds, contains('user_2'));
      expect(team.memberNames, contains('Alice'));
    });

    test('default status is open', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'Creator',
        title: 'New Team',
        description: 'Desc',
        category: TeamCategory.other,
        teamSize: 4,
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      expect(team.status, 'open');
    });
  });

  group('TeamRequest Computed Properties', () {
    test('isOpen returns true for open non-full team', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'Creator',
        title: 'Open Team',
        description: 'Desc',
        category: TeamCategory.hackathon,
        teamSize: 4,
        currentMembers: 2,
        status: 'open',
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      expect(team.isOpen, true);
    });

    test('isFull returns true when team is full', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'Creator',
        title: 'Full Team',
        description: 'Desc',
        category: TeamCategory.hackathon,
        teamSize: 4,
        currentMembers: 4,
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      expect(team.isFull, true);
      expect(team.isOpen, false);
    });

    test('isPastDeadline returns true for expired deadline', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'Creator',
        title: 'Expired Team',
        description: 'Desc',
        category: TeamCategory.hackathon,
        teamSize: 4,
        deadline: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      expect(team.isPastDeadline, true);
      expect(team.isOpen, false);
    });

    test('spotsLeft calculates correctly', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'Creator',
        title: 'Team',
        description: 'Desc',
        category: TeamCategory.hackathon,
        teamSize: 6,
        currentMembers: 4,
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      expect(team.spotsLeft, 2);
    });

    test('isMember checks user correctly', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'Creator',
        title: 'Team',
        description: 'Desc',
        category: TeamCategory.hackathon,
        teamSize: 4,
        memberIds: ['user_2', 'user_3'],
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      expect(team.isMember('user_1'), true);  // Creator
      expect(team.isMember('user_2'), true);  // Member
      expect(team.isMember('user_4'), false); // Not a member
    });

    test('isCreator checks correctly', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'Creator',
        title: 'Team',
        description: 'Desc',
        category: TeamCategory.hackathon,
        teamSize: 4,
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      expect(team.isCreator('user_1'), true);
      expect(team.isCreator('user_2'), false);
    });
  });

  group('TeamRequest copyWith', () {
    test('copyWith creates copy with updated fields', () {
      final original = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'Creator',
        title: 'Original',
        description: 'Desc',
        category: TeamCategory.hackathon,
        teamSize: 4,
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        status: 'closed',
        currentMembers: 4,
      );

      expect(updated.status, 'closed');
      expect(updated.currentMembers, 4);
      expect(updated.title, 'Original'); // Unchanged
    });
  });

  group('TeamRequest Serialization', () {
    test('toFirestore returns correct map', () {
      final team = TeamRequest(
        id: '1',
        creatorId: 'user_1',
        creatorName: 'John',
        title: 'Test Team',
        description: 'Testing',
        category: TeamCategory.esports,
        eventName: 'Tournament',
        teamSize: 5,
        requiredSkills: ['Skill1', 'Skill2'],
        deadline: DateTime(2024, 1, 22),
        createdAt: DateTime(2024, 1, 15),
      );

      final map = team.toFirestore();

      expect(map['creatorId'], 'user_1');
      expect(map['title'], 'Test Team');
      expect(map['category'], 'esports');
      expect(map['teamSize'], 5);
      expect(map['requiredSkills'], contains('Skill1'));
    });

    test('fromFirestore creates correct object', () {
      final data = {
        'id': '1',
        'creatorId': 'user_1',
        'creatorName': 'Jane',
        'title': 'From Firestore',
        'description': 'Desc',
        'category': 'sports',
        'teamSize': 11,
        'memberIds': ['user_2'],
        'memberNames': ['Member1'],
        'deadline': '2024-01-22T10:00:00.000Z',
        'status': 'open',
        'createdAt': '2024-01-15T10:00:00.000Z',
      };

      final team = TeamRequest.fromFirestore(data);

      expect(team.title, 'From Firestore');
      expect(team.category, TeamCategory.sports);
      expect(team.memberIds, contains('user_2'));
    });
  });

  group('TeamRequest Filtering', () {
    late List<TeamRequest> testTeams;

    setUp(() {
      final now = DateTime.now();
      testTeams = [
        TeamRequest(
          id: '1',
          creatorId: 'user_1',
          creatorName: 'User1',
          title: 'Hackathon Team',
          description: 'Desc',
          category: TeamCategory.hackathon,
          teamSize: 4,
          currentMembers: 2,
          status: 'open',
          deadline: now.add(const Duration(days: 7)),
          createdAt: now,
        ),
        TeamRequest(
          id: '2',
          creatorId: 'user_2',
          creatorName: 'User2',
          title: 'Sports Team',
          description: 'Desc',
          category: TeamCategory.sports,
          teamSize: 11,
          currentMembers: 11,
          status: 'open',
          deadline: now.add(const Duration(days: 14)),
          createdAt: now,
        ),
        TeamRequest(
          id: '3',
          creatorId: 'user_3',
          creatorName: 'User3',
          title: 'Gaming Squad',
          description: 'Desc',
          category: TeamCategory.esports,
          teamSize: 5,
          currentMembers: 3,
          status: 'open',
          deadline: now.add(const Duration(days: 3)),
          createdAt: now,
        ),
      ];
    });

    test('filter by category', () {
      final hackathons = testTeams
          .where((t) => t.category == TeamCategory.hackathon)
          .toList();
      expect(hackathons.length, 1);
    });

    test('filter open teams with spots', () {
      final openWithSpots = testTeams.where((t) => t.isOpen).toList();
      expect(openWithSpots.length, 2); // Excludes full sports team
    });

    test('filter by creator', () {
      final user1Teams = testTeams.where((t) => t.isCreator('user_1')).toList();
      expect(user1Teams.length, 1);
    });

    test('filter non-full teams', () {
      final notFull = testTeams.where((t) => !t.isFull).toList();
      expect(notFull.length, 2);
    });
  });

  group('JoinRequest Model', () {
    test('creates join request with required fields', () {
      final request = JoinRequest(
        id: '1',
        teamRequestId: 'team_1',
        userId: 'user_1',
        userName: 'John',
        message: 'I can help with backend!',
        createdAt: DateTime.now(),
      );

      expect(request.id, '1');
      expect(request.teamRequestId, 'team_1');
      expect(request.message, isNotEmpty);
      expect(request.status, 'pending'); // Default
    });

    test('join request with skills', () {
      final request = JoinRequest(
        id: '1',
        teamRequestId: 'team_1',
        userId: 'user_1',
        userName: 'Developer',
        message: 'Experienced in Python and ML',
        relevantSkills: ['Python', 'TensorFlow', 'React'],
        createdAt: DateTime.now(),
      );

      expect(request.relevantSkills, contains('Python'));
      expect(request.relevantSkills.length, 3);
    });

    test('accepted join request', () {
      final request = JoinRequest(
        id: '1',
        teamRequestId: 'team_1',
        userId: 'user_1',
        userName: 'User',
        message: 'msg',
        status: 'accepted',
        createdAt: DateTime.now(),
      );

      expect(request.status, 'accepted');
    });

    test('rejected join request', () {
      final request = JoinRequest(
        id: '1',
        teamRequestId: 'team_1',
        userId: 'user_1',
        userName: 'User',
        message: 'msg',
        status: 'rejected',
        createdAt: DateTime.now(),
      );

      expect(request.status, 'rejected');
    });

    test('toFirestore returns correct map', () {
      final request = JoinRequest(
        id: '1',
        teamRequestId: 'team_1',
        userId: 'user_1',
        userName: 'John',
        message: 'Want to join!',
        relevantSkills: ['Flutter', 'Dart'],
        createdAt: DateTime(2024, 1, 15),
      );

      final map = request.toFirestore();

      expect(map['teamRequestId'], 'team_1');
      expect(map['userId'], 'user_1');
      expect(map['message'], 'Want to join!');
      expect(map['relevantSkills'], contains('Flutter'));
    });
  });

  group('Test Data', () {
    test('testRequests provides sample data', () {
      final samples = TeamRequest.testRequests;
      expect(samples.length, greaterThan(0));
    });

    test('testRequests contain various categories', () {
      final samples = TeamRequest.testRequests;
      final categories = samples.map((t) => t.category).toSet();
      expect(categories.length, greaterThan(1));
    });
  });
}
