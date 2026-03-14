import 'package:flutter/material.dart';
import '../../../core/widgets/premium_loading_indicator.dart';
import '../../../core/widgets/claymorphic_widgets.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/animations.dart';
import '../../../services/supabase_announcement_service.dart';
import '../../../services/supabase_event_service.dart';
import '../../../services/supabase_club_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../services/supabase_meetups_service.dart';
import '../../../services/suggestion_service.dart';

/// Section Title Widget - Reusable across home sections
class HomeSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const HomeSectionTitle({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('See all'),
          ),
      ],
    );
  }
}

/// Quick Access Grid - Grid of navigation items
class QuickAccessGrid extends StatelessWidget {
  const QuickAccessGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isModerator = user?.role.canModerate ?? false;

    // Base items available to everyone
    final items = [
      QuickItem(
        icon: Icons.groups_outlined,
        label: 'Clubs',
        color: AppColors.clubsColor,
        route: '/clubs',
      ),
      QuickItem(
        icon: Icons.event_outlined,
        label: 'Events',
        color: AppColors.eventsColor,
        route: '/events',
      ),
      QuickItem(
        icon: Icons.forum_outlined,
        label: 'Forum',
        color: AppColors.forumColor,
        route: '/forum',
      ),
      QuickItem(
        icon: Icons.folder_outlined,
        label: 'Vault',
        color: AppColors.vaultColor,
        route: '/vault',
      ),
      // Moderator-only item
      if (isModerator)
        const QuickItem(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Council',
          color: AppColors.primary,
          route: '/moderation',
        ),
      QuickItem(
        icon: Icons.search,
        label: 'Lost & Found',
        color: AppColors.lostFoundColor,
        route: '/lost_found',
      ),
      QuickItem(
        icon: Icons.school_outlined,
        label: 'Study Buddy',
        color: AppColors.studyBuddyColor,
        route: '/study_buddy',
      ),
      QuickItem(
        icon: Icons.sports_esports_outlined,
        label: 'Teams',
        color: AppColors.playBuddyColor,
        route: '/teams',
      ),
      QuickItem(
        icon: Icons.radio_outlined,
        label: 'Radio',
        color: AppColors.radioColor,
        route: '/radio',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => StaggeredListAnimation(
        index: index,
        baseDelay: const Duration(milliseconds: 40),
        child: items[index],
      ),
    );
  }
}

/// Quick Access Item with optional image support and tap animation
class QuickItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final String? imagePath;

  const QuickItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    this.imagePath,
  });

  @override
  State<QuickItem> createState() => _QuickItemState();
}

class _QuickItemState extends State<QuickItem> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticUtils.lightTap();
        Navigator.pushNamed(context, widget.route);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: LiquidCurves.flow,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.clayDark : AppColors.clayLight,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _isPressed
                      ? ClayShadows.pressed(isDark)
                      : (isDark 
                          ? ClayShadows.dark(intensity: 0.6)
                          : ClayShadows.light(intensity: 0.6)),
                ),
                child: widget.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          widget.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(widget.icon, color: widget.color, size: 26),
                        ),
                      )
                    : Icon(widget.icon, color: widget.color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Announcements Section
class AnnouncementsSection extends StatelessWidget {
  const AnnouncementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseAnnouncementService>(
      builder: (context, announcementService, _) {
        final announcements = announcementService.announcements.take(3).toList();

        if (announcements.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionTitle(
              title: 'Announcements',
              onSeeAll: () => Navigator.pushNamed(context, '/announcements'),
            ),
            const SizedBox(height: 16),
            ...announcements.map(
              (announcement) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnnouncementCard(
                  title: announcement.title,
                  source: announcement.authorRole,
                  isPinned: announcement.isPinned,
                  isUrgent: announcement.isUrgent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Announcement Card
class AnnouncementCard extends StatelessWidget {
  final String title;
  final String source;
  final bool isPinned;
  final bool isUrgent;

  const AnnouncementCard({
    super.key,
    required this.title,
    required this.source,
    this.isPinned = false,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppColors.warning.withValues(alpha: 0.08)
            : (isDark ? AppColors.clayDark : AppColors.clayLight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? AppColors.warning.withValues(alpha: 0.3)
              : (isDark 
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.5)),
        ),
        boxShadow: isDark 
            ? ClayShadows.dark(intensity: 0.5)
            : ClayShadows.light(intensity: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isPinned
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPinned ? Icons.push_pin : Icons.campaign_outlined,
              color: isPinned ? AppColors.accent : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  source,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Upcoming Events Section
class UpcomingEventsSection extends StatefulWidget {
  const UpcomingEventsSection({super.key});

  @override
  State<UpcomingEventsSection> createState() => _UpcomingEventsSectionState();
}

class _UpcomingEventsSectionState extends State<UpcomingEventsSection> {
  late Future<List<dynamic>> _eventsFuture;
  final _eventService = supabaseEventService;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _eventService.getEvents();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        final events = (snapshot.data ?? []).take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionTitle(
              title: 'Upcoming Events',
              onSeeAll: () => Navigator.pushNamed(context, '/events'),
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              _buildEventSkeleton()
            else if (events.isEmpty)
              HomeEmptyCard(
                icon: Icons.event_outlined,
                message: 'No upcoming events',
              )
            else
              ...events.map((event) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EventCard(
                    title: event.title,
                    date: event.eventDate,
                    venue: event.venue,
                    rsvpCount: event.rsvpCount,
                    hasRSVP: false, // Simplified for now
                    onRSVP: () {
                      // Navigate to event detail for full RSVP
                      Navigator.pushNamed(context, '/events');
                    },
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildEventSkeleton() {
    return ShimmerLoading(
      child: Column(
        children: List.generate(2, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        )),
      ),
    );
  }
}

/// Event Card
class EventCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final String venue;
  final int rsvpCount;
  final bool hasRSVP;
  final VoidCallback onRSVP;

  const EventCard({
    super.key,
    required this.title,
    required this.date,
    required this.venue,
    required this.rsvpCount,
    required this.hasRSVP,
    required this.onRSVP,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.clayDark : AppColors.clayLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark 
            ? ClayShadows.dark(intensity: 0.5)
            : ClayShadows.light(intensity: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date Badge
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.eventsColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.eventsColor,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getMonthAbbr(date.month),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.eventsColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Event Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: context.appColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue,
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
                  const SizedBox(height: 2),
                  Text(
                    '$rsvpCount going',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // RSVP Button
            SizedBox(
              height: 36,
              child: hasRSVP
                  ? OutlinedButton(
                      onPressed: onRSVP,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text(
                        'Going',
                        style: TextStyle(fontSize: 13),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: onRSVP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('RSVP', style: TextStyle(fontSize: 13)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return months[month - 1];
  }
}

/// Active Clubs Section
class ActiveClubsSection extends StatelessWidget {
  const ActiveClubsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // SupabaseClubService is not a ChangeNotifier, so use a FutureBuilder with proper async call
    return FutureBuilder<List<dynamic>>(
      future: _fetchClubs(),
      builder: (context, snapshot) {
        final clubs = (snapshot.data ?? []).take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionTitle(
              title: 'Active Clubs',
              onSeeAll: () => Navigator.pushNamed(context, '/clubs'),
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const SizedBox(height: 100, child: Center(child: PremiumLoadingIndicator()))
            else if (clubs.isEmpty)
              const SizedBox(
                height: 100,
                child: Center(child: Text('No clubs yet')),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: clubs.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final club = clubs[index];
                    return ClubChip(
                      name: club.name,
                      iconData: club.category.iconData,
                      memberCount: club.totalMembers,
                      onTap: () => Navigator.pushNamed(context, '/clubs'),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<List<dynamic>> _fetchClubs() async {
    await SupabaseClubService.instance.fetchClubs();
    return SupabaseClubService.instance.clubs;
  }
}

/// Club Chip with Material Icon
class ClubChip extends StatelessWidget {
  final String name;
  final IconData iconData;
  final int memberCount;
  final VoidCallback onTap;

  const ClubChip({
    super.key,
    required this.name,
    required this.iconData,
    required this.memberCount,
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
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark 
              ? ClayShadows.dark(intensity: 0.6)
              : ClayShadows.light(intensity: 0.6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.clubsColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: AppColors.clubsColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              '$memberCount members',
              style: TextStyle(
                fontSize: 10,
                color: context.appColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty Card - Shows when section has no content
class HomeEmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const HomeEmptyCard({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClayContainer(
      padding: const EdgeInsets.all(32),
      borderRadius: 14,
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: context.appColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: context.appColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// For You Section - Interest-based recommendations
class ForYouSection extends StatelessWidget {
  const ForYouSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    final interests = user.interests;

    return Consumer3<SupabaseClubService, SupabaseEventService, SupabaseMeetupsService>(
      builder: (context, clubService, eventService, meetupService, _) {
        final suggestionService = SuggestionService(clubService, eventService, meetupService);

        // If no interests set, show prompt to set them
        if (interests.isEmpty) {
          return const SetInterestsPrompt();
        }

        final suggestions = suggestionService.getAllRecommendations(interests);

        // If no recommendations available
        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'For You',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/interests'),
                  child: const Text('Edit Interests'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Based on your interests: ${interests.take(3).join(', ')}${interests.length > 3 ? '...' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),

            // Recommended Clubs
            if (suggestions.clubs.isNotEmpty) ...[
              Text(
                'Clubs for you',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.clubs.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final club = suggestions.clubs[index];
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/clubs'),
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.appColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  club.category.iconData,
                                  size: 16,
                                  color: AppColors.clubsColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    club.category.displayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.clubsColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              club.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Recommended Events
            if (suggestions.events.isNotEmpty) ...[
              Text(
                'Events for you',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.events.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final event = suggestions.events[index];
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/events'),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.appColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  event.category.iconData,
                                  size: 16,
                                  color: AppColors.eventsColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatEventDate(event.eventDate),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.eventsColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Recommended Meetups
            if (suggestions.meetups.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Meetups for you',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 85,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.meetups.length,
                  separatorBuilder: (_, i) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final meetup = suggestions.meetups[index];
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/meetups'),
                      child: Container(
                        width: 180,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.appColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.groups,
                                  size: 14,
                                  color: AppColors.mentorshipColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  meetup.category.displayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.mentorshipColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              meetup.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${meetup.participantIds.length} attending',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.appColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return 'In ${diff.inDays} days';
    return '${date.day}/${date.month}';
  }
}

/// Prompt to set interests if empty
class SetInterestsPrompt extends StatelessWidget {
  const SetInterestsPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 32, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'Personalize Your Experience',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Set your interests to get recommendations for clubs, events, and more!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.appColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/interests'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Set Your Interests'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
