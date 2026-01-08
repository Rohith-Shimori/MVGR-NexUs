/// Supabase Realtime Service
/// Handles real-time subscriptions for live data updates
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../features/clubs/models/club_model.dart';
import '../features/events/models/event_model.dart';

/// Callback types for realtime events
typedef OnClubChange = void Function(Club club, RealtimeChangeType type);
typedef OnEventChange = void Function(Event event, RealtimeChangeType type);
typedef OnAnnouncementChange = void Function(Map<String, dynamic> data, RealtimeChangeType type);

/// Type of realtime change
enum RealtimeChangeType { insert, update, delete }

/// Realtime service for live data updates
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._();
  static RealtimeService get instance => _instance;
  RealtimeService._();

  final List<RealtimeChannel> _channels = [];
  bool _isInitialized = false;

  /// Initialize realtime subscriptions
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!SupabaseConfig.isInitialized) {
      debugPrint('⚠️ Supabase not initialized, skipping realtime');
      return;
    }

    debugPrint('🔄 Initializing Supabase Realtime...');
    _isInitialized = true;
  }

  /// Subscribe to club changes
  RealtimeChannel subscribeToClubs({
    OnClubChange? onChange,
  }) {
    final channel = SupabaseConfig.client
        .channel('clubs-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'clubs',
          callback: (payload) {
            debugPrint('🔔 Club change: ${payload.eventType}');
            if (onChange != null) {
              final type = _mapEventType(payload.eventType);
              final data = payload.newRecord.isNotEmpty 
                  ? payload.newRecord 
                  : payload.oldRecord;
              try {
                final club = _clubFromJson(data);
                onChange(club, type);
              } catch (e) {
                debugPrint('❌ Error parsing club: $e');
              }
            }
          },
        )
        .subscribe();

    _channels.add(channel);
    debugPrint('📡 Subscribed to clubs channel');
    return channel;
  }

  /// Subscribe to event changes
  RealtimeChannel subscribeToEvents({
    OnEventChange? onChange,
  }) {
    final channel = SupabaseConfig.client
        .channel('events-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'events',
          callback: (payload) {
            debugPrint('🔔 Event change: ${payload.eventType}');
            if (onChange != null) {
              final type = _mapEventType(payload.eventType);
              final data = payload.newRecord.isNotEmpty 
                  ? payload.newRecord 
                  : payload.oldRecord;
              try {
                final event = _eventFromJson(data);
                onChange(event, type);
              } catch (e) {
                debugPrint('❌ Error parsing event: $e');
              }
            }
          },
        )
        .subscribe();

    _channels.add(channel);
    debugPrint('📡 Subscribed to events channel');
    return channel;
  }

  /// Subscribe to announcement changes
  RealtimeChannel subscribeToAnnouncements({
    OnAnnouncementChange? onChange,
  }) {
    final channel = SupabaseConfig.client
        .channel('announcements-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (payload) {
            debugPrint('🔔 Announcement change: ${payload.eventType}');
            if (onChange != null) {
              final type = _mapEventType(payload.eventType);
              final data = payload.newRecord.isNotEmpty 
                  ? payload.newRecord 
                  : payload.oldRecord;
              onChange(data, type);
            }
          },
        )
        .subscribe();

    _channels.add(channel);
    debugPrint('📡 Subscribed to announcements channel');
    return channel;
  }

  /// Subscribe to a specific club's posts
  RealtimeChannel subscribeToClubPosts({
    required String clubId,
    Function(Map<String, dynamic> data, RealtimeChangeType type)? onChange,
  }) {
    final channel = SupabaseConfig.client
        .channel('club-posts-$clubId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'club_posts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'club_id',
            value: clubId,
          ),
          callback: (payload) {
            debugPrint('🔔 Club post change in $clubId');
            if (onChange != null) {
              final type = _mapEventType(payload.eventType);
              final data = payload.newRecord.isNotEmpty 
                  ? payload.newRecord 
                  : payload.oldRecord;
              onChange(data, type);
            }
          },
        )
        .subscribe();

    _channels.add(channel);
    return channel;
  }

  /// Subscribe to event RSVPs
  RealtimeChannel subscribeToEventRsvps({
    required String eventId,
    Function(Map<String, dynamic> data, RealtimeChangeType type)? onChange,
  }) {
    final channel = SupabaseConfig.client
        .channel('event-rsvps-$eventId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_rsvps',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'event_id',
            value: eventId,
          ),
          callback: (payload) {
            debugPrint('🔔 RSVP change for event $eventId');
            if (onChange != null) {
              final type = _mapEventType(payload.eventType);
              final data = payload.newRecord.isNotEmpty 
                  ? payload.newRecord 
                  : payload.oldRecord;
              onChange(data, type);
            }
          },
        )
        .subscribe();

    _channels.add(channel);
    return channel;
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await channel.unsubscribe();
    _channels.remove(channel);
  }

  /// Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    for (final channel in _channels) {
      await channel.unsubscribe();
    }
    _channels.clear();
    debugPrint('📴 Unsubscribed from all channels');
  }

  /// Dispose all subscriptions
  void dispose() {
    unsubscribeAll();
    _isInitialized = false;
  }

  // Helper to map event types
  RealtimeChangeType _mapEventType(PostgresChangeEvent event) {
    switch (event) {
      case PostgresChangeEvent.insert:
        return RealtimeChangeType.insert;
      case PostgresChangeEvent.update:
        return RealtimeChangeType.update;
      case PostgresChangeEvent.delete:
        return RealtimeChangeType.delete;
      default:
        return RealtimeChangeType.update;
    }
  }

  // JSON converters (duplicated for isolation)
  Club _clubFromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id']?.toString() ?? '',
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
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      createdBy: json['created_by'],
    );
  }

  Event _eventFromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      clubId: json['club_id'],
      clubName: json['club_name'],
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? '',
      eventDate: DateTime.tryParse(json['event_date'] ?? '') ?? DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
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
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Singleton instance
final realtimeService = RealtimeService.instance;
