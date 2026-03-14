import '../../../core/widgets/glassmorphic_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';


import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/premium_loading_indicator.dart';
import '../../../services/supabase_meetups_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/meetup_model.dart';
import 'package:intl/intl.dart';

/// Meetups Screen — Offline community gatherings
class MeetupsScreen extends StatefulWidget {
  const MeetupsScreen({super.key});

  @override
  State<MeetupsScreen> createState() => _MeetupsScreenState();
}

class _MeetupsScreenState extends State<MeetupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseMeetupsService>().fetchMeetups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => context.read<SupabaseMeetupsService>().fetchMeetups(),
        child: Consumer<SupabaseMeetupsService>(
            builder: (context, service, _) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 180,
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.meetupsColor,
                              AppColors.meetupsColor.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'Meetups',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Connect with your community offline',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content
                  if (service.isLoading)
                    const SliverFillRemaining(child: ShimmerList())
                  else if (service.meetups.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.groups,
                        title: 'No upcoming meetups',
                        subtitle: 'Be the first to organize a meetup',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _MeetupCard(
                          meetup: service.meetups[index],
                          onTap: () => _showMeetupDetail(service.meetups[index]),
                        ),
                        childCount: service.meetups.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateMeetupSheet(context),
        backgroundColor: AppColors.meetupsColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showMeetupDetail(Meetup meetup) {
    final user = context.read<AuthProvider>().user;
    showGlassModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.meetupsColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(meetup.category.iconData, color: AppColors.meetupsColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meetup.title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${meetup.category.displayName} • Organized by ${meetup.organizerName}',
                        style: TextStyle(fontSize: 13, color: context.appColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (meetup.description.isNotEmpty) ...[
              Text(meetup.description, style: TextStyle(fontSize: 14, color: context.appColors.textSecondary)),
              const SizedBox(height: 16),
            ],
            
            // Details
            _DetailRow(icon: Icons.calendar_today, text: DateFormat('EEE, MMM d • h:mm a').format(meetup.scheduledAt)),
            const SizedBox(height: 8),
            _DetailRow(icon: Icons.location_on, text: meetup.venue + (meetup.venueDetails != null ? ' • ${meetup.venueDetails}' : '')),
            const SizedBox(height: 8),
            _DetailRow(icon: Icons.access_time, text: '${meetup.duration.inHours}h ${meetup.duration.inMinutes % 60}m duration'),
            const SizedBox(height: 24),

            if (user != null && !meetup.isOrganizer(user.id))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Start simplified join flow
                    // In a real app, strict RSVP tracking would be here.
                    // Assuming 'going' for now.
                    final success = await supabaseMeetupsService.joinMeetup(
                      meetupId: meetup.id,
                      userId: user.id,
                      userName: user.name,
                    );
                     if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(success ? 'You are going!' : 'Error joining meetup')),
                        );
                      }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.meetupsColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Join Meetup'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateMeetupSheet(BuildContext context) {
    showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateMeetupSheet(onCreated: () => supabaseMeetupsService.fetchMeetups()),
    );
  }
}

class _MeetupCard extends StatelessWidget {
  final Meetup meetup;
  final VoidCallback onTap;

  const _MeetupCard({required this.meetup, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? ClayShadows.dark(intensity: 0.5) : ClayShadows.light(intensity: 0.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Date Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.meetupsColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.meetupsColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM').format(meetup.scheduledAt).toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.meetupsColor),
                      ),
                      Text(
                        DateFormat('d').format(meetup.scheduledAt),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.meetupsColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meetup.title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.appColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(meetup.scheduledAt) + ' • ' + meetup.venue,
                        style: TextStyle(fontSize: 13, color: context.appColors.textTertiary),
                         maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.appColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.appColors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(meetup.category.iconData, size: 12, color: context.appColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(meetup.category.displayName, style: TextStyle(fontSize: 11, color: context.appColors.textSecondary)),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${meetup.participantIds.length} going', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.appColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: context.appColors.textSecondary))),
      ],
    );
  }
}

class _CreateMeetupSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateMeetupSheet({required this.onCreated});

  @override
  State<_CreateMeetupSheet> createState() => _CreateMeetupSheetState();
}

class _CreateMeetupSheetState extends State<_CreateMeetupSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _venueController = TextEditingController();
  MeetupCategory _category = MeetupCategory.other;
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 2));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    
    if (mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      );
      if (time == null) return;

      setState(() {
        _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      });
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _venueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter title and venue')));
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      await supabaseMeetupsService.createMeetup(
        creatorId: user.id,
        creatorName: user.name,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category.name,
        venue: _venueController.text.trim(),
        dateTime: _scheduledAt,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meetup created!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Host Meetup', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
          const SizedBox(height: 24),
          TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
           TextField(controller: _venueController, decoration: InputDecoration(labelText: 'Venue', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: _descController, maxLines: 3, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          // Date Picker Button
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(DateFormat('EEE, MMM d • h:mm a').format(_scheduledAt), style: TextStyle(fontSize: 16, color: context.appColors.textPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MeetupCategory>(
            value: _category,
            decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: MeetupCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
            onChanged: (v) => setState(() => _category = v ?? MeetupCategory.other),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.meetupsColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isSubmitting ? const PremiumLoadingIndicator.small() : const Text('Host', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
