import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/models/user_model.dart';
import 'package:mvgr_nexus/core/constants/app_constants.dart';

void main() {
  group('AppUser', () {
    late AppUser testUser;

    setUp(() {
      testUser = AppUser(
        uid: 'user_001',
        email: 'test@mvgrce.edu.in',
        name: 'Test User',
        rollNumber: '21BCE7100',
        department: 'Computer Science',
        year: 3,
        role: UserRole.student,
        clubIds: ['club_001', 'club_002'],
        interests: ['coding', 'music'],
        skills: ['flutter', 'dart'],
        bio: 'Test bio',
        isVerified: true,
        createdAt: DateTime(2024, 1, 1),
      );
    });

    group('constructor', () {
      test('creates user with required fields', () {
        final user = AppUser(
          uid: 'uid',
          email: 'test@test.com',
          name: 'Name',
          rollNumber: '21BCE0000',
          department: 'CSE',
          year: 1,
          createdAt: DateTime.now(),
        );
        expect(user.uid, 'uid');
        expect(user.email, 'test@test.com');
        expect(user.role, UserRole.student); // Default
        expect(user.isVerified, false); // Default
      });

      test('sets default values correctly', () {
        final user = AppUser(
          uid: 'uid',
          email: 'test@test.com',
          name: 'Name',
          rollNumber: '21BCE0000',
          department: 'CSE',
          year: 1,
          createdAt: DateTime.now(),
        );
        expect(user.clubIds, isEmpty);
        expect(user.interests, isEmpty);
        expect(user.skills, isEmpty);
        expect(user.profilePhotoUrl, isNull);
        expect(user.bio, isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final updated = testUser.copyWith(
          name: 'New Name',
          year: 4,
        );
        expect(updated.name, 'New Name');
        expect(updated.year, 4);
        expect(updated.uid, testUser.uid); // Unchanged
        expect(updated.email, testUser.email); // Unchanged
      });

      test('creates copy with same values when no args passed', () {
        final copy = testUser.copyWith();
        expect(copy.uid, testUser.uid);
        expect(copy.email, testUser.email);
        expect(copy.name, testUser.name);
        expect(copy.role, testUser.role);
      });

      test('can update optional fields', () {
        final updated = testUser.copyWith(
          bio: 'Updated bio',
          profilePhotoUrl: 'http://example.com/photo.jpg',
        );
        expect(updated.bio, 'Updated bio');
        expect(updated.profilePhotoUrl, 'http://example.com/photo.jpg');
      });
    });

    group('displayNameWithRole', () {
      test('returns name with role for student', () {
        expect(testUser.displayNameWithRole, 'Test User (Student)');
      });

      test('returns name with role for different roles', () {
        final admin = testUser.copyWith(role: UserRole.clubAdmin);
        expect(admin.displayNameWithRole, 'Test User (Club Admin)');

        final council = testUser.copyWith(role: UserRole.council);
        expect(council.displayNameWithRole, 'Test User (Student Council)');

        final faculty = testUser.copyWith(role: UserRole.faculty);
        expect(faculty.displayNameWithRole, 'Test User (Faculty)');
      });
    });

    group('isClubAdmin', () {
      test('returns true when clubId is in clubIds', () {
        expect(testUser.isClubAdmin('club_001'), true);
        expect(testUser.isClubAdmin('club_002'), true);
      });

      test('returns false when clubId is not in clubIds', () {
        expect(testUser.isClubAdmin('club_999'), false);
        expect(testUser.isClubAdmin(''), false);
      });
    });

    group('toFirestore', () {
      test('returns correct map structure', () {
        final map = testUser.toFirestore();
        
        expect(map['email'], 'test@mvgrce.edu.in');
        expect(map['name'], 'Test User');
        expect(map['rollNumber'], '21BCE7100');
        expect(map['department'], 'Computer Science');
        expect(map['year'], 3);
        expect(map['role'], 'student');
        expect(map['clubIds'], ['club_001', 'club_002']);
        expect(map['interests'], ['coding', 'music']);
        expect(map['skills'], ['flutter', 'dart']);
        expect(map['bio'], 'Test bio');
        expect(map['isVerified'], true);
      });

      test('does not include uid in map (used as document ID)', () {
        final map = testUser.toFirestore();
        expect(map.containsKey('uid'), false);
      });
    });

    group('static constructors', () {
      test('empty returns anonymous user', () {
        final empty = AppUser.empty;
        expect(empty.uid, '');
        expect(empty.name, 'Anonymous');
        expect(empty.year, 0);
      });

      test('testStudent returns valid test user', () {
        final student = AppUser.testStudent();
        expect(student.uid, 'test_student_001');
        expect(student.name, 'Test Student');
        expect(student.role, UserRole.student);
        expect(student.isVerified, true);
      });

      test('testStudent accepts custom name and role', () {
        final admin = AppUser.testStudent(name: 'Admin User', role: UserRole.clubAdmin);
        expect(admin.name, 'Admin User');
        expect(admin.role, UserRole.clubAdmin);
      });
    });
  });

  group('UserRole', () {
    group('displayName', () {
      test('returns correct display names', () {
        expect(UserRole.student.displayName, 'Student');
        expect(UserRole.clubAdmin.displayName, 'Club Admin');
        expect(UserRole.council.displayName, 'Student Council');
        expect(UserRole.faculty.displayName, 'Faculty');
      });
    });

    group('permissions', () {
      test('canModerate is true for council and faculty', () {
        expect(UserRole.student.canModerate, false);
        expect(UserRole.clubAdmin.canModerate, false);
        expect(UserRole.council.canModerate, true);
        expect(UserRole.faculty.canModerate, true);
      });

      test('canCreateClub is false only for student', () {
        expect(UserRole.student.canCreateClub, false);
        expect(UserRole.clubAdmin.canCreateClub, true);
        expect(UserRole.council.canCreateClub, true);
        expect(UserRole.faculty.canCreateClub, true);
      });

      test('canCreateEvent is false only for student', () {
        expect(UserRole.student.canCreateEvent, false);
        expect(UserRole.clubAdmin.canCreateEvent, true);
        expect(UserRole.council.canCreateEvent, true);
        expect(UserRole.faculty.canCreateEvent, true);
      });

      test('canApproveContent is true for council and faculty', () {
        expect(UserRole.student.canApproveContent, false);
        expect(UserRole.clubAdmin.canApproveContent, false);
        expect(UserRole.council.canApproveContent, true);
        expect(UserRole.faculty.canApproveContent, true);
      });

      test('canPostAnnouncement is true for council and faculty', () {
        expect(UserRole.student.canPostAnnouncement, false);
        expect(UserRole.clubAdmin.canPostAnnouncement, false);
        expect(UserRole.council.canPostAnnouncement, true);
        expect(UserRole.faculty.canPostAnnouncement, true);
      });

      test('isFaculty is true only for faculty', () {
        expect(UserRole.student.isFaculty, false);
        expect(UserRole.clubAdmin.isFaculty, false);
        expect(UserRole.council.isFaculty, false);
        expect(UserRole.faculty.isFaculty, true);
      });
    });
  });
}
