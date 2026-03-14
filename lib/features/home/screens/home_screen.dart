import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/liquid_glass_widgets.dart';
import '../../../core/widgets/frosted_app_bar.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../services/settings_service.dart';
import '../../../services/supabase_club_service.dart';
import '../../../services/supabase_event_service.dart';
import '../../../services/supabase_announcement_service.dart';
import '../../../core/utils/helpers.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../widgets/home_widgets.dart';

import 'package:get_it/get_it.dart';
import '../../../services/analytics_service.dart' as analytics_svc;

/// Premium Home Screen - Clean, Warm, and Welcoming
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Track screen view
    final analytics = GetIt.instance<analytics_svc.AnalyticsService>();
    analytics.logScreenView('home_screen');
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.userName;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          // Actually refresh data from services
          await Future.wait([
            context.read<SupabaseClubService>().fetchClubs(),
            context.read<SupabaseEventService>().getEvents(),
            context.read<SupabaseAnnouncementService>().fetchAnnouncements(),
          ]);
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium Header
            FrostedSliverAppBar(
              title: '', // Title is in the background for custom greeting
              expandedHeight: 160,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: AuroraBackground(
                  colors: AppColors.auroraGradient,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            NameHelpers.getFirstName(userName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                // Search Button
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  tooltip: 'Search',
                  onPressed: () => Navigator.pushNamed(context, '/search'),
                ),
                // Theme Toggle Button
                IconButton(
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: Colors.white,
                  ),
                  tooltip: isDark
                      ? 'Switch to Light Mode'
                      : 'Switch to Dark Mode',
                  onPressed: () {
                    final settings = SettingsService.instance;
                    settings.themeMode = isDark
                        ? AppThemeMode.light
                        : AppThemeMode.dark;
                    setState(() {});
                  },
                ),
                // Notification Button
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),

                  // Quick Access Section
                  HomeSectionTitle(title: 'Quick Access'),
                  const SizedBox(height: 16),
                  const QuickAccessGrid(),

                  const SizedBox(height: 32),

                  // For You Section - Interest-based recommendations
                  const ForYouSection(),

                  const SizedBox(height: 32),

                  // Announcements
                  const AnnouncementsSection(),

                  const SizedBox(height: 32),

                  // Upcoming Events
                  const UpcomingEventsSection(),

                  const SizedBox(height: 32),

                  // Active Clubs
                  const ActiveClubsSection(),

                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}
