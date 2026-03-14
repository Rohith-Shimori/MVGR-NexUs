import 'package:flutter/material.dart';
import '../../../core/widgets/animated_tab_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_event_service.dart';
import '../models/event_model.dart';

/// Attendee Management Screen - View and manage event attendees
class AttendeeManagementScreen extends StatefulWidget {
  final Event event;

  const AttendeeManagementScreen({super.key, required this.event});

  @override
  State<AttendeeManagementScreen> createState() => _AttendeeManagementScreenState();
}

class _AttendeeManagementScreenState extends State<AttendeeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Event?>(
      future: supabaseEventService.getEventById(widget.event.id),
      builder: (context, snapshot) {
        final event = snapshot.data ?? widget.event;
        final rsvpIds = event.rsvpIds;

        // Filter by search
        final filteredRsvps = _searchQuery.isEmpty
            ? rsvpIds
            : rsvpIds.where((id) => id.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Attendees'),
            backgroundColor: AppColors.eventsColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicator: AnimatedPillTabIndicator(color: Colors.white.withValues(alpha: 0.2)),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'All (${filteredRsvps.length})'),
                Tab(text: 'Actions'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search attendees...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
              ),

              // Tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // All Attendees
                    _buildAttendeeList(filteredRsvps, event),
                    // Actions Tab
                    _buildActionsTab(event),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendeeList(List<String> attendeeIds, Event event) {
    if (attendeeIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: context.appColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No attendees yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: attendeeIds.length,
      itemBuilder: (context, index) {
        final userId = attendeeIds[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.eventsColor.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: AppColors.eventsColor),
            ),
            title: Text(
              'User ${userId.substring(0, userId.length > 8 ? 8 : userId.length)}...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Registered',
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textTertiary,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.qr_code_scanner, color: AppColors.eventsColor),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checked in!')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionsTab(Event event) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionCard(
            icon: Icons.check_circle_outline,
            title: 'Check In All',
            subtitle: 'Mark all attendees as checked in',
            color: AppColors.success,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All attendees checked in')),
              );
            },
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.download,
            title: 'Export to CSV',
            subtitle: 'Download attendee list',
            color: AppColors.primary,
            onTap: () => _showExportDialog(context, event),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.notifications_active,
            title: 'Send Reminder',
            subtitle: 'Notify all attendees',
            color: AppColors.warning,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminder sent!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, Event event) {
    // Generate simple CSV content
    final csvRows = <String>['User ID,Status'];
    for (final userId in event.rsvpIds) {
      csvRows.add('$userId,Registered');
    }
    final csvContent = csvRows.join('\n');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.table_chart, color: AppColors.eventsColor),
            const SizedBox(width: 10),
            const Text('Export Attendees'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${event.rsvpIds.length} attendees will be exported',
                style: TextStyle(color: context.appColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.appColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.appColors.divider),
                ),
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(
                    csvContent,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exported ${event.rsvpIds.length} attendees to CSV'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download CSV'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.eventsColor),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.appColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
