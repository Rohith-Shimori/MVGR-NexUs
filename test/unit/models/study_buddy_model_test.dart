import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/study_buddy/models/study_buddy_model.dart';

void main() {
  group('StudyMode', () {
    test('has 3 values', () {
      expect(StudyMode.values.length, 3);
    });

    test('displayName returns correct names', () {
      expect(StudyMode.online.displayName, 'Online');
      expect(StudyMode.inPerson.displayName, 'In-Person');
      expect(StudyMode.hybrid.displayName, 'Hybrid');
    });

    test('icon returns emoji for each mode', () {
      expect(StudyMode.online.icon, '💻');
      expect(StudyMode.inPerson.icon, '🏫');
      expect(StudyMode.hybrid.icon, '🔄');
    });

    test('iconData returns IconData', () {
      expect(StudyMode.online.iconData, Icons.laptop_mac_rounded);
      expect(StudyMode.inPerson.iconData, Icons.school_rounded);
      expect(StudyMode.hybrid.iconData, Icons.sync_alt_rounded);
    });
  });

  group('RequestStatus', () {
    test('has 4 values', () {
      expect(RequestStatus.values.length, 4);
    });

    test('displayName returns correct names', () {
      expect(RequestStatus.active.displayName, 'Active');
      expect(RequestStatus.matched.displayName, 'Matched');
      expect(RequestStatus.expired.displayName, 'Expired');
      expect(RequestStatus.cancelled.displayName, 'Cancelled');
    });
  });

  group('StudyRequest', () {
    late StudyRequest request;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      request = StudyRequest(
        id: 'sr_001',
        userId: 'user_001',
        userName: 'John Doe',
        subject: 'Data Structures',
        topic: 'Binary Trees',
        description: 'Looking for study partner',
        preferredMode: StudyMode.inPerson,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 14)),
      );
    });

    group('constructor', () {
      test('creates request with required fields', () {
        expect(request.id, 'sr_001');
        expect(request.userId, 'user_001');
        expect(request.subject, 'Data Structures');
        expect(request.topic, 'Binary Trees');
        expect(request.preferredMode, StudyMode.inPerson);
      });

      test('default status is active', () {
        expect(request.status, RequestStatus.active);
      });

      test('preferredLocation is null by default', () {
        expect(request.preferredLocation, isNull);
      });

      test('availableDays is empty by default', () {
        expect(request.availableDays, isEmpty);
      });
    });

    group('isActive getter', () {
      test('returns true for active non-expired request', () {
        expect(request.isActive, true);
      });

      test('returns false for matched request', () {
        final matched = request.copyWith(status: RequestStatus.matched);
        expect(matched.isActive, false);
      });
    });

    group('isExpired getter', () {
      test('returns false for future expiry', () {
        expect(request.isExpired, false);
      });

      test('returns true for past expiry', () {
        final expired = request.copyWith(
          expiresAt: now.subtract(const Duration(days: 1)),
        );
        expect(expired.isExpired, true);
      });
    });

    group('isOwnedBy', () {
      test('returns true for owner', () {
        expect(request.isOwnedBy('user_001'), true);
      });

      test('returns false for non-owner', () {
        expect(request.isOwnedBy('user_999'), false);
      });
    });

    group('copyWith', () {
      test('copies with new subject', () {
        final copy = request.copyWith(subject: 'Algorithms');
        expect(copy.subject, 'Algorithms');
        expect(copy.id, request.id);
      });

      test('copies with new status', () {
        final copy = request.copyWith(status: RequestStatus.matched);
        expect(copy.status, RequestStatus.matched);
      });

      test('copies with new preferredMode', () {
        final copy = request.copyWith(preferredMode: StudyMode.online);
        expect(copy.preferredMode, StudyMode.online);
      });

      test('copies with availableDays', () {
        final copy = request.copyWith(availableDays: ['Monday', 'Tuesday']);
        expect(copy.availableDays, ['Monday', 'Tuesday']);
      });
    });

    group('toFirestore', () {
      test('returns map with correct fields', () {
        final map = request.toFirestore();
        expect(map['userId'], 'user_001');
        expect(map['userName'], 'John Doe');
        expect(map['subject'], 'Data Structures');
        expect(map['topic'], 'Binary Trees');
        expect(map['preferredMode'], 'inPerson');
        expect(map['status'], 'active');
      });
    });

    group('testRequests', () {
      test('returns non-empty list', () {
        expect(StudyRequest.testRequests, isNotEmpty);
      });
    });
  });

  group('MatchStatus', () {
    test('has 3 values', () {
      expect(MatchStatus.values.length, 3);
    });

    test('displayName returns correct names', () {
      expect(MatchStatus.pending.displayName, 'Pending');
      expect(MatchStatus.accepted.displayName, 'Accepted');
      expect(MatchStatus.declined.displayName, 'Declined');
    });
  });

  group('StudyMatch', () {
    late StudyMatch match;

    setUp(() {
      match = StudyMatch(
        id: 'sm_001',
        requestId: 'sr_001',
        requesterId: 'user_001',
        requesterName: 'John Doe',
        matchedUserId: 'user_002',
        matchedUserName: 'Jane Doe',
        createdAt: DateTime.now(),
      );
    });

    group('constructor', () {
      test('creates match with required fields', () {
        expect(match.id, 'sm_001');
        expect(match.requestId, 'sr_001');
        expect(match.requesterId, 'user_001');
        expect(match.matchedUserId, 'user_002');
      });

      test('default requesterStatus is pending', () {
        expect(match.requesterStatus, MatchStatus.pending);
      });

      test('default matchedUserStatus is pending', () {
        expect(match.matchedUserStatus, MatchStatus.pending);
      });

      test('default contactRevealed is false', () {
        expect(match.contactRevealed, false);
      });
    });

    group('isMutuallyAccepted getter', () {
      test('returns false when both pending', () {
        expect(match.isMutuallyAccepted, false);
      });

      test('returns true when both accepted', () {
        final mutualMatch = StudyMatch(
          id: 'sm_002',
          requestId: 'sr_001',
          requesterId: 'user_001',
          requesterName: 'John',
          matchedUserId: 'user_002',
          matchedUserName: 'Jane',
          requesterStatus: MatchStatus.accepted,
          matchedUserStatus: MatchStatus.accepted,
          createdAt: DateTime.now(),
        );
        expect(mutualMatch.isMutuallyAccepted, true);
      });

      test('returns false when only one accepted', () {
        final partialMatch = StudyMatch(
          id: 'sm_003',
          requestId: 'sr_001',
          requesterId: 'user_001',
          requesterName: 'John',
          matchedUserId: 'user_002',
          matchedUserName: 'Jane',
          requesterStatus: MatchStatus.accepted,
          matchedUserStatus: MatchStatus.pending,
          createdAt: DateTime.now(),
        );
        expect(partialMatch.isMutuallyAccepted, false);
      });
    });

    group('isParticipant', () {
      test('returns true for requester', () {
        expect(match.isParticipant('user_001'), true);
      });

      test('returns true for matched user', () {
        expect(match.isParticipant('user_002'), true);
      });

      test('returns false for non-participant', () {
        expect(match.isParticipant('user_999'), false);
      });
    });

    group('toFirestore', () {
      test('returns correct map', () {
        final map = match.toFirestore();
        expect(map['requestId'], 'sr_001');
        expect(map['requesterId'], 'user_001');
        expect(map['matchedUserId'], 'user_002');
        expect(map['requesterStatus'], 'pending');
        expect(map['matchedUserStatus'], 'pending');
        expect(map['contactRevealed'], false);
      });
    });
  });
}
