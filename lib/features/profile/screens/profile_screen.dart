import 'package:flutter/material.dart';
import '../../../core/widgets/glassmorphic_sheet.dart';
import '../../../core/widgets/frosted_app_bar.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/claymorphic_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../interests/screens/interests_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../help/screens/help_support_screen.dart';
import '../../../core/utils/helpers.dart';
import '../widgets/edit_profile_sheet.dart';
import '../../../services/app_version_service.dart';

/// Premium Profile Screen with dynamic background
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Build dynamic background based on user's saved settings
  BoxDecoration _buildDynamicBackground(BuildContext context) {
    // Default to primary gradient (simplified - background customization will be added later)
    return BoxDecoration(
      gradient: LinearGradient(
        colors: AppColors.primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Fallback for unauthenticated state
    final userName = user?.name ?? 'User';
    final userEmail = user?.email ?? '';
    final userRole = user?.role.displayName ?? 'Student';
    final userDept = user?.department ?? 'Unknown';
    final userYear = user?.year ?? 1;
    final userRollNo = user?.rollNumber ?? '—';
    final userInterests = user?.interests ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with dynamic background
          FrostedSliverAppBar(
            title: '', // Title is in the background
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
                tooltip: 'Notifications',
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                tooltip: 'Settings',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) => FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    decoration: _buildDynamicBackground(context),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Avatar with scale animation + clay depth
                            ScaleTransition(
                              scale: _scaleAnim,
                              child: ClayAvatar(
                                size: 80,
                                imageUrl: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                                    ? user.photoUrl
                                    : null,
                                initials: NameHelpers.getInitials(userName),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                userRole,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Stats — 2x2 grid for Branch, Year, Roll No, Interests
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.school,
                        value: userDept,
                        label: 'Branch',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.calendar_today,
                        value: 'Year $userYear',
                        label: 'Current',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.badge,
                        value: userRollNo,
                        label: 'Roll No',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.interests,
                        value: '${userInterests.length}',
                        label: 'Interests',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Interests Section
          SliverToBoxAdapter(
            child: _SectionCard(
              title: 'My Interests',
              subtitle: 'Personalize your experience',
              icon: Icons.favorite_outline,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InterestsScreen()),
              ),
              isDark: isDark,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: userInterests.take(6).map((interest) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),

          // My Activity Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'My Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.dividerDark : context.appColors.divider),
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.groups_outlined,
                      title: 'My Clubs',
                      subtitle: 'Clubs you\'ve joined',
                      iconColor: AppColors.clubsColor,
                      onTap: () => Navigator.pushNamed(context, '/my_clubs'),
                      isDark: isDark,
                    ),
                    _Divider(isDark: isDark),
                    _SettingsTile(
                      icon: Icons.event_available_outlined,
                      title: 'My Events',
                      subtitle: 'Events you\'ve RSVP\'d to',
                      iconColor: AppColors.eventsColor,
                      onTap: () => Navigator.pushNamed(context, '/my_events'),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Quick Actions Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.dividerDark : context.appColors.divider),
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'Notifications, appearance, privacy & more',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                      isDark: isDark,
                    ),
                    _Divider(isDark: isDark),
                    _SettingsTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'FAQs and contact us',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                      ),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Account Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.dividerDark : context.appColors.divider),
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      subtitle: 'Update your information',
                      onTap: () => _showEditProfileSheet(context),
                      isDark: isDark,
                    ),

                  ],
                ),
              ),
            ),
          ),

          // App Version
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'MVGR NexUs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : context.appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppVersionService.instance.displayVersion,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat Card
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark 
              ? ClayShadows.dark(intensity: 0.6)
              : ClayShadows.light(intensity: 0.6),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section Card
class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final VoidCallback onTap;
  final bool isDark;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          HapticUtils.lightTap();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.clayDark : AppColors.clayLight,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isDark 
                ? ClayShadows.dark(intensity: 0.6)
                : ClayShadows.light(intensity: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings Tile
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing, // ignore: unused_element_parameter - May be used in future
    this.iconColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
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
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Divider
class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(
        height: 1,
        color: isDark ? AppColors.dividerDark : context.appColors.divider,
      ),
    );
  }
}

/// Show Edit Profile Sheet
void _showEditProfileSheet(BuildContext context) {
  showGlassModalBottomSheet(
    context: context,
    isScrollControlled: true,
        builder: (context) => const EditProfileSheet(),
  );
}
