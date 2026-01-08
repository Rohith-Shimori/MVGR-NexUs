// Notification Service - Smart Alerts & Prioritized Notifications
// Manages notification scheduling, prioritization, and reminders
// Now with Supabase Realtime for live push notifications

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../core/theme/app_colors.dart';

/// Priority levels for notifications
enum NotificationPriority {
  low,
  normal,
  high,
  urgent;

  int get weight {
    switch (this) {
      case NotificationPriority.low:
        return 1;
      case NotificationPriority.normal:
        return 2;
      case NotificationPriority.high:
        return 3;
      case NotificationPriority.urgent:
        return 4;
    }
  }

  Color get color {
    switch (this) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }
}

/// Notification category for relevance filtering
enum NotificationCategory {
  academic,
  club,
  event,
  mentorship,
  lostFound,
  announcement,
  forum,
  social,
  system,
}

/// A smart notification with priority and relevance scoring
class SmartNotification {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? deadline;
  final String? targetUserId;
  final String? department;
  final int? targetYear;
  final List<String> relatedInterests;
  final bool isRead;
  final String? actionRoute;

  SmartNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.priority = NotificationPriority.normal,
    required this.createdAt,
    this.deadline,
    this.targetUserId,
    this.department,
    this.targetYear,
    this.relatedInterests = const [],
    this.isRead = false,
    this.actionRoute,
  });

  SmartNotification copyWith({bool? isRead, NotificationPriority? priority}) {
    return SmartNotification(
      id: id,
      title: title,
      body: body,
      category: category,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      deadline: deadline,
      targetUserId: targetUserId,
      department: department,
      targetYear: targetYear,
      relatedInterests: relatedInterests,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute,
    );
  }
}

/// Global key for showing notification snackbars app-wide
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = 
    GlobalKey<ScaffoldMessengerState>();

/// Notification Service for smart alert management with Supabase Realtime
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<SmartNotification> _notifications = [];
  RealtimeChannel? _announcementChannel;
  RealtimeChannel? _eventChannel;
  RealtimeChannel? _clubChannel;
  bool _isSubscribed = false;

  List<SmartNotification> get all => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  /// Initialize Supabase Realtime subscriptions
  Future<void> initializeRealtime() async {
    if (!SupabaseConfig.isInitialized || _isSubscribed) return;
    
    debugPrint('🔔 Initializing NotificationService realtime...');
    final supabase = Supabase.instance.client;
    
    // Subscribe to new announcements
    _announcementChannel = supabase.channel('realtime:announcements')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'announcements',
        callback: (payload) => _handleNewAnnouncement(payload),
      )
      .subscribe();
    
    // Subscribe to new events
    _eventChannel = supabase.channel('realtime:events')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'events',
        callback: (payload) => _handleNewEvent(payload),
      )
      .subscribe();
    
    // Subscribe to new clubs
    _clubChannel = supabase.channel('realtime:clubs')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'clubs',
        callback: (payload) => _handleNewClub(payload),
      )
      .subscribe();
    
    _isSubscribed = true;
    debugPrint('✅ NotificationService realtime subscribed');
  }

  void _handleNewAnnouncement(PostgresChangePayload payload) {
    final data = payload.newRecord;
    final notification = SmartNotification(
      id: 'notif_announcement_${DateTime.now().millisecondsSinceEpoch}',
      title: '📢 ${data['title'] ?? 'New Announcement'}',
      body: data['content']?.toString().substring(0, 50) ?? '',
      category: NotificationCategory.announcement,
      priority: data['is_urgent'] == true 
          ? NotificationPriority.urgent 
          : NotificationPriority.high,
      createdAt: DateTime.now(),
    );
    _addAndNotify(notification);
  }

  void _handleNewEvent(PostgresChangePayload payload) {
    final data = payload.newRecord;
    final notification = SmartNotification(
      id: 'notif_event_${DateTime.now().millisecondsSinceEpoch}',
      title: '🎉 New Event: ${data['title'] ?? 'Event'}',
      body: data['venue']?.toString() ?? '',
      category: NotificationCategory.event,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
    );
    _addAndNotify(notification);
  }

  void _handleNewClub(PostgresChangePayload payload) {
    final data = payload.newRecord;
    final notification = SmartNotification(
      id: 'notif_club_${DateTime.now().millisecondsSinceEpoch}',
      title: '🏛️ New Club Created',
      body: '${data['name']} is now on campus!',
      category: NotificationCategory.club,
      priority: NotificationPriority.low,
      createdAt: DateTime.now(),
    );
    _addAndNotify(notification);
  }

  void _addAndNotify(SmartNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
    _showSnackbar(notification);
    debugPrint('🔔 New notification: ${notification.title}');
  }

  void _showSnackbar(SmartNotification notification) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                notification.category == NotificationCategory.announcement
                    ? Icons.campaign
                    : notification.category == NotificationCategory.event
                        ? Icons.event
                        : Icons.groups,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(notification.title),
              ),
            ],
          ),
          backgroundColor: notification.priority == NotificationPriority.urgent
              ? AppColors.error
              : notification.priority == NotificationPriority.high
                  ? AppColors.warning
                  : AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Add a new notification
  void addNotification(SmartNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  /// Get prioritized notifications for a user
  /// Considers: priority, relevance, deadline proximity, recency
  List<SmartNotification> getPrioritized({
    required String userId,
    String? department,
    int? year,
    List<String> interests = const [],
    int limit = 20,
  }) {
    final now = DateTime.now();

    // Filter relevant notifications
    var filtered = _notifications.where((n) {
      // Skip if targeted to someone else
      if (n.targetUserId != null && n.targetUserId != userId) return false;
      return true;
    }).toList();

    // Score and sort
    filtered.sort((a, b) {
      final aScore = _calculateScore(a, now, department, year, interests);
      final bScore = _calculateScore(b, now, department, year, interests);
      return bScore.compareTo(aScore); // Higher score first
    });

    return filtered.take(limit).toList();
  }

  /// Calculate notification relevance score
  double _calculateScore(
    SmartNotification n,
    DateTime now,
    String? userDept,
    int? userYear,
    List<String> userInterests,
  ) {
    double score = 0;

    // Priority weight (max 40)
    score += n.priority.weight * 10;

    // Deadline proximity bonus (max 30)
    if (n.deadline != null) {
      final hoursUntilDeadline = n.deadline!.difference(now).inHours;
      if (hoursUntilDeadline < 0) {
        score += 0; // Expired
      } else if (hoursUntilDeadline < 24) {
        score += 30; // Due within 24h
      } else if (hoursUntilDeadline < 72) {
        score += 20; // Due within 3 days
      } else if (hoursUntilDeadline < 168) {
        score += 10; // Due within week
      }
    }

    // Department match bonus (10)
    if (n.department != null && n.department == userDept) {
      score += 10;
    }

    // Year match bonus (10)
    if (n.targetYear != null && n.targetYear == userYear) {
      score += 10;
    }

    // Interest overlap bonus (max 20)
    if (userInterests.isNotEmpty && n.relatedInterests.isNotEmpty) {
      final overlap = n.relatedInterests
          .where((i) => userInterests.contains(i))
          .length;
      score += (overlap * 5).clamp(0, 20);
    }

    // Recency bonus (max 10)
    final hoursOld = now.difference(n.createdAt).inHours;
    if (hoursOld < 1) {
      score += 10;
    } else if (hoursOld < 6) {
      score += 7;
    } else if (hoursOld < 24) {
      score += 4;
    }

    // Unread bonus (5)
    if (!n.isRead) {
      score += 5;
    }

    return score;
  }

  /// Get unread count
  int getUnreadCount(String userId) {
    return _notifications
        .where(
          (n) =>
              !n.isRead && (n.targetUserId == null || n.targetUserId == userId),
        )
        .length;
  }

  /// Mark as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  /// Mark all as read
  void markAllAsRead(String userId) {
    for (int i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      if (!n.isRead && (n.targetUserId == null || n.targetUserId == userId)) {
        _notifications[i] = n.copyWith(isRead: true);
      }
    }
  }

  /// Escalate priority based on deadline
  void escalatePriorities() {
    final now = DateTime.now();
    for (int i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      if (n.deadline != null && n.priority != NotificationPriority.urgent) {
        final hoursLeft = n.deadline!.difference(now).inHours;
        if (hoursLeft > 0 && hoursLeft < 6) {
          _notifications[i] = n.copyWith(priority: NotificationPriority.urgent);
        } else if (hoursLeft > 0 && hoursLeft < 24) {
          _notifications[i] = n.copyWith(priority: NotificationPriority.high);
        }
      }
    }
  }

  /// Create reminder notification
  static SmartNotification createReminder({
    required String title,
    required String body,
    required DateTime reminderTime,
    NotificationCategory category = NotificationCategory.system,
    String? actionRoute,
  }) {
    return SmartNotification(
      id: 'reminder_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      category: category,
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
      deadline: reminderTime,
      actionRoute: actionRoute,
    );
  }
}
