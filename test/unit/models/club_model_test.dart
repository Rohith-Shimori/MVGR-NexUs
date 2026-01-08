import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/clubs/models/club_model.dart';

void main() {
  group('Club', () {
    late Club testClub;

    setUp(() {
      testClub = Club(
        id: 'club_001',
        name: 'Test Club',
        description: 'A test club description',
        category: ClubCategory.technical,
        adminIds: ['admin_001', 'admin_002'],
        memberIds: ['member_001', 'member_002', 'member_003'],
        logoUrl: 'http://example.com/logo.png',
        contactEmail: 'club@test.com',
        instagramHandle: 'testclub',
        isApproved: true,
        isOfficial: false,
        createdAt: DateTime(2024, 1, 1),
        createdBy: 'admin_001',
      );
    });

    group('constructor', () {
      test('creates club with required fields', () {
        final club = Club(
          id: 'id',
          name: 'Name',
          description: 'Desc',
          category: ClubCategory.cultural,
          adminIds: ['admin'],
          createdAt: DateTime.now(),
          createdBy: 'creator',
        );
        expect(club.id, 'id');
        expect(club.name, 'Name');
        expect(club.memberIds, isEmpty);
        expect(club.isApproved, false);
        expect(club.isOfficial, false);
      });
    });

    group('totalMembers', () {
      test('returns sum of adminIds and memberIds', () {
        expect(testClub.totalMembers, 5); // 2 admins + 3 members
      });

      test('returns correct count for empty members', () {
        final clubNoMembers = testClub.copyWith(memberIds: []);
        expect(clubNoMembers.totalMembers, 2); // Only admins
      });
    });

    group('isAdmin', () {
      test('returns true for admin users', () {
        expect(testClub.isAdmin('admin_001'), true);
        expect(testClub.isAdmin('admin_002'), true);
      });

      test('returns false for non-admin users', () {
        expect(testClub.isAdmin('member_001'), false);
        expect(testClub.isAdmin('unknown_user'), false);
      });
    });

    group('isMember', () {
      test('returns true for members', () {
        expect(testClub.isMember('member_001'), true);
        expect(testClub.isMember('member_002'), true);
      });

      test('returns true for admins (admins are also members)', () {
        expect(testClub.isMember('admin_001'), true);
        expect(testClub.isMember('admin_002'), true);
      });

      test('returns false for non-members', () {
        expect(testClub.isMember('unknown_user'), false);
        expect(testClub.isMember(''), false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final updated = testClub.copyWith(
          name: 'Updated Name',
          isApproved: false,
        );
        expect(updated.name, 'Updated Name');
        expect(updated.isApproved, false);
        expect(updated.id, testClub.id); // Unchanged
      });

      test('preserves original values when not specified', () {
        final copy = testClub.copyWith();
        expect(copy.id, testClub.id);
        expect(copy.name, testClub.name);
        expect(copy.adminIds, testClub.adminIds);
      });
    });

    group('toFirestore', () {
      test('returns correct map structure', () {
        final map = testClub.toFirestore();
        
        expect(map['name'], 'Test Club');
        expect(map['description'], 'A test club description');
        expect(map['category'], 'technical');
        expect(map['adminIds'], ['admin_001', 'admin_002']);
        expect(map['memberIds'], ['member_001', 'member_002', 'member_003']);
        expect(map['logoUrl'], 'http://example.com/logo.png');
        expect(map['contactEmail'], 'club@test.com');
        expect(map['instagramHandle'], 'testclub');
        expect(map['isApproved'], true);
        expect(map['isOfficial'], false);
      });
    });

    group('testClubs', () {
      test('returns non-empty list of test clubs', () {
        final clubs = Club.testClubs;
        expect(clubs, isNotEmpty);
        expect(clubs.length, greaterThanOrEqualTo(3));
      });

      test('all test clubs have required fields', () {
        for (final club in Club.testClubs) {
          expect(club.id, isNotEmpty);
          expect(club.name, isNotEmpty);
          expect(club.adminIds, isNotEmpty);
          expect(club.isApproved, true);
        }
      });
    });
  });

  group('ClubCategory', () {
    group('displayName', () {
      test('returns correct display names', () {
        expect(ClubCategory.technical.displayName, 'Technical');
        expect(ClubCategory.cultural.displayName, 'Cultural');
        expect(ClubCategory.sports.displayName, 'Sports');
        expect(ClubCategory.social.displayName, 'Social');
        expect(ClubCategory.academic.displayName, 'Academic');
        expect(ClubCategory.other.displayName, 'Other');
      });
    });

    group('icon', () {
      test('returns emoji for each category', () {
        expect(ClubCategory.technical.icon, '💻');
        expect(ClubCategory.cultural.icon, '🎭');
        expect(ClubCategory.sports.icon, '🏃');
        expect(ClubCategory.social.icon, '🤝');
        expect(ClubCategory.academic.icon, '📚');
        expect(ClubCategory.other.icon, '⭐');
      });
    });

    group('iconData', () {
      test('returns IconData for each category', () {
        expect(ClubCategory.technical.iconData, Icons.code_rounded);
        expect(ClubCategory.cultural.iconData, Icons.palette_rounded);
        expect(ClubCategory.sports.iconData, Icons.sports_soccer_rounded);
        expect(ClubCategory.social.iconData, Icons.people_rounded);
        expect(ClubCategory.academic.iconData, Icons.school_rounded);
        expect(ClubCategory.other.iconData, Icons.stars_rounded);
      });
    });
  });

  group('ClubPost', () {
    group('constructor', () {
      test('creates post with required fields', () {
        final post = ClubPost(
          id: 'post_001',
          clubId: 'club_001',
          authorId: 'author_001',
          authorName: 'Test Author',
          title: 'Test Post',
          content: 'Post content here',
          type: ClubPostType.announcement,
          createdAt: DateTime.now(),
        );
        expect(post.id, 'post_001');
        expect(post.isPinned, false); // Default
      });
    });

    group('toFirestore', () {
      test('returns correct map structure', () {
        final post = ClubPost(
          id: 'post_001',
          clubId: 'club_001',
          authorId: 'author_001',
          authorName: 'Test Author',
          title: 'Test Post',
          content: 'Content',
          type: ClubPostType.recruitment,
          createdAt: DateTime(2024, 1, 1),
          isPinned: true,
        );
        final map = post.toFirestore();
        
        expect(map['clubId'], 'club_001');
        expect(map['authorId'], 'author_001');
        expect(map['authorName'], 'Test Author');
        expect(map['title'], 'Test Post');
        expect(map['type'], 'recruitment');
        expect(map['isPinned'], true);
      });
    });
  });

  group('ClubPostType', () {
    test('displayName returns correct values', () {
      expect(ClubPostType.announcement.displayName, 'Announcement');
      expect(ClubPostType.event.displayName, 'Event');
      expect(ClubPostType.recruitment.displayName, 'Recruitment');
      expect(ClubPostType.general.displayName, 'General');
    });
  });
}
