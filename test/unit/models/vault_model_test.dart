import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/vault/models/vault_model.dart';

void main() {
  group('VaultItemType', () {
    test('has notes value', () {
      expect(VaultItemType.notes, isA<VaultItemType>());
    });

    test('has pyq value', () {
      expect(VaultItemType.pyq, isA<VaultItemType>());
    });

    test('has handwritten value', () {
      expect(VaultItemType.handwritten, isA<VaultItemType>());
    });

    test('has assignment value', () {
      expect(VaultItemType.assignment, isA<VaultItemType>());
    });

    test('has slides value', () {
      expect(VaultItemType.slides, isA<VaultItemType>());
    });

    test('has lab value', () {
      expect(VaultItemType.lab, isA<VaultItemType>());
    });

    test('has other value', () {
      expect(VaultItemType.other, isA<VaultItemType>());
    });

    test('values contains all 7 types', () {
      expect(VaultItemType.values.length, 7);
    });

    group('displayName', () {
      test('returns Notes for notes', () {
        expect(VaultItemType.notes.displayName, 'Notes');
      });

      test('returns Previous Year Questions for pyq', () {
        expect(VaultItemType.pyq.displayName, 'Previous Year Questions');
      });

      test('returns Handwritten Notes for handwritten', () {
        expect(VaultItemType.handwritten.displayName, 'Handwritten Notes');
      });

      test('returns Assignment for assignment', () {
        expect(VaultItemType.assignment.displayName, 'Assignment');
      });

      test('returns Slides for slides', () {
        expect(VaultItemType.slides.displayName, 'Slides');
      });

      test('returns Lab Manual for lab', () {
        expect(VaultItemType.lab.displayName, 'Lab Manual');
      });

      test('returns Other for other', () {
        expect(VaultItemType.other.displayName, 'Other');
      });
    });

    group('icon', () {
      test('returns emoji for notes', () {
        expect(VaultItemType.notes.icon, '📝');
      });

      test('returns emoji for pyq', () {
        expect(VaultItemType.pyq.icon, '📋');
      });

      test('returns emoji for handwritten', () {
        expect(VaultItemType.handwritten.icon, '✍️');
      });

      test('returns emoji for assignment', () {
        expect(VaultItemType.assignment.icon, '📄');
      });

      test('returns emoji for slides', () {
        expect(VaultItemType.slides.icon, '📊');
      });

      test('returns emoji for lab', () {
        expect(VaultItemType.lab.icon, '🔬');
      });

      test('returns emoji for other', () {
        expect(VaultItemType.other.icon, '📁');
      });
    });

    group('iconData', () {
      test('returns IconData for notes', () {
        expect(VaultItemType.notes.iconData, Icons.description_rounded);
      });

      test('returns IconData for pyq', () {
        expect(VaultItemType.pyq.iconData, Icons.quiz_rounded);
      });

      test('returns IconData for handwritten', () {
        expect(VaultItemType.handwritten.iconData, Icons.draw_rounded);
      });

      test('returns IconData for assignment', () {
        expect(VaultItemType.assignment.iconData, Icons.assignment_rounded);
      });

      test('returns IconData for slides', () {
        expect(VaultItemType.slides.iconData, Icons.slideshow_rounded);
      });

      test('returns IconData for lab', () {
        expect(VaultItemType.lab.iconData, Icons.science_rounded);
      });

      test('returns IconData for other', () {
        expect(VaultItemType.other.iconData, Icons.folder_rounded);
      });
    });
  });

  group('VaultItem', () {
    late VaultItem item;

    setUp(() {
      item = VaultItem(
        id: 'vault_001',
        uploaderId: 'user_001',
        uploaderName: 'John Doe',
        title: 'DSA Notes',
        fileUrl: 'https://example.com/file.pdf',
        fileName: 'dsa_notes.pdf',
        fileSizeBytes: 5242880,
        type: VaultItemType.notes,
        subject: 'Data Structures',
        branch: 'CSE',
        year: 2,
        semester: 1,
        createdAt: DateTime(2024, 1, 15),
      );
    });

    group('constructor', () {
      test('creates item with required fields', () {
        expect(item.id, 'vault_001');
        expect(item.uploaderId, 'user_001');
        expect(item.uploaderName, 'John Doe');
        expect(item.title, 'DSA Notes');
        expect(item.fileName, 'dsa_notes.pdf');
        expect(item.type, VaultItemType.notes);
        expect(item.year, 2);
        expect(item.semester, 1);
      });

      test('default description is empty', () {
        expect(item.description, '');
      });

      test('default downloadCount is 0', () {
        expect(item.downloadCount, 0);
      });

      test('default rating is 0.0', () {
        expect(item.rating, 0.0);
      });

      test('default isApproved is false', () {
        expect(item.isApproved, false);
      });

      test('default tags is empty list', () {
        expect(item.tags, isEmpty);
      });

      test('can create with all optional fields', () {
        final fullItem = VaultItem(
          id: 'vault_002',
          uploaderId: 'user_002',
          uploaderName: 'Jane Doe',
          title: 'DBMS PYQ',
          description: 'Previous year questions',
          fileUrl: 'https://example.com/pyq.pdf',
          fileName: 'dbms_pyq.pdf',
          fileSizeBytes: 3145728,
          type: VaultItemType.pyq,
          subject: 'Database',
          branch: 'CSE',
          year: 3,
          semester: 1,
          downloadCount: 100,
          rating: 4.5,
          isApproved: true,
          createdAt: DateTime(2024, 1, 10),
          tags: ['dbms', 'sql'],
        );

        expect(fullItem.description, 'Previous year questions');
        expect(fullItem.downloadCount, 100);
        expect(fullItem.rating, 4.5);
        expect(fullItem.isApproved, true);
        expect(fullItem.tags, ['dbms', 'sql']);
      });
    });

    group('formattedSize getter', () {
      test('returns MB for large files', () {
        final largeItem = item.copyWith(fileSizeBytes: 5242880);
        expect(largeItem.formattedSize, '5.00 MB');
      });

      test('returns KB for medium files', () {
        final medItem = item.copyWith(fileSizeBytes: 512000);
        expect(medItem.formattedSize, '500.00 KB');
      });

      test('returns B for small files', () {
        final smallItem = item.copyWith(fileSizeBytes: 500);
        expect(smallItem.formattedSize, '500 B');
      });

      test('handles exactly 1 MB', () {
        final mbItem = item.copyWith(fileSizeBytes: 1048576);
        expect(mbItem.formattedSize, '1.00 MB');
      });

      test('handles exactly 1 KB', () {
        final kbItem = item.copyWith(fileSizeBytes: 1024);
        expect(kbItem.formattedSize, '1.00 KB');
      });
    });

    group('fileExtension getter', () {
      test('returns PDF for pdf files', () {
        expect(item.fileExtension, 'PDF');
      });

      test('returns DOC for doc files', () {
        final docItem = item.copyWith(fileName: 'document.docx');
        expect(docItem.fileExtension, 'DOCX');
      });

      test('returns FILE for files without extension', () {
        final noExtItem = item.copyWith(fileName: 'noextension');
        expect(noExtItem.fileExtension, 'FILE');
      });

      test('handles multiple dots in filename', () {
        final multiDotItem = item.copyWith(fileName: 'my.file.name.txt');
        expect(multiDotItem.fileExtension, 'TXT');
      });
    });

    group('copyWith', () {
      test('copies with new id', () {
        final copy = item.copyWith(id: 'new_id');
        expect(copy.id, 'new_id');
        expect(copy.uploaderId, item.uploaderId);
      });

      test('copies with new title', () {
        final copy = item.copyWith(title: 'New Title');
        expect(copy.title, 'New Title');
      });

      test('copies with new type', () {
        final copy = item.copyWith(type: VaultItemType.pyq);
        expect(copy.type, VaultItemType.pyq);
      });

      test('copies with new downloadCount', () {
        final copy = item.copyWith(downloadCount: 50);
        expect(copy.downloadCount, 50);
      });

      test('copies with new rating', () {
        final copy = item.copyWith(rating: 4.8);
        expect(copy.rating, 4.8);
      });

      test('copies with new isApproved', () {
        final copy = item.copyWith(isApproved: true);
        expect(copy.isApproved, true);
      });

      test('copies with new tags', () {
        final copy = item.copyWith(tags: ['tag1', 'tag2']);
        expect(copy.tags, ['tag1', 'tag2']);
      });

      test('preserves unchanged fields', () {
        final copy = item.copyWith(title: 'New Title');
        expect(copy.id, item.id);
        expect(copy.uploaderId, item.uploaderId);
        expect(copy.uploaderName, item.uploaderName);
        expect(copy.type, item.type);
        expect(copy.subject, item.subject);
        expect(copy.branch, item.branch);
        expect(copy.year, item.year);
        expect(copy.semester, item.semester);
      });
    });

    group('toFirestore', () {
      test('returns map with all fields', () {
        final map = item.toFirestore();
        expect(map['uploaderId'], item.uploaderId);
        expect(map['uploaderName'], item.uploaderName);
        expect(map['title'], item.title);
        expect(map['fileName'], item.fileName);
        expect(map['type'], 'notes');
        expect(map['subject'], item.subject);
        expect(map['branch'], item.branch);
        expect(map['year'], item.year);
        expect(map['semester'], item.semester);
      });

      test('includes downloadCount', () {
        final map = item.toFirestore();
        expect(map['downloadCount'], 0);
      });

      test('includes rating', () {
        final map = item.toFirestore();
        expect(map['rating'], 0.0);
      });

      test('includes isApproved', () {
        final map = item.toFirestore();
        expect(map['isApproved'], false);
      });

      test('includes tags', () {
        final itemWithTags = item.copyWith(tags: ['tag1']);
        final map = itemWithTags.toFirestore();
        expect(map['tags'], ['tag1']);
      });
    });

    group('testItems', () {
      test('returns non-empty list', () {
        expect(VaultItem.testItems, isNotEmpty);
      });

      test('test items have valid data', () {
        for (final testItem in VaultItem.testItems) {
          expect(testItem.id, isNotEmpty);
          expect(testItem.title, isNotEmpty);
          expect(testItem.uploaderName, isNotEmpty);
        }
      });
    });
  });

  group('Branches', () {
    test('all contains expected branches', () {
      expect(Branches.all, contains('CSE'));
      expect(Branches.all, contains('ECE'));
      expect(Branches.all, contains('ME'));
      expect(Branches.all, contains('EEE'));
      expect(Branches.all, contains('CE'));
      expect(Branches.all, contains('IT'));
    });

    test('all has correct count', () {
      expect(Branches.all.length, 8);
    });

    test('fullNames contains mapping for all branches', () {
      for (final branch in Branches.all) {
        expect(Branches.fullNames.containsKey(branch), true);
      }
    });

    test('fullNames has correct CSE full name', () {
      expect(Branches.fullNames['CSE'], 'Computer Science & Engineering');
    });

    test('fullNames has correct ECE full name', () {
      expect(Branches.fullNames['ECE'], 'Electronics & Communication');
    });

    test('fullNames has correct ME full name', () {
      expect(Branches.fullNames['ME'], 'Mechanical Engineering');
    });
  });
}
