import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/animations.dart';
import '../../../services/notification_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Premium Notifications Screen
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationService = NotificationService.instance;
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.user?.id ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (notificationService.all.isNotEmpty)
            TextButton(
              onPressed: () {
                notificationService.markAllAsRead(userId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All marked as read')),
                );
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notificationService.all.isEmpty
          ? _EmptyState(isDark: isDark)
          : _NotificationsList(isDark: isDark, userId: userId),
    );
  }
}

/// Empty State
class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No new notifications at the moment.\nWe\'ll let you know when something happens.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Notifications List
class _NotificationsList extends StatelessWidget {
  final bool isDark;
  final String userId;

  const _NotificationsList({required this.isDark, required this.userId});

  @override
  Widget build(BuildContext context) {
    final notifications = NotificationService.instance.getPrioritized(
      userId: userId,
      limit: 50,
    );

    // Group by date
    final today = <SmartNotification>[];
    final yesterday = <SmartNotification>[];
    final older = <SmartNotification>[];

    final now = DateTime.now();
    for (final n in notifications) {
      final diff = now.difference(n.createdAt).inDays;
      if (diff == 0) {
        today.add(n);
      } else if (diff == 1) {
        yesterday.add(n);
      } else {
        older.add(n);
      }
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (today.isNotEmpty) ...[
                _SectionHeader(title: 'Today', isDark: isDark),
                const SizedBox(height: 12),
                ...today.asMap().entries.map((entry) => FadeInAnimation(
                  delay: Duration(milliseconds: entry.key * 50),
                  child: _NotificationCard(notification: entry.value, isDark: isDark),
                )),
                const SizedBox(height: 20),
              ],
              if (yesterday.isNotEmpty) ...[
                _SectionHeader(title: 'Yesterday', isDark: isDark),
                const SizedBox(height: 12),
                ...yesterday.asMap().entries.map((entry) => FadeInAnimation(
                  delay: Duration(milliseconds: entry.key * 50),
                  child: _NotificationCard(notification: entry.value, isDark: isDark),
                )),
                const SizedBox(height: 20),
              ],
              if (older.isNotEmpty) ...[
                _SectionHeader(title: 'Earlier', isDark: isDark),
                const SizedBox(height: 12),
                ...older.asMap().entries.map((entry) => FadeInAnimation(
                  delay: Duration(milliseconds: entry.key * 50),
                  child: _NotificationCard(notification: entry.value, isDark: isDark),
                )),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

/// Section Header
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSecondaryDark : context.appColors.textSecondary,
      ),
    );
  }
}

/// Notification Card
class _NotificationCard extends StatelessWidget {
  final SmartNotification notification;
  final bool isDark;

  const _NotificationCard({required this.notification, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead
            ? (isDark ? AppColors.clayDark : AppColors.clayLight)
            : AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark 
            ? ClayShadows.dark(intensity: 0.6)
            : ClayShadows.light(intensity: 0.6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getCategoryColor(notification.category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(notification.category),
              color: _getCategoryColor(notification.category),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: notification.priority.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : context.appColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(notification.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.event:
        return AppColors.eventsColor;
      case NotificationCategory.club:
        return AppColors.clubsColor;
      case NotificationCategory.announcement:
        return AppColors.primary;
      case NotificationCategory.mentorship:
        return AppColors.mentorshipColor;
      case NotificationCategory.forum:
        return AppColors.forumColor;
      case NotificationCategory.academic:
        return AppColors.vaultColor;
      case NotificationCategory.lostFound:
        return AppColors.lostFoundColor;
      case NotificationCategory.social:
        return AppColors.studyBuddyColor;
      case NotificationCategory.system:
        return AppColors.info;
    }
  }

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.event:
        return Icons.event;
      case NotificationCategory.club:
        return Icons.groups;
      case NotificationCategory.announcement:
        return Icons.campaign;
      case NotificationCategory.mentorship:
        return Icons.school;
      case NotificationCategory.forum:
        return Icons.forum;
      case NotificationCategory.academic:
        return Icons.menu_book;
      case NotificationCategory.lostFound:
        return Icons.search;
      case NotificationCategory.social:
        return Icons.people;
      case NotificationCategory.system:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
