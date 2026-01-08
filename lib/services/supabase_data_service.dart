import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/errors/app_exception.dart';
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
import 'data_service_interface.dart';

/// Supabase implementation of DataServiceInterface
/// Connects to real Supabase database
class SupabaseDataService extends ChangeNotifier implements DataServiceInterface {
  final SupabaseClient _client;
  
  // Local caches (refreshed from server)
  final List<Club> _clubs = [];
  final List<ClubPost> _clubPosts = [];
  final List<ClubJoinRequest> _joinRequests = [];
  final List<Event> _events = [];
  final List<EventRegistration> _eventRegistrations = [];
  final List<Announcement> _announcements = [];
  final List<AcademicQuestion> _questions = [];
  final List<Answer> _answers = [];
  final List<VaultItem> _vaultItems = [];
  final List<LostFoundItem> _lostFoundItems = [];
  final List<StudyRequest> _studyRequests = [];
  final List<StudyMatch> _studyMatches = [];
  final List<TeamRequest> _teamRequests = [];
  final List<Mentor> _mentors = [];
  final List<MentorshipRequest> _mentorshipRequests = [];
  final List<Meetup> _meetups = [];
  final List<SongVote> _songVotes = [];
  final List<Shoutout> _shoutouts = [];
  final List<Report> _reports = [];
  
  SupabaseDataService() : _client = Supabase.instance.client {
    _initializeData();
  }
  
  /// Initialize and fetch initial data
  Future<void> _initializeData() async {
    await Future.wait([
      _fetchClubs(),
      _fetchEvents(),
      _fetchAnnouncements(),
    ]);
  }
  
  // ============ GETTERS ============
  
  @override
  List<Club> get clubs => List.unmodifiable(_clubs.where((c) => c.isApproved));
  
  @override
  List<ClubPost> get clubPosts => List.unmodifiable(_clubPosts);
  
  @override
  List<ClubJoinRequest> get joinRequests => List.unmodifiable(_joinRequests);
  
  @override
  List<Event> get events => List.unmodifiable(_events);
  
  @override
  List<EventRegistration> get eventRegistrations => List.unmodifiable(_eventRegistrations);
  
  @override
  List<Announcement> get announcements => List.unmodifiable(_announcements);
  
  @override
  List<AcademicQuestion> get questions => List.unmodifiable(_questions);
  
  @override
  List<Answer> get answers => List.unmodifiable(_answers);
  
  @override
  List<VaultItem> get vaultItems => List.unmodifiable(_vaultItems.where((v) => v.isApproved));
  
  @override
  List<LostFoundItem> get lostFoundItems => List.unmodifiable(_lostFoundItems.where((i) => i.isActive));
  
  @override
  List<StudyRequest> get studyRequests => List.unmodifiable(_studyRequests.where((r) => r.isActive));
  
  @override
  List<StudyMatch> get studyMatches => List.unmodifiable(_studyMatches);
  
  @override
  List<TeamRequest> get teamRequests => List.unmodifiable(_teamRequests.where((t) => t.isOpen));
  
  @override
  List<Mentor> get mentors => List.unmodifiable(_mentors.where((m) => m.isAvailable && m.hasCapacity));
  
  @override
  List<MentorshipRequest> get mentorshipRequests => List.unmodifiable(_mentorshipRequests);
  
  @override
  List<Meetup> get meetups => List.unmodifiable(_meetups.where((m) => m.isActive && !m.isPast));
  
  @override
  RadioSession? get activeRadioSession => null; // TODO: Implement radio sessions
  
  @override
  List<SongVote> get songVotes => List.unmodifiable(_songVotes);
  
  @override
  List<Shoutout> get shoutouts => List.unmodifiable(_shoutouts);
  
  @override
  List<Report> get reports => List.unmodifiable(_reports);
  
  // Helper to create database exception
  DataException _dbError(String message, dynamic e) =>
      DataException(message: '$message: $e');
  
  // ============ FETCH METHODS ============
  
  Future<void> _fetchClubs() async {
    try {
      final response = await _client.from('clubs').select().order('created_at', ascending: false);
      _clubs
        ..clear()
        ..addAll((response as List).map((json) => _clubFromJson(json)));
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching clubs: $e');
    }
  }
  
  Future<void> _fetchEvents() async {
    try {
      final response = await _client
          .from('events')
          .select()
          .gte('event_date', DateTime.now().toIso8601String())
          .order('event_date', ascending: true);
      _events
        ..clear()
        ..addAll((response as List).map((json) => _eventFromJson(json)));
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching events: $e');
    }
  }
  
  Future<void> _fetchAnnouncements() async {
    try {
      final response = await _client
          .from('announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(20);
      _announcements
        ..clear()
        ..addAll((response as List).map((json) => _announcementFromJson(json)));
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
    }
  }
  
  // ============ CLUBS CRUD ============
  
  @override
  Future<Result<Club?>> getClubById(String id) async {
    try {
      final response = await _client.from('clubs').select().eq('id', id).maybeSingle();
      if (response == null) return Result.success(null);
      return Result.success(_clubFromJson(response));
    } catch (e) {
      return Result.failure(_dbError('Failed to get club', e));
    }
  }
  
  @override
  Future<Result<Club>> addClub(Club club) async {
    try {
      final response = await _client.from('clubs').insert(_clubToJson(club)).select().single();
      final newClub = _clubFromJson(response);
      _clubs.insert(0, newClub);
      notifyListeners();
      return Result.success(newClub);
    } catch (e) {
      return Result.failure(_dbError('Failed to add club', e));
    }
  }
  
  @override
  Future<Result<Club>> updateClub(Club club) async {
    try {
      final response = await _client.from('clubs').update(_clubToJson(club)).eq('id', club.id).select().single();
      final updatedClub = _clubFromJson(response);
      final index = _clubs.indexWhere((c) => c.id == club.id);
      if (index != -1) {
        _clubs[index] = updatedClub;
        notifyListeners();
      }
      return Result.success(updatedClub);
    } catch (e) {
      return Result.failure(_dbError('Failed to update club', e));
    }
  }
  
  @override
  Future<Result<void>> deleteClub(String clubId) async {
    try {
      await _client.from('clubs').delete().eq('id', clubId);
      _clubs.removeWhere((c) => c.id == clubId);
      notifyListeners();
      return Result.success(null);
    } catch (e) {
      return Result.failure(_dbError('Failed to delete club', e));
    }
  }
  
  @override
  List<ClubPost> getClubPosts(String clubId) => _clubPosts.where((p) => p.clubId == clubId).toList();
  
  @override
  Future<Result<ClubPost>> addClubPost(ClubPost post) async {
    try {
      final response = await _client.from('club_posts').insert(_clubPostToJson(post)).select().single();
      final newPost = _clubPostFromJson(response);
      _clubPosts.insert(0, newPost);
      notifyListeners();
      return Result.success(newPost);
    } catch (e) {
      return Result.failure(_dbError('Failed to add post', e));
    }
  }
  
  @override
  Future<Result<void>> deleteClubPost(String postId) async {
    try {
      await _client.from('club_posts').delete().eq('id', postId);
      _clubPosts.removeWhere((p) => p.id == postId);
      notifyListeners();
      return Result.success(null);
    } catch (e) {
      return Result.failure(_dbError('Failed to delete post', e));
    }
  }
  
  // ============ CLUB MEMBERSHIP ============
  
  @override
  List<ClubJoinRequest> getPendingRequestsForClub(String clubId) =>
      _joinRequests.where((r) => r.clubId == clubId && r.status == ClubJoinStatus.pending).toList();
  
  @override
  List<ClubJoinRequest> getMyJoinRequests(String userId) =>
      _joinRequests.where((r) => r.userId == userId).toList();
  
  @override
  bool hasPendingRequest(String clubId, String userId) =>
      _joinRequests.any((r) => r.clubId == clubId && r.userId == userId && r.status == ClubJoinStatus.pending);
  
  @override
  Future<Result<ClubJoinRequest>> requestToJoinClub({
    required String clubId,
    required String clubName,
    required String userId,
    required String userName,
    String? note,
  }) async {
    try {
      await _client.from('club_members').insert({
        'club_id': clubId,
        'user_id': userId,
        'role': 'member',
      });
      final request = ClubJoinRequest(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        clubId: clubId,
        clubName: clubName,
        userId: userId,
        userName: userName,
        note: note,
        status: ClubJoinStatus.approved,
        requestedAt: DateTime.now(),
      );
      _joinRequests.add(request);
      notifyListeners();
      return Result.success(request);
    } catch (e) {
      return Result.failure(_dbError('Failed to join club', e));
    }
  }
  
  @override
  Future<Result<void>> approveJoinRequest(String requestId, String approvedBy) async => Result.success(null);
  
  @override
  Future<Result<void>> rejectJoinRequest(String requestId, String rejectedBy, {String? reason}) async => Result.success(null);
  
  @override
  Future<Result<void>> cancelJoinRequest(String requestId) async => Result.success(null);
  
  @override
  List<Club> getMyClubs(String userId) => [];
  
  @override
  List<Club> getAdminClubs(String userId) => [];
  
  @override
  Future<Result<void>> leaveClub(String clubId, String userId) async {
    try {
      await _client.from('club_members').delete().eq('club_id', clubId).eq('user_id', userId);
      notifyListeners();
      return Result.success(null);
    } catch (e) {
      return Result.failure(_dbError('Failed to leave club', e));
    }
  }
  
  @override
  Future<Result<void>> joinClubDirectly(String clubId, String userId) async {
    try {
      await _client.from('club_members').insert({'club_id': clubId, 'user_id': userId, 'role': 'member'});
      notifyListeners();
      return Result.success(null);
    } catch (e) {
      return Result.failure(_dbError('Failed to join club', e));
    }
  }
  
  // ============ EVENTS ============
  
  @override
  Future<Result<Event?>> getEventById(String id) async {
    try {
      final response = await _client.from('events').select().eq('id', id).maybeSingle();
      if (response == null) return Result.success(null);
      return Result.success(_eventFromJson(response));
    } catch (e) {
      return Result.failure(_dbError('Failed to get event', e));
    }
  }
  
  @override
  Future<Result<Event>> addEvent(Event event) async {
    try {
      final response = await _client.from('events').insert(_eventToJson(event)).select().single();
      final newEvent = _eventFromJson(response);
      _events.add(newEvent);
      _events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      notifyListeners();
      return Result.success(newEvent);
    } catch (e) {
      return Result.failure(_dbError('Failed to add event', e));
    }
  }
  
  @override
  Future<Result<Event>> updateEvent(Event event) async {
    try {
      final response = await _client.from('events').update(_eventToJson(event)).eq('id', event.id).select().single();
      final updated = _eventFromJson(response);
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = updated;
        notifyListeners();
      }
      return Result.success(updated);
    } catch (e) {
      return Result.failure(_dbError('Failed to update event', e));
    }
  }
  
  @override
  Future<Result<void>> deleteEvent(String eventId) async {
    try {
      await _client.from('events').delete().eq('id', eventId);
      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();
      return Result.success(null);
    } catch (e) {
      return Result.failure(_dbError('Failed to delete event', e));
    }
  }
  
  @override
  Future<Result<void>> rsvpEvent(String eventId, String userId) async {
    try {
      await _client.from('event_rsvps').insert({
        'event_id': eventId,
        'user_id': userId,
        'user_name': 'User',
        'status': 'going',
      });
      await _fetchEvents();
      return Result.success(null);
    } catch (e) {
      return Result.failure(_dbError('Failed to RSVP', e));
    }
  }
  
  @override
  Future<Result<void>> removeRsvp(String eventId, String userId) async {
    try {
      await _client.from('event_rsvps').delete().eq('event_id', eventId).eq('user_id', userId);
      await _fetchEvents();
      return Result.success(null);
    } catch (e) {
      return Result.failure(_dbError('Failed to remove RSVP', e));
    }
  }
  
  @override
  List<Event> getMyEvents(String userId) => _events.where((e) => e.hasRSVP(userId) && !e.isPast).toList();
  
  @override
  List<Event> getMyPastEvents(String userId) => _events.where((e) => e.hasRSVP(userId) && e.isPast).toList();
  
  @override
  List<EventRegistration> getEventAttendees(String eventId) =>
      _eventRegistrations.where((r) => r.eventId == eventId).toList();
  
  @override
  EventRegistration? getEventRegistration(String eventId, String userId) {
    try {
      return _eventRegistrations.firstWhere((r) => r.eventId == eventId && r.userId == userId);
    } catch (_) {
      return null;
    }
  }
  
  @override
  Future<Result<EventRegistration>> rsvpWithDetails({
    required String eventId,
    required String eventTitle,
    required String userId,
    required String userName,
    Map<String, dynamic>? formResponses,
  }) async {
    try {
      final response = await _client.from('event_rsvps').insert({
        'event_id': eventId,
        'user_id': userId,
        'user_name': userName,
        'status': 'going',
        'form_responses': formResponses,
      }).select().single();
      final reg = EventRegistration(
        id: response['id'],
        eventId: eventId,
        eventTitle: eventTitle,
        userId: userId,
        userName: userName,
        registeredAt: DateTime.now(),
        formResponses: formResponses,
      );
      _eventRegistrations.add(reg);
      notifyListeners();
      return Result.success(reg);
    } catch (e) {
      return Result.failure(_dbError('Failed to RSVP', e));
    }
  }
  
  @override
  Future<Result<void>> checkInAttendee(String eventId, String userId) async {
    try {
      await _client.from('event_rsvps').update({
        'status': 'checked_in',
        'checked_in_at': DateTime.now().toIso8601String(),
      }).eq('event_id', eventId).eq('user_id', userId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(_dbError('Failed to check in', e));
    }
  }
  
  // ============ ANNOUNCEMENTS ============
  
  @override
  Future<Result<Announcement>> addAnnouncement(Announcement announcement) async {
    try {
      final response = await _client.from('announcements').insert(_announcementToJson(announcement)).select().single();
      final newAnn = _announcementFromJson(response);
      _announcements.insert(0, newAnn);
      notifyListeners();
      return Result.success(newAnn);
    } catch (e) {
      return Result.failure(_dbError('Failed to add announcement', e));
    }
  }
  
  @override
  Future<Result<Announcement>> updateAnnouncement(Announcement announcement) async {
    try {
      final response = await _client.from('announcements').update(_announcementToJson(announcement)).eq('id', announcement.id).select().single();
      final updated = _announcementFromJson(response);
      final index = _announcements.indexWhere((a) => a.id == announcement.id);
      if (index != -1) {
        _announcements[index] = updated;
        notifyListeners();
      }
      return Result.success(updated);
    } catch (e) {
      return Result.failure(_dbError('Failed to update announcement', e));
    }
  }
  
  @override
  Future<Result<void>> deleteAnnouncement(String id) async {
    try {
      await _client.from('announcements').delete().eq('id', id);
      _announcements.removeWhere((a) => a.id == id);
      notifyListeners();
      return Result.success(null);
    } catch (e) {
      return Result.failure(_dbError('Failed to delete announcement', e));
    }
  }
  
  // ============ STUB IMPLEMENTATIONS ============
  
  @override
  Future<Result<AcademicQuestion>> addQuestion(AcademicQuestion question) async =>
      Result.failure(DataException.operationFailed( 'Forum not implemented'));
  
  @override
  Future<Result<AcademicQuestion>> updateQuestion(AcademicQuestion question) async =>
      Result.failure(DataException.operationFailed( 'Forum not implemented'));
  
  @override
  Future<Result<void>> deleteQuestion(String questionId) async =>
      Result.failure(DataException.operationFailed( 'Forum not implemented'));
  
  @override
  Future<Result<void>> upvoteQuestion(String questionId, String userId) async =>
      Result.failure(DataException.operationFailed( 'Forum not implemented'));
  
  @override
  Future<Result<void>> incrementViewCount(String questionId) async =>
      Result.failure(DataException.operationFailed( 'Forum not implemented'));
  
  @override
  List<Answer> getAnswersForQuestion(String questionId) => [];
  
  @override
  Future<Result<Answer>> addAnswer(Answer answer) async =>
      Result.failure(DataException.operationFailed( 'Forum not implemented'));
  
  @override
  Future<Result<void>> markAnswerAsAccepted(String questionId, String answerId) async =>
      Result.failure(DataException.operationFailed( 'Forum not implemented'));
  
  @override
  Future<Result<void>> markAnswerAsHelpful(String answerId, String userId) async =>
      Result.failure(DataException.operationFailed( 'Forum not implemented'));
  
  @override
  Future<Result<VaultItem>> addVaultItem(VaultItem item) async =>
      Result.failure(DataException.operationFailed( 'Vault not implemented'));
  
  @override
  Future<Result<void>> upvoteVaultItem(String itemId, String userId) async =>
      Result.failure(DataException.operationFailed( 'Vault not implemented'));
  
  @override
  Future<Result<void>> downvoteVaultItem(String itemId, String userId) async =>
      Result.failure(DataException.operationFailed( 'Vault not implemented'));
  
  @override
  Future<Result<void>> incrementDownloadCount(String itemId) async =>
      Result.failure(DataException.operationFailed( 'Vault not implemented'));
  
  @override
  Future<Result<LostFoundItem>> addLostFoundItem(LostFoundItem item) async =>
      Result.failure(DataException.operationFailed( 'Lost&Found not implemented'));
  
  @override
  Future<Result<LostFoundItem>> updateLostFoundItem(LostFoundItem item) async =>
      Result.failure(DataException.operationFailed( 'Lost&Found not implemented'));
  
  @override
  Future<Result<void>> deleteLostFoundItem(String itemId) async =>
      Result.failure(DataException.operationFailed( 'Lost&Found not implemented'));
  
  @override
  Future<Result<void>> claimLostFoundItem(String itemId, String claimerId) async =>
      Result.failure(DataException.operationFailed( 'Lost&Found not implemented'));
  
  @override
  Future<Result<StudyRequest>> addStudyRequest(StudyRequest request) async =>
      Result.failure(DataException.operationFailed( 'StudyBuddy not implemented'));
  
  @override
  Future<Result<void>> deleteStudyRequest(String requestId) async =>
      Result.failure(DataException.operationFailed( 'StudyBuddy not implemented'));
  
  @override
  Future<Result<StudyMatch>> connectStudyBuddy(String requestId, String userId, String userName) async =>
      Result.failure(DataException.operationFailed( 'StudyBuddy not implemented'));
  
  @override
  bool hasStudyConnection(String requestId, String userId) => false;
  
  @override
  Future<Result<TeamRequest>> addTeamRequest(TeamRequest request) async =>
      Result.failure(DataException.operationFailed( 'TeamFinder not implemented'));
  
  @override
  Future<Result<TeamRequest>> updateTeamRequest(TeamRequest request) async =>
      Result.failure(DataException.operationFailed( 'TeamFinder not implemented'));
  
  @override
  Future<Result<void>> deleteTeamRequest(String requestId) async =>
      Result.failure(DataException.operationFailed( 'TeamFinder not implemented'));
  
  @override
  Future<Result<void>> joinTeam(String teamId, String userId) async =>
      Result.failure(DataException.operationFailed( 'TeamFinder not implemented'));
  
  @override
  Future<Result<void>> leaveTeam(String teamId, String userId) async =>
      Result.failure(DataException.operationFailed( 'TeamFinder not implemented'));
  
  @override
  Future<Result<Mentor>> addMentor(Mentor mentor) async =>
      Result.failure(DataException.operationFailed( 'Mentorship not implemented'));
  
  @override
  Future<Result<MentorshipRequest>> addMentorshipRequest(MentorshipRequest request) async =>
      Result.failure(DataException.operationFailed( 'Mentorship not implemented'));
  
  @override
  Future<Result<void>> approveMentorshipRequest(String requestId) async =>
      Result.failure(DataException.operationFailed( 'Mentorship not implemented'));
  
  @override
  Future<Result<void>> rejectMentorshipRequest(String requestId) async =>
      Result.failure(DataException.operationFailed( 'Mentorship not implemented'));
  
  @override
  Future<Result<Meetup>> addMeetup(Meetup meetup) async =>
      Result.failure(DataException.operationFailed( 'Meetups not implemented'));
  
  @override
  Future<Result<void>> joinMeetup(String meetupId, String userId) async =>
      Result.failure(DataException.operationFailed( 'Meetups not implemented'));
  
  @override
  Future<Result<void>> leaveMeetup(String meetupId, String userId) async =>
      Result.failure(DataException.operationFailed( 'Meetups not implemented'));
  
  @override
  Future<Result<SongVote>> voteSong(SongVote vote) async =>
      Result.failure(DataException.operationFailed( 'Radio not implemented'));
  
  @override
  Future<Result<Shoutout>> sendShoutout(Shoutout shoutout) async =>
      Result.failure(DataException.operationFailed( 'Radio not implemented'));
  
  @override
  Future<Result<Report>> addReport(Report report) async =>
      Result.failure(DataException.operationFailed( 'Reports not implemented'));
  
  @override
  Future<Result<void>> resolveReport(String reportId, String resolvedBy) async =>
      Result.failure(DataException.operationFailed( 'Reports not implemented'));
  
  @override
  Future<Result<void>> dismissReport(String reportId, String dismissedBy) async =>
      Result.failure(DataException.operationFailed( 'Reports not implemented'));
  
  // ============ JSON CONVERTERS ============
  
  Club _clubFromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: ClubCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ClubCategory.other,
      ),
      adminIds: [],
      memberIds: [],
      logoUrl: json['logo_url'],
      coverImageUrl: json['cover_image_url'],
      contactEmail: json['contact_email'],
      instagramHandle: json['instagram_handle'],
      isApproved: json['is_approved'] ?? false,
      isOfficial: json['is_official'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'],
    );
  }
  
  Map<String, dynamic> _clubToJson(Club club) => {
    'name': club.name,
    'description': club.description,
    'category': club.category.name,
    'logo_url': club.logoUrl,
    'cover_image_url': club.coverImageUrl,
    'contact_email': club.contactEmail,
    'instagram_handle': club.instagramHandle,
    'is_approved': club.isApproved,
    'is_official': club.isOfficial,
    'created_by': club.createdBy,
  };
  
  ClubPost _clubPostFromJson(Map<String, dynamic> json) {
    return ClubPost(
      id: json['id'],
      clubId: json['club_id'],
      authorId: json['author_id'],
      authorName: json['author_name'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      type: ClubPostType.values.firstWhere(
        (t) => t.name == json['post_type'],
        orElse: () => ClubPostType.general,
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> _clubPostToJson(ClubPost post) => {
    'club_id': post.clubId,
    'author_id': post.authorId,
    'author_name': post.authorName,
    'title': post.title,
    'content': post.content,
    'image_url': post.imageUrl,
    'post_type': post.type.name,
  };
  
  Event _eventFromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      clubId: json['club_id'],
      clubName: json['club_name'],
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? '',
      eventDate: DateTime.parse(json['event_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      venue: json['venue'] ?? '',
      rsvpIds: [],
      interestedIds: [],
      category: EventCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => EventCategory.other,
      ),
      imageUrl: json['image_url'],
      registrationLink: json['registration_link'],
      requiresRegistration: json['requires_registration'] ?? false,
      isOnline: json['is_online'] ?? false,
      meetingLink: json['meeting_link'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> _eventToJson(Event event) => {
    'title': event.title,
    'description': event.description,
    'club_id': event.clubId,
    'club_name': event.clubName,
    'author_id': event.authorId,
    'author_name': event.authorName,
    'event_date': event.eventDate.toIso8601String(),
    'end_date': event.endDate?.toIso8601String(),
    'venue': event.venue,
    'category': event.category.name,
    'image_url': event.imageUrl,
    'registration_link': event.registrationLink,
    'requires_registration': event.requiresRegistration,
    'is_online': event.isOnline,
    'meeting_link': event.meetingLink,
  };
  
  Announcement _announcementFromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? '',
      authorRole: json['source'] ?? 'Council',
      isPinned: json['is_pinned'] ?? false,
      isUrgent: json['is_urgent'] ?? false,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> _announcementToJson(Announcement ann) => {
    'title': ann.title,
    'content': ann.content,
    'author_id': ann.authorId,
    'author_name': ann.authorName,
    'source': ann.authorRole,
    'is_pinned': ann.isPinned,
    'is_urgent': ann.isUrgent,
    'expires_at': ann.expiresAt?.toIso8601String(),
  };
}
