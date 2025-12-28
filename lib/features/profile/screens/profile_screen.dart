import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/user_service.dart';
import '../../interests/screens/interests_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../help/screens/help_support_screen.dart';
import '../../../core/utils/helpers.dart';

/// Premium Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockUserService.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              NameHelpers.getInitials(user.name),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.role.displayName,
                            style: TextStyle(
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

          // Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.school,
                    value: user.department,
                    label: 'Branch',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.calendar_today,
                    value: 'Year ${user.year}',
                    label: 'Current',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.interests,
                    value: '${user.interests.length}',
                    label: 'Interests',
                    isDark: isDark,
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
                children: user.interests.take(6).map((interest) => Container(
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

          // Settings Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Settings',
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
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage push notifications',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      ),
                      isDark: isDark,
                    ),
                    _Divider(isDark: isDark),
                    _SettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Appearance',
                      subtitle: 'Dark mode & themes',
                      trailing: Text(
                        isDark ? 'Dark' : 'Light',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                      isDark: isDark,
                    ),
                    _Divider(isDark: isDark),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy',
                      subtitle: 'Control your data',
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
                    _Divider(isDark: isDark),
                    _SettingsTile(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      subtitle: 'Log out of your account',
                      iconColor: AppColors.error,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text('Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Signed out (demo mode)')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );
                      },
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
                      'Version 1.0.0 Beta',
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.dividerDark : context.appColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 8),
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
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.dividerDark : context.appColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
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
    this.trailing,
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _EditProfileSheet(),
  );
}

/// Edit Profile Sheet - Only cosmetic changes allowed
/// Name/Department/Year tied to college email verification
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _bioController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = MockUserService.currentUser;
    
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
              'Edit Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personalize your profile appearance',
              style: TextStyle(
                fontSize: 13,
                color: context.appColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        NameHelpers.getInitials(user.name),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Photo upload coming soon!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Fixed info notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Name, Department & Year are verified by your college email and cannot be changed here.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Profile Background Color
            Text(
              'Profile Background',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ColorOption(color: AppColors.primary, isSelected: true),
                _ColorOption(color: AppColors.accent, isSelected: false),
                _ColorOption(color: AppColors.success, isSelected: false),
                _ColorOption(color: AppColors.clubsColor, isSelected: false),
                _ColorOption(color: AppColors.eventsColor, isSelected: false),
                _ColorOption(color: AppColors.mentorshipColor, isSelected: false),
                _ColorOption(color: AppColors.studyBuddyColor, isSelected: false),
                _ColorOption(color: AppColors.playBuddyColor, isSelected: false),
              ],
            ),
            const SizedBox(height: 20),
            
            // Bio field
            TextField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                labelText: 'Bio / About Me',
                hintText: 'Tell others about yourself...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 50),
                  child: Icon(Icons.edit_note),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Color Option for profile background
class _ColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;

  const _ColorOption({required this.color, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Background color changed!'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: isSelected 
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}
