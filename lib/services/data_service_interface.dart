/// Abstract Data Service Interface
/// Defines the contract for all data operations
/// Allows swapping between MockDataService and SupabaseDataService
library;

import '../core/errors/result.dart';
import '../features/clubs/models/club_model.dart';
import '../features/events/models/event_model.dart';
import '../features/academic_forum/models/forum_model.dart';
import '../features/vault/models/vault_model.dart';
import '../features/lost_found/models/lost_found_model.dart';
import '../features/study_buddy/models/study_buddy_model.dart';
import '../features/play_buddy/models/play_buddy_model.dart';
import '../features/mentorship/models/mentorship_model.dart';
import '../features/offline_community/models/meetup_model.dart';
import '../features/radio/models/radio_model.dart';
import '../models/join_request_model.dart';
import '../models/event_registration_model.dart';
import '../features/council/models/report_model.dart';

/// Interface for all data operations
/// Both MockDataService and SupabaseDataService implement this
abstract class DataServiceInterface {

  // ============ CLUBS ============
  
  List<Club> get clubs;
  Future<Result<Club?>> getClubById(String id);
  Future<Result<Club>> addClub(Club club);
  Future<Result<Club>> updateClub(Club club);
  Future<Result<void>> deleteClub(String clubId);
  
  List<ClubPost> get clubPosts;
  List<ClubPost> getClubPosts(String clubId);
  Future<Result<ClubPost>> addClubPost(ClubPost post);
  Future<Result<void>> deleteClubPost(String postId);
  
  List<ClubJoinRequest> get joinRequests;
  List<ClubJoinRequest> getPendingRequestsForClub(String clubId);
  List<ClubJoinRequest> getMyJoinRequests(String userId);
  bool hasPendingRequest(String clubId, String userId);
  Future<Result<ClubJoinRequest>> requestToJoinClub({
    required String clubId,
    required String clubName,
    required String userId,
    required String userName,
    String? note,
  });
  Future<Result<void>> approveJoinRequest(String requestId, String approvedBy);
  Future<Result<void>> rejectJoinRequest(String requestId, String rejectedBy, {String? reason});
  Future<Result<void>> cancelJoinRequest(String requestId);
  
  List<Club> getMyClubs(String userId);
  List<Club> getAdminClubs(String userId);
  Future<Result<void>> leaveClub(String clubId, String userId);
  Future<Result<void>> joinClubDirectly(String clubId, String userId);

  // ============ EVENTS ============
  
  List<Event> get events;
  Future<Result<Event?>> getEventById(String id);
  Future<Result<Event>> addEvent(Event event);
  Future<Result<Event>> updateEvent(Event event);
  Future<Result<void>> deleteEvent(String eventId);
  Future<Result<void>> rsvpEvent(String eventId, String userId);
  Future<Result<void>> removeRsvp(String eventId, String userId);
  List<Event> getMyEvents(String userId);
  List<Event> getMyPastEvents(String userId);
  
  List<EventRegistration> get eventRegistrations;
  List<EventRegistration> getEventAttendees(String eventId);
  EventRegistration? getEventRegistration(String eventId, String userId);
  Future<Result<EventRegistration>> rsvpWithDetails({
    required String eventId,
    required String eventTitle,
    required String userId,
    required String userName,
    Map<String, dynamic>? formResponses,
  });
  Future<Result<void>> checkInAttendee(String eventId, String userId);

  // ============ ANNOUNCEMENTS ============
  
  List<Announcement> get announcements;
  Future<Result<Announcement>> addAnnouncement(Announcement announcement);
  Future<Result<Announcement>> updateAnnouncement(Announcement announcement);
  Future<Result<void>> deleteAnnouncement(String id);

  // ============ FORUM ============
  
  List<AcademicQuestion> get questions;
  Future<Result<AcademicQuestion>> addQuestion(AcademicQuestion question);
  Future<Result<AcademicQuestion>> updateQuestion(AcademicQuestion question);
  Future<Result<void>> deleteQuestion(String questionId);
  Future<Result<void>> upvoteQuestion(String questionId, String userId);
  Future<Result<void>> incrementViewCount(String questionId);
  
  List<Answer> get answers;
  List<Answer> getAnswersForQuestion(String questionId);
  Future<Result<Answer>> addAnswer(Answer answer);
  Future<Result<void>> markAnswerAsAccepted(String questionId, String answerId);
  Future<Result<void>> markAnswerAsHelpful(String answerId, String userId);

  // ============ VAULT ============
  
  List<VaultItem> get vaultItems;
  Future<Result<VaultItem>> addVaultItem(VaultItem item);
  Future<Result<void>> upvoteVaultItem(String itemId, String userId);
  Future<Result<void>> downvoteVaultItem(String itemId, String userId);
  Future<Result<void>> incrementDownloadCount(String itemId);

  // ============ LOST & FOUND ============
  
  List<LostFoundItem> get lostFoundItems;
  Future<Result<LostFoundItem>> addLostFoundItem(LostFoundItem item);
  Future<Result<LostFoundItem>> updateLostFoundItem(LostFoundItem item);
  Future<Result<void>> deleteLostFoundItem(String itemId);
  Future<Result<void>> claimLostFoundItem(String itemId, String claimerId);

  // ============ STUDY BUDDY ============
  
  List<StudyRequest> get studyRequests;
  Future<Result<StudyRequest>> addStudyRequest(StudyRequest request);
  Future<Result<void>> deleteStudyRequest(String requestId);
  
  List<StudyMatch> get studyMatches;
  Future<Result<StudyMatch>> connectStudyBuddy(String requestId, String userId, String userName);
  bool hasStudyConnection(String requestId, String userId);

  // ============ PLAY BUDDY / TEAMS ============
  
  List<TeamRequest> get teamRequests;
  Future<Result<TeamRequest>> addTeamRequest(TeamRequest request);
  Future<Result<TeamRequest>> updateTeamRequest(TeamRequest request);
  Future<Result<void>> deleteTeamRequest(String requestId);
  Future<Result<void>> joinTeam(String teamId, String userId);
  Future<Result<void>> leaveTeam(String teamId, String userId);

  // ============ MENTORSHIP ============
  
  List<Mentor> get mentors;
  Future<Result<Mentor>> addMentor(Mentor mentor);
  
  List<MentorshipRequest> get mentorshipRequests;
  Future<Result<MentorshipRequest>> addMentorshipRequest(MentorshipRequest request);
  Future<Result<void>> approveMentorshipRequest(String requestId);
  Future<Result<void>> rejectMentorshipRequest(String requestId);

  // ============ MEETUPS ============
  
  List<Meetup> get meetups;
  Future<Result<Meetup>> addMeetup(Meetup meetup);
  Future<Result<void>> joinMeetup(String meetupId, String userId);
  Future<Result<void>> leaveMeetup(String meetupId, String userId);

  // ============ RADIO ============
  
  RadioSession? get activeRadioSession;
  List<SongVote> get songVotes;
  List<Shoutout> get shoutouts;
  Future<Result<SongVote>> voteSong(SongVote vote);
  Future<Result<Shoutout>> sendShoutout(Shoutout shoutout);

  // ============ REPORTS ============
  
  List<Report> get reports;
  Future<Result<Report>> addReport(Report report);
  Future<Result<void>> resolveReport(String reportId, String resolvedBy);
  Future<Result<void>> dismissReport(String reportId, String dismissedBy);
}
