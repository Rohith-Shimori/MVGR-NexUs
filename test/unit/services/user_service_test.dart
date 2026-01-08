import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/user_service.dart';
import 'package:mvgr_nexus/models/user_model.dart';
import 'package:mvgr_nexus/core/constants/app_constants.dart';

void main() {
  group('MockUserService', () {
    setUp(() {
      // Reset to default student before each test
      MockUserService.loginAsStudent();
    });

    group('currentUser', () {
      test('returns default test student', () {
        final user = MockUserService.currentUser;
        expect(user, isNotNull);
        expect(user.role, UserRole.student);
      });
    });

    group('allUsers', () {
      test('returns list of test users', () {
        final users = MockUserService.allUsers;
        expect(users, isNotEmpty);
        expect(users.length, greaterThanOrEqualTo(4));
      });

      test('includes different roles', () {
        final users = MockUserService.allUsers;
        final roles = users.map((u) => u.role).toSet();
        expect(roles, contains(UserRole.student));
        expect(roles, contains(UserRole.clubAdmin));
        expect(roles, contains(UserRole.council));
        expect(roles, contains(UserRole.faculty));
      });
    });

    group('getUserById', () {
      test('returns user when exists', () {
        final testUser = MockUserService.allUsers.first;
        final found = MockUserService.getUserById(testUser.uid);
        expect(found, isNotNull);
        expect(found!.uid, testUser.uid);
      });

      test('returns null when user does not exist', () {
        final found = MockUserService.getUserById('non_existent_id');
        expect(found, isNull);
      });
    });

    group('setCurrentUser', () {
      test('changes current user', () {
        final newUser = AppUser.testStudent(name: 'Custom User');
        MockUserService.setCurrentUser(newUser);
        expect(MockUserService.currentUser.name, 'Custom User');
      });
    });

    group('loginAsStudent', () {
      test('sets current user to student role', () {
        MockUserService.loginAsStudent();
        expect(MockUserService.currentUser.role, UserRole.student);
      });
    });

    group('loginAsClubAdmin', () {
      test('sets current user to club admin role', () {
        MockUserService.loginAsClubAdmin();
        expect(MockUserService.currentUser.role, UserRole.clubAdmin);
        expect(MockUserService.currentUser.email, contains('clubadmin'));
      });
    });

    group('loginAsCouncil', () {
      test('sets current user to council role', () {
        MockUserService.loginAsCouncil();
        expect(MockUserService.currentUser.role, UserRole.council);
        expect(MockUserService.currentUser.email, contains('council'));
      });
    });

    group('loginAsFaculty', () {
      test('sets current user to faculty role', () {
        MockUserService.loginAsFaculty();
        expect(MockUserService.currentUser.role, UserRole.faculty);
        expect(MockUserService.currentUser.email, contains('faculty'));
      });
    });

    group('Permission checks', () {
      test('student cannot moderate', () {
        MockUserService.loginAsStudent();
        expect(MockUserService.canModerate(), false);
      });

      test('council can moderate', () {
        MockUserService.loginAsCouncil();
        expect(MockUserService.canModerate(), true);
      });

      test('faculty can moderate', () {
        MockUserService.loginAsFaculty();
        expect(MockUserService.canModerate(), true);
      });

      test('student cannot create club', () {
        MockUserService.loginAsStudent();
        expect(MockUserService.canCreateClub(), false);
      });

      test('club admin can create club', () {
        MockUserService.loginAsClubAdmin();
        expect(MockUserService.canCreateClub(), true);
      });

      test('student cannot create event', () {
        MockUserService.loginAsStudent();
        expect(MockUserService.canCreateEvent(), false);
      });

      test('club admin can create event', () {
        MockUserService.loginAsClubAdmin();
        expect(MockUserService.canCreateEvent(), true);
      });

      test('student cannot approve content', () {
        MockUserService.loginAsStudent();
        expect(MockUserService.canApproveContent(), false);
      });

      test('council can approve content', () {
        MockUserService.loginAsCouncil();
        expect(MockUserService.canApproveContent(), true);
      });
    });

    group('updateInterests', () {
      test('updates current user interests', () {
        final interests = ['coding', 'music', 'sports'];
        MockUserService.updateInterests(interests);
        expect(MockUserService.currentUser.interests, interests);
      });
    });

    group('updateProfile', () {
      test('updates profile fields', () {
        MockUserService.updateProfile(
          bio: 'New bio',
          profilePhotoUrl: 'http://example.com/photo.jpg',
        );
        
        expect(MockUserService.currentUser.bio, 'New bio');
        expect(MockUserService.currentUser.profilePhotoUrl, 'http://example.com/photo.jpg');
      });

      test('preserves unspecified fields', () {
        final originalName = MockUserService.currentUser.name;
        MockUserService.updateProfile(bio: 'Updated bio');
        expect(MockUserService.currentUser.name, originalName);
      });

      test('updates background settings', () {
        MockUserService.updateProfile(
          backgroundType: 'gradient',
          backgroundColorValue: 0xFF0000FF,
        );
        expect(MockUserService.currentUser.backgroundType, 'gradient');
        expect(MockUserService.currentUser.backgroundColorValue, 0xFF0000FF);
      });
    });
  });

  group('UserProvider', () {
    late UserProvider provider;

    setUp(() {
      provider = UserProvider();
      MockUserService.loginAsStudent();
    });

    test('currentUser returns MockUserService current user', () {
      expect(provider.currentUser, MockUserService.currentUser);
    });

    test('isLoggedIn always returns true (for testing)', () {
      expect(provider.isLoggedIn, true);
    });

    test('userId returns current user uid', () {
      expect(provider.userId, MockUserService.currentUser.uid);
    });

    test('userName returns current user name', () {
      expect(provider.userName, MockUserService.currentUser.name);
    });

    test('userRole returns current user role', () {
      expect(provider.userRole, MockUserService.currentUser.role);
    });

    test('canModerate reflects current user permissions', () {
      MockUserService.loginAsStudent();
      expect(UserProvider().canModerate, false);

      MockUserService.loginAsCouncil();
      expect(UserProvider().canModerate, true);
    });

    test('canCreateClub reflects current user permissions', () {
      MockUserService.loginAsStudent();
      expect(UserProvider().canCreateClub, false);

      MockUserService.loginAsClubAdmin();
      expect(UserProvider().canCreateClub, true);
    });

    test('canCreateEvent reflects current user permissions', () {
      MockUserService.loginAsStudent();
      expect(UserProvider().canCreateEvent, false);

      MockUserService.loginAsClubAdmin();
      expect(UserProvider().canCreateEvent, true);
    });
  });
}
