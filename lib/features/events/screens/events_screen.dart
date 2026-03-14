
import '../../../core/widgets/animated_tab_indicator.dart';
import '../../../core/widgets/glassmorphic_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/premium_loading_indicator.dart';
import '../../../services/supabase_event_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/event_model.dart';
import 'event_dashboard_screen.dart';

/// Events Screen — Discover campus happenings
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  bool _isLoading = true;
  List<Event> _events = [];

  final _categories = ['All', ...EventCategory.values.map((c) => c.displayName)];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEvents());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await context.read<SupabaseEventService>().getEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Event> get _filteredEvents {
    var filtered = _events;
    if (_selectedCategory != 'All') {
      filtered = filtered.where((e) => e.category.displayName == _selectedCategory).toList();
    }
    return filtered;
  }

  List<Event> get _upcomingEvents =>
      _filteredEvents.where((e) => e.eventDate.isAfter(DateTime.now())).toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

  List<Event> get _pastEvents =>
      _filteredEvents.where((e) => e.eventDate.isBefore(DateTime.now())).toList()
        ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.eventsColor,
                        AppColors.eventsColor.withValues(alpha: 0.7),
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
                            'Events',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Discover campus happenings',
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
              bottom: TabBar(
                controller: _tabController,
                indicator: AnimatedPillTabIndicator(color: AppColors.eventsColor.withValues(alpha: 0.2)),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Past'),
                  Tab(text: 'My Events'),
                ],
              ),
            ),

            // Category Filters
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: _categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(cat, isDark),
                  )).toList(),
                ),
              ),
            ),

            // Content
            if (_isLoading)
              const SliverFillRemaining(child: ShimmerList())
            else
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventsList(_upcomingEvents, 'No upcoming events', 'Check back later for new events'),
                    _buildEventsList(_pastEvents, 'No past events', 'Events you attended will show here'),
                    _buildMyEvents(),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventSheet(context),
        backgroundColor: AppColors.eventsColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isDark) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        HapticUtils.selection();
        setState(() => _selectedCategory = category);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.eventsColor : (isDark ? AppColors.clayDark : AppColors.clayLight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? null : (isDark ? ClayShadows.dark(intensity: 0.4) : ClayShadows.light(intensity: 0.4)),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(List<Event> events, String emptyTitle, String emptySubtitle) {
    if (events.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.event_busy,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) => _EventCard(
        event: events[index],
        onTap: () => _navigateToEvent(events[index]),
      ),
    );
  }

  Widget _buildMyEvents() {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const EmptyStateWidget(
        icon: Icons.login,
        title: 'Sign in required',
        subtitle: 'Log in to see your events',
      );
    }

    return FutureBuilder<List<Event>>(
      future: supabaseEventService.getUserEvents(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: PremiumLoadingIndicator.small());
        }
        final myEvents = snapshot.data ?? [];
        if (myEvents.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.event_available,
            title: 'No registered events',
            subtitle: 'RSVP to events to see them here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: myEvents.length,
          itemBuilder: (context, index) => _EventCard(
            event: myEvents[index],
            onTap: () => _navigateToEvent(myEvents[index]),
          ),
        );
      },
    );
  }

  void _navigateToEvent(Event event) {
    final user = context.read<AuthProvider>().user;
    final isOrganizer = user != null && event.authorId == user.id;

    if (isOrganizer) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDashboardScreen(event: event)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _EventDetailScreen(event: event)),
      );
    }
  }

  void _showCreateEventSheet(BuildContext context) {
    showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateEventSheet(onCreated: _loadEvents),
    );
  }
}

// ─── Event Card ────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? ClayShadows.dark(intensity: 0.5) : ClayShadows.light(intensity: 0.5),
        ),
        child: Row(
          children: [
            // Date badge
            Container(
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.eventsColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _dayOfMonth(event.eventDate),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.eventsColor,
                    ),
                  ),
                  Text(
                    _monthAbbr(event.eventDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.eventsColor,
                    ),
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
                    event.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: context.appColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venue,
                          style: TextStyle(fontSize: 13, color: context.appColors.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.eventsColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.category.displayName,
                          style: TextStyle(fontSize: 11, color: AppColors.eventsColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.people, size: 14, color: context.appColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        '${event.rsvpIds.length}',
                        style: TextStyle(fontSize: 12, color: context.appColors.textTertiary),
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

  String _dayOfMonth(DateTime d) => '${d.day}';
  String _monthAbbr(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return m[d.month - 1];
  }
}

// ─── Event Detail Screen ───────────────────────────────────────
class _EventDetailScreen extends StatefulWidget {
  final Event event;
  const _EventDetailScreen({required this.event});

  @override
  State<_EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<_EventDetailScreen> {
  bool _hasRsvped = false;
  int _rsvpCount = 0;
  bool _isRsvping = false;

  @override
  void initState() {
    super.initState();
    _checkRsvp();
  }

  Future<void> _checkRsvp() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final hasRsvped = await supabaseEventService.hasRsvped(widget.event.id, user.id);
      final count = await supabaseEventService.getRsvpCount(widget.event.id);
      if (mounted) {
        setState(() {
          _hasRsvped = hasRsvped;
          _rsvpCount = count;
        });
      }
    }
  }

  Future<void> _toggleRsvp() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to RSVP')),
      );
      return;
    }

    setState(() => _isRsvping = true);
    try {
      if (_hasRsvped) {
        await supabaseEventService.cancelRsvp(widget.event.id, user.id);
      } else {
        await supabaseEventService.rsvpToEvent(widget.event.id, user.id);
      }
      await _checkRsvp();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRsvping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.eventsColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.eventsColor, AppColors.eventsColor.withValues(alpha: 0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(event.category.icon, style: const TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(
                        event.category.displayName,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hosted by ${event.clubName}',
                    style: TextStyle(fontSize: 14, color: AppColors.eventsColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

                  // Info rows
                  _InfoRow(icon: Icons.calendar_today, text: _formatDate(event.eventDate)),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.access_time, text: _formatTime(event.eventDate)),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.location_on, text: event.venue),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.people, text: '$_rsvpCount attending'),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'About',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.appColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: TextStyle(fontSize: 15, color: context.appColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // RSVP Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isRsvping ? null : _toggleRsvp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasRsvped ? Colors.grey : AppColors.eventsColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isRsvping
                          ? const PremiumLoadingIndicator.small()
                          : Text(
                              _hasRsvped ? 'Cancel RSVP' : 'RSVP Now',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatTime(DateTime d) {
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${d.minute.toString().padLeft(2, '0')} $ampm';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.appColors.textTertiary),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 14, color: context.appColors.textSecondary)),
      ],
    );
  }
}

// ─── Create Event Sheet ────────────────────────────────────────
class _CreateEventSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateEventSheet({required this.onCreated});

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  EventCategory _category = EventCategory.other;
  DateTime _eventDate = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _venueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and venue')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final event = Event(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        clubId: '',
        clubName: user.name,
        authorId: user.id,
        authorName: user.name,
        eventDate: _eventDate,
        venue: _venueController.text.trim(),
        category: _category,
        createdAt: DateTime.now(),
      );

      await supabaseEventService.createEvent(event);
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
          Text(
            'Create Event',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Event Title',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _venueController,
            decoration: InputDecoration(
              labelText: 'Venue',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<EventCategory>(
            value: _category,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: EventCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
            onChanged: (v) => setState(() => _category = v ?? EventCategory.other),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.eventsColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const PremiumLoadingIndicator.small()
                  : const Text('Create Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
