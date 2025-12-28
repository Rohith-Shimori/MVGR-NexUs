import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
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

/// Mock data service for testing before Firebase integration
/// Provides in-memory CRUD operations with test data
class MockDataService extends ChangeNotifier {
  // ============ CLUBS ============
  final List<Club> _clubs = List.from(Club.testClubs);
  final List<ClubPost> _clubPosts = [];

  List<Club> get clubs => List.unmodifiable(_clubs.where((c) => c.isApproved));
  List<Club> get allClubs => List.unmodifiable(_clubs);

  Club? getClubById(String id) {
    try {
      return _clubs.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void addClub(Club club) {
    _clubs.add(club);
    notifyListeners();
  }

  void updateClub(Club club) {
    final index = _clubs.indexWhere((c) => c.id == club.id);
    if (index != -1) {
      _clubs[index] = club;
      notifyListeners();
    }
  }

  List<ClubPost> getClubPosts(String clubId) =>
      _clubPosts.where((p) => p.clubId == clubId).toList();

  void addClubPost(ClubPost post) {
    _clubPosts.add(post);
    notifyListeners();
  }

  // ============ CLUB JOIN REQUESTS ============
  final List<ClubJoinRequest> _clubJoinRequests = [];

  List<ClubJoinRequest> get clubJoinRequests => List.unmodifiable(_clubJoinRequests);

  /// Get pending join requests for a specific club (for admins)
  List<ClubJoinRequest> getPendingRequestsForClub(String clubId) =>
      _clubJoinRequests.where((r) => r.clubId == clubId && r.isPending).toList();

  /// Get all join requests for a user
  List<ClubJoinRequest> getMyJoinRequests(String userId) =>
      _clubJoinRequests.where((r) => r.userId == userId).toList();

  /// Check if user has a pending request for a club
  bool hasPendingRequest(String clubId, String userId) =>
      _clubJoinRequests.any((r) => r.clubId == clubId && r.userId == userId && r.isPending);

  /// Request to join a club
  ClubJoinRequest requestToJoinClub({
    required String clubId,
    required String clubName,
    required String userId,
    required String userName,
    String? note,
  }) {
    final request = ClubJoinRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      clubId: clubId,
      clubName: clubName,
      status: ClubJoinStatus.pending,
      requestedAt: DateTime.now(),
      note: note,
    );
    _clubJoinRequests.add(request);
    notifyListeners();
    return request;
  }

  /// Approve a join request (adds user to club)
  void approveJoinRequest(String requestId, String approvedBy) {
    final index = _clubJoinRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final request = _clubJoinRequests[index];
      _clubJoinRequests[index] = request.copyWith(
        status: ClubJoinStatus.approved,
        resolvedAt: DateTime.now(),
        resolvedBy: approvedBy,
      );
      
      // Add user to club
      final clubIndex = _clubs.indexWhere((c) => c.id == request.clubId);
      if (clubIndex != -1) {
        final club = _clubs[clubIndex];
        _clubs[clubIndex] = club.copyWith(
          memberIds: [...club.memberIds, request.userId],
        );
      }
      notifyListeners();
    }
  }

  /// Reject a join request
  void rejectJoinRequest(String requestId, String rejectedBy, {String? reason}) {
    final index = _clubJoinRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _clubJoinRequests[index] = _clubJoinRequests[index].copyWith(
        status: ClubJoinStatus.rejected,
        resolvedAt: DateTime.now(),
        resolvedBy: rejectedBy,
        rejectionReason: reason,
      );
      notifyListeners();
    }
  }

  /// Cancel a join request (by the user who made it)
  void cancelJoinRequest(String requestId) {
    final index = _clubJoinRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _clubJoinRequests[index] = _clubJoinRequests[index].copyWith(
        status: ClubJoinStatus.cancelled,
        resolvedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // ============ MEMBERSHIP ============
  
  /// Get clubs where user is a member
  List<Club> getMyClubs(String userId) =>
      _clubs.where((c) => c.isMember(userId) || c.isAdmin(userId)).toList();

  /// Get clubs where user is an admin
  List<Club> getAdminClubs(String userId) =>
      _clubs.where((c) => c.isAdmin(userId)).toList();

  /// Leave a club
  void leaveClub(String clubId, String userId) {
    final index = _clubs.indexWhere((c) => c.id == clubId);
    if (index != -1) {
      final club = _clubs[index];
      _clubs[index] = club.copyWith(
        memberIds: club.memberIds.where((id) => id != userId).toList(),
      );
      notifyListeners();
    }
  }

  /// Join a club directly (for open clubs without approval)
  void joinClubDirectly(String clubId, String userId) {
    final index = _clubs.indexWhere((c) => c.id == clubId);
    if (index != -1) {
      final club = _clubs[index];
      if (!club.isMember(userId)) {
        _clubs[index] = club.copyWith(
          memberIds: [...club.memberIds, userId],
        );
        notifyListeners();
      }
    }
  }

  // ============ EVENTS ============
  final List<Event> _events = List.from(Event.testEvents);

  List<Event> get events => List.unmodifiable(_events);
  List<Event> get upcomingEvents =>
      _events.where((e) => !e.isPast).toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  List<Event> get pastEvents =>
      _events.where((e) => e.isPast).toList()
        ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

  Event? getEventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void addEvent(Event event) {
    _events.add(event);
    notifyListeners();
  }

  void rsvpEvent(String eventId, String userId) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final event = _events[index];
      if (!event.rsvpIds.contains(userId)) {
        _events[index] = event.copyWith(rsvpIds: [...event.rsvpIds, userId]);
        notifyListeners();
      }
    }
  }

  void removeRsvp(String eventId, String userId) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final event = _events[index];
      _events[index] = event.copyWith(
        rsvpIds: event.rsvpIds.where((id) => id != userId).toList(),
      );
      // Also remove from registrations
      _eventRegistrations.removeWhere(
        (r) => r.eventId == eventId && r.userId == userId,
      );
      notifyListeners();
    }
  }

  // ============ EVENT REGISTRATIONS ============
  final List<EventRegistration> _eventRegistrations = [];

  List<EventRegistration> get eventRegistrations => List.unmodifiable(_eventRegistrations);

  /// Get events user has RSVP'd to (upcoming)
  List<Event> getMyEvents(String userId) =>
      _events.where((e) => e.hasRSVP(userId) && !e.isPast).toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

  /// Get events user has attended (past)
  List<Event> getMyPastEvents(String userId) =>
      _events.where((e) => e.hasRSVP(userId) && e.isPast).toList()
        ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

  /// Get full registration details for an event
  List<EventRegistration> getEventAttendees(String eventId) =>
      _eventRegistrations.where((r) => r.eventId == eventId).toList();

  /// Get user's registration for a specific event
  EventRegistration? getEventRegistration(String eventId, String userId) {
    try {
      return _eventRegistrations.firstWhere(
        (r) => r.eventId == eventId && r.userId == userId,
      );
    } catch (_) {
      return null;
    }
  }

  /// RSVP with full registration details
  EventRegistration rsvpWithDetails({
    required String eventId,
    required String eventTitle,
    required String userId,
    required String userName,
    Map<String, dynamic>? formResponses,
  }) {
    // Also add to simple rsvp list
    rsvpEvent(eventId, userId);
    
    final registration = EventRegistration(
      id: 'reg_${DateTime.now().millisecondsSinceEpoch}',
      eventId: eventId,
      eventTitle: eventTitle,
      userId: userId,
      userName: userName,
      status: RegistrationStatus.registered,
      registeredAt: DateTime.now(),
      formResponses: formResponses,
    );
    _eventRegistrations.add(registration);
    notifyListeners();
    return registration;
  }

  /// Check in an attendee
  void checkInAttendee(String eventId, String userId) {
    final index = _eventRegistrations.indexWhere(
      (r) => r.eventId == eventId && r.userId == userId,
    );
    if (index != -1) {
      _eventRegistrations[index] = _eventRegistrations[index].copyWith(
        status: RegistrationStatus.checkedIn,
        checkedInAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Update an event
  void updateEvent(Event event) {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      notifyListeners();
    }
  }

  /// Delete an event
  void deleteEvent(String eventId) {
    _events.removeWhere((e) => e.id == eventId);
    _eventRegistrations.removeWhere((r) => r.eventId == eventId);
    notifyListeners();
  }

  /// Get check-in stats for an event
  Map<String, int> getEventStats(String eventId) {
    final registrations = getEventAttendees(eventId);
    return {
      'total': registrations.length,
      'checkedIn': registrations.where((r) => r.isCheckedIn).length,
      'cancelled': registrations.where((r) => r.isCancelled).length,
    };
  }

  // ============ ANNOUNCEMENTS ============
  final List<Announcement> _announcements = List.from(
    Announcement.testAnnouncements,
  );

  List<Announcement> get announcements => List.unmodifiable(_announcements);
  List<Announcement> get activeAnnouncements =>
      _announcements.where((a) => !a.isExpired).toList()..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

  void addAnnouncement(Announcement announcement) {
    _announcements.add(announcement);
    notifyListeners();
  }

  /// Get announcements ranked by relevance for a user
  /// Score = urgency + expiry proximity + recency + pinned bonus
  List<Announcement> getRelevantAnnouncements({int limit = 20}) {
    var announcements = activeAnnouncements;
    if (announcements.isEmpty) return [];

    final now = DateTime.now();
    announcements = List.from(announcements);

    announcements.sort((a, b) {
      // Pinned always first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      double aScore = 0, bScore = 0;

      // Urgent bonus (40 points)
      if (a.isUrgent) aScore += 40;
      if (b.isUrgent) bScore += 40;

      // Expiry urgency (30 points) - prioritize expiring soon
      if (a.expiresAt != null) {
        final hoursLeft = a.expiresAt!.difference(now).inHours;
        if (hoursLeft > 0 && hoursLeft < 24) {
          aScore += 30;
        } else if (hoursLeft > 0 && hoursLeft < 72) {
          aScore += 20;
        }
      }
      if (b.expiresAt != null) {
        final hoursLeft = b.expiresAt!.difference(now).inHours;
        if (hoursLeft > 0 && hoursLeft < 24) {
          bScore += 30;
        } else if (hoursLeft > 0 && hoursLeft < 72) {
          bScore += 20;
        }
      }

      // Recency (30 points)
      final aHoursOld = now.difference(a.createdAt).inHours;
      final bHoursOld = now.difference(b.createdAt).inHours;
      aScore += (30 - aHoursOld).clamp(0, 30);
      bScore += (30 - bHoursOld).clamp(0, 30);

      return bScore.compareTo(aScore);
    });

    return announcements.take(limit).toList();
  }

  // ============ ACADEMIC FORUM ============
  final List<AcademicQuestion> _questions = List.from(
    AcademicQuestion.testQuestions,
  );
  final List<Answer> _answers = [];

  List<AcademicQuestion> get questions => List.unmodifiable(
    _questions.where((q) => q.status == ModerationStatus.approved),
  );

  AcademicQuestion? getQuestionById(String id) {
    try {
      return _questions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  void addQuestion(AcademicQuestion question) {
    _questions.add(question);
    notifyListeners();
  }

  List<Answer> getAnswers(String questionId) =>
      _answers.where((a) => a.questionId == questionId).toList();

  // Alias for getAnswers (used by forum screen)
  List<Answer> getAnswersForQuestion(String questionId) =>
      getAnswers(questionId);

  /// Get answers ranked by quality (accepted first, then by score)
  /// Score = upvotes * 10 + recency bonus
  List<Answer> getRankedAnswers(String questionId) {
    final answers = getAnswers(questionId);
    if (answers.isEmpty) return [];

    // Calculate score for each answer
    answers.sort((a, b) {
      // Accepted answers always come first
      if (a.isAccepted && !b.isAccepted) return -1;
      if (!a.isAccepted && b.isAccepted) return 1;

      // Calculate quality score
      final now = DateTime.now();

      // Upvote score (weight: 10 points per upvote, max 100)
      final aUpvoteScore = (a.helpfulCount * 10).clamp(0, 100);
      final bUpvoteScore = (b.helpfulCount * 10).clamp(0, 100);

      // Recency bonus (newer answers get up to 30 points)
      final aDays = now.difference(a.createdAt).inDays;
      final bDays = now.difference(b.createdAt).inDays;
      final aRecencyBonus = (30 - aDays * 2).clamp(0, 30);
      final bRecencyBonus = (30 - bDays * 2).clamp(0, 30);

      final aTotal = aUpvoteScore + aRecencyBonus;
      final bTotal = bUpvoteScore + bRecencyBonus;

      return bTotal.compareTo(aTotal); // Higher score first
    });

    return answers;
  }

  void addAnswer(Answer answer) {
    _answers.add(answer);
    // Update answer count
    final qIndex = _questions.indexWhere((q) => q.id == answer.questionId);
    if (qIndex != -1) {
      _questions[qIndex] = _questions[qIndex].copyWith(
        answerCount: _questions[qIndex].answerCount + 1,
      );
    }
    notifyListeners();
  }

  /// Get expert users based on answer acceptance rate
  /// Returns users with high helpful counts and accepted answers
  List<ExpertUser> getExpertUsers({String? subject, int limit = 10}) {
    final answersByUser = <String, List<Answer>>{};

    for (final answer in _answers) {
      answersByUser.putIfAbsent(answer.authorId, () => []).add(answer);
    }

    final experts = <ExpertUser>[];

    for (final entry in answersByUser.entries) {
      final answers = entry.value;
      if (answers.length < 2) continue; // Need at least 2 answers

      final acceptedCount = answers.where((a) => a.isAccepted).length;
      final totalHelpful = answers.fold<int>(
        0,
        (sum, a) => sum + a.helpfulCount,
      );

      // Calculate expert score
      final acceptRate = acceptedCount / answers.length;
      final score =
          (acceptRate * 50) + (totalHelpful * 2) + (answers.length * 5);

      if (score >= 15) {
        // Minimum threshold
        experts.add(
          ExpertUser(
            userId: entry.key,
            userName: answers.first.authorName,
            answerCount: answers.length,
            acceptedCount: acceptedCount,
            totalHelpful: totalHelpful,
            expertScore: score,
          ),
        );
      }
    }

    experts.sort((a, b) => b.expertScore.compareTo(a.expertScore));
    return experts.take(limit).toList();
  }

  /// Get related questions based on subject and keyword overlap
  List<AcademicQuestion> getRelatedQuestions(
    String questionId, {
    int limit = 5,
  }) {
    final question = getQuestionById(questionId);
    if (question == null) return [];

    final keywords = _extractKeywords('${question.title} ${question.content}');

    var related = questions.where((q) {
      if (q.id == questionId) return false;

      // Same subject bonus
      if (q.subject != question.subject) return false;

      final qKeywords = _extractKeywords('${q.title} ${q.content}');
      final overlap = keywords.intersection(qKeywords);
      return overlap.isNotEmpty;
    }).toList();

    // Sort by keyword overlap
    related.sort((a, b) {
      final aKeywords = _extractKeywords('${a.title} ${a.content}');
      final bKeywords = _extractKeywords('${b.title} ${b.content}');
      final aOverlap = keywords.intersection(aKeywords).length;
      final bOverlap = keywords.intersection(bKeywords).length;
      return bOverlap.compareTo(aOverlap);
    });

    return related.take(limit).toList();
  }

  Set<String> _extractKeywords(String text) {
    final stopwords = {
      'the',
      'a',
      'an',
      'is',
      'are',
      'was',
      'were',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'and',
      'or',
      'how',
      'what',
      'why',
      'when',
      'where',
      'which',
      'this',
      'that',
      'these',
      'those',
      'i',
      'you',
      'he',
      'she',
      'it',
      'we',
      'they',
      'my',
      'your',
      'his',
      'her',
      'its',
      'our',
      'their',
      'can',
      'will',
      'would',
      'could',
      'should',
      'do',
      'does',
      'did',
      'have',
      'has',
      'had',
      'be',
      'been',
      'being',
    };
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((w) => w.length > 3 && !stopwords.contains(w))
        .toSet();
  }

  // Question upvote methods
  void upvoteQuestion(String questionId, String userId) {
    final qIndex = _questions.indexWhere((q) => q.id == questionId);
    if (qIndex != -1) {
      final question = _questions[qIndex];
      if (!question.upvotedBy.contains(userId)) {
        _questions[qIndex] = question.copyWith(
          upvoteCount: question.upvoteCount + 1,
          upvotedBy: [...question.upvotedBy, userId],
        );
        notifyListeners();
      }
    }
  }

  void removeQuestionUpvote(String questionId, String userId) {
    final qIndex = _questions.indexWhere((q) => q.id == questionId);
    if (qIndex != -1) {
      final question = _questions[qIndex];
      if (question.upvotedBy.contains(userId)) {
        _questions[qIndex] = question.copyWith(
          upvoteCount: question.upvoteCount - 1,
          upvotedBy: question.upvotedBy.where((id) => id != userId).toList(),
        );
        notifyListeners();
      }
    }
  }

  // Answer upvote methods
  void upvoteAnswer(String answerId, String userId) {
    final aIndex = _answers.indexWhere((a) => a.id == answerId);
    if (aIndex != -1) {
      final answer = _answers[aIndex];
      if (!answer.helpfulByIds.contains(userId)) {
        _answers[aIndex] = Answer(
          id: answer.id,
          questionId: answer.questionId,
          authorId: answer.authorId,
          authorName: answer.authorName,
          content: answer.content,
          isAccepted: answer.isAccepted,
          helpfulCount: answer.helpfulCount + 1,
          helpfulByIds: [...answer.helpfulByIds, userId],
          createdAt: answer.createdAt,
          editedAt: answer.editedAt,
        );
        notifyListeners();
      }
    }
  }

  void removeAnswerUpvote(String answerId, String userId) {
    final aIndex = _answers.indexWhere((a) => a.id == answerId);
    if (aIndex != -1) {
      final answer = _answers[aIndex];
      if (answer.helpfulByIds.contains(userId)) {
        _answers[aIndex] = Answer(
          id: answer.id,
          questionId: answer.questionId,
          authorId: answer.authorId,
          authorName: answer.authorName,
          content: answer.content,
          isAccepted: answer.isAccepted,
          helpfulCount: answer.helpfulCount - 1,
          helpfulByIds: answer.helpfulByIds
              .where((id) => id != userId)
              .toList(),
          createdAt: answer.createdAt,
          editedAt: answer.editedAt,
        );
        notifyListeners();
      }
    }
  }

  // ============ VAULT ============
  final List<VaultItem> _vaultItems = List.from(VaultItem.testItems);

  List<VaultItem> get vaultItems =>
      List.unmodifiable(_vaultItems.where((v) => v.isApproved));

  List<VaultItem> getVaultItemsByFilter({
    String? branch,
    int? year,
    int? semester,
    String? subject,
    VaultItemType? type,
  }) {
    return vaultItems.where((item) {
      if (branch != null && item.branch != branch) return false;
      if (year != null && item.year != year) return false;
      if (semester != null && item.semester != semester) return false;
      if (subject != null &&
          !item.subject.toLowerCase().contains(subject.toLowerCase())) {
        return false;
      }
      if (type != null && item.type != type) return false;
      return true;
    }).toList();
  }

  void addVaultItem(VaultItem item) {
    _vaultItems.add(item);
    notifyListeners();
  }

  void incrementDownloadCount(String itemId) {
    final index = _vaultItems.indexWhere((v) => v.id == itemId);
    if (index != -1) {
      _vaultItems[index] = _vaultItems[index].copyWith(
        downloadCount: _vaultItems[index].downloadCount + 1,
      );
      notifyListeners();
    }
  }

  /// Get vault items ranked by quality score
  /// Score = downloads * 2 + rating * 20 + recency bonus
  List<VaultItem> getRankedVaultItems({
    String? branch,
    int? year,
    VaultItemType? type,
  }) {
    var items = vaultItems.where((item) {
      if (branch != null && item.branch != branch) return false;
      if (year != null && item.year != year) return false;
      if (type != null && item.type != type) return false;
      return true;
    }).toList();

    if (items.isEmpty) return [];

    final now = DateTime.now();
    items.sort((a, b) {
      // Download score (2 points per download, max 50)
      final aDownloadScore = (a.downloadCount * 2).clamp(0, 50);
      final bDownloadScore = (b.downloadCount * 2).clamp(0, 50);

      // Rating score (max 100 from 5.0 rating)
      final aRatingScore = a.rating * 20;
      final bRatingScore = b.rating * 20;

      // Recency bonus (newer items get up to 30 points)
      final aDays = now.difference(a.createdAt).inDays;
      final bDays = now.difference(b.createdAt).inDays;
      final aRecencyBonus = (30 - aDays).clamp(0, 30);
      final bRecencyBonus = (30 - bDays).clamp(0, 30);

      final aTotal = aDownloadScore + aRatingScore + aRecencyBonus;
      final bTotal = bDownloadScore + bRatingScore + bRecencyBonus;

      return bTotal.compareTo(aTotal); // Higher score first
    });

    return items;
  }

  // ============ LOST & FOUND ============
  final List<LostFoundItem> _lostFoundItems = List.from(
    LostFoundItem.testItems,
  );

  List<LostFoundItem> get lostFoundItems =>
      List.unmodifiable(_lostFoundItems.where((i) => i.isActive));

  List<LostFoundItem> get lostItems =>
      lostFoundItems.where((i) => i.status == LostFoundStatus.lost).toList();

  List<LostFoundItem> get foundItems =>
      lostFoundItems.where((i) => i.status == LostFoundStatus.found).toList();

  void addLostFoundItem(LostFoundItem item) {
    _lostFoundItems.add(item);
    notifyListeners();
  }

  void claimItem(String itemId, String claimerId, String claimerName) {
    final index = _lostFoundItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _lostFoundItems[index] = _lostFoundItems[index].copyWith(
        status: LostFoundStatus.claimed,
        claimerId: claimerId,
        claimerName: claimerName,
      );
      notifyListeners();
    }
  }

  void deleteLostFoundItem(String itemId) {
    _lostFoundItems.removeWhere((i) => i.id == itemId);
    notifyListeners();
  }

  // ============ STUDY BUDDY ============
  final List<StudyRequest> _studyRequests = List.from(
    StudyRequest.testRequests,
  );
  final List<StudyMatch> _studyMatches = [];

  List<StudyRequest> get studyRequests =>
      List.unmodifiable(_studyRequests.where((r) => r.isActive));

  void addStudyRequest(StudyRequest request) {
    _studyRequests.add(request);
    notifyListeners();
  }

  void addStudyMatch(StudyMatch match) {
    _studyMatches.add(match);
    notifyListeners();
  }

  List<StudyMatch> getMatchesForUser(String userId) =>
      _studyMatches.where((m) => m.isParticipant(userId)).toList();

  // ============ PLAY BUDDY / TEAM FINDER ============
  final List<TeamRequest> _teamRequests = List.from(TeamRequest.testRequests);
  final List<JoinRequest> _joinRequests = [];

  List<TeamRequest> get teamRequests =>
      List.unmodifiable(_teamRequests.where((r) => r.isOpen));

  List<TeamRequest> getTeamRequestsByCategory(TeamCategory category) =>
      teamRequests.where((r) => r.category == category).toList();

  void addTeamRequest(TeamRequest request) {
    _teamRequests.add(request);
    notifyListeners();
  }

  void addJoinRequest(JoinRequest request) {
    _joinRequests.add(request);
    notifyListeners();
  }

  List<JoinRequest> getJoinRequestsForTeam(String teamId) =>
      _joinRequests.where((r) => r.teamRequestId == teamId).toList();

  // ============ MENTORSHIP ============
  final List<Mentor> _mentors = List.from(Mentor.testMentors);
  final List<MentorshipRequest> _mentorshipRequests = [];

  List<Mentor> get mentors =>
      List.unmodifiable(_mentors.where((m) => m.isAvailable && m.hasCapacity));

  void addMentor(Mentor mentor) {
    _mentors.add(mentor);
    notifyListeners();
  }

  void addMentorshipRequest(MentorshipRequest request) {
    _mentorshipRequests.add(request);
    notifyListeners();
  }

  List<Mentor> getMentorsByArea(MentorshipArea? area) {
    if (area == null) return mentors;
    return mentors.where((m) => m.areas.contains(area)).toList();
  }

  /// Get mentors ranked by quality score
  /// Score = availability bonus + capacity bonus + expertise breadth
  List<Mentor> getRankedMentors({MentorshipArea? area}) {
    var mentorList = getMentorsByArea(area);
    if (mentorList.isEmpty) return [];

    mentorList = List.from(mentorList);
    mentorList.sort((a, b) {
      // Availability bonus (40 points if available)
      final aAvailBonus = a.isAvailable ? 40 : 0;
      final bAvailBonus = b.isAvailable ? 40 : 0;

      // Capacity bonus (10 points for each open slot, max 30)
      final aCapacityBonus = ((a.maxMentees - a.currentMentees) * 10).clamp(
        0,
        30,
      );
      final bCapacityBonus = ((b.maxMentees - b.currentMentees) * 10).clamp(
        0,
        30,
      );

      // Expertise breadth bonus (5 points per expertise, max 30)
      final aExpertiseBonus = (a.expertise.length * 5).clamp(0, 30);
      final bExpertiseBonus = (b.expertise.length * 5).clamp(0, 30);

      // Areas covered bonus (10 points per area, max 30)
      final aAreasBonus = (a.areas.length * 10).clamp(0, 30);
      final bAreasBonus = (b.areas.length * 10).clamp(0, 30);

      final aTotal =
          aAvailBonus + aCapacityBonus + aExpertiseBonus + aAreasBonus;
      final bTotal =
          bAvailBonus + bCapacityBonus + bExpertiseBonus + bAreasBonus;

      return bTotal.compareTo(aTotal); // Higher score first
    });

    return mentorList;
  }

  // ============ OFFLINE COMMUNITY / MEETUPS ============
  final List<Meetup> _meetups = List.from(Meetup.testMeetups);

  List<Meetup> get meetups =>
      List.unmodifiable(_meetups.where((m) => m.isActive && !m.isPast));

  List<Meetup> getMeetupsByCategory(MeetupCategory category) =>
      meetups.where((m) => m.category == category).toList();

  void addMeetup(Meetup meetup) {
    _meetups.add(meetup);
    notifyListeners();
  }

  void joinMeetup(String meetupId, String userId) {
    final index = _meetups.indexWhere((m) => m.id == meetupId);
    if (index != -1) {
      final meetup = _meetups[index];
      if (!meetup.participantIds.contains(userId)) {
        _meetups[index] = meetup.copyWith(
          participantIds: [...meetup.participantIds, userId],
        );
        notifyListeners();
      }
    }
  }

  void leaveMeetup(String meetupId, String userId) {
    final index = _meetups.indexWhere((m) => m.id == meetupId);
    if (index != -1) {
      final meetup = _meetups[index];
      _meetups[index] = meetup.copyWith(
        participantIds: meetup.participantIds
            .where((id) => id != userId)
            .toList(),
      );
      notifyListeners();
    }
  }

  // ============ RADIO ============
  final List<SongVote> _songVotes = [];
  final List<Shoutout> _shoutouts = [];

  List<SongVote> get songVotes => List.unmodifiable(_songVotes);
  List<Shoutout> get shoutouts => List.unmodifiable(_shoutouts);

  void addSongVote(SongVote vote) {
    _songVotes.add(vote);
    notifyListeners();
  }

  void voteSong(String songId, String userId) {
    final index = _songVotes.indexWhere((s) => s.id == songId);
    if (index != -1) {
      final song = _songVotes[index];
      if (!song.voterIds.contains(userId)) {
        _songVotes[index] = SongVote(
          id: song.id,
          sessionId: song.sessionId,
          songName: song.songName,
          artistName: song.artistName,
          requesterId: song.requesterId,
          requesterName: song.requesterName,
          voteCount: song.voteCount + 1,
          voterIds: [...song.voterIds, userId],
          isPlayed: song.isPlayed,
          isApproved: song.isApproved,
          requestedAt: song.requestedAt,
          playedAt: song.playedAt,
        );
        notifyListeners();
      }
    }
  }

  void addShoutout(Shoutout shoutout) {
    _shoutouts.add(shoutout);
    notifyListeners();
  }

  void moderateShoutout(String shoutoutId, ModerationStatus status) {
    final index = _shoutouts.indexWhere((s) => s.id == shoutoutId);
    if (index != -1) {
      final oldShoutout = _shoutouts[index];
      _shoutouts[index] = Shoutout(
        id: oldShoutout.id,
        sessionId: oldShoutout.sessionId,
        authorId: oldShoutout.authorId,
        authorName: oldShoutout.authorName,
        message: oldShoutout.message,
        dedicatedTo: oldShoutout.dedicatedTo,
        isAnonymous: oldShoutout.isAnonymous,
        status: status,
        createdAt: oldShoutout.createdAt,
        isRead: oldShoutout.isRead,
      );
      notifyListeners();
    }
  }
}

/// Expert user with answer statistics
class ExpertUser {
  final String userId;
  final String userName;
  final int answerCount;
  final int acceptedCount;
  final int totalHelpful;
  final double expertScore;

  ExpertUser({
    required this.userId,
    required this.userName,
    required this.answerCount,
    required this.acceptedCount,
    required this.totalHelpful,
    required this.expertScore,
  });

  double get acceptanceRate =>
      answerCount > 0 ? acceptedCount / answerCount : 0;
  String get badge {
    if (expertScore >= 100) return '🏆 Expert';
    if (expertScore >= 50) return '⭐ Top Contributor';
    if (expertScore >= 25) return '📚 Helpful';
    return '👤 Active';
  }
}

/// Singleton instance
final mockDataService = MockDataService();
