import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/supabase_escalation_service.dart';

void main() {
  group('SupabaseEscalationService', () {
    test('singleton instance is created', () {
      expect(supabaseEscalationService, isNotNull);
      expect(supabaseEscalationService, equals(SupabaseEscalationService()));
    });

    test('EscalationType enum has correct values', () {
      expect(EscalationType.values.length, equals(4));
      expect(EscalationType.dispute.name, 'dispute');
      expect(EscalationType.misconduct.name, 'misconduct');
      expect(EscalationType.appeal.name, 'appeal');
      expect(EscalationType.other.name, 'other');
    });

    test('EscalationPriority enum has correct values', () {
      expect(EscalationPriority.values.length, equals(4));
      expect(EscalationPriority.low.name, 'low');
      expect(EscalationPriority.medium.name, 'medium');
      expect(EscalationPriority.high.name, 'high');
      expect(EscalationPriority.urgent.name, 'urgent');
    });

    test('EscalationStatus enum has correct values', () {
      expect(EscalationStatus.values.length, equals(3));
      expect(EscalationStatus.pending.name, 'pending');
      expect(EscalationStatus.inProgress.name, 'inProgress');
      expect(EscalationStatus.resolved.name, 'resolved');
    });

    test('Escalation.fromJson parses correctly', () {
      final json = {
        'id': 'test-123',
        'title': 'Test Escalation',
        'description': 'Test description',
        'type': 'dispute',
        'priority': 'high',
        'status': 'pending',
        'submitted_by': 'Test User',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final escalation = Escalation.fromJson(json);
      
      expect(escalation.id, 'test-123');
      expect(escalation.title, 'Test Escalation');
      expect(escalation.description, 'Test description');
      expect(escalation.type, EscalationType.dispute);
      expect(escalation.priority, EscalationPriority.high);
      expect(escalation.status, EscalationStatus.pending);
      expect(escalation.submittedBy, 'Test User');
    });

    test('Escalation.copyWith creates correct copy', () {
      final original = Escalation.fromJson({
        'id': 'test-123',
        'title': 'Test',
        'description': 'Desc',
        'type': 'dispute',
        'priority': 'high',
        'status': 'pending',
        'submitted_by': 'User',
        'created_at': '2024-01-01T00:00:00.000Z',
      });

      final resolved = original.copyWith(
        status: EscalationStatus.resolved,
        resolution: 'Fixed',
      );

      expect(resolved.id, original.id);
      expect(resolved.title, original.title);
      expect(resolved.status, EscalationStatus.resolved);
      expect(resolved.resolution, 'Fixed');
    });

    group('Operations', () {
      test('submitEscalation returns true on success', () async {
        final success = await supabaseEscalationService.submitEscalation(
          title: 'Title',
          description: 'Desc',
          type: EscalationType.dispute,
          priority: EscalationPriority.high,
          submittedBy: 'User',
        );
        expect(success, isTrue);
      });

      test('resolveEscalation returns true on success', () async {
        final success = await supabaseEscalationService.resolveEscalation('1', 'Fixed');
        expect(success, isTrue);
      });

      test('assignEscalation returns true on success', () async {
        final success = await supabaseEscalationService.assignEscalation('1', 'Faculty X');
        expect(success, isTrue);
      });
    });
  });
}
