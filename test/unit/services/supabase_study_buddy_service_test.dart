import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/study_buddy/models/study_buddy_model.dart';

void main() {
  group('StudyMode Enum', () {
    test('all modes are defined', () {
      expect(StudyMode.values.length, 3);
    });

    test('displayName returns correct string', () {
      expect(StudyMode.online.displayName, 'Online');
      expect(StudyMode.inPerson.displayName, 'In-Person');
      expect(StudyMode.hybrid.displayName, 'Hybrid');
    });

    test('icon returns emoji', () {
      for (final mode in StudyMode.values) {
        expect(mode.icon, isNotEmpty);
      }
    });

    test('iconData returns non-null icon', () {
      for (final mode in StudyMode.values) {
        expect(mode.iconData, isNotNull);
      }
    });
  });

  group('RequestStatus Enum', () {
    test('all statuses are defined', () {
      expect(RequestStatus.values.length, 4);
    });

    test('displayName returns correct string', () {
      expect(RequestStatus.active.displayName, 'Active');
      expect(RequestStatus.matched.displayName, 'Matched');
      expect(RequestStatus.expired.displayName, 'Expired');
      expect(RequestStatus.cancelled.displayName, 'Cancelled');
    });
  });

  group('StudyRequest Model', () {
    test('creates request with required fields', () {
      final request = StudyRequest(
        id: '1',
        userId: 'user_1',
        userName: 'John Doe',
        subject: 'Data Structures',
        topic: 'Binary Trees',
        description: 'Need help with tree traversal',
        preferredMode: StudyMode.inPerson,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      );

      expect(request.id, '1');
      expect(request.subject, 'Data Structures');
      expect(request.topic, 'Binary Trees');
      expect(request.preferredMode, StudyMode.inPerson);
    });

    test('creates online study request', () {
      final request = StudyRequest(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        subject: 'Machine Learning',
        topic: 'Neural Networks',
        description: 'Online session preferred',
        preferredMode: StudyMode.online,
        preferredTime: 'Evening',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      );

      expect(request.preferredMode, StudyMode.online);
      expect(request.preferredTime, 'Evening');
    });

    test('creates request with location', () {
      final request = StudyRequest(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        subject: 'Physics',
        topic: 'Mechanics',
        description: 'In person study',
        preferredMode: StudyMode.inPerson,
        preferredLocation: 'Library Study Room',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      );

      expect(request.preferredLocation, 'Library Study Room');
    });

    test('creates request with available days', () {
      final request = StudyRequest(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        subject: 'Math',
        topic: 'Calculus',
        description: 'Study together',
        preferredMode: StudyMode.hybrid,
        availableDays: ['Monday', 'Wednesday', 'Friday'],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      );

      expect(request.availableDays, contains('Monday'));
      expect(request.availableDays.length, 3);
    });

    test('default status is active', () {
      final request = StudyRequest(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        subject: 'Subject',
        topic: 'Topic',
        description: 'Desc',
        preferredMode: StudyMode.online,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      );

      expect(request.status, RequestStatus.active);
    });
  });

  group('StudyRequest Computed Properties', () {
    test('isActive returns true for active non-expired request', () {
      final request = StudyRequest(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        subject: 'Subject',
        topic: 'Topic',
        description: 'Desc',
        preferredMode: StudyMode.online,
        status: RequestStatus.active,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      );

      expect(request.isActive, true);
    });

    test('isActive returns false for expired request', () {
      final request = StudyRequest(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        subject: 'Subject',
        topic: 'Topic',
        description: 'Desc',
        preferredMode: StudyMode.online,
        status: RequestStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        expiresAt: DateTime.now().subtract(const Duration(days: 6)),
      );

      expect(request.isExpired, true);
      expect(request.isActive, false);
    });

    test('isOwnedBy checks user ID', () {
      final request = StudyRequest(
        id: '1',
        userId: 'user_123',
        userName: 'User',
        subject: 'Subject',
        topic: 'Topic',
        description: 'Desc',
        preferredMode: StudyMode.online,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      );

      expect(request.isOwnedBy('user_123'), true);
      expect(request.isOwnedBy('user_456'), false);
    });
  });

  group('StudyRequest copyWith', () {
    test('copyWith creates copy with updated fields', () {
      final original = StudyRequest(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        subject: 'Math',
        topic: 'Algebra',
        description: 'Desc',
        preferredMode: StudyMode.online,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      );

      final updated = original.copyWith(
        status: RequestStatus.matched,
        topic: 'Calculus',
      );

      expect(updated.status, RequestStatus.matched);
      expect(updated.topic, 'Calculus');
      expect(updated.subject, 'Math'); // Unchanged
    });
  });

  group('StudyRequest Serialization', () {
    test('toFirestore returns correct map', () {
      final request = StudyRequest(
        id: '1',
        userId: 'user_1',
        userName: 'John',
        subject: 'DSA',
        topic: 'Trees',
        description: 'Study trees',
        preferredMode: StudyMode.inPerson,
        preferredLocation: 'Library',
        createdAt: DateTime(2024, 1, 15),
        expiresAt: DateTime(2024, 1, 29),
      );

      final map = request.toFirestore();

      expect(map['userId'], 'user_1');
      expect(map['subject'], 'DSA');
      expect(map['preferredMode'], 'inPerson');
      expect(map['preferredLocation'], 'Library');
    });

    test('fromFirestore creates correct object', () {
      final data = {
        'id': '1',
        'userId': 'user_1',
        'userName': 'Jane',
        'subject': 'ML',
        'topic': 'NLP',
        'description': 'NLP study',
        'preferredMode': 'online',
        'preferredTime': 'Morning',
        'status': 'active',
        'createdAt': '2024-01-15T10:00:00.000Z',
        'expiresAt': '2024-01-29T10:00:00.000Z',
      };

      final request = StudyRequest.fromFirestore(data);

      expect(request.subject, 'ML');
      expect(request.preferredMode, StudyMode.online);
      expect(request.status, RequestStatus.active);
    });
  });

  group('StudyRequest Filtering', () {
    late List<StudyRequest> testRequests;

    setUp(() {
      final now = DateTime.now();
      testRequests = [
        StudyRequest(
          id: '1',
          userId: 'user_1',
          userName: 'User1',
          subject: 'Math',
          topic: 'Algebra',
          description: 'Desc',
          preferredMode: StudyMode.online,
          createdAt: now,
          expiresAt: now.add(const Duration(days: 14)),
        ),
        StudyRequest(
          id: '2',
          userId: 'user_2',
          userName: 'User2',
          subject: 'Physics',
          topic: 'Mechanics',
          description: 'Desc',
          preferredMode: StudyMode.inPerson,
          preferredLocation: 'Library',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 14)),
        ),
        StudyRequest(
          id: '3',
          userId: 'user_1',
          userName: 'User1',
          subject: 'Chemistry',
          topic: 'Organic',
          description: 'Desc',
          preferredMode: StudyMode.hybrid,
          status: RequestStatus.matched,
          createdAt: now.subtract(const Duration(days: 5)),
          expiresAt: now.add(const Duration(days: 9)),
        ),
      ];
    });

    test('filter by subject', () {
      final mathRequests = testRequests.where((r) => r.subject == 'Math').toList();
      expect(mathRequests.length, 1);
    });

    test('filter by mode', () {
      final inPerson = testRequests
          .where((r) => r.preferredMode == StudyMode.inPerson)
          .toList();
      expect(inPerson.length, 1);
    });

    test('filter by status', () {
      final matched = testRequests
          .where((r) => r.status == RequestStatus.matched)
          .toList();
      expect(matched.length, 1);
    });

    test('filter active requests', () {
      final active = testRequests.where((r) => r.isActive).toList();
      expect(active.length, 2);
    });

    test('filter by user', () {
      final user1Requests = testRequests.where((r) => r.isOwnedBy('user_1')).toList();
      expect(user1Requests.length, 2);
    });
  });

  group('MatchStatus Enum', () {
    test('all statuses are defined', () {
      expect(MatchStatus.values.length, 3);
    });

    test('statuses are correct', () {
      expect(MatchStatus.values, contains(MatchStatus.pending));
      expect(MatchStatus.values, contains(MatchStatus.accepted));
      expect(MatchStatus.values, contains(MatchStatus.declined));
    });

    test('displayName returns correct string', () {
      expect(MatchStatus.pending.displayName, 'Pending');
      expect(MatchStatus.accepted.displayName, 'Accepted');
      expect(MatchStatus.declined.displayName, 'Declined');
    });
  });

  group('StudyMatch Model', () {
    test('creates match with required fields', () {
      final match = StudyMatch(
        id: '1',
        requestId: 'req_1',
        requesterId: 'user_1',
        requesterName: 'John',
        matchedUserId: 'user_2',
        matchedUserName: 'Jane',
        createdAt: DateTime.now(),
      );

      expect(match.id, '1');
      expect(match.requesterId, 'user_1');
      expect(match.matchedUserId, 'user_2');
    });

    test('match with message', () {
      final match = StudyMatch(
        id: '1',
        requestId: 'req_1',
        requesterId: 'user_1',
        requesterName: 'Requester',
        matchedUserId: 'user_2',
        matchedUserName: 'Matcher',
        message: 'I can help with trees and graphs!',
        createdAt: DateTime.now(),
      );

      expect(match.message, isNotEmpty);
    });

    test('default statuses are pending', () {
      final match = StudyMatch(
        id: '1',
        requestId: 'req_1',
        requesterId: 'user_1',
        requesterName: 'User1',
        matchedUserId: 'user_2',
        matchedUserName: 'User2',
        createdAt: DateTime.now(),
      );

      expect(match.requesterStatus, MatchStatus.pending);
      expect(match.matchedUserStatus, MatchStatus.pending);
    });

    test('isMutuallyAccepted when both accept', () {
      final match = StudyMatch(
        id: '1',
        requestId: 'req_1',
        requesterId: 'user_1',
        requesterName: 'User1',
        matchedUserId: 'user_2',
        matchedUserName: 'User2',
        requesterStatus: MatchStatus.accepted,
        matchedUserStatus: MatchStatus.accepted,
        createdAt: DateTime.now(),
      );

      expect(match.isMutuallyAccepted, true);
    });

    test('isMutuallyAccepted false when only one accepts', () {
      final match = StudyMatch(
        id: '1',
        requestId: 'req_1',
        requesterId: 'user_1',
        requesterName: 'User1',
        matchedUserId: 'user_2',
        matchedUserName: 'User2',
        requesterStatus: MatchStatus.accepted,
        matchedUserStatus: MatchStatus.pending,
        createdAt: DateTime.now(),
      );

      expect(match.isMutuallyAccepted, false);
    });

    test('isParticipant checks user correctly', () {
      final match = StudyMatch(
        id: '1',
        requestId: 'req_1',
        requesterId: 'user_1',
        requesterName: 'User1',
        matchedUserId: 'user_2',
        matchedUserName: 'User2',
        createdAt: DateTime.now(),
      );

      expect(match.isParticipant('user_1'), true);
      expect(match.isParticipant('user_2'), true);
      expect(match.isParticipant('user_3'), false);
    });

    test('contact revealed after mutual accept', () {
      final match = StudyMatch(
        id: '1',
        requestId: 'req_1',
        requesterId: 'user_1',
        requesterName: 'User1',
        matchedUserId: 'user_2',
        matchedUserName: 'User2',
        requesterStatus: MatchStatus.accepted,
        matchedUserStatus: MatchStatus.accepted,
        contactRevealed: true,
        requesterContact: '9876543210',
        matchedUserContact: '1234567890',
        createdAt: DateTime.now(),
      );

      expect(match.contactRevealed, true);
      expect(match.requesterContact, isNotNull);
      expect(match.matchedUserContact, isNotNull);
    });
  });

  group('Test Data', () {
    test('testRequests provides sample data', () {
      final samples = StudyRequest.testRequests;
      expect(samples.length, greaterThan(0));
    });

    test('testRequests contain various modes', () {
      final samples = StudyRequest.testRequests;
      final modes = samples.map((r) => r.preferredMode).toSet();
      expect(modes.length, greaterThan(1));
    });
  });
}
