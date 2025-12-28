import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'services/mock_data_service.dart';
import 'services/user_service.dart';
import 'services/settings_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved settings from SharedPreferences
  await SettingsService.instance.loadFromStorage();
  
  runApp(const MVGRNexUsApp());
}

class MVGRNexUsApp extends StatelessWidget {
  const MVGRNexUsApp({super.key});

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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => mockDataService),
        Provider(create: (_) => UserProvider()),
      ],
      // Listen to SettingsService for theme changes
      child: ListenableBuilder(
        listenable: SettingsService.instance,
        builder: (context, _) {
          return MaterialApp(
            title: 'MVGR NexUs',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: _getThemeMode(SettingsService.instance.themeMode),
            home: const MainNavigationScreen(),
            routes: {
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
            },
          );
        },
      ),
    );
  }
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
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
    );
  }
}

/// Explore screen - Clubs, Events, Mentorship
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
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
    );
  }
}

/// Community screen - Forums, Study Buddy, Teams
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: ListView(
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
    );
  }
}

/// Tools screen - Vault, Lost & Found, Radio
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: ListView(
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
    );
  }
}

/// Profile screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = MockUserService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      NameHelpers.getAvatarChar(user.name),
                      style: TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
                  Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Chip(label: Text(user.role.displayName)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats
          Row(
            children: [
              Expanded(child: _StatCard(icon: Icons.groups, value: '3', label: 'Clubs')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(icon: Icons.event, value: '12', label: 'Events')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(icon: Icons.upload_file, value: '5', label: 'Uploads')),
            ],
          ),
          const SizedBox(height: 24),
          
          // Role switcher (Dev only)
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.developer_mode, size: 20),
                      SizedBox(width: 8),
                      Text('Developer Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Switch roles to test different permissions:'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RoleButton(label: 'Student', onTap: () {
                        MockUserService.loginAsStudent();
                        setState(() {});
                      }),
                      _RoleButton(label: 'Club Admin', onTap: () {
                        MockUserService.loginAsClubAdmin();
                        setState(() {});
                      }),
                      _RoleButton(label: 'Council', onTap: () {
                        MockUserService.loginAsCouncil();
                        setState(() {});
                      }),
                      _RoleButton(label: 'Faculty', onTap: () {
                        MockUserService.loginAsFaculty();
                        setState(() {});
                      }),
                    ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RoleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(label),
    );
  }
}
