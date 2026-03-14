
import 'package:mvgr_nexus/domain/entities/user.dart';
import 'package:mvgr_nexus/features/clubs/models/club_model.dart';
import 'package:mvgr_nexus/features/events/models/event_model.dart';

/// Test fixtures for development and testing
class ModelFixtures {
  // Test Users
  static User get testStudent => User(
    id: 'test_student_001',
    email: 'student@mvgrce.edu.in',
    name: 'Test Student',
    department: 'CSE',
    year: 3,
    role: UserRole.student,
    createdAt: DateTime(2024, 1, 1),
  );

  static User get testClubAdmin => User(
    id: 'test_admin_001',
    email: 'acm@mvgrce.edu.in',
    name: 'ACM Admin',
    department: 'CSE',
    year: 3,
    role: UserRole.clubAdmin,
    createdAt: DateTime(2024, 1, 1),
  );
  
  static User get testCouncil => User(
    id: 'council_001',
    email: 'council@mvgrce.edu.in',
    name: 'Student Council',
    department: 'CSE',
    year: 4,
    role: UserRole.council,
    createdAt: DateTime(2024, 1, 1),
  );

  static User get testFaculty => User(
    id: 'faculty_001',
    email: 'faculty@mvgrce.edu.in',
    name: 'Dr. Faculty Member',
    department: 'CSE',
    year: 0,
    role: UserRole.faculty,
    createdAt: DateTime(2024, 1, 1),
  );

  // Test Clubs
  static List<Club> get testClubs => [
    Club(
      id: 'club_001',
      name: 'Coding Club',
      description: 'A community of passionate programmers exploring cutting-edge technologies and building amazing projects together.',
      category: ClubCategory.technical,
      memberCount: 3,
      adminCount: 2,
      isApproved: true,
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
      createdBy: 'test_student_001',
    ),
    Club(
      id: 'club_002',
      name: 'Music Society',
      description: 'Where melodies come alive! Join us for jamming sessions, performances, and music workshops.',
      category: ClubCategory.cultural,
      memberCount: 2,
      adminCount: 2,
      isApproved: true,
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
      createdBy: 'user_005',
    ),
    Club(
      id: 'club_003',
      name: 'Robotics Team',
      description: 'Building the future, one robot at a time. Competitions, workshops, and hands-on projects.',
      category: ClubCategory.technical,
      memberCount: 2,
      adminCount: 2,
      isApproved: true,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      createdBy: 'user_008',
    ),
  ];

  // Test Events
  static List<Event> get testEvents => [
    Event(
      id: 'event_001',
      title: 'Annual Hackathon 2025',
      description: 'Join us for a 24-hour coding marathon! Build innovative solutions, win exciting prizes, and network with industry experts.',
      clubId: 'club_001',
      clubName: 'Coding Club',
      authorId: 'test_student_001',
      authorName: 'Test Student',
      eventDate: DateTime.now().add(const Duration(days: 7)),
      venue: 'Main Auditorium',
      venueDetails: 'Block A, Ground Floor',
      maxParticipants: 200,
      rsvpIds: ['user_002', 'user_003'],
      interestedIds: ['user_004', 'user_005', 'user_006'],
      category: EventCategory.hackathon,
      requiresRegistration: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Event(
      id: 'event_002',
      title: 'Cultural Night',
      description: 'An evening of music, dance, and drama. Celebrate the diversity of our college!',
      authorId: 'user_007',
      authorName: 'Cultural Committee',
      eventDate: DateTime.now().add(const Duration(days: 14)),
      venue: 'Open Air Theatre',
      category: EventCategory.cultural,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Event(
      id: 'event_003',
      title: 'Machine Learning Workshop',
      description: 'Hands-on workshop on ML basics. Bring your laptops!',
      clubId: 'club_001',
      clubName: 'Coding Club',
      authorId: 'test_student_001',
      authorName: 'Test Student',
      eventDate: DateTime.now().add(const Duration(days: 2)),
      venue: 'Computer Lab 3',
      maxParticipants: 50,
      category: EventCategory.workshop,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // Test Announcements
  static List<Announcement> get testAnnouncements => [
    Announcement(
      id: 'ann_001',
      title: 'Mid-Semester Exam Schedule Released',
      content: 'The mid-semester examination schedule has been released. Please check the academic portal for detailed timetable.',
      authorId: 'faculty_001',
      authorName: 'Academic Office',
      authorRole: 'Faculty',
      isPinned: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Announcement(
      id: 'ann_002',
      title: 'Library Timings Extended',
      content: 'The central library will remain open until 10 PM during exam week for student convenience.',
      authorId: 'council_001',
      authorName: 'Student Council',
      authorRole: 'Student Council',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
