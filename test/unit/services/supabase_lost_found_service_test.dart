import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/lost_found/models/lost_found_model.dart';

void main() {
  group('LostFoundStatus Enum', () {
    test('all statuses are defined', () {
      expect(LostFoundStatus.values.length, 4);
    });

    test('displayName returns correct string', () {
      expect(LostFoundStatus.lost.displayName, 'Lost');
      expect(LostFoundStatus.found.displayName, 'Found');
      expect(LostFoundStatus.claimed.displayName, 'Claimed');
      expect(LostFoundStatus.expired.displayName, 'Expired');
    });

    test('icon returns emoji', () {
      for (final status in LostFoundStatus.values) {
        expect(status.icon, isNotEmpty);
      }
    });

    test('iconData returns non-null icon', () {
      for (final status in LostFoundStatus.values) {
        expect(status.iconData, isNotNull);
      }
    });
  });

  group('LostFoundCategory Enum', () {
    test('all categories are defined', () {
      expect(LostFoundCategory.values.length, 9);
    });

    test('displayName returns correct string', () {
      expect(LostFoundCategory.electronics.displayName, 'Electronics');
      expect(LostFoundCategory.documents.displayName, 'Documents');
      expect(LostFoundCategory.keys.displayName, 'Keys');
      expect(LostFoundCategory.wallet.displayName, 'Wallet/Purse');
    });

    test('icon returns emoji', () {
      for (final category in LostFoundCategory.values) {
        expect(category.icon, isNotEmpty);
      }
    });

    test('iconData returns non-null icon', () {
      for (final category in LostFoundCategory.values) {
        expect(category.iconData, isNotNull);
      }
    });
  });

  group('LostFoundItem Model', () {
    test('creates item with required fields', () {
      final now = DateTime.now();
      final item = LostFoundItem(
        id: '1',
        userId: 'user_1',
        userName: 'John Doe',
        status: LostFoundStatus.lost,
        category: LostFoundCategory.electronics,
        title: 'Lost Phone',
        description: 'Black iPhone 14',
        location: 'Library',
        itemDate: now,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 30)),
      );

      expect(item.id, '1');
      expect(item.title, 'Lost Phone');
      expect(item.status, LostFoundStatus.lost);
      expect(item.category, LostFoundCategory.electronics);
    });

    test('creates lost item', () {
      final item = LostFoundItem(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        status: LostFoundStatus.lost,
        category: LostFoundCategory.wallet,
        title: 'Lost Wallet',
        description: 'Brown leather wallet',
        location: 'Canteen',
        itemDate: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(item.status, LostFoundStatus.lost);
    });

    test('creates found item', () {
      final item = LostFoundItem(
        id: '1',
        userId: 'user_1',
        userName: 'Finder',
        status: LostFoundStatus.found,
        category: LostFoundCategory.keys,
        title: 'Found Keys',
        description: 'Honda car keys',
        location: 'Parking Lot',
        itemDate: DateTime.now(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(item.status, LostFoundStatus.found);
    });

    test('item with optional fields', () {
      final item = LostFoundItem(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        status: LostFoundStatus.found,
        category: LostFoundCategory.electronics,
        title: 'Found Earbuds',
        description: 'Sony earbuds',
        imageUrl: 'https://example.com/image.jpg',
        location: 'Library',
        itemDate: DateTime.now(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        contactInfo: '9876543210',
      );

      expect(item.imageUrl, 'https://example.com/image.jpg');
      expect(item.contactInfo, '9876543210');
    });

    test('claimed item with claimer info', () {
      final item = LostFoundItem(
        id: '1',
        userId: 'owner_1',
        userName: 'Owner',
        status: LostFoundStatus.claimed,
        category: LostFoundCategory.electronics,
        title: 'Phone',
        description: 'Claimed phone',
        location: 'Office',
        itemDate: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        expiresAt: DateTime.now().add(const Duration(days: 25)),
        claimerId: 'claimer_1',
        claimerName: 'Claimer',
        isContactRevealed: true,
      );

      expect(item.status, LostFoundStatus.claimed);
      expect(item.claimerId, 'claimer_1');
      expect(item.claimerName, 'Claimer');
      expect(item.isContactRevealed, true);
    });
  });

  group('LostFoundItem Computed Properties', () {
    test('isExpired returns true for expired items', () {
      final item = LostFoundItem(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        status: LostFoundStatus.lost,
        category: LostFoundCategory.other,
        title: 'Expired Item',
        description: 'desc',
        location: 'loc',
        itemDate: DateTime.now().subtract(const Duration(days: 40)),
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
        expiresAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      expect(item.isExpired, true);
    });

    test('isExpired returns false for active items', () {
      final item = LostFoundItem(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        status: LostFoundStatus.lost,
        category: LostFoundCategory.other,
        title: 'Active Item',
        description: 'desc',
        location: 'loc',
        itemDate: DateTime.now(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(item.isExpired, false);
    });

    test('isActive returns true for non-expired non-claimed items', () {
      final item = LostFoundItem(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        status: LostFoundStatus.lost,
        category: LostFoundCategory.other,
        title: 'Active Item',
        description: 'desc',
        location: 'loc',
        itemDate: DateTime.now(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(item.isActive, true);
    });

    test('isActive returns false for claimed items', () {
      final item = LostFoundItem(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        status: LostFoundStatus.claimed,
        category: LostFoundCategory.other,
        title: 'Claimed Item',
        description: 'desc',
        location: 'loc',
        itemDate: DateTime.now(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(item.isActive, false);
    });

    test('daysUntilExpiry calculates correctly', () {
      final item = LostFoundItem(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        status: LostFoundStatus.lost,
        category: LostFoundCategory.other,
        title: 'Item',
        description: 'desc',
        location: 'loc',
        itemDate: DateTime.now(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 15)),
      );

      expect(item.daysUntilExpiry, inInclusiveRange(14, 15));
    });

    test('isOwnedBy checks user ID', () {
      final item = LostFoundItem(
        id: '1',
        userId: 'user_123',
        userName: 'User',
        status: LostFoundStatus.lost,
        category: LostFoundCategory.other,
        title: 'Item',
        description: 'desc',
        location: 'loc',
        itemDate: DateTime.now(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(item.isOwnedBy('user_123'), true);
      expect(item.isOwnedBy('user_456'), false);
    });
  });

  group('LostFoundItem copyWith', () {
    test('copyWith creates copy with updated fields', () {
      final original = LostFoundItem(
        id: '1',
        userId: 'user_1',
        userName: 'User',
        status: LostFoundStatus.lost,
        category: LostFoundCategory.electronics,
        title: 'Original',
        description: 'desc',
        location: 'loc',
        itemDate: DateTime.now(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      final updated = original.copyWith(
        status: LostFoundStatus.claimed,
        claimerId: 'claimer_1',
      );

      expect(updated.status, LostFoundStatus.claimed);
      expect(updated.claimerId, 'claimer_1');
      expect(updated.title, 'Original'); // Unchanged
    });
  });

  group('LostFoundItem Serialization', () {
    test('toFirestore returns correct map', () {
      final item = LostFoundItem(
        id: '1',
        userId: 'user_1',
        userName: 'John',
        status: LostFoundStatus.found,
        category: LostFoundCategory.keys,
        title: 'Found Keys',
        description: 'Car keys',
        location: 'Parking',
        itemDate: DateTime(2024, 1, 15),
        createdAt: DateTime(2024, 1, 15),
        expiresAt: DateTime(2024, 2, 14),
      );

      final map = item.toFirestore();

      expect(map['userId'], 'user_1');
      expect(map['status'], 'found');
      expect(map['category'], 'keys');
      expect(map['title'], 'Found Keys');
    });

    test('fromFirestore creates correct object', () {
      final data = {
        'id': '1',
        'userId': 'user_1',
        'userName': 'Jane',
        'status': 'lost',
        'category': 'wallet',
        'title': 'Lost Wallet',
        'description': 'Brown wallet',
        'location': 'Canteen',
        'itemDate': '2024-01-15T10:00:00.000Z',
        'createdAt': '2024-01-15T10:00:00.000Z',
        'expiresAt': '2024-02-14T10:00:00.000Z',
      };

      final item = LostFoundItem.fromFirestore(data);

      expect(item.title, 'Lost Wallet');
      expect(item.status, LostFoundStatus.lost);
      expect(item.category, LostFoundCategory.wallet);
    });
  });

  group('LostFoundItem Filtering', () {
    late List<LostFoundItem> testItems;

    setUp(() {
      final now = DateTime.now();
      testItems = [
        LostFoundItem(
          id: '1',
          userId: 'user_1',
          userName: 'User1',
          status: LostFoundStatus.lost,
          category: LostFoundCategory.electronics,
          title: 'Lost Phone',
          description: 'desc',
          location: 'Library',
          itemDate: now,
          createdAt: now,
          expiresAt: now.add(const Duration(days: 30)),
        ),
        LostFoundItem(
          id: '2',
          userId: 'user_2',
          userName: 'User2',
          status: LostFoundStatus.found,
          category: LostFoundCategory.documents,
          title: 'Found ID Card',
          description: 'desc',
          location: 'Canteen',
          itemDate: now,
          createdAt: now,
          expiresAt: now.add(const Duration(days: 30)),
        ),
        LostFoundItem(
          id: '3',
          userId: 'user_1',
          userName: 'User1',
          status: LostFoundStatus.claimed,
          category: LostFoundCategory.keys,
          title: 'Claimed Keys',
          description: 'desc',
          location: 'Parking',
          itemDate: now.subtract(const Duration(days: 10)),
          createdAt: now.subtract(const Duration(days: 10)),
          expiresAt: now.add(const Duration(days: 20)),
        ),
      ];
    });

    test('filter lost items', () {
      final lost = testItems.where((i) => i.status == LostFoundStatus.lost).toList();
      expect(lost.length, 1);
    });

    test('filter found items', () {
      final found = testItems.where((i) => i.status == LostFoundStatus.found).toList();
      expect(found.length, 1);
    });

    test('filter by category', () {
      final electronics = testItems.where((i) => i.category == LostFoundCategory.electronics).toList();
      expect(electronics.length, 1);
    });

    test('filter by location', () {
      final library = testItems.where((i) => i.location.contains('Library')).toList();
      expect(library.length, 1);
    });

    test('filter active items', () {
      final active = testItems.where((i) => i.isActive).toList();
      expect(active.length, 2); // Lost and Found, not Claimed
    });

    test('filter by user', () {
      final user1Items = testItems.where((i) => i.isOwnedBy('user_1')).toList();
      expect(user1Items.length, 2);
    });
  });

  group('ClaimStatus Enum', () {
    test('all statuses are defined', () {
      expect(ClaimStatus.values.length, 3);
    });

    test('statuses are correct', () {
      expect(ClaimStatus.values, contains(ClaimStatus.pending));
      expect(ClaimStatus.values, contains(ClaimStatus.approved));
      expect(ClaimStatus.values, contains(ClaimStatus.rejected));
    });
  });

  group('ClaimRequest Model', () {
    test('creates claim request with required fields', () {
      final claim = ClaimRequest(
        id: '1',
        itemId: 'item_1',
        claimerId: 'claimer_1',
        claimerName: 'Claimer',
        message: 'This is my wallet, it has my ID inside.',
        createdAt: DateTime.now(),
      );

      expect(claim.id, '1');
      expect(claim.itemId, 'item_1');
      expect(claim.claimerId, 'claimer_1');
      expect(claim.message, isNotEmpty);
      expect(claim.status, ClaimStatus.pending); // Default
    });

    test('claim request with approved status', () {
      final claim = ClaimRequest(
        id: '1',
        itemId: 'item_1',
        claimerId: 'claimer_1',
        claimerName: 'Claimer',
        message: 'message',
        status: ClaimStatus.approved,
        createdAt: DateTime.now(),
      );

      expect(claim.status, ClaimStatus.approved);
    });

    test('claim request serialization', () {
      final claim = ClaimRequest(
        id: '1',
        itemId: 'item_1',
        claimerId: 'claimer_1',
        claimerName: 'John',
        message: 'My wallet',
        createdAt: DateTime(2024, 1, 15),
      );

      final map = claim.toFirestore();

      expect(map['itemId'], 'item_1');
      expect(map['claimerId'], 'claimer_1');
      expect(map['status'], 'pending');
    });
  });

  group('Test Data', () {
    test('testItems provides sample data', () {
      final samples = LostFoundItem.testItems;
      expect(samples.length, greaterThan(0));
    });

    test('testItems contains both lost and found', () {
      final samples = LostFoundItem.testItems;
      final statuses = samples.map((i) => i.status).toSet();
      expect(statuses, containsAll([LostFoundStatus.lost, LostFoundStatus.found]));
    });
  });
}
