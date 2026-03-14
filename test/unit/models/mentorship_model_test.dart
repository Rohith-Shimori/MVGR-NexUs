import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/features/mentorship/models/mentorship_model.dart';

void main() {
  group('MentorType', () {
    test('has 3 values', () {
      expect(MentorType.values.length, 3);
    });

    test('displayName returns correct names', () {
      expect(MentorType.faculty.displayName, 'Faculty');
      expect(MentorType.senior.displayName, 'Senior Student');
      expect(MentorType.alumni.displayName, 'Alumni');
    });

    test('iconData returns IconData', () {
      expect(MentorType.faculty.iconData, Icons.school_rounded);
      expect(MentorType.senior.iconData, Icons.person_rounded);
      expect(MentorType.alumni.iconData, Icons.workspace_premium_rounded);
    });
  });

  group('MentorshipArea', () {
    test('has 6 values', () {
      expect(MentorshipArea.values.length, 6);
    });

    test('displayName returns correct names', () {
      expect(MentorshipArea.academic.displayName, 'Academic Guidance');
      expect(MentorshipArea.career.displayName, 'Career Advice');
      expect(MentorshipArea.research.displayName, 'Research');
      expect(MentorshipArea.skills.displayName, 'Skill Development');
      expect(MentorshipArea.placement.displayName, 'Placement Prep');
      expect(MentorshipArea.other.displayName, 'Other');
    });

    test('icon returns emoji', () {
      expect(MentorshipArea.academic.icon, '📚');
      expect(MentorshipArea.career.icon, '💼');
      expect(MentorshipArea.research.icon, '🔬');
    });

    test('iconData returns IconData', () {
      expect(MentorshipArea.academic.iconData, Icons.menu_book_rounded);
      expect(MentorshipArea.career.iconData, Icons.work_rounded);
      expect(MentorshipArea.research.iconData, Icons.science_rounded);
    });
  });

  group('Mentor', () {
    late Mentor mentor;

    setUp(() {
      mentor = Mentor(
        id: 'mentor_001',
        userId: 'user_001',
        name: 'Dr. John Doe',
        type: MentorType.faculty,
        areas: [MentorshipArea.research, MentorshipArea.academic],
        bio: 'AI researcher with 10 years experience',
        createdAt: DateTime.now(),
      );
    });

    group('constructor', () {
      test('creates mentor with required fields', () {
        expect(mentor.id, 'mentor_001');
        expect(mentor.userId, 'user_001');
        expect(mentor.name, 'Dr. John Doe');
        expect(mentor.type, MentorType.faculty);
        expect(mentor.areas.length, 2);
      });

      test('default maxMentees is 5', () {
        expect(mentor.maxMentees, 5);
      });

      test('default currentMentees is 0', () {
        expect(mentor.currentMentees, 0);
      });

      test('default isAvailable is true', () {
        expect(mentor.isAvailable, true);
      });

      test('default expertise is empty', () {
        expect(mentor.expertise, isEmpty);
      });
    });

    group('hasCapacity getter', () {
      test('returns true when under capacity', () {
        expect(mentor.hasCapacity, true);
      });

      test('returns false when at capacity', () {
        final fullMentor = Mentor(
          id: 'mentor_002',
          userId: 'user_002',
          name: 'Jane',
          type: MentorType.senior,
          areas: [MentorshipArea.career],
          bio: 'Bio',
          maxMentees: 3,
          currentMentees: 3,
          createdAt: DateTime.now(),
        );
        expect(fullMentor.hasCapacity, false);
      });
    });

    group('availableSlots getter', () {
      test('returns correct available slots', () {
        expect(mentor.availableSlots, 5);
      });

      test('returns 0 when full', () {
        final fullMentor = Mentor(
          id: 'mentor_002',
          userId: 'user_002',
          name: 'Jane',
          type: MentorType.senior,
          areas: [MentorshipArea.career],
          bio: 'Bio',
          maxMentees: 3,
          currentMentees: 3,
          createdAt: DateTime.now(),
        );
        expect(fullMentor.availableSlots, 0);
      });
    });

    group('toFirestore', () {
      test('returns correct map', () {
        final map = mentor.toFirestore();
        expect(map['userId'], 'user_001');
        expect(map['name'], 'Dr. John Doe');
        expect(map['type'], 'faculty');
        expect(map['bio'], 'AI researcher with 10 years experience');
        expect(map['maxMentees'], 5);
        expect(map['isAvailable'], true);
      });

      test('converts areas to names', () {
        final map = mentor.toFirestore();
        expect(map['areas'], ['research', 'academic']);
      });
    });

    group('testMentors', () {
      test('returns non-empty list', () {
        expect(Mentor.testMentors, isNotEmpty);
      });
    });
  });

  group('MentorshipRequest', () {
    late MentorshipRequest request;

    setUp(() {
      request = MentorshipRequest(
        id: 'req_001',
        mentorId: 'mentor_001',
        menteeId: 'user_002',
        menteeName: 'Student',
        area: MentorshipArea.career,
        message: 'I want to improve my coding skills',
        goal: 'Get placed at a top company',
        createdAt: DateTime.now(),
      );
    });

    group('constructor', () {
      test('creates request with required fields', () {
        expect(request.id, 'req_001');
        expect(request.mentorId, 'mentor_001');
        expect(request.menteeId, 'user_002');
        expect(request.area, MentorshipArea.career);
      });

      test('default status is pending', () {
        expect(request.status, 'pending');
      });

      test('acceptedAt is null by default', () {
        expect(request.acceptedAt, isNull);
      });
    });

    group('isPending getter', () {
      test('returns true for pending status', () {
        expect(request.isPending, true);
      });

      test('returns false for accepted status', () {
        final accepted = MentorshipRequest(
          id: 'req_002',
          mentorId: 'mentor_001',
          menteeId: 'user_003',
          menteeName: 'Student2',
          area: MentorshipArea.research,
          message: 'msg',
          goal: 'goal',
          status: 'accepted',
          createdAt: DateTime.now(),
        );
        expect(accepted.isPending, false);
      });
    });

    group('isAccepted getter', () {
      test('returns false for pending status', () {
        expect(request.isAccepted, false);
      });

      test('returns true for accepted status', () {
        final accepted = MentorshipRequest(
          id: 'req_002',
          mentorId: 'mentor_001',
          menteeId: 'user_003',
          menteeName: 'Student2',
          area: MentorshipArea.research,
          message: 'msg',
          goal: 'goal',
          status: 'accepted',
          createdAt: DateTime.now(),
        );
        expect(accepted.isAccepted, true);
      });
    });

    group('toFirestore', () {
      test('returns correct map', () {
        final map = request.toFirestore();
        expect(map['mentorId'], 'mentor_001');
        expect(map['menteeId'], 'user_002');
        expect(map['area'], 'career');
        expect(map['status'], 'pending');
      });
    });
  });

  group('MentorshipSession', () {
    test('creates with required fields', () {
      final session = MentorshipSession(
        id: 'session_001',
        mentorId: 'mentor_001',
        menteeId: 'user_002',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
      );

      expect(session.id, 'session_001');
      expect(session.mentorId, 'mentor_001');
      expect(session.completed, false);
    });

    test('toFirestore returns correct map', () {
      final session = MentorshipSession(
        id: 'session_001',
        mentorId: 'mentor_001',
        menteeId: 'user_002',
        scheduledAt: DateTime.now(),
        topic: 'Career advice',
        createdAt: DateTime.now(),
      );

      final map = session.toFirestore();
      expect(map['mentorId'], 'mentor_001');
      expect(map['menteeId'], 'user_002');
      expect(map['topic'], 'Career advice');
      expect(map['completed'], false);
    });
  });
}
