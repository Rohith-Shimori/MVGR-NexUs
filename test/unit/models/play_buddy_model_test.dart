import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/play_buddy/models/play_buddy_model.dart';

void main() {
  group('TeamCategory', () {
    test('has 7 values', () {
      expect(TeamCategory.values.length, 7);
    });

    test('displayName returns correct names', () {
      expect(TeamCategory.hackathon.displayName, 'Hackathon');
      expect(TeamCategory.sports.displayName, 'Sports');
      expect(TeamCategory.esports.displayName, 'E-Sports/Gaming');
      expect(TeamCategory.cultural.displayName, 'Cultural');
      expect(TeamCategory.academic.displayName, 'Academic Competition');
      expect(TeamCategory.project.displayName, 'Project Team');
      expect(TeamCategory.other.displayName, 'Other');
    });

    test('icon returns emoji for each category', () {
      expect(TeamCategory.hackathon.icon, '💻');
      expect(TeamCategory.sports.icon, '⚽');
      expect(TeamCategory.esports.icon, '🎮');
      expect(TeamCategory.cultural.icon, '🎭');
      expect(TeamCategory.academic.icon, '🏆');
      expect(TeamCategory.project.icon, '📊');
      expect(TeamCategory.other.icon, '👥');
    });

    test('iconData returns IconData', () {
      expect(TeamCategory.hackathon.iconData, Icons.code_rounded);
      expect(TeamCategory.sports.iconData, Icons.sports_soccer_rounded);
      expect(TeamCategory.esports.iconData, Icons.sports_esports_rounded);
      expect(TeamCategory.cultural.iconData, Icons.theater_comedy_rounded);
      expect(TeamCategory.academic.iconData, Icons.emoji_events_rounded);
    });
  });

  group('TeamRequest', () {
    late TeamRequest request;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      request = TeamRequest(
        id: 'tr_001',
        creatorId: 'user_001',
        creatorName: 'John Doe',
        title: 'Hackathon Team',
        description: 'Need teammates for SIH',
        category: TeamCategory.hackathon,
        teamSize: 6,
        deadline: now.add(const Duration(days: 7)),
        createdAt: now,
      );
    });

    group('constructor', () {
      test('creates request with required fields', () {
        expect(request.id, 'tr_001');
        expect(request.creatorId, 'user_001');
        expect(request.creatorName, 'John Doe');
        expect(request.title, 'Hackathon Team');
        expect(request.category, TeamCategory.hackathon);
        expect(request.teamSize, 6);
      });

      test('default currentMembers is 1', () {
        expect(request.currentMembers, 1);
      });

      test('default status is open', () {
        expect(request.status, 'open');
      });

      test('default memberIds is empty', () {
        expect(request.memberIds, isEmpty);
      });

      test('default requiredSkills is empty', () {
        expect(request.requiredSkills, isEmpty);
      });
    });

    group('isOpen getter', () {
      test('returns true for open non-full request', () {
        expect(request.isOpen, true);
      });

      test('returns false for closed status', () {
        final closed = request.copyWith(status: 'closed');
        expect(closed.isOpen, false);
      });

      test('returns false when full', () {
        final full = request.copyWith(currentMembers: 6);
        expect(full.isOpen, false);
      });
    });

    group('isFull getter', () {
      test('returns false when not full', () {
        expect(request.isFull, false);
      });

      test('returns true when currentMembers equals teamSize', () {
        final full = request.copyWith(currentMembers: 6);
        expect(full.isFull, true);
      });

      test('returns true when currentMembers exceeds teamSize', () {
        final overfull = request.copyWith(currentMembers: 7);
        expect(overfull.isFull, true);
      });
    });

    group('isPastDeadline getter', () {
      test('returns false for future deadline', () {
        expect(request.isPastDeadline, false);
      });

      test('returns true for past deadline', () {
        final past = request.copyWith(
          deadline: now.subtract(const Duration(days: 1)),
        );
        expect(past.isPastDeadline, true);
      });
    });

    group('spotsLeft getter', () {
      test('returns correct spots left', () {
        expect(request.spotsLeft, 5);
      });

      test('returns 0 when full', () {
        final full = request.copyWith(currentMembers: 6);
        expect(full.spotsLeft, 0);
      });

      test('returns negative when overfull', () {
        final overfull = request.copyWith(currentMembers: 7);
        expect(overfull.spotsLeft, -1);
      });
    });

    group('isMember', () {
      test('returns true for creator', () {
        expect(request.isMember('user_001'), true);
      });

      test('returns true for member in list', () {
        final withMembers = request.copyWith(
          memberIds: ['user_002', 'user_003'],
        );
        expect(withMembers.isMember('user_002'), true);
      });

      test('returns false for non-member', () {
        expect(request.isMember('user_999'), false);
      });
    });

    group('isCreator', () {
      test('returns true for creator', () {
        expect(request.isCreator('user_001'), true);
      });

      test('returns false for non-creator', () {
        expect(request.isCreator('user_002'), false);
      });
    });

    group('copyWith', () {
      test('copies with new title', () {
        final copy = request.copyWith(title: 'New Title');
        expect(copy.title, 'New Title');
        expect(copy.id, request.id);
      });

      test('copies with new category', () {
        final copy = request.copyWith(category: TeamCategory.sports);
        expect(copy.category, TeamCategory.sports);
      });

      test('copies with new memberIds', () {
        final copy = request.copyWith(memberIds: ['user_002']);
        expect(copy.memberIds, ['user_002']);
      });

      test('copies with requiredSkills', () {
        final copy = request.copyWith(requiredSkills: ['Python', 'React']);
        expect(copy.requiredSkills, ['Python', 'React']);
      });
    });

    group('toFirestore', () {
      test('returns map with correct fields', () {
        final map = request.toFirestore();
        expect(map['creatorId'], 'user_001');
        expect(map['creatorName'], 'John Doe');
        expect(map['title'], 'Hackathon Team');
        expect(map['category'], 'hackathon');
        expect(map['teamSize'], 6);
        expect(map['status'], 'open');
      });
    });

    group('testRequests', () {
      test('returns non-empty list', () {
        expect(TeamRequest.testRequests, isNotEmpty);
      });

      test('test requests have valid data', () {
        for (final req in TeamRequest.testRequests) {
          expect(req.id, isNotEmpty);
          expect(req.title, isNotEmpty);
          expect(req.teamSize, greaterThan(0));
        }
      });
    });
  });

  group('JoinRequest', () {
    late JoinRequest joinRequest;

    setUp(() {
      joinRequest = JoinRequest(
        id: 'jr_001',
        teamRequestId: 'tr_001',
        userId: 'user_002',
        userName: 'Jane Doe',
        message: 'I want to join',
        createdAt: DateTime.now(),
      );
    });

    group('constructor', () {
      test('creates with required fields', () {
        expect(joinRequest.id, 'jr_001');
        expect(joinRequest.teamRequestId, 'tr_001');
        expect(joinRequest.userId, 'user_002');
        expect(joinRequest.userName, 'Jane Doe');
        expect(joinRequest.message, 'I want to join');
      });

      test('default status is pending', () {
        expect(joinRequest.status, 'pending');
      });

      test('default relevantSkills is empty', () {
        expect(joinRequest.relevantSkills, isEmpty);
      });
    });

    group('can create with skills', () {
      test('relevantSkills can be provided', () {
        final withSkills = JoinRequest(
          id: 'jr_002',
          teamRequestId: 'tr_001',
          userId: 'user_003',
          userName: 'Bob',
          message: 'Skilled dev here',
          relevantSkills: ['Python', 'ML'],
          createdAt: DateTime.now(),
        );
        expect(withSkills.relevantSkills, ['Python', 'ML']);
      });
    });

    group('toFirestore', () {
      test('returns correct map', () {
        final map = joinRequest.toFirestore();
        expect(map['teamRequestId'], 'tr_001');
        expect(map['userId'], 'user_002');
        expect(map['userName'], 'Jane Doe');
        expect(map['message'], 'I want to join');
        expect(map['status'], 'pending');
      });
    });
  });
}
