import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/mock_data_service.dart';
import 'package:mvgr_nexus/features/clubs/models/club_model.dart';

void main() {
  group('MockDataService - Clubs', () {
    late MockDataService service;

    setUp(() {
      // Create a fresh instance for each test
      service = MockDataService();
    });

    group('clubs getter', () {
      test('returns only approved clubs', () {
        final clubs = service.clubs;
        for (final club in clubs) {
          expect(club.isApproved, true);
        }
      });

      test('returns unmodifiable list', () {
        final clubs = service.clubs;
        expect(() => clubs.add(Club.testClubs.first), throwsUnsupportedError);
      });
    });

    group('allClubs getter', () {
      test('returns all clubs including unapproved', () {
        final allClubs = service.allClubs;
        expect(allClubs, isNotEmpty);
      });
    });

    group('getClubById', () {
      test('returns club when it exists', () {
        final testClub = service.clubs.first;
        final found = service.getClubById(testClub.id);
        expect(found, isNotNull);
        expect(found!.id, testClub.id);
        expect(found.name, testClub.name);
      });

      test('returns null when club does not exist', () {
        final found = service.getClubById('non_existent_id');
        expect(found, isNull);
      });
    });

    group('addClub', () {
      test('adds club to list', () {
        final initialCount = service.allClubs.length;
        final newClub = Club(
          id: 'new_club_${DateTime.now().millisecondsSinceEpoch}',
          name: 'New Test Club',
          description: 'Description',
          category: ClubCategory.technical,
          adminIds: ['admin_001'],
          isApproved: true,
          createdAt: DateTime.now(),
          createdBy: 'admin_001',
        );
        
        service.addClub(newClub);
        
        expect(service.allClubs.length, initialCount + 1);
        expect(service.getClubById(newClub.id), isNotNull);
      });
    });

    group('updateClub', () {
      test('updates existing club', () {
        final club = service.clubs.first;
        final updatedClub = club.copyWith(name: 'Updated Name');
        
        service.updateClub(updatedClub);
        
        final found = service.getClubById(club.id);
        expect(found!.name, 'Updated Name');
      });

      test('ignores update for non-existent club', () {
        final fakeClub = Club(
          id: 'fake_id',
          name: 'Fake',
          description: 'Fake',
          category: ClubCategory.other,
          adminIds: [],
          createdAt: DateTime.now(),
          createdBy: 'fake',
        );
        
        // Should not throw
        service.updateClub(fakeClub);
        expect(service.getClubById('fake_id'), isNull);
      });
    });

    group('deleteClub', () {
      test('removes club from list', () {
        // First add a club we can delete
        final clubToDelete = Club(
          id: 'club_to_delete',
          name: 'Delete Me',
          description: 'Will be deleted',
          category: ClubCategory.other,
          adminIds: ['admin'],
          isApproved: true,
          createdAt: DateTime.now(),
          createdBy: 'admin',
        );
        service.addClub(clubToDelete);
        expect(service.getClubById('club_to_delete'), isNotNull);
        
        service.deleteClub('club_to_delete');
        
        expect(service.getClubById('club_to_delete'), isNull);
      });
    });

    group('getMyClubs', () {
      test('returns clubs where user is member or admin', () {
        final clubs = service.clubs;
        if (clubs.isNotEmpty) {
          final adminId = clubs.first.adminIds.first;
          final myClubs = service.getMyClubs(adminId);
          expect(myClubs, isNotEmpty);
          for (final club in myClubs) {
            expect(club.isMember(adminId), true);
          }
        }
      });

      test('returns empty list for user with no clubs', () {
        final myClubs = service.getMyClubs('user_with_no_clubs');
        expect(myClubs, isEmpty);
      });
    });

    group('getAdminClubs', () {
      test('returns clubs where user is admin', () {
        final clubs = service.clubs;
        if (clubs.isNotEmpty) {
          final adminId = clubs.first.adminIds.first;
          final adminClubs = service.getAdminClubs(adminId);
          expect(adminClubs, isNotEmpty);
          for (final club in adminClubs) {
            expect(club.isAdmin(adminId), true);
          }
        }
      });
    });

    group('leaveClub', () {
      test('removes user from memberIds', () {
        // First add a user to club
        final club = service.clubs.first;
        service.joinClubDirectly(club.id, 'temp_member');
        
        var updatedClub = service.getClubById(club.id)!;
        expect(updatedClub.memberIds.contains('temp_member'), true);
        
        service.leaveClub(club.id, 'temp_member');
        
        updatedClub = service.getClubById(club.id)!;
        expect(updatedClub.memberIds.contains('temp_member'), false);
      });
    });

    group('joinClubDirectly', () {
      test('adds user to memberIds', () {
        final club = service.clubs.first;
        final newUserId = 'new_user_${DateTime.now().millisecondsSinceEpoch}';
        
        service.joinClubDirectly(club.id, newUserId);
        
        final updatedClub = service.getClubById(club.id)!;
        expect(updatedClub.memberIds.contains(newUserId), true);
      });

      test('does not add duplicate member', () {
        final club = service.clubs.first;
        final userId = 'duplicate_test_user';
        
        service.joinClubDirectly(club.id, userId);
        final countAfterFirst = service.getClubById(club.id)!.memberIds.length;
        
        service.joinClubDirectly(club.id, userId);
        final countAfterSecond = service.getClubById(club.id)!.memberIds.length;
        
        expect(countAfterSecond, countAfterFirst); // No change
      });
    });

    group('Club Join Requests', () {
      test('requestToJoinClub creates pending request', () {
        final request = service.requestToJoinClub(
          clubId: 'club_001',
          clubName: 'Test Club',
          userId: 'requesting_user',
          userName: 'Requesting User',
          note: 'Please let me join!',
        );
        
        expect(request.isPending, true);
        expect(request.clubId, 'club_001');
        expect(request.userId, 'requesting_user');
      });

      test('hasPendingRequest returns true for pending requests', () {
        service.requestToJoinClub(
          clubId: 'club_pending_test',
          clubName: 'Test',
          userId: 'pending_user',
          userName: 'User',
        );
        
        expect(service.hasPendingRequest('club_pending_test', 'pending_user'), true);
        expect(service.hasPendingRequest('club_pending_test', 'other_user'), false);
      });

      test('approveJoinRequest changes status and adds user to club', () {
        final request = service.requestToJoinClub(
          clubId: service.clubs.first.id,
          clubName: service.clubs.first.name,
          userId: 'approve_test_user',
          userName: 'Approve Test',
        );
        
        service.approveJoinRequest(request.id, 'adminId');
        
        final updatedClub = service.getClubById(service.clubs.first.id)!;
        expect(updatedClub.memberIds.contains('approve_test_user'), true);
      });

      test('rejectJoinRequest changes status', () {
        final request = service.requestToJoinClub(
          clubId: 'club_reject',
          clubName: 'Club',
          userId: 'reject_user',
          userName: 'User',
        );
        
        service.rejectJoinRequest(request.id, 'adminId', reason: 'Not qualified');
        
        expect(service.hasPendingRequest('club_reject', 'reject_user'), false);
      });

      test('cancelJoinRequest changes status', () {
        final request = service.requestToJoinClub(
          clubId: 'club_cancel',
          clubName: 'Club',
          userId: 'cancel_user',
          userName: 'User',
        );
        
        service.cancelJoinRequest(request.id);
        
        expect(service.hasPendingRequest('club_cancel', 'cancel_user'), false);
      });

      test('getPendingRequestsForClub returns only pending requests', () {
        service.requestToJoinClub(
          clubId: 'club_pending_filter',
          clubName: 'Club',
          userId: 'user_a',
          userName: 'User A',
        );
        service.requestToJoinClub(
          clubId: 'club_pending_filter',
          clubName: 'Club',
          userId: 'user_b',
          userName: 'User B',
        );
        
        final pending = service.getPendingRequestsForClub('club_pending_filter');
        expect(pending.length, 2);
        for (final req in pending) {
          expect(req.isPending, true);
        }
      });
    });

    group('Club Posts', () {
      test('getClubPosts returns posts for specific club', () {
        final clubId = service.clubs.first.id;
        
        service.addClubPost(ClubPost(
          id: 'post_test_1',
          clubId: clubId,
          authorId: 'author',
          authorName: 'Author',
          title: 'Test Post',
          content: 'Content',
          type: ClubPostType.announcement,
          createdAt: DateTime.now(),
        ));
        
        final posts = service.getClubPosts(clubId);
        expect(posts.any((p) => p.id == 'post_test_1'), true);
      });

      test('addClubPost adds post to service', () {
        final post = ClubPost(
          id: 'new_post_${DateTime.now().millisecondsSinceEpoch}',
          clubId: 'club_001',
          authorId: 'author',
          authorName: 'Author',
          title: 'New Post',
          content: 'Content',
          type: ClubPostType.general,
          createdAt: DateTime.now(),
        );
        
        final countBefore = service.getClubPosts('club_001').length;
        service.addClubPost(post);
        final countAfter = service.getClubPosts('club_001').length;
        
        expect(countAfter, countBefore + 1);
      });
    });
  });
}
