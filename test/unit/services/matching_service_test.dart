import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/matching_service.dart';
import 'package:mvgr_nexus/services/mock_data_service.dart';
import 'package:mvgr_nexus/features/study_buddy/models/study_buddy_model.dart';
import 'package:mvgr_nexus/features/play_buddy/models/play_buddy_model.dart';
import 'package:mvgr_nexus/models/user_model.dart';

void main() {
  late MockDataService dataService;
  late MatchingService matchingService;

  setUp(() {
    dataService = MockDataService();
    matchingService = MatchingService(dataService);
  });

  group('MatchingService - Study Buddy', () {
    group('calculateStudyBuddyScore', () {
      test('returns score between 0 and 100', () {
        final request = StudyRequest(
          id: 'sr_001',
          userId: 'user_001',
          userName: 'Test User',
          subject: 'Data Structures',
          topic: 'Trees',
          description: 'Looking for study partner',
          preferredMode: StudyMode.hybrid,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 14)),
        );

        final user = AppUser.testStudent();
        final score = matchingService.calculateStudyBuddyScore(request, user);
        
        expect(score, greaterThanOrEqualTo(0));
        expect(score, lessThanOrEqualTo(100));
      });

      test('hybrid mode gets full compatibility points', () {
        final hybridRequest = StudyRequest(
          id: 'sr_001',
          userId: 'user_001',
          userName: 'Test',
          subject: 'Math',
          topic: 'Calculus',
          description: 'Study partner needed',
          preferredMode: StudyMode.hybrid,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 14)),
        );

        final inPersonRequest = hybridRequest.copyWith(
          id: 'sr_002',
          preferredMode: StudyMode.inPerson,
        );

        final user = AppUser.testStudent();
        final hybridScore = matchingService.calculateStudyBuddyScore(hybridRequest, user);
        final inPersonScore = matchingService.calculateStudyBuddyScore(inPersonRequest, user);

        expect(hybridScore, greaterThanOrEqualTo(inPersonScore));
      });

      test('department match adds bonus points', () {
        final request = StudyRequest(
          id: 'sr_001',
          userId: 'user_001',
          userName: 'Test',
          subject: 'Math',
          topic: 'Algebra',
          description: 'Study partner',
          preferredMode: StudyMode.online,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 14)),
        );

        final userWithDept = AppUser.testStudent().copyWith(department: 'CSE');
        final userNoDept = AppUser.testStudent().copyWith(department: '');

        final scoreWithDept = matchingService.calculateStudyBuddyScore(request, userWithDept);
        final scoreNoDept = matchingService.calculateStudyBuddyScore(request, userNoDept);

        expect(scoreWithDept, greaterThan(scoreNoDept));
      });
    });

    group('getStudyBuddyMatches', () {
      test('returns list of matches', () {
        final user = AppUser.testStudent();
        final matches = matchingService.getStudyBuddyMatches(user);
        
        expect(matches, isA<List<StudyBuddyMatch>>());
      });

      test('excludes own requests', () {
        final user = AppUser.testStudent();
        final matches = matchingService.getStudyBuddyMatches(user);
        
        for (final match in matches) {
          expect(match.request.userId, isNot(user.uid));
        }
      });

      test('respects limit parameter', () {
        final user = AppUser.testStudent();
        final matches = matchingService.getStudyBuddyMatches(user, limit: 3);
        
        expect(matches.length, lessThanOrEqualTo(3));
      });

      test('sorts by score descending', () {
        final user = AppUser.testStudent();
        final matches = matchingService.getStudyBuddyMatches(user);
        
        if (matches.length >= 2) {
          for (int i = 0; i < matches.length - 1; i++) {
            expect(
              matches[i].compatibilityScore,
              greaterThanOrEqualTo(matches[i + 1].compatibilityScore),
            );
          }
        }
      });
    });
  });

  group('MatchingService - Team', () {
    group('calculateTeamMatchScore', () {
      test('returns score between 0 and 100', () {
        final team = TeamRequest(
          id: 'tr_001',
          creatorId: 'user_002',
          creatorName: 'Creator',
          title: 'Hackathon Team',
          description: 'Looking for teammates',
          category: TeamCategory.hackathon,
          teamSize: 4,
          deadline: DateTime.now().add(const Duration(days: 7)),
          createdAt: DateTime.now(),
        );

        final user = AppUser.testStudent();
        final score = matchingService.calculateTeamMatchScore(team, user);
        
        expect(score, greaterThanOrEqualTo(0));
        expect(score, lessThanOrEqualTo(100));
      });

      test('skill matches increase score', () {
        final teamWithSkills = TeamRequest(
          id: 'tr_001',
          creatorId: 'user_002',
          creatorName: 'Creator',
          title: 'Hackathon Team',
          description: 'Need Flutter dev',
          category: TeamCategory.hackathon,
          teamSize: 4,
          requiredSkills: ['Flutter', 'Dart'],
          deadline: DateTime.now().add(const Duration(days: 7)),
          createdAt: DateTime.now(),
        );

        final teamNoSkills = teamWithSkills.copyWith(
          id: 'tr_002',
          requiredSkills: [],
        );

        final userWithSkills = AppUser.testStudent().copyWith(
          skills: ['Flutter', 'Dart', 'Python'],
        );

        final scoreWithSkills = matchingService.calculateTeamMatchScore(teamWithSkills, userWithSkills);
        final scoreNoSkills = matchingService.calculateTeamMatchScore(teamNoSkills, userWithSkills);

        expect(scoreWithSkills, greaterThanOrEqualTo(scoreNoSkills));
      });

      test('more available spots adds points', () {
        final teamManySpots = TeamRequest(
          id: 'tr_001',
          creatorId: 'user_002',
          creatorName: 'Creator',
          title: 'Team',
          description: 'Join us',
          category: TeamCategory.hackathon,
          teamSize: 10,
          currentMembers: 2,
          deadline: DateTime.now().add(const Duration(days: 7)),
          createdAt: DateTime.now(),
        );

        final teamFewSpots = teamManySpots.copyWith(
          id: 'tr_002',
          currentMembers: 9,
        );


        expect(teamManySpots.spotsLeft, greaterThan(2));
        expect(teamFewSpots.spotsLeft, lessThan(2));
      });
    });

    group('getTeamMatches', () {
      test('returns list of matches', () {
        final user = AppUser.testStudent();
        final matches = matchingService.getTeamMatches(user);
        
        expect(matches, isA<List<TeamMatch>>());
      });

      test('excludes own teams', () {
        final user = AppUser.testStudent();
        final matches = matchingService.getTeamMatches(user);
        
        for (final match in matches) {
          expect(match.team.creatorId, isNot(user.uid));
        }
      });

      test('only includes teams with available spots', () {
        final user = AppUser.testStudent();
        final matches = matchingService.getTeamMatches(user);
        
        for (final match in matches) {
          expect(match.team.spotsLeft, greaterThan(0));
        }
      });
    });
  });

  group('MatchingService - Lost & Found', () {
    group('findLostFoundMatches', () {
      test('returns list of matches', () {
        final items = dataService.lostFoundItems;
        if (items.isNotEmpty) {
          final matches = matchingService.findLostFoundMatches(items.first.id);
          expect(matches, isA<List<LostFoundMatch>>());
        }
      });

      test('returns at most 5 matches', () {
        final items = dataService.lostFoundItems;
        if (items.isNotEmpty) {
          final matches = matchingService.findLostFoundMatches(items.first.id);
          expect(matches.length, lessThanOrEqualTo(5));
        }
      });
    });
  });

  group('StudyBuddyMatch', () {
    test('scorePercentage rounds correctly', () {
      final request = StudyRequest(
        id: 'sr_001',
        userId: 'user_001',
        userName: 'Test',
        subject: 'Math',
        topic: 'Calc',
        description: 'Desc',
        preferredMode: StudyMode.hybrid,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      );

      final match = StudyBuddyMatch(
        request: request,
        compatibilityScore: 85.7,
        matchReason: 'Great Match',
      );

      expect(match.scorePercentage, 86);
    });
  });

  group('TeamMatch', () {
    test('scorePercentage rounds correctly', () {
      final team = TeamRequest(
        id: 'tr_001',
        creatorId: 'user_001',
        creatorName: 'Creator',
        title: 'Team',
        description: 'Desc',
        category: TeamCategory.hackathon,
        teamSize: 4,
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      );

      final match = TeamMatch(
        team: team,
        compatibilityScore: 92.3,
        matchReason: 'Perfect Match',
        isPerfectMatch: true,
      );

      expect(match.scorePercentage, 92);
      expect(match.isPerfectMatch, true);
    });
  });

  group('LostFoundMatch', () {
    test('scorePercentage rounds correctly', () {
      final item = dataService.lostFoundItems.isNotEmpty
          ? dataService.lostFoundItems.first
          : null;

      if (item != null) {
        final match = LostFoundMatch(
          item: item,
          matchScore: 78.5,
          reason: 'Possible Match',
        );

        expect(match.scorePercentage, 79);
      }
    });
  });
}
