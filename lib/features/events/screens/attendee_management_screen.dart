import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MockDataService>(
      builder: (context, dataService, _) {
        final event = dataService.getEventById(widget.event.id) ?? widget.event;
        final rsvpIds = event.rsvpIds;

        // Filter by search
        final filteredRsvps = _searchQuery.isEmpty
            ? rsvpIds
            : rsvpIds.where((id) {
                final reg = dataService.getEventRegistration(event.id, id);
                return reg?.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
              }).toList();

        final checkedIn = filteredRsvps.where((id) {
          final reg = dataService.getEventRegistration(event.id, id);
          return reg?.isCheckedIn ?? false;
        }).toList();

        final notCheckedIn = filteredRsvps.where((id) {
          final reg = dataService.getEventRegistration(event.id, id);
          return !(reg?.isCheckedIn ?? false);
        }).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Attendees'),
            backgroundColor: AppColors.eventsColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'All (${filteredRsvps.length})'),
                Tab(text: 'Checked In (${checkedIn.length})'),
                Tab(text: 'Pending (${notCheckedIn.length})'),
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
                    _AttendeeList(
                      attendeeIds: filteredRsvps,
                      event: event,
                      dataService: dataService,
                    ),
                    // Checked In
                    _AttendeeList(
                      attendeeIds: checkedIn,
                      event: event,
                      dataService: dataService,
                      showCheckInButton: false,
                    ),
                    // Pending
                    _AttendeeList(
                      attendeeIds: notCheckedIn,
                      event: event,
                      dataService: dataService,
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showBulkActions(context, event, dataService),
            backgroundColor: AppColors.eventsColor,
            icon: const Icon(Icons.checklist),
            label: const Text('Bulk Actions'),
          ),
        );
      },
    );
  }

  void _showBulkActions(BuildContext context, Event event, MockDataService dataService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Check In All'),
              subtitle: const Text('Mark all attendees as checked in'),
              onTap: () {
                for (final userId in event.rsvpIds) {
                  dataService.checkInAttendee(event.id, userId);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All attendees checked in')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export to CSV'),
              subtitle: const Text('Download attendee list'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Send Reminder'),
              subtitle: const Text('Notify pending attendees'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder sent!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendeeList extends StatelessWidget {
  final List<String> attendeeIds;
  final Event event;
  final MockDataService dataService;
  final bool showCheckInButton;

  const _AttendeeList({
    required this.attendeeIds,
    required this.event,
    required this.dataService,
    this.showCheckInButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (attendeeIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: context.appColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No attendees',
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
        final registration = dataService.getEventRegistration(event.id, userId);
        final isCheckedIn = registration?.isCheckedIn ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCheckedIn
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.eventsColor.withValues(alpha: 0.1),
              child: Icon(
                isCheckedIn ? Icons.check : Icons.person,
                color: isCheckedIn ? AppColors.success : AppColors.eventsColor,
              ),
            ),
            title: Text(
              registration?.userName ?? 'User ${userId.substring(0, 8)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCheckedIn
                      ? 'Checked in at ${_formatTime(registration?.checkedInAt)}'
                      : 'Registered ${_formatDate(registration?.registeredAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCheckedIn ? AppColors.success : context.appColors.textTertiary,
                  ),
                ),
              ],
            ),
            trailing: isCheckedIn
                ? Icon(Icons.check_circle, color: AppColors.success)
                : showCheckInButton
                    ? IconButton(
                        icon: Icon(Icons.qr_code_scanner, color: AppColors.eventsColor),
                        onPressed: () {
                          dataService.checkInAttendee(event.id, userId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Checked in!')),
                          );
                        },
                      )
                    : null,
          ),
        );
      },
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}
