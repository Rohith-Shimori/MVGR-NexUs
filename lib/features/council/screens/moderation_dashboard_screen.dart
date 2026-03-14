import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/supabase_club_service.dart';
import '../../../services/supabase_announcement_service.dart';
import '../../../services/supabase_report_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'content_moderation_screen.dart';
import 'create_announcement_screen.dart';
import '../../../core/widgets/frosted_app_bar.dart';

/// Moderation Dashboard - Main hub for council members
class ModerationDashboardScreen extends StatelessWidget {
  const ModerationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canModerate = user?.role.canModerate ?? false;

    if (!canModerate) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moderation')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: context.appColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need council or faculty privileges',
                style: TextStyle(color: context.appColors.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer3<SupabaseClubService, SupabaseAnnouncementService, SupabaseReportService>(
      builder: (context, clubService, announcementService, reportService, _) {
        // Get pending items for moderation
        final pendingClubs = clubService.clubs.where((c) => !c.isApproved).length;
        final announcements = announcementService.announcements.length;
        final flaggedCount = reportService.pendingCount;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              const FrostedSliverAppBar(
                title: 'Moderation Hub',
              ),

              // Stats Overview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _StatCard(
                        icon: Icons.pending_actions,
                        value: '$pendingClubs',
                        label: 'Pending Clubs',
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.campaign,
                        value: '$announcements',
                        label: 'Announcements',
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.flag,
                        value: '$flaggedCount',
                        label: 'Flagged',
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Moderation Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _ActionTile(
                        icon: Icons.campaign,
                        title: 'Create Announcement',
                        subtitle: 'Send important updates to everyone',
                        color: AppColors.primary,
                        badge: null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _ActionTile(
                        icon: Icons.groups,
                        title: 'Club Approvals',
                        subtitle: 'Review pending club requests',
                        color: AppColors.clubsColor,
                        badge: pendingClubs > 0 ? '$pendingClubs' : null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContentModerationScreen(initialTab: 0)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _ActionTile(
                        icon: Icons.flag_outlined,
                        title: 'Flagged Content',
                        subtitle: 'Review reported posts and content',
                        color: AppColors.error,
                        badge: null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContentModerationScreen(initialTab: 1)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _ActionTile(
                        icon: Icons.event,
                        title: 'Event Approvals',
                        subtitle: 'Review pending events',
                        color: AppColors.eventsColor,
                        badge: null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ContentModerationScreen(initialTab: 2)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Activity
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.appColors.divider),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.history, size: 48, color: context.appColors.textTertiary),
                              const SizedBox(height: 12),
                              Text(
                                'No recent activity',
                                style: TextStyle(
                                  color: context.appColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? ClayShadows.dark(intensity: 0.5)
              : ClayShadows.light(intensity: 0.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: context.appColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        HapticUtils.lightTap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? ClayShadows.dark(intensity: 0.5)
              : ClayShadows.light(intensity: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.appColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right, color: context.appColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
