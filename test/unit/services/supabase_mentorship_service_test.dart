import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/supabase_mentorship_service.dart';

void main() {
  group('Mentor Model', () {
    test('creates mentor with required fields', () {
      final mentor = Mentor(
        id: '1',
        userId: 'user_1',
        name: 'Dr. Smith',
        mentorType: 'faculty',
        createdAt: DateTime.now(),
      );

      expect(mentor.id, '1');
      expect(mentor.name, 'Dr. Smith');
      expect(mentor.mentorType, 'faculty');
    });

    test('creates faculty mentor', () {
      final mentor = Mentor(
        id: '1',
        userId: 'faculty_1',
        name: 'Prof. Johnson',
        bio: 'Professor of Computer Science with 15 years experience',
        mentorType: 'faculty',
        expertise: ['Machine Learning', 'Data Science', 'Python'],
        position: 'Associate Professor',
        createdAt: DateTime.now(),
      );

      expect(mentor.mentorType, 'faculty');
      expect(mentor.expertise, contains('Machine Learning'));
      expect(mentor.position, 'Associate Professor');
    });

    test('creates alumni mentor', () {
      final mentor = Mentor(
        id: '1',
        userId: 'alumni_1',
        name: 'John Doe',
        bio: 'Software Engineer at Google',
        mentorType: 'alumni',
        expertise: ['Web Development', 'Interview Prep', 'Career Guidance'],
        company: 'Google',
        position: 'Senior Engineer',
        linkedinUrl: 'https://linkedin.com/in/johndoe',
        createdAt: DateTime.now(),
      );

      expect(mentor.mentorType, 'alumni');
      expect(mentor.company, 'Google');
      expect(mentor.linkedinUrl, isNotEmpty);
    });

    test('creates senior student mentor', () {
      final mentor = Mentor(
        id: '1',
        userId: 'student_1',
        name: 'Jane Senior',
        bio: 'Final year CSE student, GATE AIR 50',
        mentorType: 'senior',
        expertise: ['GATE Prep', 'DSA', 'Competitive Programming'],
        availability: 'Weekends 10AM-12PM',
        createdAt: DateTime.now(),
      );

      expect(mentor.mentorType, 'senior');
      expect(mentor.availability, isNotEmpty);
    });

    test('mentor with session duration', () {
      final mentor = Mentor(
        id: '1',
        userId: 'user_1',
        name: 'Mentor',
        mentorType: 'faculty',
        sessionDurationMinutes: 45,
        createdAt: DateTime.now(),
      );

      expect(mentor.sessionDurationMinutes, 45);
    });

    test('mentor with profile image', () {
      final mentor = Mentor(
        id: '1',
        userId: 'user_1',
        name: 'Mentor',
        mentorType: 'alumni',
        profileImageUrl: 'https://example.com/photo.jpg',
        createdAt: DateTime.now(),
      );

      expect(mentor.profileImageUrl, isNotEmpty);
    });

    test('default session duration is 30 minutes', () {
      final mentor = Mentor(
        id: '1',
        userId: 'user_1',
        name: 'Mentor',
        mentorType: 'faculty',
        createdAt: DateTime.now(),
      );

      expect(mentor.sessionDurationMinutes, 30);
    });
  });

  group('Mentor Filtering', () {
    late List<Mentor> testMentors;

    setUp(() {
      testMentors = [
        Mentor(
          id: '1',
          userId: 'user_1',
          name: 'Faculty Mentor',
          mentorType: 'faculty',
          expertise: ['ML', 'AI'],
          createdAt: DateTime.now(),
        ),
        Mentor(
          id: '2',
          userId: 'user_2',
          name: 'Alumni Mentor',
          mentorType: 'alumni',
          company: 'Microsoft',
          expertise: ['SDE', 'DSA'],
          createdAt: DateTime.now(),
        ),
        Mentor(
          id: '3',
          userId: 'user_3',
          name: 'Senior Student',
          mentorType: 'senior',
          expertise: ['GATE', 'Placements'],
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('filter by mentor type', () {
      final faculty = testMentors.where((m) => m.mentorType == 'faculty').toList();
      expect(faculty.length, 1);
      expect(faculty.first.name, 'Faculty Mentor');
    });

    test('filter by expertise', () {
      final mlMentors = testMentors
          .where((m) => m.expertise.contains('ML'))
          .toList();
      expect(mlMentors.length, 1);
    });

    test('filter alumni with company', () {
      final withCompany = testMentors
          .where((m) => m.mentorType == 'alumni' && m.company != null)
          .toList();
      expect(withCompany.length, 1);
      expect(withCompany.first.company, 'Microsoft');
    });
  });

  group('MentorshipSession Model', () {
    test('creates session with required fields', () {
      final scheduledAt = DateTime.now().add(const Duration(days: 2));
      final session = MentorshipSession(
        id: '1',
        mentorId: 'mentor_1',
        menteeId: 'mentee_1',
        menteeName: 'Student',
        topic: 'Career Guidance',
        scheduledAt: scheduledAt,
        durationMinutes: 30,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      expect(session.id, '1');
      expect(session.topic, 'Career Guidance');
      expect(session.status, 'pending');
      expect(session.durationMinutes, 30);
    });

    test('session with description', () {
      final session = MentorshipSession(
        id: '1',
        mentorId: 'mentor_1',
        menteeId: 'mentee_1',
        menteeName: 'Mentee',
        topic: 'Mock Interview',
        description: 'Prepare for technical interviews at FAANG companies',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        durationMinutes: 45,
        status: 'confirmed',
        createdAt: DateTime.now(),
      );

      expect(session.description, isNotEmpty);
    });

    test('confirmed session with meeting link', () {
      final session = MentorshipSession(
        id: '1',
        mentorId: 'mentor_1',
        menteeId: 'mentee_1',
        menteeName: 'Mentee',
        topic: 'Resume Review',
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        durationMinutes: 30,
        status: 'confirmed',
        meetingLink: 'https://meet.google.com/abc-defg-hij',
        createdAt: DateTime.now(),
      );

      expect(session.status, 'confirmed');
      expect(session.meetingLink, isNotEmpty);
    });

    test('completed session with feedback', () {
      final session = MentorshipSession(
        id: '1',
        mentorId: 'mentor_1',
        menteeId: 'mentee_1',
        menteeName: 'Mentee',
        topic: 'Project Discussion',
        scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
        durationMinutes: 30,
        status: 'completed',
        notes: 'Discussed final year project ideas',
        rating: 5,
        feedback: 'Very helpful session!',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      expect(session.status, 'completed');
      expect(session.rating, 5);
      expect(session.feedback, isNotEmpty);
      expect(session.notes, isNotEmpty);
    });

    test('cancelled session', () {
      final session = MentorshipSession(
        id: '1',
        mentorId: 'mentor_1',
        menteeId: 'mentee_1',
        menteeName: 'Mentee',
        topic: 'Cancelled Session',
        scheduledAt: DateTime.now().add(const Duration(days: 5)),
        durationMinutes: 30,
        status: 'cancelled',
        createdAt: DateTime.now(),
      );

      expect(session.status, 'cancelled');
    });
  });

  group('MentorshipSession Filtering', () {
    late List<MentorshipSession> testSessions;

    setUp(() {
      final now = DateTime.now();
      testSessions = [
        MentorshipSession(
          id: '1',
          mentorId: 'mentor_1',
          menteeId: 'mentee_1',
          menteeName: 'Mentee1',
          topic: 'Topic 1',
          scheduledAt: now.add(const Duration(days: 1)),
          durationMinutes: 30,
          status: 'pending',
          createdAt: now,
        ),
        MentorshipSession(
          id: '2',
          mentorId: 'mentor_1',
          menteeId: 'mentee_2',
          menteeName: 'Mentee2',
          topic: 'Topic 2',
          scheduledAt: now.add(const Duration(days: 2)),
          durationMinutes: 30,
          status: 'confirmed',
          createdAt: now,
        ),
        MentorshipSession(
          id: '3',
          mentorId: 'mentor_2',
          menteeId: 'mentee_1',
          menteeName: 'Mentee1',
          topic: 'Topic 3',
          scheduledAt: now.subtract(const Duration(days: 3)),
          durationMinutes: 45,
          status: 'completed',
          rating: 5,
          createdAt: now.subtract(const Duration(days: 5)),
        ),
      ];
    });

    test('filter by status', () {
      final pending = testSessions.where((s) => s.status == 'pending').toList();
      expect(pending.length, 1);
    });

    test('filter by mentor', () {
      final mentor1Sessions = testSessions
          .where((s) => s.mentorId == 'mentor_1')
          .toList();
      expect(mentor1Sessions.length, 2);
    });

    test('filter by mentee', () {
      final mentee1Sessions = testSessions
          .where((s) => s.menteeId == 'mentee_1')
          .toList();
      expect(mentee1Sessions.length, 2);
    });

    test('filter upcoming sessions', () {
      final now = DateTime.now();
      final upcoming = testSessions
          .where((s) => s.scheduledAt.isAfter(now) && s.status != 'cancelled')
          .toList();
      expect(upcoming.length, 2);
    });

    test('filter completed with rating', () {
      final rated = testSessions
          .where((s) => s.status == 'completed' && s.rating != null)
          .toList();
      expect(rated.length, 1);
      expect(rated.first.rating, 5);
    });
  });

  group('Session Status Flow', () {
    test('session statuses are valid', () {
      final validStatuses = ['pending', 'confirmed', 'completed', 'cancelled'];
      
      for (final status in validStatuses) {
        final session = MentorshipSession(
          id: '1',
          mentorId: 'm1',
          menteeId: 'me1',
          menteeName: 'Me',
          topic: 'T',
          scheduledAt: DateTime.now(),
          durationMinutes: 30,
          status: status,
          createdAt: DateTime.now(),
        );
        expect(session.status, status);
      }
    });
  });

  group('Mentor Type Validation', () {
    test('all mentor types are valid', () {
      final validTypes = ['faculty', 'alumni', 'senior'];
      
      for (final type in validTypes) {
        final mentor = Mentor(
          id: '1',
          userId: 'u1',
          name: 'Name',
          mentorType: type,
          createdAt: DateTime.now(),
        );
        expect(mentor.mentorType, type);
      }
    });
  });
}
