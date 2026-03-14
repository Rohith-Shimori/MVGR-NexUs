import '../features/clubs/models/club_model.dart';
import '../features/events/models/event_model.dart';
import '../features/offline_community/models/meetup_model.dart';
import '../services/supabase_club_service.dart';
import '../services/supabase_event_service.dart';
import '../services/supabase_meetups_service.dart';

/// Suggestion Service for Interest-Based Recommendations
/// Maps user interests to relevant clubs, events, meetups
class SuggestionService {
  final SupabaseClubService _clubService;
  final SupabaseEventService _eventService;
  final SupabaseMeetupsService _meetupService;

  SuggestionService(this._clubService, this._eventService, this._meetupService);

  // ============ INTEREST TO CATEGORY MAPPING ============
  
  /// Maps interests to ClubCategories
  /// ClubCategory: technical, cultural, sports, social, academic, other
  static const Map<String, List<ClubCategory>> _interestToClubCategories = {
    // Tech & Academic
    'Programming': [ClubCategory.technical],
    'Machine Learning': [ClubCategory.technical, ClubCategory.academic],
    'Web Development': [ClubCategory.technical],
    'Mobile Development': [ClubCategory.technical],
    'Data Science': [ClubCategory.technical, ClubCategory.academic],
    'Cybersecurity': [ClubCategory.technical],
    'Cloud Computing': [ClubCategory.technical],
    'Robotics': [ClubCategory.technical],
    'IoT': [ClubCategory.technical],
    'Blockchain': [ClubCategory.technical],
    
    // Creative & Cultural
    'Music': [ClubCategory.cultural],
    'Dance': [ClubCategory.cultural],
    'Art & Design': [ClubCategory.cultural],
    'Photography': [ClubCategory.cultural],
    'Video Editing': [ClubCategory.cultural],
    'Writing': [ClubCategory.cultural, ClubCategory.academic],
    'Content Creation': [ClubCategory.cultural],
    
    // Sports
    'Cricket': [ClubCategory.sports],
    'Football': [ClubCategory.sports],
    'Basketball': [ClubCategory.sports],
    'Badminton': [ClubCategory.sports],
    'Table Tennis': [ClubCategory.sports],
    'Chess': [ClubCategory.sports],
    'Athletics': [ClubCategory.sports],
    'Fitness': [ClubCategory.sports],
    
    // Social
    'Public Speaking': [ClubCategory.social],
    'Debate': [ClubCategory.social, ClubCategory.academic],
    'Event Management': [ClubCategory.social],
    'Volunteering': [ClubCategory.social],
    'Entrepreneurship': [ClubCategory.social, ClubCategory.technical],
    
    // Gaming & Entertainment
    'E-Sports': [ClubCategory.technical],
    'PC Gaming': [ClubCategory.technical],
    'Mobile Gaming': [ClubCategory.technical],
    'Movies': [ClubCategory.cultural],
    'Anime': [ClubCategory.cultural],
    'Reading': [ClubCategory.academic, ClubCategory.cultural],
  };

  /// Maps interests to EventCategories
  /// EventCategory: academic, cultural, sports, hackathon, workshop, seminar, competition, other
  static const Map<String, List<EventCategory>> _interestToEventCategories = {
    // Tech
    'Programming': [EventCategory.workshop, EventCategory.hackathon, EventCategory.competition],
    'Machine Learning': [EventCategory.workshop, EventCategory.seminar, EventCategory.hackathon],
    'Web Development': [EventCategory.workshop, EventCategory.hackathon],
    'Mobile Development': [EventCategory.workshop, EventCategory.hackathon],
    'Cybersecurity': [EventCategory.workshop, EventCategory.seminar],
    'Robotics': [EventCategory.workshop, EventCategory.competition],
    
    // Creative
    'Music': [EventCategory.cultural],
    'Dance': [EventCategory.cultural, EventCategory.competition],
    'Art & Design': [EventCategory.cultural],
    'Photography': [EventCategory.workshop],
    
    // Sports
    'Cricket': [EventCategory.sports],
    'Football': [EventCategory.sports],
    'Basketball': [EventCategory.sports],
    'E-Sports': [EventCategory.competition],
    
    // Social
    'Public Speaking': [EventCategory.seminar, EventCategory.competition],
    'Debate': [EventCategory.competition],
  };

  /// Maps interests to MeetupCategories
  /// MeetupCategory: studyCircle, gaming, anime, music, art, sports, movies, books, tech, other
  static const Map<String, List<MeetupCategory>> _interestToMeetupCategories = {
    // Tech
    'Programming': [MeetupCategory.studyCircle, MeetupCategory.tech],
    'Machine Learning': [MeetupCategory.studyCircle, MeetupCategory.tech],
    'Web Development': [MeetupCategory.studyCircle, MeetupCategory.tech],
    
    // Creative
    'Music': [MeetupCategory.music],
    'Photography': [MeetupCategory.art],
    'Art & Design': [MeetupCategory.art],
    
    // Gaming
    'E-Sports': [MeetupCategory.gaming],
    'PC Gaming': [MeetupCategory.gaming],
    'Mobile Gaming': [MeetupCategory.gaming],
    
    // Sports
    'Cricket': [MeetupCategory.sports],
    'Football': [MeetupCategory.sports],
    'Badminton': [MeetupCategory.sports],
    'Fitness': [MeetupCategory.sports],
    
    // Entertainment
    'Movies': [MeetupCategory.movies],
    'Anime': [MeetupCategory.anime],
    'Reading': [MeetupCategory.books],
  };

  // ============ RECOMMENDATION METHODS ============

  /// Get recommended clubs based on user interests
  List<Club> getRecommendedClubs(List<String> interests, {int limit = 10}) {
    if (interests.isEmpty) return [];

    final Set<ClubCategory> relevantCategories = {};
    for (final interest in interests) {
      final categories = _interestToClubCategories[interest];
      if (categories != null) {
        relevantCategories.addAll(categories);
      }
    }

    if (relevantCategories.isEmpty) return [];

    final clubs = _clubService.clubs.where((club) {
      return relevantCategories.contains(club.category);
    }).toList();

    // Sort by member count (more members = more popular)
    clubs.sort((a, b) => b.totalMembers.compareTo(a.totalMembers));

    return clubs.take(limit).toList();
  }

  /// Get recommended events based on user interests
  List<Event> getRecommendedEvents(List<String> interests, {int limit = 10}) {
    if (interests.isEmpty) return [];

    final Set<EventCategory> relevantCategories = {};
    for (final interest in interests) {
      final categories = _interestToEventCategories[interest];
      if (categories != null) {
        relevantCategories.addAll(categories);
      }
    }

    if (relevantCategories.isEmpty) return [];

    final events = _eventService.events.where((event) {
      return relevantCategories.contains(event.category) && 
             event.eventDate.isAfter(DateTime.now());  // Future events only
    }).toList();

    // Sort by date (soonest first)
    events.sort((a, b) => a.eventDate.compareTo(b.eventDate));

    return events.take(limit).toList();
  }

  /// Get recommended meetups based on user interests
  List<Meetup> getRecommendedMeetups(List<String> interests, {int limit = 10}) {
    if (interests.isEmpty) return [];

    final Set<MeetupCategory> relevantCategories = {};
    for (final interest in interests) {
      final categories = _interestToMeetupCategories[interest];
      if (categories != null) {
        relevantCategories.addAll(categories);
      }
    }

    if (relevantCategories.isEmpty) return [];

    // Meetups filtered by category string matching

    // Better implementation for Meetups:
    // Filter by the string category since MeetupService returns Meetup objects with String category
    final relevantCategoryStrings = relevantCategories.map((e) => e.name).toSet();
    
    final filteredMeetups = _meetupService.upcomingMeetups.where((meetup) {
       // We need to map the enum names to what's stored in DB ('study', 'social' etc)
       // This part depends on how _interestToMeetupCategories values map to DB strings
       // If MeetupCategory is an enum in the model, we use it. If it's in this service, we map it.
       return relevantCategoryStrings.contains(meetup.category.name.toLowerCase()) || 
              relevantCategoryStrings.contains(meetup.category.name);
    }).toList();

    // Sort by date (soonest first)
    filteredMeetups.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return filteredMeetups.take(limit).toList();
  }

  /// Get all recommendations as a combined list for home screen
  SuggestionResults getAllRecommendations(List<String> interests) {
    return SuggestionResults(
      clubs: getRecommendedClubs(interests, limit: 5),
      events: getRecommendedEvents(interests, limit: 5),
      meetups: getRecommendedMeetups(interests, limit: 5),
    );
  }

  /// Check if user has set any interests
  bool hasInterests(List<String> interests) => interests.isNotEmpty;
}

/// Container for all suggestion results
class SuggestionResults {
  final List<Club> clubs;
  final List<Event> events;
  final List<Meetup> meetups;

  SuggestionResults({
    required this.clubs,
    required this.events,
    required this.meetups,
  });

  bool get isEmpty => clubs.isEmpty && events.isEmpty && meetups.isEmpty;
  int get totalCount => clubs.length + events.length + meetups.length;
}
