import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/models/join_request_model.dart';

void main() {
  group('ClubJoinStatus', () {
    test('has pending value', () {
      expect(ClubJoinStatus.pending, isA<ClubJoinStatus>());
    });

    test('has approved value', () {
      expect(ClubJoinStatus.approved, isA<ClubJoinStatus>());
    });

    test('has rejected value', () {
      expect(ClubJoinStatus.rejected, isA<ClubJoinStatus>());
    });

    test('has cancelled value', () {
      expect(ClubJoinStatus.cancelled, isA<ClubJoinStatus>());
    });

    test('displayName returns Pending for pending', () {
      expect(ClubJoinStatus.pending.displayName, 'Pending');
    });

    test('displayName returns Approved for approved', () {
      expect(ClubJoinStatus.approved.displayName, 'Approved');
    });

    test('displayName returns Rejected for rejected', () {
      expect(ClubJoinStatus.rejected.displayName, 'Rejected');
    });

    test('displayName returns Cancelled for cancelled', () {
      expect(ClubJoinStatus.cancelled.displayName, 'Cancelled');
    });

    test('values contains all statuses', () {
      expect(ClubJoinStatus.values.length, 4);
    });
  });

  group('ClubJoinRequest', () {
    late ClubJoinRequest request;

    setUp(() {
      request = ClubJoinRequest(
        id: 'req_001',
        userId: 'user_001',
        userName: 'John Doe',
        clubId: 'club_001',
        clubName: 'Coding Club',
        requestedAt: DateTime(2024, 1, 15),
      );
    });

    group('constructor', () {
      test('creates request with required fields', () {
        expect(request.id, 'req_001');
        expect(request.userId, 'user_001');
        expect(request.userName, 'John Doe');
        expect(request.clubId, 'club_001');
        expect(request.clubName, 'Coding Club');
      });

      test('default status is pending', () {
        expect(request.status, ClubJoinStatus.pending);
      });

      test('resolvedAt is null by default', () {
        expect(request.resolvedAt, isNull);
      });

      test('resolvedBy is null by default', () {
        expect(request.resolvedBy, isNull);
      });

      test('note is null by default', () {
        expect(request.note, isNull);
      });

      test('rejectionReason is null by default', () {
        expect(request.rejectionReason, isNull);
      });

      test('can create with all optional fields', () {
        final fullReq = ClubJoinRequest(
          id: 'req_002',
          userId: 'user_002',
          userName: 'Jane Doe',
          clubId: 'club_002',
          clubName: 'Art Club',
          status: ClubJoinStatus.approved,
          requestedAt: DateTime(2024, 1, 10),
          resolvedAt: DateTime(2024, 1, 12),
          resolvedBy: 'admin_001',
          note: 'I love art!',
        );

        expect(fullReq.status, ClubJoinStatus.approved);
        expect(fullReq.resolvedAt, isNotNull);
        expect(fullReq.resolvedBy, 'admin_001');
        expect(fullReq.note, 'I love art!');
      });
    });

    group('isPending getter', () {
      test('returns true when status is pending', () {
        expect(request.isPending, true);
      });

      test('returns false when status is approved', () {
        final approved = request.copyWith(status: ClubJoinStatus.approved);
        expect(approved.isPending, false);
      });

      test('returns false when status is rejected', () {
        final rejected = request.copyWith(status: ClubJoinStatus.rejected);
        expect(rejected.isPending, false);
      });
    });

    group('isApproved getter', () {
      test('returns false when status is pending', () {
        expect(request.isApproved, false);
      });

      test('returns true when status is approved', () {
        final approved = request.copyWith(status: ClubJoinStatus.approved);
        expect(approved.isApproved, true);
      });
    });

    group('isRejected getter', () {
      test('returns false when status is pending', () {
        expect(request.isRejected, false);
      });

      test('returns true when status is rejected', () {
        final rejected = request.copyWith(status: ClubJoinStatus.rejected);
        expect(rejected.isRejected, true);
      });
    });

    group('copyWith', () {
      test('copies with new id', () {
        final copy = request.copyWith(id: 'new_id');
        expect(copy.id, 'new_id');
        expect(copy.userId, request.userId);
      });

      test('copies with new status', () {
        final copy = request.copyWith(status: ClubJoinStatus.approved);
        expect(copy.status, ClubJoinStatus.approved);
        expect(copy.id, request.id);
      });

      test('copies with new clubName', () {
        final copy = request.copyWith(clubName: 'New Club');
        expect(copy.clubName, 'New Club');
      });

      test('copies with new userName', () {
        final copy = request.copyWith(userName: 'New User');
        expect(copy.userName, 'New User');
      });

      test('copies with resolvedAt', () {
        final resolveTime = DateTime(2024, 1, 16);
        final copy = request.copyWith(resolvedAt: resolveTime);
        expect(copy.resolvedAt, resolveTime);
      });

      test('copies with resolvedBy', () {
        final copy = request.copyWith(resolvedBy: 'admin_001');
        expect(copy.resolvedBy, 'admin_001');
      });

      test('copies with note', () {
        final copy = request.copyWith(note: 'Please accept me');
        expect(copy.note, 'Please accept me');
      });

      test('copies with rejectionReason', () {
        final copy = request.copyWith(rejectionReason: 'Not eligible');
        expect(copy.rejectionReason, 'Not eligible');
      });

      test('preserves unchanged fields', () {
        final copy = request.copyWith(status: ClubJoinStatus.approved);
        expect(copy.id, request.id);
        expect(copy.userId, request.userId);
        expect(copy.userName, request.userName);
        expect(copy.clubId, request.clubId);
        expect(copy.clubName, request.clubName);
        expect(copy.requestedAt, request.requestedAt);
      });
    });

    group('toFirestore', () {
      test('returns map with all required fields', () {
        final map = request.toFirestore();
        expect(map['userId'], request.userId);
        expect(map['userName'], request.userName);
        expect(map['clubId'], request.clubId);
        expect(map['clubName'], request.clubName);
        expect(map['status'], 'pending');
      });

      test('converts requestedAt to Timestamp', () {
        final map = request.toFirestore();
        expect(map['requestedAt'], isNotNull);
      });

      test('includes null for optional fields when not set', () {
        final map = request.toFirestore();
        expect(map['resolvedAt'], isNull);
        expect(map['resolvedBy'], isNull);
        expect(map['note'], isNull);
        expect(map['rejectionReason'], isNull);
      });

      test('includes note when set', () {
        final reqWithNote = request.copyWith(note: 'My note');
        final map = reqWithNote.toFirestore();
        expect(map['note'], 'My note');
      });
    });
  });
}
