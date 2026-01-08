import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/user_service.dart';
import '../../interests/screens/interests_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../help/screens/help_support_screen.dart';
import '../../../core/utils/helpers.dart';

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
  BoxDecoration _buildDynamicBackground() {
    final user = MockUserService.currentUser;
    
    switch (user.backgroundType) {
      case 'gradient':
        // Use premium gradients based on saved color
        final gradients = [
          [Color(0xFF667eea), Color(0xFF764ba2)],
          [Color(0xFF11998e), Color(0xFF38ef7d)],
          [Color(0xFFf093fb), Color(0xFFf5576c)],
          [Color(0xFF4facfe), Color(0xFF00f2fe)],
          [Color(0xFFfa709a), Color(0xFFfee140)],
          [Color(0xFF43e97b), Color(0xFF38f9d7)],
        ];
        final colorValue = user.backgroundColorValue ?? AppColors.primary.toARGB32();
        final index = gradients.indexWhere((g) => g[0].toARGB32() == colorValue);
        final gradient = index >= 0 ? gradients[index] : gradients[0];
        return BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      
      case 'image':
        return BoxDecoration(
          image: DecorationImage(
            image: AssetImage(user.backgroundImageUrl ?? 'assets/images/bg_abstract.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.3),
              BlendMode.darken,
            ),
          ),
        );
      
      case 'solid':
      default:
        final color = user.backgroundColorValue != null 
          ? Color(user.backgroundColorValue!) 
          : AppColors.primary;
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = MockUserService.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with dynamic background
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    decoration: _buildDynamicBackground(),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Avatar with scale animation
                            ScaleTransition(
                              scale: _scaleAnim,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        user.profilePhotoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, e, s) => Center(
                                          child: Text(
                                            NameHelpers.getInitials(user.name),
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        NameHelpers.getInitials(user.name),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
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
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                user.role.displayName,
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
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _EditProfileSheet(),
  );
}

/// Edit Profile Sheet - Enhanced with real functionality
class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> with SingleTickerProviderStateMixin {
  final _bioController = TextEditingController();
  late TabController _tabController;
  bool _isLoading = false;
  File? _selectedImage;
  
  // Background customization state
  String _backgroundType = 'color'; // 'color', 'gradient', 'image'
  int _selectedColorIndex = 0;
  int _selectedGradientIndex = 0;
  int _selectedImageIndex = 0;

  static const List<Color> _colors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.success,
    AppColors.clubsColor,
    AppColors.eventsColor,
    AppColors.mentorshipColor,
    AppColors.studyBuddyColor,
    AppColors.playBuddyColor,
  ];

  static const List<List<Color>> _gradients = [
    [Color(0xFF667eea), Color(0xFF764ba2)], // Purple Dream
    [Color(0xFFf093fb), Color(0xFFf5576c)], // Pink Sunset
    [Color(0xFF4facfe), Color(0xFF00f2fe)], // Ocean Blue
    [Color(0xFF43e97b), Color(0xFF38f9d7)], // Fresh Green
    [Color(0xFFfa709a), Color(0xFFfee140)], // Warm Glow
    [Color(0xFF30cfd0), Color(0xFF330867)], // Deep Space
  ];

  static const List<String> _bgImages = [
    'https://picsum.photos/400/200?random=1',
    'https://picsum.photos/400/200?random=2',
    'https://picsum.photos/400/200?random=3',
    'https://picsum.photos/400/200?random=4',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final user = MockUserService.currentUser;
    _bioController.text = user.bio ?? '';
    _backgroundType = user.backgroundType ?? 'color';
    if (user.backgroundColorValue != null) {
      final colorIndex = _colors.indexWhere((c) => c.toARGB32() == user.backgroundColorValue);
      if (colorIndex >= 0) _selectedColorIndex = colorIndex;
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = MockUserService.currentUser;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header with live preview
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _backgroundType == 'gradient'
                  ? LinearGradient(colors: _gradients[_selectedGradientIndex])
                  : null,
              color: _backgroundType == 'color' ? _colors[_selectedColorIndex] : null,
              image: _backgroundType == 'image'
                  ? DecorationImage(
                      image: NetworkImage(_bgImages[_selectedImageIndex]),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        image: _selectedImage != null
                            ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                            : user.profilePhotoUrl != null
                                ? DecorationImage(image: NetworkImage(user.profilePhotoUrl!), fit: BoxFit.cover)
                                : null,
                      ),
                      child: _selectedImage == null && user.profilePhotoUrl == null
                          ? Center(
                              child: Text(
                                NameHelpers.getInitials(user.name),
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                        ),
                        child: Icon(Icons.camera_alt, size: 16, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Tabs for background customization
          TabBar(
            controller: _tabController,
            onTap: (index) {
              setState(() {
                _backgroundType = ['color', 'gradient', 'image'][index];
              });
            },
            labelColor: AppColors.primary,
            unselectedLabelColor: context.appColors.textTertiary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Colors', icon: Icon(Icons.palette, size: 18)),
              Tab(text: 'Gradients', icon: Icon(Icons.gradient, size: 18)),
              Tab(text: 'Images', icon: Icon(Icons.image, size: 18)),
            ],
          ),
          
          // Tab content
          SizedBox(
            height: 70,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Colors
                ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _colors.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedColorIndex = index;
                        _backgroundType = 'color';
                      }),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _colors[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColorIndex == index && _backgroundType == 'color'
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: _selectedColorIndex == index && _backgroundType == 'color'
                              ? [BoxShadow(color: _colors[index].withValues(alpha: 0.5), blurRadius: 8)]
                              : null,
                        ),
                        child: _selectedColorIndex == index && _backgroundType == 'color'
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                  ),
                ),
                // Gradients
                ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _gradients.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedGradientIndex = index;
                        _backgroundType = 'gradient';
                      }),
                      child: Container(
                        width: 60,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: _gradients[index]),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedGradientIndex == index && _backgroundType == 'gradient'
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: _selectedGradientIndex == index && _backgroundType == 'gradient'
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                  ),
                ),
                // Images
                ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _bgImages.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedImageIndex = index;
                        _backgroundType = 'image';
                      }),
                      child: Container(
                        width: 70,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedImageIndex == index && _backgroundType == 'image'
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(_bgImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: _selectedImageIndex == index && _backgroundType == 'image'
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 20),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Bio field
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notice
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
                            'Name, Department & Year are verified by your college email.',
                            style: TextStyle(fontSize: 12, color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    maxLength: 150,
                    decoration: InputDecoration(
                      labelText: 'Bio / About Me',
                      hintText: 'Tell others about yourself...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Generate mock profile photo URL if image was selected
    String? photoUrl;
    if (_selectedImage != null) {
      photoUrl = 'https://picsum.photos/200?random=${DateTime.now().millisecondsSinceEpoch}';
    }

    // Save to MockUserService
    MockUserService.updateProfile(
      bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      profilePhotoUrl: photoUrl,
      backgroundType: _backgroundType,
      backgroundColorValue: _backgroundType == 'color' ? _colors[_selectedColorIndex].toARGB32() : null,
      backgroundImageUrl: _backgroundType == 'image' ? _bgImages[_selectedImageIndex] : null,
    );
    
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

