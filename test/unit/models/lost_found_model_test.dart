import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/lost_found/models/lost_found_model.dart';

void main() {
  group('LostFoundStatus', () {
    test('has 4 values', () {
      expect(LostFoundStatus.values.length, 4);
    });

    test('displayName returns Lost for lost', () {
      expect(LostFoundStatus.lost.displayName, 'Lost');
    });

    test('displayName returns Found for found', () {
      expect(LostFoundStatus.found.displayName, 'Found');
    });

    test('displayName returns Claimed for claimed', () {
      expect(LostFoundStatus.claimed.displayName, 'Claimed');
    });

    test('displayName returns Expired for expired', () {
      expect(LostFoundStatus.expired.displayName, 'Expired');
    });

    test('icon returns emoji for each status', () {
      expect(LostFoundStatus.lost.icon, '🔍');
      expect(LostFoundStatus.found.icon, '📦');
      expect(LostFoundStatus.claimed.icon, '✅');
      expect(LostFoundStatus.expired.icon, '⏰');
    });

    test('iconData returns IconData for each status', () {
      expect(LostFoundStatus.lost.iconData, Icons.search_rounded);
      expect(LostFoundStatus.found.iconData, Icons.inventory_2_rounded);
      expect(LostFoundStatus.claimed.iconData, Icons.check_circle_rounded);
      expect(LostFoundStatus.expired.iconData, Icons.timer_off_rounded);
    });
  });

  group('LostFoundCategory', () {
    test('has 9 values', () {
      expect(LostFoundCategory.values.length, 9);
    });

    test('displayName returns correct names', () {
      expect(LostFoundCategory.electronics.displayName, 'Electronics');
      expect(LostFoundCategory.documents.displayName, 'Documents');
      expect(LostFoundCategory.wallet.displayName, 'Wallet/Purse');
      expect(LostFoundCategory.bag.displayName, 'Bag/Backpack');
      expect(LostFoundCategory.keys.displayName, 'Keys');
    });

    test('icon returns emoji for each category', () {
      expect(LostFoundCategory.electronics.icon, '📱');
      expect(LostFoundCategory.documents.icon, '📄');
      expect(LostFoundCategory.keys.icon, '🔑');
    });

    test('iconData returns IconData for each category', () {
      expect(LostFoundCategory.electronics.iconData, Icons.smartphone_rounded);
      expect(LostFoundCategory.documents.iconData, Icons.description_rounded);
      expect(LostFoundCategory.keys.iconData, Icons.key_rounded);
    });
  });

  group('LostFoundItem', () {
    late LostFoundItem item;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      item = LostFoundItem(
        id: 'lf_001',
        userId: 'user_001',
        userName: 'John Doe',
        status: LostFoundStatus.lost,
        category: LostFoundCategory.electronics,
        title: 'Lost Earbuds',
        description: 'Black Sony earbuds',
        location: 'Library',
        itemDate: now.subtract(const Duration(days: 1)),
        createdAt: now,
        expiresAt: now.add(const Duration(days: 30)),
      );
    });

    group('constructor', () {
      test('creates item with required fields', () {
        expect(item.id, 'lf_001');
        expect(item.userId, 'user_001');
        expect(item.userName, 'John Doe');
        expect(item.status, LostFoundStatus.lost);
        expect(item.category, LostFoundCategory.electronics);
        expect(item.title, 'Lost Earbuds');
      });

      test('imageUrl is null by default', () {
        expect(item.imageUrl, isNull);
      });

      test('claimerId is null by default', () {
        expect(item.claimerId, isNull);
      });

      test('isContactRevealed is false by default', () {
        expect(item.isContactRevealed, false);
      });
    });

    group('isExpired getter', () {
      test('returns false for future expiry', () {
        expect(item.isExpired, false);
      });

      test('returns true for past expiry', () {
        final expired = item.copyWith(
          expiresAt: now.subtract(const Duration(days: 1)),
        );
        expect(expired.isExpired, true);
      });
    });

    group('isActive getter', () {
      test('returns true for non-expired lost item', () {
        expect(item.isActive, true);
      });

      test('returns false for claimed item', () {
        final claimed = item.copyWith(status: LostFoundStatus.claimed);
        expect(claimed.isActive, false);
      });
    });

    group('daysUntilExpiry getter', () {
      test('returns positive days for future expiry', () {
        expect(item.daysUntilExpiry, greaterThanOrEqualTo(29));
      });
    });

    group('isOwnedBy', () {
      test('returns true for owner', () {
        expect(item.isOwnedBy('user_001'), true);
      });

      test('returns false for non-owner', () {
        expect(item.isOwnedBy('user_999'), false);
      });
    });

    group('copyWith', () {
      test('copies with new status', () {
        final copy = item.copyWith(status: LostFoundStatus.claimed);
        expect(copy.status, LostFoundStatus.claimed);
        expect(copy.id, item.id);
      });

      test('copies with new category', () {
        final copy = item.copyWith(category: LostFoundCategory.documents);
        expect(copy.category, LostFoundCategory.documents);
      });

      test('copies with claimerId', () {
        final copy = item.copyWith(claimerId: 'claimer_001');
        expect(copy.claimerId, 'claimer_001');
      });
    });

    group('toFirestore', () {
      test('returns map with correct fields', () {
        final map = item.toFirestore();
        expect(map['userId'], 'user_001');
        expect(map['userName'], 'John Doe');
        expect(map['status'], 'lost');
        expect(map['category'], 'electronics');
        expect(map['title'], 'Lost Earbuds');
        expect(map['location'], 'Library');
      });
    });

    group('testItems', () {
      test('returns non-empty list', () {
        expect(LostFoundItem.testItems, isNotEmpty);
      });
    });
  });

  group('ClaimStatus', () {
    test('has 3 values', () {
      expect(ClaimStatus.values.length, 3);
    });

    test('contains pending, approved, rejected', () {
      expect(ClaimStatus.values, contains(ClaimStatus.pending));
      expect(ClaimStatus.values, contains(ClaimStatus.approved));
      expect(ClaimStatus.values, contains(ClaimStatus.rejected));
    });
  });

  group('ClaimRequest', () {
    test('creates with required fields', () {
      final claim = ClaimRequest(
        id: 'claim_001',
        itemId: 'lf_001',
        claimerId: 'user_002',
        claimerName: 'Jane Doe',
        message: 'This is my item',
        createdAt: DateTime.now(),
      );

      expect(claim.id, 'claim_001');
      expect(claim.itemId, 'lf_001');
      expect(claim.status, ClaimStatus.pending);
    });

    group('toFirestore', () {
      test('returns correct map', () {
        final claim = ClaimRequest(
          id: 'claim_001',
          itemId: 'lf_001',
          claimerId: 'user_002',
          claimerName: 'Jane Doe',
          message: 'My item',
          createdAt: DateTime.now(),
        );

        final map = claim.toFirestore();
        expect(map['itemId'], 'lf_001');
        expect(map['claimerId'], 'user_002');
        expect(map['status'], 'pending');
      });
    });
  });
}
