import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/models/event_registration_model.dart';

void main() {
  group('RegistrationStatus', () {
    test('has registered value', () {
      expect(RegistrationStatus.registered, isA<RegistrationStatus>());
    });

    test('has checkedIn value', () {
      expect(RegistrationStatus.checkedIn, isA<RegistrationStatus>());
    });

    test('has cancelled value', () {
      expect(RegistrationStatus.cancelled, isA<RegistrationStatus>());
    });

    test('has noShow value', () {
      expect(RegistrationStatus.noShow, isA<RegistrationStatus>());
    });

    test('displayName returns Registered for registered', () {
      expect(RegistrationStatus.registered.displayName, 'Registered');
    });

    test('displayName returns Checked In for checkedIn', () {
      expect(RegistrationStatus.checkedIn.displayName, 'Checked In');
    });

    test('displayName returns Cancelled for cancelled', () {
      expect(RegistrationStatus.cancelled.displayName, 'Cancelled');
    });

    test('displayName returns No Show for noShow', () {
      expect(RegistrationStatus.noShow.displayName, 'No Show');
    });

    test('values contains all statuses', () {
      expect(RegistrationStatus.values.length, 4);
    });
  });

  group('EventRegistration', () {
    late EventRegistration registration;

    setUp(() {
      registration = EventRegistration(
        id: 'reg_001',
        eventId: 'event_001',
        eventTitle: 'Tech Talk',
        userId: 'user_001',
        userName: 'John Doe',
        registeredAt: DateTime(2024, 1, 15),
      );
    });

    group('constructor', () {
      test('creates registration with required fields', () {
        expect(registration.id, 'reg_001');
        expect(registration.eventId, 'event_001');
        expect(registration.eventTitle, 'Tech Talk');
        expect(registration.userId, 'user_001');
        expect(registration.userName, 'John Doe');
      });

      test('default status is registered', () {
        expect(registration.status, RegistrationStatus.registered);
      });

      test('checkedInAt is null by default', () {
        expect(registration.checkedInAt, isNull);
      });

      test('cancelledAt is null by default', () {
        expect(registration.cancelledAt, isNull);
      });

      test('formResponses is null by default', () {
        expect(registration.formResponses, isNull);
      });

      test('can create with all optional fields', () {
        final fullReg = EventRegistration(
          id: 'reg_002',
          eventId: 'event_002',
          eventTitle: 'Workshop',
          userId: 'user_002',
          userName: 'Jane Doe',
          status: RegistrationStatus.checkedIn,
          registeredAt: DateTime(2024, 1, 10),
          checkedInAt: DateTime(2024, 1, 15, 10, 30),
          formResponses: {'question1': 'answer1'},
        );

        expect(fullReg.status, RegistrationStatus.checkedIn);
        expect(fullReg.checkedInAt, isNotNull);
        expect(fullReg.formResponses, isNotNull);
      });
    });

    group('isRegistered getter', () {
      test('returns true when status is registered', () {
        expect(registration.isRegistered, true);
      });

      test('returns false when status is checkedIn', () {
        final checkedIn = registration.copyWith(status: RegistrationStatus.checkedIn);
        expect(checkedIn.isRegistered, false);
      });

      test('returns false when status is cancelled', () {
        final cancelled = registration.copyWith(status: RegistrationStatus.cancelled);
        expect(cancelled.isRegistered, false);
      });
    });

    group('isCheckedIn getter', () {
      test('returns false when status is registered', () {
        expect(registration.isCheckedIn, false);
      });

      test('returns true when status is checkedIn', () {
        final checkedIn = registration.copyWith(status: RegistrationStatus.checkedIn);
        expect(checkedIn.isCheckedIn, true);
      });
    });

    group('isCancelled getter', () {
      test('returns false when status is registered', () {
        expect(registration.isCancelled, false);
      });

      test('returns true when status is cancelled', () {
        final cancelled = registration.copyWith(status: RegistrationStatus.cancelled);
        expect(cancelled.isCancelled, true);
      });
    });

    group('copyWith', () {
      test('copies with new id', () {
        final copy = registration.copyWith(id: 'new_id');
        expect(copy.id, 'new_id');
        expect(copy.eventId, registration.eventId);
      });

      test('copies with new status', () {
        final copy = registration.copyWith(status: RegistrationStatus.cancelled);
        expect(copy.status, RegistrationStatus.cancelled);
        expect(copy.id, registration.id);
      });

      test('copies with new eventTitle', () {
        final copy = registration.copyWith(eventTitle: 'New Title');
        expect(copy.eventTitle, 'New Title');
      });

      test('copies with new userName', () {
        final copy = registration.copyWith(userName: 'New User');
        expect(copy.userName, 'New User');
      });

      test('copies with new checkedInAt', () {
        final checkInTime = DateTime(2024, 1, 15, 14, 0);
        final copy = registration.copyWith(checkedInAt: checkInTime);
        expect(copy.checkedInAt, checkInTime);
      });

      test('copies with new cancelledAt', () {
        final cancelTime = DateTime(2024, 1, 16);
        final copy = registration.copyWith(cancelledAt: cancelTime);
        expect(copy.cancelledAt, cancelTime);
      });

      test('copies with new formResponses', () {
        final responses = {'q1': 'a1', 'q2': 'a2'};
        final copy = registration.copyWith(formResponses: responses);
        expect(copy.formResponses, responses);
      });

      test('preserves unchanged fields', () {
        final copy = registration.copyWith(status: RegistrationStatus.checkedIn);
        expect(copy.id, registration.id);
        expect(copy.eventId, registration.eventId);
        expect(copy.eventTitle, registration.eventTitle);
        expect(copy.userId, registration.userId);
        expect(copy.userName, registration.userName);
        expect(copy.registeredAt, registration.registeredAt);
      });
    });

    group('toFirestore', () {
      test('returns map with all required fields', () {
        final map = registration.toFirestore();
        expect(map['eventId'], registration.eventId);
        expect(map['eventTitle'], registration.eventTitle);
        expect(map['userId'], registration.userId);
        expect(map['userName'], registration.userName);
        expect(map['status'], 'registered');
      });

      test('converts registeredAt to Timestamp', () {
        final map = registration.toFirestore();
        expect(map['registeredAt'], isNotNull);
      });

      test('includes null for optional date fields when not set', () {
        final map = registration.toFirestore();
        expect(map['checkedInAt'], isNull);
        expect(map['cancelledAt'], isNull);
      });

      test('includes formResponses when set', () {
        final regWithForm = registration.copyWith(
          formResponses: {'q1': 'a1'},
        );
        final map = regWithForm.toFirestore();
        expect(map['formResponses'], isNotNull);
        expect(map['formResponses']['q1'], 'a1');
      });
    });
  });
}
