/// Empty State Widget
/// Reusable widget for showing empty states across the app
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A beautiful empty state widget with icon, title, subtitle, and optional action
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
  });

  // ─── Preset Factories ─────────────────────────────────

  factory EmptyStateWidget.noClubs({VoidCallback? onExplore}) => EmptyStateWidget(
    icon: Icons.groups_outlined,
    title: 'No Clubs Yet',
    subtitle: 'Join clubs to connect with like-minded peers',
    actionLabel: 'Explore Clubs',
    onAction: onExplore,
  );

  factory EmptyStateWidget.noEvents({VoidCallback? onExplore}) => EmptyStateWidget(
    icon: Icons.event_outlined,
    title: 'No Events Found',
    subtitle: 'Check back later for upcoming campus events',
    actionLabel: 'Refresh',
    onAction: onExplore,
  );

  factory EmptyStateWidget.noResults() => const EmptyStateWidget(
    icon: Icons.search_off_rounded,
    title: 'No Results',
    subtitle: 'Try adjusting your search or filters',
  );

  factory EmptyStateWidget.noData({String? message}) => EmptyStateWidget(
    icon: Icons.inbox_outlined,
    title: 'Nothing Here',
    subtitle: message ?? 'There\'s no data to display right now',
  );

  factory EmptyStateWidget.noNotifications() => const EmptyStateWidget(
    icon: Icons.notifications_off_outlined,
    title: 'All Caught Up',
    subtitle: 'You have no new notifications',
  );

  factory EmptyStateWidget.noLostItems({VoidCallback? onReport}) => EmptyStateWidget(
    icon: Icons.find_in_page_outlined,
    title: 'No Lost Items',
    subtitle: 'No items have been reported lost or found',
    actionLabel: 'Report Item',
    onAction: onReport,
  );

  factory EmptyStateWidget.noForumPosts({VoidCallback? onPost}) => EmptyStateWidget(
    icon: Icons.forum_outlined,
    title: 'No Discussions',
    subtitle: 'Be the first to start a conversation',
    actionLabel: 'Start Discussion',
    onAction: onPost,
  );

  factory EmptyStateWidget.noStudyBuddies({VoidCallback? onPost}) => EmptyStateWidget(
    icon: Icons.school_outlined,
    title: 'No Study Buddies',
    subtitle: 'Post a request to find study partners',
    actionLabel: 'Find Buddies',
    onAction: onPost,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with gradient background
            Container(
              width: iconSize + 40,
              height: iconSize + 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                    AppColors.primaryLight.withValues(alpha: isDark ? 0.08 : 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1C1C1E),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF8E8E93),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            // Optional action button
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
