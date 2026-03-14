import 'package:flutter/material.dart';
import '../../../core/widgets/animated_tab_indicator.dart';
import '../../../core/widgets/premium_loading_indicator.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_club_service.dart';
import '../../../services/supabase_event_service.dart';
import '../../../services/supabase_report_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Content Moderation Screen - Review and moderate content
class ContentModerationScreen extends StatefulWidget {
  final int initialTab;

  const ContentModerationScreen({super.key, this.initialTab = 0});

  @override
  State<ContentModerationScreen> createState() => _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Content Moderation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicator: AnimatedPillTabIndicator(color: Colors.white.withValues(alpha: 0.2)),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Clubs'),
            Tab(text: 'Flagged'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: Consumer2<SupabaseClubService, SupabaseEventService>(
        builder: (context, clubService, eventService, _) {
          final pendingClubs = clubService.clubs.where((c) => !c.isApproved).toList();
          final pendingEvents = eventService.events.where((e) => !e.isPast).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Clubs Tab
              _ClubApprovalTab(
                pendingClubs: pendingClubs,
                clubService: clubService,
              ),
              
              // Flagged Content Tab - Simplified
              _FlaggedContentTab(),
              
              // Events Tab
              _EventsTab(events: pendingEvents),
            ],
          );
        },
      ),
    );
  }
}

class _ClubApprovalTab extends StatelessWidget {
  final List<dynamic> pendingClubs;
  final SupabaseClubService clubService;

  const _ClubApprovalTab({
    required this.pendingClubs,
    required this.clubService,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingClubs.isEmpty) {
      return _EmptyState(
        icon: Icons.check_circle_outline,
        title: 'All caught up!',
        subtitle: 'No pending club approvals',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingClubs.length,
      itemBuilder: (context, index) {
        final club = pendingClubs[index];
        return _ApprovalCard(
          icon: club.category.icon,
          title: club.name,
          subtitle: club.description,
          metadata: 'Category: ${club.category.displayName}',
          onApprove: () async {
            await clubService.approveClub(club.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${club.name} approved!')),
              );
            }
          },
          onReject: () {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('${club.name} rejected')),
             );
          },
        );
      },
    );
  }
}

class _FlaggedContentTab extends StatefulWidget {
  const _FlaggedContentTab();

  @override
  State<_FlaggedContentTab> createState() => _FlaggedContentTabState();
}

class _FlaggedContentTabState extends State<_FlaggedContentTab> {
  @override
  void initState() {
    super.initState();
    context.read<SupabaseReportService>().fetchPendingReports();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseReportService>(
      builder: (context, reportService, _) {
        if (reportService.isLoading) {
          return const Center(child: PremiumLoadingIndicator());
        }

        final reports = reportService.reports.where((r) => r.status == ReportStatus.pending).toList();

        if (reports.isEmpty) {
          return _EmptyState(
            icon: Icons.flag_outlined,
            title: 'No flagged content',
            subtitle: 'Content reported by users will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _ReportCard(
              report: report,
              onResolve: () => _resolveReport(report.id),
              onDismiss: () => _dismissReport(report.id),
            );
          },
        );
      },
    );
  }

  Future<void> _resolveReport(String reportId) async {
    final userId = context.read<AuthProvider>().user?.id ?? 'unknown';
    final success = await context.read<SupabaseReportService>().updateReportStatus(
      reportId: reportId,
      newStatus: ReportStatus.actionTaken,
      reviewerId: userId,
      actionNotes: 'Content reviewed and action taken',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Report resolved' : 'Failed to resolve'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _dismissReport(String reportId) async {
    final userId = context.read<AuthProvider>().user?.id ?? 'unknown';
    final success = await context.read<SupabaseReportService>().updateReportStatus(
      reportId: reportId,
      newStatus: ReportStatus.dismissed,
      reviewerId: userId,
      actionNotes: 'Report dismissed - no action needed',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Report dismissed' : 'Failed to dismiss'),
        backgroundColor: success ? AppColors.warning : AppColors.error,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ContentReport report;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;

  const _ReportCard({
    required this.report,
    required this.onResolve,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getReasonColor(report.reason).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.reason.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getReasonColor(report.reason),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.appColors.divider,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.contentType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              report.additionalDetails ?? 'No description provided',
              style: TextStyle(
                fontSize: 14,
                color: context.appColors.textPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Reported ${_formatDate(report.createdAt)} • ${report.contentType}',
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onResolve,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    child: const Text('Take Action'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getReasonColor(ReportReason reason) {
    return switch (reason) {
      ReportReason.spam => AppColors.warning,
      ReportReason.harassment => AppColors.error,
      ReportReason.inappropriateContent => Colors.orange,
      ReportReason.violatesGuidelines => Colors.deepOrange,
      ReportReason.impersonation => Colors.purple,
      ReportReason.misinformation => AppColors.info,
      ReportReason.other => AppColors.secondary,
    };
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _EventsTab extends StatelessWidget {
  final List<dynamic> events;

  const _EventsTab({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _EmptyState(
        icon: Icons.event_available,
        title: 'No pending events',
        subtitle: 'All events are approved',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.take(20).length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _ApprovalCard(
          icon: event.category.icon,
          title: event.title,
          subtitle: '${event.venue} • ${_formatDate(event.eventDate)}',
          metadata: 'Hosted by: ${event.clubName ?? 'Campus'}',
          onApprove: () {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('${event.title} approved!')),
             );
          },
          onReject: () {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('${event.title} rejected')),
             );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _ApprovalCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String metadata;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.metadata,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metadata,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: context.appColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: context.appColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: context.appColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
