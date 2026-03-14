import 'package:flutter/material.dart';
import 'core/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'services/supabase_club_service.dart';
import 'services/supabase_event_service.dart';
import 'services/supabase_announcement_service.dart';
import 'services/supabase_vault_service.dart';
import 'services/supabase_forum_service.dart';
import 'services/supabase_study_buddy_service.dart';
import 'services/supabase_play_buddy_service.dart';
import 'services/supabase_lost_found_service.dart';
import 'services/supabase_radio_service.dart';
import 'services/supabase_meetups_service.dart';
import 'services/supabase_mentorship_service.dart';
import 'services/supabase_feedback_service.dart';
import 'services/supabase_report_service.dart';
import 'services/supabase_storage_service.dart';
import 'services/settings_service.dart';
import 'services/audio_service.dart';

import 'config/supabase_config.dart';
import 'core/utils/helpers.dart';
import 'features/home/screens/home_screen.dart';
import 'features/clubs/screens/clubs_screen.dart';
import 'features/events/screens/events_screen.dart';
import 'features/academic_forum/screens/forum_screen.dart';
import 'features/vault/screens/vault_screen.dart';
import 'features/lost_found/screens/lost_found_screen.dart';
import 'features/study_buddy/screens/study_buddy_screen.dart';
import 'features/play_buddy/screens/play_buddy_screen.dart';
import 'features/radio/screens/radio_screen.dart';
import 'features/offline_community/screens/meetups_screen.dart';
// Premium screens
import 'features/profile/screens/profile_screen.dart' as profile;
import 'features/profile/screens/my_clubs_screen.dart';
import 'features/profile/screens/my_events_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/help/screens/help_support_screen.dart';
import 'features/announcements/screens/announcements_screen.dart';
import 'features/mentorship/screens/mentorship_screen.dart';
import 'features/interests/screens/interests_screen.dart';
import 'features/search/screens/search_screen.dart';
import 'features/council/screens/moderation_dashboard_screen.dart';
import 'features/faculty/screens/faculty_dashboard_screen.dart';
import 'core/widgets/mini_player.dart';
import 'core/widgets/frosted_app_bar.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'services/favorites_service.dart';
import 'services/notification_service.dart' as notification;
import 'services/app_version_service.dart';
import 'services/realtime_service.dart';

// New clean architecture imports
import 'core/di/injection.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (optional - for local development)
  // In production, use --dart-define flags instead
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    AppLogger.warning(' .env not found - using dart-define values');
  }
  
  // Load saved settings and favorites
  await SettingsService.instance.loadFromStorage();
  await FavoritesService.instance.init();
  
  // Initialize Supabase FIRST (required for auth)
  await SupabaseConfig.initialize();
  
  // Initialize new DI system
  await initDependencies();
  
  // Initialize app version service
  await AppVersionService.instance.init();
  
  // Initialize realtime service
  await realtimeService.initialize();
  
  // Initialize audio service for radio playback
  await audioService.initialize();
  
  // Initialize notification service for realtime push notifications
  await notification.NotificationService.instance.initializeRealtime();
  
  // Initialize non-core Supabase services (fetch initial data)
  // Use Future.wait to parallelize and try-catch to handle failures gracefully
  try {
    await Future.wait([
      supabaseStudyBuddyService.fetchRequests(),
      supabasePlayBuddyService.fetchTeams(),
      supabaseLostFoundService.fetchItems(),
      supabaseRadioService.fetchTracks(),
      supabaseMeetupsService.fetchMeetups(),
      supabaseMentorshipService.fetchMentors(),
    ], eagerError: false);
  } catch (e) {
    AppLogger.warning('Some services failed to initialize: $e');
  }
  
  // Supabase services initialized
  AppLogger.info(' Data Source: Supabase');
  
  // Check if onboarding completed
  final showOnboarding = !await OnboardingScreen.isCompleted();
  
  runApp(MVGRNexUsApp(showOnboarding: showOnboarding));
}

class MVGRNexUsApp extends StatefulWidget {
  final bool showOnboarding;
  
  const MVGRNexUsApp({super.key, this.showOnboarding = false});

  @override
  State<MVGRNexUsApp> createState() => _MVGRNexUsAppState();
}

class _MVGRNexUsAppState extends State<MVGRNexUsApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Widget _buildHome(AuthProvider authProvider) {
    // Show onboarding first
    if (_showOnboarding) {
      return OnboardingScreen(
        onComplete: () => setState(() => _showOnboarding = false),
      );
    }
    
    // Check auth state - show login if not authenticated
    if (!authProvider.isAuthenticated) {
      return LoginScreen(
        onLoginSuccess: () => setState(() {}),
      );
    }
    
    // Show main app
    return const MainNavigationScreen();
  }

  @override
  Widget build(BuildContext context) {
    // Get AuthProvider instance explicitly for merge
    final authProvider = sl<AuthProvider>();

    return MultiProvider(
      providers: [
        // NEW: Auth from clean architecture DI
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        
        // Core Supabase Services — all use .instance singletons
        ChangeNotifierProvider<SupabaseClubService>.value(value: SupabaseClubService.instance),
        ChangeNotifierProvider<SupabaseEventService>.value(value: SupabaseEventService()),
        ChangeNotifierProvider<SupabaseAnnouncementService>.value(value: SupabaseAnnouncementService.instance),
        ChangeNotifierProvider<SupabaseVaultService>.value(value: SupabaseVaultService.instance),
        ChangeNotifierProvider<SupabaseForumService>.value(value: SupabaseForumService.instance),
        // Non-Core Supabase Services — all use factory singleton pattern
        ChangeNotifierProvider<SupabaseStudyBuddyService>.value(value: SupabaseStudyBuddyService()),
        ChangeNotifierProvider<SupabasePlayBuddyService>.value(value: SupabasePlayBuddyService()),
        ChangeNotifierProvider<SupabaseLostFoundService>.value(value: SupabaseLostFoundService()),
        ChangeNotifierProvider<SupabaseRadioService>.value(value: SupabaseRadioService()),
        ChangeNotifierProvider<SupabaseMeetupsService>.value(value: SupabaseMeetupsService()),
        ChangeNotifierProvider<SupabaseMentorshipService>.value(value: SupabaseMentorshipService()),
        ChangeNotifierProvider<SupabaseFeedbackService>.value(value: SupabaseFeedbackService.instance),
        ChangeNotifierProvider<SupabaseReportService>.value(value: SupabaseReportService.instance),
        ChangeNotifierProvider<SupabaseStorageService>.value(value: SupabaseStorageService.instance),
        // Audio service for radio playback
        ChangeNotifierProvider<AudioService>.value(value: audioService),
      ],
      // Listen to SettingsService and AuthProvider for changes
      child: ListenableBuilder(
        listenable: Listenable.merge([SettingsService.instance, authProvider]),
        builder: (context, _) {
          return MaterialApp(
            title: 'MVGR NexUs',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: _getThemeMode(SettingsService.instance.themeMode),
            home: _buildHome(authProvider),
            onGenerateRoute: (settings) {
              final routes = <String, WidgetBuilder>{
                '/clubs': (context) => const ClubsScreen(),
                '/events': (context) => const EventsScreen(),
                '/forum': (context) => const AcademicForumScreen(),
                '/vault': (context) => const VaultScreen(),
                '/lost_found': (context) => const LostFoundScreen(),
                '/study_buddy': (context) => const StudyBuddyScreen(),
                '/teams': (context) => const PlayBuddyScreen(),
                '/radio': (context) => const RadioScreen(),
                '/meetups': (context) => const MeetupsScreen(),
                // Premium screens
                '/announcements': (context) => const AnnouncementsScreen(),
                '/mentorship': (context) => const MentorshipScreen(),
                '/interests': (context) => const InterestsScreen(),
                '/settings': (context) => const SettingsScreen(),
                '/notifications': (context) => const NotificationsScreen(),
                '/help': (context) => const HelpSupportScreen(),
                '/profile': (context) => const profile.ProfileScreen(),
                '/my_clubs': (context) => const MyClubsScreen(),
                '/my_events': (context) => const MyEventsScreen(),
                '/moderation': (context) => const ModerationDashboardScreen(),
                '/faculty': (context) => const FacultyDashboardScreen(),
                '/search': (context) => const GlobalSearchScreen(),
                '/login': (context) => LoginScreen(
                  onLoginSuccess: () => Navigator.of(context).pushReplacementNamed('/'),
                ),
              };

              final builder = routes[settings.name];
              if (builder != null) {
                return _buildPageRoute(builder, settings);
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

/// Builds a page route with a smooth slide-up + fade transition
PageRouteBuilder _buildPageRoute(WidgetBuilder builder, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        child: FadeTransition(
          opacity: curve,
          child: child,
        ),
      );
    },
  );
}

/// Main screen with bottom navigation
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const CommunityScreen(),
    const ToolsScreen(),
    const profile.ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              HapticUtils.selection();
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Community',
              ),
              NavigationDestination(
                icon: Icon(Icons.construction_outlined),
                selectedIcon: Icon(Icons.construction),
                label: 'Tools',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Explore screen - Clubs, Events, Mentorship
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const FrostedSliverAppBar(title: 'Explore'),
          SliverFillRemaining(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  context.read<SupabaseClubService>().fetchClubs(),
                  context.read<SupabaseEventService>().getEvents(),
                  context.read<SupabaseMentorshipService>().fetchMentors(),
                  context.read<SupabaseMeetupsService>().fetchMeetups(),
                ]);
              },
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _FeatureTile(
                    icon: Icons.groups,
                    title: 'Clubs & Committees',
                    subtitle: 'Join student organizations',
                    color: AppColors.clubsColor,
                    onTap: () => Navigator.pushNamed(context, '/clubs'),
                  ),
                  _FeatureTile(
                    icon: Icons.event,
                    title: 'Events',
                    subtitle: 'Discover campus events',
                    color: AppColors.eventsColor,
                    onTap: () => Navigator.pushNamed(context, '/events'),
                  ),
                  _FeatureTile(
                    icon: Icons.school,
                    title: 'Mentorship',
                    subtitle: 'Find guidance from seniors & faculty',
                    color: AppColors.mentorshipColor,
                    onTap: () => Navigator.pushNamed(context, '/mentorship'),
                  ),
                  _FeatureTile(
                    icon: Icons.calendar_today,
                    title: 'Meetups',
                    subtitle: 'Join offline gatherings',
                    color: AppColors.meetupsColor,
                    onTap: () => Navigator.pushNamed(context, '/meetups'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Community screen - Forums, Study Buddy, Teams
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const FrostedSliverAppBar(title: 'Community'),
          SliverFillRemaining(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  context.read<SupabaseForumService>().fetchQuestions(),
                  context.read<SupabaseStudyBuddyService>().fetchRequests(),
                  context.read<SupabasePlayBuddyService>().fetchTeams(),
                ]);
              },
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _FeatureTile(
                    icon: Icons.forum,
                    title: 'Discussion Forum',
                    subtitle: 'Ask doubts & help others',
                    color: AppColors.forumColor,
                    onTap: () => Navigator.pushNamed(context, '/forum'),
                  ),
                  _FeatureTile(
                    icon: Icons.school,
                    title: 'Study Buddy',
                    subtitle: 'Find study partners',
                    color: AppColors.studyBuddyColor,
                    onTap: () => Navigator.pushNamed(context, '/study_buddy'),
                  ),
                  _FeatureTile(
                    icon: Icons.sports_esports,
                    title: 'Team Finder',
                    subtitle: 'Build teams for competitions',
                    color: AppColors.playBuddyColor,
                    onTap: () => Navigator.pushNamed(context, '/teams'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tools screen - Vault, Lost & Found, Radio
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const FrostedSliverAppBar(title: 'Tools'),
          SliverFillRemaining(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  context.read<SupabaseVaultService>().fetchItems(),
                  context.read<SupabaseLostFoundService>().fetchItems(),
                  context.read<SupabaseRadioService>().fetchTracks(),
                ]);
              },
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _FeatureTile(
                    icon: Icons.folder_copy,
                    title: 'The Vault',
                    subtitle: 'Academic resources & notes',
                    color: AppColors.vaultColor,
                    onTap: () => Navigator.pushNamed(context, '/vault'),
                  ),
                  _FeatureTile(
                    icon: Icons.search,
                    title: 'Lost & Found',
                    subtitle: 'Report or find lost items',
                    color: AppColors.lostFoundColor,
                    onTap: () => Navigator.pushNamed(context, '/lost_found'),
                  ),
                  _FeatureTile(
                    icon: Icons.radio,
                    title: 'Campus Radio',
                    subtitle: 'Request songs & shoutouts',
                    color: AppColors.radioColor,
                    onTap: () => Navigator.pushNamed(context, '/radio'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ProfileScreen removed (dead code, replaced by features/profile/screens/profile_screen.dart)

// Helper widgets
class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? ClayShadows.dark(intensity: 0.6)
              : ClayShadows.light(intensity: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Icon(icon, color: color, size: 26)),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.appColors.textSecondary,
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


