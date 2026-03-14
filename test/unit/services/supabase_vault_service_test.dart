import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/vault/models/vault_model.dart';

void main() {
  group('VaultItem Model', () {
    test('creates vault item with required fields', () {
      final item = VaultItem(
        id: '1',
        title: 'Data Structures Notes',
        description: 'Complete notes for DSA',
        fileUrl: 'https://example.com/file.pdf',
        fileName: 'dsa_notes.pdf',
        fileSizeBytes: 1024000,
        type: VaultItemType.notes,
        subject: 'Data Structures',
        branch: 'CSE',
        year: 3,
        semester: 5,
        uploaderId: 'user_1',
        uploaderName: 'John Doe',
        createdAt: DateTime.now(),
      );

      expect(item.id, '1');
      expect(item.title, 'Data Structures Notes');
      expect(item.type, VaultItemType.notes);
      expect(item.subject, 'Data Structures');
    });

    test('creates vault item with file info', () {
      final item = VaultItem(
        id: '1',
        title: 'Physics Lab Manual',
        fileUrl: 'https://storage.example.com/files/lab-manual.pdf',
        fileName: 'lab-manual.pdf',
        fileSizeBytes: 2048000,
        type: VaultItemType.lab,
        subject: 'Physics',
        branch: 'ECE',
        year: 2,
        semester: 3,
        uploaderId: 'user_1',
        uploaderName: 'Jane',
        createdAt: DateTime.now(),
      );

      expect(item.fileUrl, 'https://storage.example.com/files/lab-manual.pdf');
      expect(item.fileName, 'lab-manual.pdf');
      expect(item.fileSizeBytes, 2048000);
    });

    test('creates vault item with tags', () {
      final item = VaultItem(
        id: '1',
        title: 'Algorithms Notes',
        fileUrl: 'https://example.com/algo.pdf',
        fileName: 'algo.pdf',
        fileSizeBytes: 512000,
        type: VaultItemType.notes,
        subject: 'Algorithms',
        branch: 'CSE',
        year: 3,
        semester: 5,
        uploaderId: 'user_1',
        uploaderName: 'Test User',
        tags: ['sorting', 'searching', 'algorithms'],
        createdAt: DateTime.now(),
      );

      expect(item.tags, contains('sorting'));
      expect(item.tags.length, 3);
    });

    test('vault item with download count and rating', () {
      final item = VaultItem(
        id: '1',
        title: 'Popular Notes',
        fileUrl: 'https://example.com/popular.pdf',
        fileName: 'popular.pdf',
        fileSizeBytes: 1024000,
        type: VaultItemType.notes,
        subject: 'Math',
        branch: 'CSE',
        year: 1,
        semester: 1,
        uploaderId: 'user_1',
        uploaderName: 'Expert',
        downloadCount: 150,
        rating: 4.5,
        createdAt: DateTime.now(),
      );

      expect(item.downloadCount, 150);
      expect(item.rating, 4.5);
    });
  });

  group('VaultItemType', () {
    test('all vault item types are defined', () {
      expect(VaultItemType.values.length, 7);
    });

    test('notes type exists', () {
      expect(VaultItemType.values, contains(VaultItemType.notes));
    });

    test('pyq (previous year questions) type exists', () {
      expect(VaultItemType.values, contains(VaultItemType.pyq));
    });

    test('lab type exists', () {
      expect(VaultItemType.values, contains(VaultItemType.lab));
    });

    test('slides type exists', () {
      expect(VaultItemType.values, contains(VaultItemType.slides));
    });

    test('displayName returns correct string', () {
      expect(VaultItemType.notes.displayName, 'Notes');
      expect(VaultItemType.pyq.displayName, 'Previous Year Questions');
      expect(VaultItemType.lab.displayName, 'Lab Manual');
    });

    test('icon returns emoji', () {
      expect(VaultItemType.notes.icon, isNotEmpty);
      expect(VaultItemType.pyq.icon, isNotEmpty);
    });
  });

  group('VaultItem Computed Properties', () {
    test('formattedSize returns correct format for bytes', () {
      final item = VaultItem(
        id: '1',
        title: 'Small file',
        fileUrl: 'url',
        fileName: 'file.pdf',
        fileSizeBytes: 500,
        type: VaultItemType.notes,
        subject: 's',
        branch: 'CSE',
        year: 1,
        semester: 1,
        uploaderId: 'u',
        uploaderName: 'n',
        createdAt: DateTime.now(),
      );
      expect(item.formattedSize, '500 B');
    });

    test('formattedSize returns correct format for KB', () {
      final item = VaultItem(
        id: '1',
        title: 'Medium file',
        fileUrl: 'url',
        fileName: 'file.pdf',
        fileSizeBytes: 2048,
        type: VaultItemType.notes,
        subject: 's',
        branch: 'CSE',
        year: 1,
        semester: 1,
        uploaderId: 'u',
        uploaderName: 'n',
        createdAt: DateTime.now(),
      );
      expect(item.formattedSize, contains('KB'));
    });

    test('formattedSize returns correct format for MB', () {
      final item = VaultItem(
        id: '1',
        title: 'Large file',
        fileUrl: 'url',
        fileName: 'file.pdf',
        fileSizeBytes: 2097152,
        type: VaultItemType.notes,
        subject: 's',
        branch: 'CSE',
        year: 1,
        semester: 1,
        uploaderId: 'u',
        uploaderName: 'n',
        createdAt: DateTime.now(),
      );
      expect(item.formattedSize, contains('MB'));
    });

    test('fileExtension extracts extension correctly', () {
      final item = VaultItem(
        id: '1',
        title: 'PDF Document',
        fileUrl: 'url',
        fileName: 'document.pdf',
        fileSizeBytes: 1024,
        type: VaultItemType.notes,
        subject: 's',
        branch: 'CSE',
        year: 1,
        semester: 1,
        uploaderId: 'u',
        uploaderName: 'n',
        createdAt: DateTime.now(),
      );
      expect(item.fileExtension, 'PDF');
    });
  });

  group('VaultItem copyWith', () {
    test('copyWith creates a copy with updated fields', () {
      final original = VaultItem(
        id: '1',
        title: 'Original',
        fileUrl: 'url',
        fileName: 'file.pdf',
        fileSizeBytes: 1024,
        type: VaultItemType.notes,
        subject: 'Subject',
        branch: 'CSE',
        year: 1,
        semester: 1,
        uploaderId: 'u',
        uploaderName: 'n',
        downloadCount: 0,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        title: 'Updated',
        downloadCount: 100,
      );

      expect(updated.title, 'Updated');
      expect(updated.downloadCount, 100);
      expect(updated.id, '1'); // Unchanged
      expect(updated.subject, 'Subject'); // Unchanged
    });
  });

  group('VaultItem Filtering', () {
    late List<VaultItem> testItems;

    setUp(() {
      testItems = [
        VaultItem(
          id: '1',
          title: 'CSE Notes',
          fileUrl: 'url1',
          fileName: 'f1.pdf',
          fileSizeBytes: 1024,
          type: VaultItemType.notes,
          subject: 'DSA',
          branch: 'CSE',
          year: 3,
          semester: 5,
          uploaderId: 'u1',
          uploaderName: 'User1',
          createdAt: DateTime.now(),
        ),
        VaultItem(
          id: '2',
          title: 'ECE Notes',
          fileUrl: 'url2',
          fileName: 'f2.pdf',
          fileSizeBytes: 2048,
          type: VaultItemType.notes,
          subject: 'Signals',
          branch: 'ECE',
          year: 2,
          semester: 4,
          uploaderId: 'u2',
          uploaderName: 'User2',
          createdAt: DateTime.now(),
        ),
        VaultItem(
          id: '3',
          title: 'PYQ',
          fileUrl: 'url3',
          fileName: 'f3.pdf',
          fileSizeBytes: 3072,
          type: VaultItemType.pyq,
          subject: 'DSA',
          branch: 'CSE',
          year: 3,
          semester: 5,
          uploaderId: 'u1',
          uploaderName: 'User1',
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('filter by branch', () {
      final cseItems = testItems.where((item) => item.branch == 'CSE').toList();
      expect(cseItems.length, 2);
    });

    test('filter by type', () {
      final notes = testItems.where((item) => item.type == VaultItemType.notes).toList();
      expect(notes.length, 2);
    });

    test('filter by year and semester', () {
      final thirdYear = testItems
          .where((item) => item.year == 3 && item.semester == 5)
          .toList();
      expect(thirdYear.length, 2);
    });

    test('filter by subject', () {
      final dsaItems = testItems.where((item) => item.subject == 'DSA').toList();
      expect(dsaItems.length, 2);
    });

    test('filter by uploader', () {
      final user1Items = testItems.where((item) => item.uploaderId == 'u1').toList();
      expect(user1Items.length, 2);
    });
  });

  group('Branches', () {
    test('all branches are defined', () {
      expect(Branches.all.length, 8);
    });

    test('common branches exist', () {
      expect(Branches.all, contains('CSE'));
      expect(Branches.all, contains('ECE'));
      expect(Branches.all, contains('ME'));
    });

    test('fullNames contains all branches', () {
      for (final branch in Branches.all) {
        expect(Branches.fullNames.containsKey(branch), true);
      }
    });
  });

  group('VaultItem serialization', () {
    test('toFirestore returns correct map', () {
      final item = VaultItem(
        id: '1',
        title: 'Test',
        fileUrl: 'https://test.com/file.pdf',
        fileName: 'file.pdf',
        fileSizeBytes: 1024,
        type: VaultItemType.notes,
        subject: 'Subject',
        branch: 'CSE',
        year: 1,
        semester: 1,
        uploaderId: 'user1',
        uploaderName: 'User',
        createdAt: DateTime(2024, 1, 15),
      );

      final map = item.toFirestore();
      
      expect(map['title'], 'Test');
      expect(map['fileUrl'], 'https://test.com/file.pdf');
      expect(map['fileName'], 'file.pdf');
      expect(map['type'], 'notes');
      expect(map['branch'], 'CSE');
    });

    test('fromFirestore creates correct object', () {
      final data = {
        'id': '1',
        'title': 'From Firestore',
        'fileUrl': 'https://test.com/file.pdf',
        'fileName': 'file.pdf',
        'fileSizeBytes': 2048,
        'type': 'pyq',
        'subject': 'Math',
        'branch': 'ECE',
        'year': 2,
        'semester': 3,
        'uploaderId': 'user1',
        'uploaderName': 'User',
        'downloadCount': 50,
        'rating': 4.5,
        'createdAt': '2024-01-15T10:00:00.000Z',
        'tags': ['exam', 'questions'],
      };

      final item = VaultItem.fromFirestore(data);
      
      expect(item.title, 'From Firestore');
      expect(item.type, VaultItemType.pyq);
      expect(item.downloadCount, 50);
      expect(item.tags, contains('exam'));
    });
  });
}
