import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/council/models/report_model.dart';

void main() {
  group('ReportType', () {
    test('has 5 values', () {
      expect(ReportType.values.length, 5);
    });

    test('contains expected types', () {
      expect(ReportType.values, contains(ReportType.clubPost));
      expect(ReportType.values, contains(ReportType.event));
      expect(ReportType.values, contains(ReportType.forumQuestion));
      expect(ReportType.values, contains(ReportType.comment));
      expect(ReportType.values, contains(ReportType.user));
    });
  });

  group('ReportReason', () {
    test('has 5 values', () {
      expect(ReportReason.values.length, 5);
    });

    test('contains expected reasons', () {
      expect(ReportReason.values, contains(ReportReason.spam));
      expect(ReportReason.values, contains(ReportReason.harassment));
      expect(ReportReason.values, contains(ReportReason.inappropriate));
      expect(ReportReason.values, contains(ReportReason.misinformation));
      expect(ReportReason.values, contains(ReportReason.other));
    });
  });

  group('ReportStatus', () {
    test('has 3 values', () {
      expect(ReportStatus.values.length, 3);
    });

    test('contains expected statuses', () {
      expect(ReportStatus.values, contains(ReportStatus.pending));
      expect(ReportStatus.values, contains(ReportStatus.resolved));
      expect(ReportStatus.values, contains(ReportStatus.dismissed));
    });
  });

  group('Report', () {
    late Report report;

    setUp(() {
      report = Report(
        id: 'report_001',
        targetId: 'post_001',
        type: ReportType.clubPost,
        reason: ReportReason.spam,
        description: 'This post is spam',
        reporterId: 'user_001',
        timestamp: DateTime(2024, 1, 15),
        targetTitle: 'Spam Post',
        targetPreview: 'Buy now!!!',
      );
    });

    group('constructor', () {
      test('creates report with required fields', () {
        expect(report.id, 'report_001');
        expect(report.targetId, 'post_001');
        expect(report.type, ReportType.clubPost);
        expect(report.reason, ReportReason.spam);
        expect(report.description, 'This post is spam');
        expect(report.reporterId, 'user_001');
        expect(report.targetTitle, 'Spam Post');
        expect(report.targetPreview, 'Buy now!!!');
      });

      test('default status is pending', () {
        expect(report.status, ReportStatus.pending);
      });

      test('resolvedBy is null by default', () {
        expect(report.resolvedBy, isNull);
      });

      test('resolvedAt is null by default', () {
        expect(report.resolvedAt, isNull);
      });
    });

    group('copyWith', () {
      test('copies with new status', () {
        final copy = report.copyWith(status: ReportStatus.resolved);
        expect(copy.status, ReportStatus.resolved);
        expect(copy.id, report.id);
      });

      test('copies with resolvedBy', () {
        final copy = report.copyWith(resolvedBy: 'admin_001');
        expect(copy.resolvedBy, 'admin_001');
      });

      test('copies with resolvedAt', () {
        final resolveTime = DateTime(2024, 1, 16);
        final copy = report.copyWith(resolvedAt: resolveTime);
        expect(copy.resolvedAt, resolveTime);
      });

      test('copies with new reason', () {
        final copy = report.copyWith(reason: ReportReason.harassment);
        expect(copy.reason, ReportReason.harassment);
      });

      test('copies with new type', () {
        final copy = report.copyWith(type: ReportType.event);
        expect(copy.type, ReportType.event);
      });

      test('preserves unchanged fields', () {
        final copy = report.copyWith(status: ReportStatus.resolved);
        expect(copy.id, report.id);
        expect(copy.targetId, report.targetId);
        expect(copy.type, report.type);
        expect(copy.reason, report.reason);
        expect(copy.description, report.description);
        expect(copy.reporterId, report.reporterId);
        expect(copy.targetTitle, report.targetTitle);
        expect(copy.targetPreview, report.targetPreview);
      });
    });

    group('different report types', () {
      test('can create event report', () {
        final eventReport = Report(
          id: 'report_002',
          targetId: 'event_001',
          type: ReportType.event,
          reason: ReportReason.misinformation,
          description: 'Wrong event info',
          reporterId: 'user_002',
          timestamp: DateTime.now(),
          targetTitle: 'Fake Event',
          targetPreview: 'Free money!',
        );
        expect(eventReport.type, ReportType.event);
      });

      test('can create forum question report', () {
        final forumReport = Report(
          id: 'report_003',
          targetId: 'q_001',
          type: ReportType.forumQuestion,
          reason: ReportReason.inappropriate,
          description: 'Inappropriate content',
          reporterId: 'user_003',
          timestamp: DateTime.now(),
          targetTitle: 'Bad Question',
          targetPreview: 'Preview...',
        );
        expect(forumReport.type, ReportType.forumQuestion);
      });

      test('can create user report', () {
        final userReport = Report(
          id: 'report_004',
          targetId: 'user_bad',
          type: ReportType.user,
          reason: ReportReason.harassment,
          description: 'This user is harassing others',
          reporterId: 'user_004',
          timestamp: DateTime.now(),
          targetTitle: 'Bad User',
          targetPreview: 'User profile',
        );
        expect(userReport.type, ReportType.user);
      });
    });
  });
}
