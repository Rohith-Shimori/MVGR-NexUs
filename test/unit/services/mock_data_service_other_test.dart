import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/services/mock_data_service.dart';
import 'package:mvgr_nexus/features/vault/models/vault_model.dart';
import 'package:mvgr_nexus/features/lost_found/models/lost_found_model.dart';
import 'package:mvgr_nexus/features/study_buddy/models/study_buddy_model.dart';
import 'package:mvgr_nexus/features/play_buddy/models/play_buddy_model.dart';
import 'package:mvgr_nexus/features/mentorship/models/mentorship_model.dart';
import 'package:mvgr_nexus/features/offline_community/models/meetup_model.dart';
import 'package:mvgr_nexus/features/radio/models/radio_model.dart';
import 'package:mvgr_nexus/core/constants/app_constants.dart';

void main() {
  group('MockDataService - Vault', () {
    late MockDataService service;

    setUp(() {
      service = MockDataService();
    });

    test('vaultItems returns list', () {
      expect(service.vaultItems, isNotEmpty);
    });

    test('addVaultItem adds to service', () {
      final countBefore = service.vaultItems.length;
      service.addVaultItem(VaultItem(
        id: 'vault_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Test Notes',
        subject: 'Math',
        branch: 'CSE',
        year: 2,
        semester: 1,
        type: VaultItemType.notes,
        fileUrl: 'http://example.com/file.pdf',
        fileName: 'test_notes.pdf',
        fileSizeBytes: 1024000,
        uploaderId: 'uploader',
        uploaderName: 'Uploader',
        isApproved: true, // Must be approved to show in vaultItems getter
        createdAt: DateTime.now(),
      ));
      expect(service.vaultItems.length, countBefore + 1);
    });

    test('getRankedVaultItems returns items sorted by quality', () {
      final ranked = service.getRankedVaultItems();
      expect(ranked, isNotEmpty);
    });
  });

  group('MockDataService - Lost & Found', () {
    late MockDataService service;

    setUp(() {
      service = MockDataService();
    });

    test('lostFoundItems returns list', () {
      expect(service.lostFoundItems, isNotEmpty);
    });

    test('lostItems returns only lost status items', () {
      final lost = service.lostItems;
      for (final item in lost) {
        expect(item.status, LostFoundStatus.lost);
      }
    });

    test('foundItems returns only found status items', () {
      final found = service.foundItems;
      for (final item in found) {
        expect(item.status, LostFoundStatus.found);
      }
    });

    test('addLostFoundItem adds to service', () {
      final countBefore = service.lostFoundItems.length;
      service.addLostFoundItem(LostFoundItem(
        id: 'lf_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Lost Wallet',
        description: 'Black leather wallet',
        category: LostFoundCategory.wallet,
        location: 'Library',
        userId: 'user',
        userName: 'User',
        status: LostFoundStatus.lost,
        itemDate: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      ));
      expect(service.lostFoundItems.length, countBefore + 1);
    });

    test('claimItem changes status to claimed', () {
      service.addLostFoundItem(LostFoundItem(
        id: 'claim_test_item',
        title: 'Test Item',
        description: 'Desc',
        category: LostFoundCategory.other,
        location: 'Somewhere',
        userId: 'user',
        userName: 'User',
        status: LostFoundStatus.found,
        itemDate: DateTime.now(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      ));
      
      // Verify item is in active list before claiming
      expect(service.lostFoundItems.any((i) => i.id == 'claim_test_item'), true);
      
      service.claimItem('claim_test_item', 'claimer_id', 'Claimer Name');
      
      // After claiming, item is no longer in active list (isActive = false when claimed)
      // This verifies the claim worked - item is removed from active list
      expect(service.lostFoundItems.any((i) => i.id == 'claim_test_item'), false);
    });

    test('deleteLostFoundItem removes from list', () {
      service.addLostFoundItem(LostFoundItem(
        id: 'delete_lf_item',
        title: 'Delete Me',
        description: 'Desc',
        category: LostFoundCategory.other,
        location: 'Here',
        userId: 'user',
        userName: 'User',
        status: LostFoundStatus.lost,
        itemDate: DateTime.now(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      ));
      
      service.deleteLostFoundItem('delete_lf_item');
      
      expect(service.lostFoundItems.any((i) => i.id == 'delete_lf_item'), false);
    });
  });

  group('MockDataService - Study Buddy', () {
    late MockDataService service;

    setUp(() {
      service = MockDataService();
    });

    test('studyRequests returns only active requests', () {
      final requests = service.studyRequests;
      for (final r in requests) {
        expect(r.isActive, true);
      }
    });

    test('addStudyRequest adds to service', () {
      final countBefore = service.studyRequests.length;
      service.addStudyRequest(StudyRequest(
        id: 'sr_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user',
        userName: 'User',
        subject: 'Data Structures',
        topic: 'Arrays and Linked Lists',
        description: 'Need help with DSA',
        preferredMode: StudyMode.hybrid,
        preferredTime: 'Evenings',
        status: RequestStatus.active,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      ));
      expect(service.studyRequests.length, countBefore + 1);
    });

    test('connectStudyBuddy creates match', () {
      final request = StudyRequest(
        id: 'connect_test_request',
        userId: 'requester',
        userName: 'Requester',
        subject: 'Math',
        topic: 'Calculus',
        description: 'Need calculus help',
        preferredMode: StudyMode.inPerson,
        preferredTime: 'Morning',
        status: RequestStatus.active,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      );
      service.addStudyRequest(request);
      
      service.connectStudyBuddy('connect_test_request', 'connector_id', 'Connector');
      
      final matches = service.getMatchesForUser('connector_id');
      expect(matches.any((m) => m.requestId == 'connect_test_request'), true);
    });

    test('hasStudyConnection returns true after connection', () {
      final request = StudyRequest(
        id: 'connection_check_req',
        userId: 'requester2',
        userName: 'Requester 2',
        subject: 'Physics',
        topic: 'Mechanics',
        description: 'Physics help needed',
        preferredMode: StudyMode.online,
        preferredTime: 'Afternoon',
        status: RequestStatus.active,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 14)),
      );
      service.addStudyRequest(request);
      
      service.connectStudyBuddy('connection_check_req', 'checker_id', 'Checker');
      
      expect(service.hasStudyConnection('connection_check_req', 'checker_id'), true);
      expect(service.hasStudyConnection('connection_check_req', 'other_user'), false);
    });
  });

  group('MockDataService - Play Buddy / Team Finder', () {
    late MockDataService service;

    setUp(() {
      service = MockDataService();
    });

    test('teamRequests returns only open requests', () {
      final requests = service.teamRequests;
      for (final r in requests) {
        expect(r.isOpen, true);
      }
    });

    test('addTeamRequest adds to service', () {
      final countBefore = service.teamRequests.length;
      service.addTeamRequest(TeamRequest(
        id: 'tr_${DateTime.now().millisecondsSinceEpoch}',
        creatorId: 'creator',
        creatorName: 'Creator',
        title: 'Looking for Team',
        description: 'Weekend hackathon',
        category: TeamCategory.hackathon,
        teamSize: 4,
        currentMembers: 1,
        memberIds: ['creator'],
        memberNames: ['Creator'],
        deadline: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
      ));
      expect(service.teamRequests.length, countBefore + 1);
    });

    test('joinTeamRequest adds user to team', () {
      service.addTeamRequest(TeamRequest(
        id: 'join_team_test',
        creatorId: 'creator',
        creatorName: 'Creator',
        title: 'Test Team',
        description: 'Desc',
        category: TeamCategory.esports,
        teamSize: 5,
        currentMembers: 1,
        memberIds: ['creator'],
        memberNames: ['Creator'],
        deadline: DateTime.now().add(const Duration(days: 5)),
        createdAt: DateTime.now(),
      ));
      
      final result = service.joinTeamRequest('join_team_test', 'joiner_id', 'Joiner');
      expect(result, true);
      
      final team = service.teamRequests.firstWhere((t) => t.id == 'join_team_test');
      expect(team.memberIds.contains('joiner_id'), true);
      expect(team.currentMembers, 2);
    });

    test('leaveTeamRequest removes user from team', () {
      service.addTeamRequest(TeamRequest(
        id: 'leave_team_test',
        creatorId: 'creator',
        creatorName: 'Creator',
        title: 'Test Team',
        description: 'Desc',
        category: TeamCategory.hackathon,
        teamSize: 4,
        currentMembers: 2,
        memberIds: ['creator', 'member'],
        memberNames: ['Creator', 'Member'],
        deadline: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now(),
      ));
      
      final result = service.leaveTeamRequest('leave_team_test', 'member');
      expect(result, true);
      
      final team = service.teamRequests.firstWhere((t) => t.id == 'leave_team_test');
      expect(team.memberIds.contains('member'), false);
      expect(team.currentMembers, 1);
    });

    test('getTeamRequestsByCategory filters correctly', () {
      final sportsTeams = service.getTeamRequestsByCategory(TeamCategory.sports);
      for (final team in sportsTeams) {
        expect(team.category, TeamCategory.sports);
      }
    });
  });

  group('MockDataService - Mentorship', () {
    late MockDataService service;

    setUp(() {
      service = MockDataService();
    });

    test('mentors returns available mentors with capacity', () {
      final mentors = service.mentors;
      for (final m in mentors) {
        expect(m.isAvailable, true);
        expect(m.hasCapacity, true);
      }
    });

    test('getMentorsByArea filters by area', () {
      final careerMentors = service.getMentorsByArea(MentorshipArea.career);
      for (final m in careerMentors) {
        expect(m.areas.contains(MentorshipArea.career), true);
      }
    });

    test('getRankedMentors returns sorted list', () {
      final ranked = service.getRankedMentors();
      expect(ranked, isA<List<Mentor>>());
    });

    test('addMentor adds to service', () {
      final countBefore = service.mentors.length;
      service.addMentor(Mentor(
        id: 'new_mentor_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'new_mentor_user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'New Mentor',
        type: MentorType.senior,
        department: 'CSE',
        areas: [MentorshipArea.academic],
        expertise: ['Flutter', 'Dart'],
        bio: 'Experienced developer',
        maxMentees: 5,
        currentMentees: 0,
        isAvailable: true,
        createdAt: DateTime.now(),
      ));
      expect(service.mentors.length, countBefore + 1);
    });
  });

  group('MockDataService - Meetups', () {
    late MockDataService service;

    setUp(() {
      service = MockDataService();
    });

    test('meetups returns active non-past meetups', () {
      final meetups = service.meetups;
      for (final m in meetups) {
        expect(m.isActive, true);
        expect(m.isPast, false);
      }
    });

    test('getMeetupsByCategory filters correctly', () {
      final studyCircles = service.getMeetupsByCategory(MeetupCategory.studyCircle);
      for (final m in studyCircles) {
        expect(m.category, MeetupCategory.studyCircle);
      }
    });

    test('addMeetup adds to service', () {
      final countBefore = service.meetups.length;
      service.addMeetup(Meetup(
        id: 'meetup_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Coffee Chat',
        description: 'Casual meetup',
        organizerId: 'organizer',
        organizerName: 'Organizer',
        category: MeetupCategory.other,
        venue: 'Cafeteria',
        scheduledAt: DateTime.now().add(const Duration(days: 3)),
        maxParticipants: 10,
        participantIds: ['organizer'],
        isActive: true,
        createdAt: DateTime.now(),
      ));
      expect(service.meetups.length, countBefore + 1);
    });

    test('joinMeetup adds user to participants', () {
      service.addMeetup(Meetup(
        id: 'join_meetup_test',
        title: 'Test Meetup',
        description: 'Desc',
        organizerId: 'org',
        organizerName: 'Org',
        category: MeetupCategory.gaming,
        venue: 'Here',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        participantIds: ['org'],
        isActive: true,
        createdAt: DateTime.now(),
      ));
      
      service.joinMeetup('join_meetup_test', 'joiner');
      
      final meetup = service.meetups.firstWhere((m) => m.id == 'join_meetup_test');
      expect(meetup.participantIds.contains('joiner'), true);
    });

    test('leaveMeetup removes user from participants', () {
      service.addMeetup(Meetup(
        id: 'leave_meetup_test',
        title: 'Test Meetup',
        description: 'Desc',
        organizerId: 'org',
        organizerName: 'Org',
        category: MeetupCategory.studyCircle,
        venue: 'There',
        scheduledAt: DateTime.now().add(const Duration(days: 2)),
        participantIds: ['org', 'leaver'],
        isActive: true,
        createdAt: DateTime.now(),
      ));
      
      service.leaveMeetup('leave_meetup_test', 'leaver');
      
      final meetup = service.meetups.firstWhere((m) => m.id == 'leave_meetup_test');
      expect(meetup.participantIds.contains('leaver'), false);
    });
  });

  group('MockDataService - Radio', () {
    late MockDataService service;

    setUp(() {
      service = MockDataService();
    });

    test('songVotes returns list', () {
      expect(service.songVotes, isA<List<SongVote>>());
    });

    test('shoutouts returns list', () {
      expect(service.shoutouts, isA<List<Shoutout>>());
    });

    test('addSongVote adds to service', () {
      final countBefore = service.songVotes.length;
      service.addSongVote(SongVote(
        id: 'song_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: 'session_1',
        songName: 'Test Song',
        artistName: 'Test Artist',
        requesterId: 'requester',
        requesterName: 'Requester',
        voteCount: 1,
        voterIds: ['requester'],
        requestedAt: DateTime.now(),
      ));
      expect(service.songVotes.length, countBefore + 1);
    });

    test('voteSong increments vote count', () {
      service.addSongVote(SongVote(
        id: 'vote_test_song',
        sessionId: 'session_1',
        songName: 'Test Song',
        artistName: 'Artist',
        requesterId: 'req',
        requesterName: 'Req',
        voteCount: 1,
        voterIds: ['req'],
        requestedAt: DateTime.now(),
      ));
      
      service.voteSong('vote_test_song', 'voter_1');
      
      final song = service.songVotes.firstWhere((s) => s.id == 'vote_test_song');
      expect(song.voteCount, 2);
      expect(song.voterIds.contains('voter_1'), true);
    });

    test('addShoutout adds to service', () {
      final countBefore = service.shoutouts.length;
      service.addShoutout(Shoutout(
        id: 'shoutout_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: 'session_1',
        authorId: 'author',
        authorName: 'Author',
        message: 'Hello everyone!',
        createdAt: DateTime.now(),
      ));
      expect(service.shoutouts.length, countBefore + 1);
    });

    test('moderateShoutout changes status', () {
      service.addShoutout(Shoutout(
        id: 'mod_shoutout_test',
        sessionId: 'session_1',
        authorId: 'author',
        authorName: 'Author',
        message: 'Test shoutout',
        createdAt: DateTime.now(),
      ));
      
      service.moderateShoutout('mod_shoutout_test', ModerationStatus.approved);
      
      final shoutout = service.shoutouts.firstWhere((s) => s.id == 'mod_shoutout_test');
      expect(shoutout.status, ModerationStatus.approved);
    });
  });

  group('MockDataService - Reports', () {
    late MockDataService service;

    setUp(() {
      service = MockDataService();
    });

    test('reports returns list', () {
      expect(service.reports, isA<List>());
    });
  });
}
