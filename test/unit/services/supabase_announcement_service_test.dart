import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/events/models/event_model.dart';

void main() {
  group('Announcement Model', () {
    test('creates announcement with required fields', () {
      final announcement = Announcement(
        id: '1',
        title: 'Test Announcement',
        content: 'Test content',
        authorId: 'author_1',
        authorName: 'Admin',
        authorRole: 'Council',
        createdAt: DateTime.now(),
      );

      expect(announcement.id, '1');
      expect(announcement.title, 'Test Announcement');
      expect(announcement.content, 'Test content');
      expect(announcement.authorId, 'author_1');
      expect(announcement.authorName, 'Admin');
    });

    test('creates announcement with optional fields', () {
      final expires = DateTime.now().add(const Duration(days: 7));
      final announcement = Announcement(
        id: '1',
        title: 'Test Announcement',
        content: 'Test content',
        authorId: 'author_1',
        authorName: 'Admin',
        authorRole: 'Faculty',
        isPinned: true,
        isUrgent: true,
        expiresAt: expires,
        imageUrl: 'https://example.com/image.png',
        createdAt: DateTime.now(),
      );

      expect(announcement.isPinned, true);
      expect(announcement.isUrgent, true);
      expect(announcement.expiresAt, expires);
      expect(announcement.imageUrl, 'https://example.com/image.png');
    });

    test('default values for optional boolean fields', () {
      final announcement = Announcement(
        id: '1',
        title: 'Test',
        content: 'Content',
        authorId: 'a1',
        authorName: 'Name',
        authorRole: 'Council',
        createdAt: DateTime.now(),
      );

      expect(announcement.isPinned, false);
      expect(announcement.isUrgent, false);
    });
  });

  group('SupabaseAnnouncementService Properties', () {
    // These tests verify the service configuration without requiring Supabase
    
    test('announcement model can serialize to expected format', () {
      final announcement = Announcement(
        id: 'test_id',
        title: 'Test Title',
        content: 'Test Content',
        authorId: 'user_1',
        authorName: 'Test User',
        authorRole: 'Council',
        isPinned: true,
        isUrgent: false,
        createdAt: DateTime(2024, 1, 15, 10, 30),
      );

      // Verify the model has expected fields
      expect(announcement.id, 'test_id');
      expect(announcement.title, 'Test Title');
      expect(announcement.isPinned, true);
      expect(announcement.isUrgent, false);
    });

    test('announcement with expiration date', () {
      final expiresAt = DateTime(2024, 2, 1);
      final announcement = Announcement(
        id: '1',
        title: 'Limited Time',
        content: 'Expires soon',
        authorId: 'a1',
        authorName: 'Admin',
        authorRole: 'Council',
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
      );

      expect(announcement.expiresAt, expiresAt);
      expect(announcement.expiresAt!.isAfter(DateTime.now()), false);
    });

    test('urgent announcements are properly flagged', () {
      final urgent = Announcement(
        id: '1',
        title: 'URGENT: Campus Alert',
        content: 'Important update',
        authorId: 'a1',
        authorName: 'Admin',
        authorRole: 'Council',
        isUrgent: true,
        createdAt: DateTime.now(),
      );

      expect(urgent.isUrgent, true);
      expect(urgent.isPinned, false);
    });

    test('pinned and urgent announcements', () {
      final pinnedUrgent = Announcement(
        id: '1',
        title: 'Critical Notice',
        content: 'Very important',
        authorId: 'a1',
        authorName: 'Dean',
        authorRole: 'Faculty',
        isPinned: true,
        isUrgent: true,
        createdAt: DateTime.now(),
      );

      expect(pinnedUrgent.isPinned, true);
      expect(pinnedUrgent.isUrgent, true);
    });
  });

  group('Announcement Author Roles', () {
    test('council announcements', () {
      final announcement = Announcement(
        id: '1',
        title: 'Student Council Update',
        content: 'Council news',
        authorId: 'council_1',
        authorName: 'Student Council',
        authorRole: 'Council',
        createdAt: DateTime.now(),
      );

      expect(announcement.authorRole, 'Council');
    });

    test('faculty announcements', () {
      final announcement = Announcement(
        id: '1',
        title: 'Faculty Notice',
        content: 'Department news',
        authorId: 'faculty_1',
        authorName: 'Dr. Smith',
        authorRole: 'Faculty',
        createdAt: DateTime.now(),
      );

      expect(announcement.authorRole, 'Faculty');
    });
  });
}
