import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('appName is correct', () {
      expect(AppConstants.appName, 'MVGR NexUs');
    });

    test('appVersion is set', () {
      expect(AppConstants.appVersion, isNotEmpty);
    });

    test('collegeName is correct', () {
      expect(AppConstants.collegeName, 'MVGR College of Engineering');
    });

    group('Firestore collections', () {
      test('usersCollection is correct', () {
        expect(AppConstants.usersCollection, 'users');
      });

      test('clubsCollection is correct', () {
        expect(AppConstants.clubsCollection, 'clubs');
      });

      test('eventsCollection is correct', () {
        expect(AppConstants.eventsCollection, 'events');
      });

      test('lostFoundCollection is correct', () {
        expect(AppConstants.lostFoundCollection, 'lost_found');
      });
    });

    group('expiry durations', () {
      test('lostFoundExpiryDays is 30', () {
        expect(AppConstants.lostFoundExpiryDays, 30);
      });

      test('studyRequestExpiryDays is 14', () {
        expect(AppConstants.studyRequestExpiryDays, 14);
      });
    });

    group('size limits', () {
      test('maxVaultFileSize is 25 MB', () {
        expect(AppConstants.maxVaultFileSize, 25 * 1024 * 1024);
      });

      test('maxImageSize is 5 MB', () {
        expect(AppConstants.maxImageSize, 5 * 1024 * 1024);
      });

      test('maxInterests is 10', () {
        expect(AppConstants.maxInterests, 10);
      });
    });
  });

  group('UserRole', () {
    test('has 4 values', () {
      expect(UserRole.values.length, 4);
    });

    group('displayName', () {
      test('student displays correctly', () {
        expect(UserRole.student.displayName, 'Student');
      });

      test('clubAdmin displays correctly', () {
        expect(UserRole.clubAdmin.displayName, 'Club Admin');
      });

      test('council displays correctly', () {
        expect(UserRole.council.displayName, 'Student Council');
      });

      test('faculty displays correctly', () {
        expect(UserRole.faculty.displayName, 'Faculty');
      });
    });

    group('canModerate', () {
      test('student cannot moderate', () {
        expect(UserRole.student.canModerate, false);
      });

      test('clubAdmin cannot moderate', () {
        expect(UserRole.clubAdmin.canModerate, false);
      });

      test('council can moderate', () {
        expect(UserRole.council.canModerate, true);
      });

      test('faculty can moderate', () {
        expect(UserRole.faculty.canModerate, true);
      });
    });

    group('canCreateClub', () {
      test('student cannot create club', () {
        expect(UserRole.student.canCreateClub, false);
      });

      test('clubAdmin can create club', () {
        expect(UserRole.clubAdmin.canCreateClub, true);
      });

      test('council can create club', () {
        expect(UserRole.council.canCreateClub, true);
      });
    });

    group('canCreateEvent', () {
      test('student cannot create event', () {
        expect(UserRole.student.canCreateEvent, false);
      });

      test('clubAdmin can create event', () {
        expect(UserRole.clubAdmin.canCreateEvent, true);
      });
    });

    group('canApproveContent', () {
      test('student cannot approve', () {
        expect(UserRole.student.canApproveContent, false);
      });

      test('council can approve', () {
        expect(UserRole.council.canApproveContent, true);
      });

      test('faculty can approve', () {
        expect(UserRole.faculty.canApproveContent, true);
      });
    });

    group('canPostAnnouncement', () {
      test('student cannot post announcement', () {
        expect(UserRole.student.canPostAnnouncement, false);
      });

      test('council can post announcement', () {
        expect(UserRole.council.canPostAnnouncement, true);
      });
    });

    group('isFaculty', () {
      test('student is not faculty', () {
        expect(UserRole.student.isFaculty, false);
      });

      test('faculty is faculty', () {
        expect(UserRole.faculty.isFaculty, true);
      });
    });
  });

  group('ModerationStatus', () {
    test('has 4 values', () {
      expect(ModerationStatus.values.length, 4);
    });

    group('displayName', () {
      test('pending displays correctly', () {
        expect(ModerationStatus.pending.displayName, 'Pending Review');
      });

      test('approved displays correctly', () {
        expect(ModerationStatus.approved.displayName, 'Approved');
      });

      test('rejected displays correctly', () {
        expect(ModerationStatus.rejected.displayName, 'Rejected');
      });

      test('flagged displays correctly', () {
        expect(ModerationStatus.flagged.displayName, 'Flagged for Review');
      });
    });
  });

  group('AnimationDurations', () {
    test('instant is zero', () {
      expect(AnimationDurations.instant, Duration.zero);
    });

    test('fast is 150ms', () {
      expect(AnimationDurations.fast, const Duration(milliseconds: 150));
    });

    test('normal is 300ms', () {
      expect(AnimationDurations.normal, const Duration(milliseconds: 300));
    });

    test('slow is 500ms', () {
      expect(AnimationDurations.slow, const Duration(milliseconds: 500));
    });

    test('pageTransition is 350ms', () {
      expect(AnimationDurations.pageTransition, const Duration(milliseconds: 350));
    });
  });

  group('UIConstants', () {
    group('border radius', () {
      test('radiusSmall is 8', () {
        expect(UIConstants.radiusSmall, 8.0);
      });

      test('radiusMedium is 12', () {
        expect(UIConstants.radiusMedium, 12.0);
      });

      test('radiusLarge is 16', () {
        expect(UIConstants.radiusLarge, 16.0);
      });

      test('radiusFull is 999', () {
        expect(UIConstants.radiusFull, 999.0);
      });
    });

    group('padding', () {
      test('paddingSmall is 8', () {
        expect(UIConstants.paddingSmall, 8.0);
      });

      test('paddingMedium is 16', () {
        expect(UIConstants.paddingMedium, 16.0);
      });

      test('paddingLarge is 24', () {
        expect(UIConstants.paddingLarge, 24.0);
      });
    });

    group('icon sizes', () {
      test('iconSmall is 16', () {
        expect(UIConstants.iconSmall, 16.0);
      });

      test('iconMedium is 24', () {
        expect(UIConstants.iconMedium, 24.0);
      });

      test('iconLarge is 32', () {
        expect(UIConstants.iconLarge, 32.0);
      });
    });

    group('avatar sizes', () {
      test('avatarSmall is 32', () {
        expect(UIConstants.avatarSmall, 32.0);
      });

      test('avatarMedium is 48', () {
        expect(UIConstants.avatarMedium, 48.0);
      });

      test('avatarLarge is 64', () {
        expect(UIConstants.avatarLarge, 64.0);
      });
    });

    group('button heights', () {
      test('buttonHeight is 52', () {
        expect(UIConstants.buttonHeight, 52.0);
      });

      test('buttonHeightSmall is 40', () {
        expect(UIConstants.buttonHeightSmall, 40.0);
      });
    });

    group('elevation', () {
      test('elevationNone is 0', () {
        expect(UIConstants.elevationNone, 0.0);
      });

      test('elevationMedium is 4', () {
        expect(UIConstants.elevationMedium, 4.0);
      });
    });
  });
}
