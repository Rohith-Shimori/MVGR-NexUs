import '../models/report_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';

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
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Clubs'),
            Tab(text: 'Flagged'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: Consumer<MockDataService>(
        builder: (context, dataService, _) {
          final pendingClubs = dataService.allClubs.where((c) => !c.isApproved).toList();
          final pendingEvents = dataService.events.where((e) => !e.isPast).toList(); // In real app, check isApproved
          final pendingReports = dataService.pendingReports;

          return TabBarView(
            controller: _tabController,
            children: [
              // Clubs Tab
              _ClubApprovalTab(
                pendingClubs: pendingClubs,
                dataService: dataService,
              ),
              
              // Flagged Content Tab
              _FlaggedContentTab(
                reports: pendingReports,
                dataService: dataService,
              ),
              
              // Events Tab (Mocking pending approval by showing all future events for now)
              _EventsTab(
                events: pendingEvents,
                dataService: dataService,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClubApprovalTab extends StatelessWidget {
  final List<dynamic> pendingClubs;
  final MockDataService dataService;

  const _ClubApprovalTab({
    required this.pendingClubs,
    required this.dataService,
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
          onApprove: () {
            final approved = club.copyWith(isApproved: true);
            dataService.updateClub(approved);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${club.name} approved!')),
            );
          },
          onReject: () => _showRejectDialog(context, club.name, (reason) {
             // In real app, update club status to rejected
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${club.name} rejected')),
              );
          }),
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, String name, Function(String) onConfirm) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject $name?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Provide feedback...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm(reasonController.text);
            },
            child: Text('Reject', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _FlaggedContentTab extends StatelessWidget {
  final List<Report> reports;
  final MockDataService dataService;

  const _FlaggedContentTab({
    required this.reports,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
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
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Reported for ${report.reason.name.toUpperCase()}',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(report.timestamp),
                      style: TextStyle(color: context.appColors.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.appColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.targetTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.targetPreview,
                        style: TextStyle(
                          color: context.appColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Reason details: ${report.description}',
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          dataService.dismissReport(report.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Report dismissed')),
                          );
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Dismiss'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          dataService.deleteContent(report.targetId, report.type);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Content deleted & report resolved')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete Content'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }
}

class _EventsTab extends StatelessWidget {
  final List<dynamic> events;
  final MockDataService dataService;

  const _EventsTab({
    required this.events,
    required this.dataService,
  });

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
          metadata: 'Hosted by: ${event.clubName}',
          onApprove: () {
             // In real app, set event.isApproved = true
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('${event.title} approved!')),
             );
          },
          onReject: () {
            // In real app, reject event
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
