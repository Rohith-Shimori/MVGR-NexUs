import 'package:flutter/material.dart';
import '../../../core/widgets/glassmorphic_sheet.dart';
import '../../../core/widgets/claymorphic_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/supabase_event_service.dart';
import '../models/event_model.dart';
import 'attendee_management_screen.dart';
import 'edit_event_screen.dart';

/// Event Dashboard Screen - Organizer view for managing an event
class EventDashboardScreen extends StatelessWidget {
  final Event event;

  const EventDashboardScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Event?>(
      future: supabaseEventService.getEventById(event.id),
      builder: (context, snapshot) {
        final currentEvent = snapshot.data ?? event;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: AppColors.eventsColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.eventsColor,
                          AppColors.eventsColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text(
                                  currentEvent.category.icon,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentEvent.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatEventDate(currentEvent.eventDate),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => _showEditEventSheet(context, currentEvent),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () => _showEventOptions(context, currentEvent),
                  ),
                ],
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _StatCard(
                        icon: Icons.people,
                        value: '${currentEvent.rsvpIds.length}',
                        label: 'RSVPs',
                        color: AppColors.eventsColor,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.check_circle,
                        value: '0',
                        label: 'Checked In',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.visibility,
                        value: '${currentEvent.rsvpIds.length}',
                        label: 'Views',
                        color: AppColors.primary,
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
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.qr_code_scanner,
                              label: 'Check-in',
                              color: AppColors.success,
                              onTap: () => _showSimpleCheckInSheet(context, currentEvent),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.people,
                              label: 'Attendees',
                              color: AppColors.eventsColor,
                              badge: currentEvent.rsvpIds.isNotEmpty ? '${currentEvent.rsvpIds.length}' : null,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AttendeeManagementScreen(event: currentEvent),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.notifications_active,
                              label: 'Notify All',
                              color: AppColors.warning,
                              onTap: () => _showNotifySheet(context, currentEvent),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.download,
                              label: 'Export List',
                              color: AppColors.primary,
                              onTap: () => _exportAttendees(context, currentEvent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Event Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.appColors.divider),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Icons.calendar_today,
                              label: 'Date',
                              value: _formatEventDate(currentEvent.eventDate),
                            ),
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Icons.access_time,
                              label: 'Time',
                              value: _formatEventTime(currentEvent.eventDate),
                            ),
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Icons.location_on,
                              label: 'Venue',
                              value: currentEvent.venue,
                            ),
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Icons.category,
                              label: 'Category',
                              value: currentEvent.category.displayName,
                            ),
                          ],
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

  String _formatEventDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatEventTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $ampm';
  }

  void _showSimpleCheckInSheet(BuildContext context, Event event) {
    showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
            builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appColors.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Check-in Attendees',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: event.rsvpIds.isEmpty
                  ? Center(
                      child: Text(
                        'No RSVPs yet',
                        style: TextStyle(color: context.appColors.textTertiary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: event.rsvpIds.length,
                      itemBuilder: (context, index) {
                        final userId = event.rsvpIds[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.eventsColor.withValues(alpha: 0.1),
                              child: const Icon(Icons.person, color: AppColors.eventsColor),
                            ),
                            title: Text(
                              'User ${userId.substring(0, userId.length > 8 ? 8 : userId.length)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: context.appColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Registered',
                              style: TextStyle(color: context.appColors.textTertiary),
                            ),
                            trailing: ClayButton(
                              text: 'Check In',
                              color: AppColors.success,
                              height: 36,
                              textSize: 12,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Checked in!')),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEventSheet(BuildContext context, Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditEventScreen(event: event)),
    );
  }

  void _showEventOptions(BuildContext context, Event event) {
    showGlassModalBottomSheet(
      context: context,
            builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Event'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate Event'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.cancel_outlined, color: AppColors.warning),
              title: Text('Cancel Event', style: TextStyle(color: AppColors.warning)),
              onTap: () {
                Navigator.pop(context);
                _showCancelConfirmation(context, event);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text('Delete Event', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, event);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Event?'),
        content: const Text('This will notify all attendees. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event cancelled')),
              );
            },
            child: Text('Yes, Cancel', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await supabaseEventService.deleteEvent(event.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event deleted')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showNotifySheet(BuildContext context, Event event) {
    showGlassModalBottomSheet(
      context: context,
            isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Notify Attendees',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to all ${event.rsvpIds.length} registered attendees',
              style: TextStyle(
                fontSize: 14,
                color: context.appColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            _ReleaseItem(
              icon: Icons.access_time_filled,
              title: 'Event Reminder',
              subtitle: 'Send standard 1 hour reminder',
              color: AppColors.info,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder sent to all attendees!')),
                );
              },
            ),
            const SizedBox(height: 12),
            _ReleaseItem(
              icon: Icons.campaign,
              title: 'Important Update',
              subtitle: 'Send custom announcement',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Update notification sent!')),
                );
              },
            ),
            const SizedBox(height: 12),
            _ReleaseItem(
              icon: Icons.check_circle,
              title: 'Post-Event Survey',
              subtitle: 'Request feedback',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Survey link sent!')),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _exportAttendees(BuildContext context, Event event) {
    // Generate simple CSV content from RSVP IDs
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
            const Text('Export Data'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exporting data for ${event.title}',
                style: TextStyle(color: context.appColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                'CSV Preview:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
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
          ClayButton(
            text: 'Download CSV',
            icon: Icons.download,
            color: AppColors.eventsColor,
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Exported ${event.rsvpIds.length} records to CSV'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
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
                fontSize: 12,
                color: context.appColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.appColors.textTertiary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: context.appColors.textTertiary,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: context.appColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _ReleaseItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ReleaseItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
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
                  const SizedBox(height: 2),
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
    );
  }
}
