import 'package:flutter/material.dart';
import '../../../core/widgets/animated_tab_indicator.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/supabase_event_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../events/models/event_model.dart';

/// My Events Screen - Shows events user has RSVP'd to
class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  List<Event> _upcomingEvents = [];
  List<Event> _pastEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final user = context.read<AuthProvider>().user;
    
    if (user != null) {
      final upcoming = await supabaseEventService.getUserEvents(user.id, isPast: false);
      final past = await supabaseEventService.getUserEvents(user.id, isPast: true);
      
      if (mounted) {
        setState(() {
          _upcomingEvents = upcoming;
          _pastEvents = past;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRsvp(Event event) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final success = await supabaseEventService.cancelRsvp(event.id, user.id);
    if (success && mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RSVP cancelled')),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('My Events'),
          backgroundColor: AppColors.eventsColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicator: AnimatedPillTabIndicator(color: Colors.white.withValues(alpha: 0.2)),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Upcoming Events
                  _upcomingEvents.isEmpty
                      ? _EmptyState(
                          icon: Icons.event_available_outlined,
                          title: 'No upcoming events',
                          subtitle: 'RSVP to events to see them here',
                          actionLabel: 'Browse Events',
                          onAction: () => Navigator.pushNamed(context, '/events'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _upcomingEvents.length,
                          itemBuilder: (context, index) => _EventCard(
                            event: _upcomingEvents[index],
                            onCancelRsvp: () => _cancelRsvp(_upcomingEvents[index]),
                          ),
                        ),

                  // Past Events
                  _pastEvents.isEmpty
                      ? _EmptyState(
                          icon: Icons.history,
                          title: 'No past events',
                          subtitle: 'Your attended events will appear here',
                          actionLabel: 'Browse Events',
                          onAction: () => Navigator.pushNamed(context, '/events'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pastEvents.length,
                          itemBuilder: (context, index) => _EventCard(
                            event: _pastEvents[index],
                            isPast: true,
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final bool isPast;
  final VoidCallback? onCancelRsvp;

  const _EventCard({
    required this.event,
    this.isPast = false,
    this.onCancelRsvp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        HapticUtils.lightTap();
        // Navigate to event detail
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? ClayShadows.dark(intensity: 0.6)
              : ClayShadows.light(intensity: 0.6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header with gradient
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPast
                      ? [Colors.grey, Colors.grey.shade600]
                      : [
                          AppColors.eventsColor.withValues(alpha: 0.8),
                          AppColors.eventsColor.withValues(alpha: 0.6),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      event.category.iconData,
                      size: 32,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatDate(event.eventDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: context.appColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venue,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: context.appColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(event.eventDate),
                        style: TextStyle(
                          fontSize: 13,
                          color: context.appColors.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      if (!isPast && onCancelRsvp != null)
                        TextButton(
                          onPressed: onCancelRsvp,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(60, 30),
                          ),
                          child: const Text('Cancel RSVP'),
                        ),
                      if (isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.appColors.textTertiary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Attended',
                            style: TextStyle(
                              color: context.appColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $ampm';
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.eventsColor,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
