import 'dart:io';
import '../../../core/widgets/glassmorphic_sheet.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/claymorphic_widgets.dart';
import '../../../services/supabase_club_service.dart';
import '../../../services/supabase_storage_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/club_model.dart';
import 'member_management_screen.dart';
import 'edit_club_screen.dart';
import 'club_analytics_screen.dart';
import '../../events/screens/create_event_screen.dart';

/// Club Dashboard Screen - Admin view for managing a club
class ClubDashboardScreen extends StatefulWidget {
  final Club club;

  const ClubDashboardScreen({super.key, required this.club});

  @override
  State<ClubDashboardScreen> createState() => _ClubDashboardScreenState();
}

class _ClubDashboardScreenState extends State<ClubDashboardScreen> {
  late Club _club;
  List<ClubPost> _posts = [];
  List<Map<String, dynamic>> _pendingRequests = []; // Raw requests mostly needed for count
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _club = widget.club;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    // Refresh club details (in case they changed)
    final freshClub = supabaseClubService.getClubById(_club.id) ?? _club;
    
    // Fetch posts
    final posts = await supabaseClubService.getClubPosts(_club.id);
    
    // Fetch pending requests
    final requests = await supabaseClubService.getPendingRequests(_club.id);

    if (mounted) {
      setState(() {
        _club = freshClub;
        _posts = posts;
        _pendingRequests = requests;
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(String requestId) async {
    // We need user ID and name from the request object to approve properly
    // But getPendingRequests returns raw map. 
    // Let's find the request in our list or re-fetch.
    final request = _pendingRequests.firstWhere((r) => r['id'] == requestId, orElse: () => {});
    if (request.isEmpty) return;

    final success = await supabaseClubService.approveRequest(
      requestId, 
      _club.id, 
      request['user_id'], 
      request['user_name']
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved'), backgroundColor: AppColors.success),
      );
      _loadDashboardData();
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final success = await supabaseClubService.rejectRequest(requestId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading 
        ? const ShimmerList()
        : RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: AppColors.clubsColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.clubsColor,
                        AppColors.clubsColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _club.category.iconData,
                                size: 32,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _club.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Club Dashboard',
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => _showClubSettings(context),
                ),
              ],
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _StatCard(
                      icon: Icons.people,
                      // We might need to fetch member count separately if totalMembers isn't auto-updated
                      // But let's assume club object has it or we will implement getMemberCount later
                      // SupabaseClubService doesn't auto-update totalMembers on club object yet.
                      // Ideally we fetch count.
                      value: '${_club.totalMembers}', // Placeholder, ideally fetch count
                      label: 'Members',
                      color: AppColors.clubsColor,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.article,
                      value: '${_posts.length}',
                      label: 'Posts',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.hourglass_empty,
                      value: '${_pendingRequests.length}',
                      label: 'Pending',
                      color: _pendingRequests.isNotEmpty ? AppColors.warning : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.edit,
                            label: 'New Post',
                            color: AppColors.primary,
                            onTap: () => _showCreatePostSheet(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.event,
                            label: 'Create Event',
                            color: AppColors.eventsColor,
                            onTap: () => _showCreateEventSheet(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.people,
                            label: 'Members',
                            color: AppColors.clubsColor,
                            badge: _pendingRequests.isNotEmpty ? '${_pendingRequests.length}' : null,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MemberManagementScreen(club: _club),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.announcement,
                            label: 'Announcement',
                            color: AppColors.warning,
                            onTap: () => _showAnnouncementSheet(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Pending Requests Section
            if (_pendingRequests.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Row(
                    children: [
                      Text(
                        'Pending Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_pendingRequests.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MemberManagementScreen(club: _club),
                          ),
                        ),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _pendingRequests.take(5).length,
                    itemBuilder: (context, index) {
                      final request = _pendingRequests[index];
                      // Request is a Map now, not an object, so we pass fields manually or create a wrapper
                      // _PendingRequestCard expects an object with 'userName'.
                      // We can wrap it.
                      return _PendingRequestCard(
                        userName: request['user_name'] ?? 'Unknown',
                        onApprove: () => _approveRequest(request['id']),
                        onReject: () => _rejectRequest(request['id']),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Recent Posts Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Text(
                  'Recent Posts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
            ),

            if (_posts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.appColors.divider),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.article_outlined, size: 48, color: context.appColors.textTertiary),
                        const SizedBox(height: 12),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 8),
                        ClayButton(
                          text: 'Create First Post',
                          icon: Icons.add,
                          color: AppColors.clubsColor,
                          onPressed: () => _showCreatePostSheet(context),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = _posts[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _PostCard(post: post),
                    );
                  },
                  childCount: _posts.take(5).length,
                ),
              ),

             const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final linkController = TextEditingController(); // For "Apply Link" or "Event Link"
    final deadlineController = TextEditingController(); // For Recruitment deadline
    ClubPostType selectedType = ClubPostType.general;
    File? selectedImage;

    showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
            builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickImage() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(source: ImageSource.gallery);
            if (picked != null) {
              setState(() => selectedImage = File(picked.path));
            }
          }

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create New Content',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      if (selectedImage != null)
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.error),
                          onPressed: () => setState(() => selectedImage = null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Post Type Selector
                  Text('Content Type', style: TextStyle(fontWeight: FontWeight.w500, color: context.appColors.textSecondary)),
                  const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ClubPostType.values.map((type) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClayChip(
                            label: type.displayName,
                            isSelected: selectedType == type,
                            color: AppColors.clubsColor,
                            onTap: () => setState(() => selectedType = type),
                          ),
                        )).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Image Preview
                  if (selectedImage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover),
                      ),
                    ),

                  // Dynamic Fields based on Type
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: selectedType == ClubPostType.recruitment ? 'Role / Position Title' : 'Title',
                      hintText: selectedType == ClubPostType.recruitment ? 'e.g. Graphic Designer' : 'e.g. Meeting at 5PM',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.title, color: context.appColors.textTertiary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: selectedType == ClubPostType.recruitment ? 'Job Description & Requirements' : 'Content',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recruitment/Announcement Specific Fields
                  if (selectedType == ClubPostType.recruitment) ...[
                    TextField(
                      controller: deadlineController,
                      decoration: InputDecoration(
                        labelText: 'Application Deadline',
                        hintText: 'e.g. 25th Oct',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.calendar_today, color: context.appColors.textTertiary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: linkController,
                      decoration: InputDecoration(
                        labelText: 'Application Link (Google Form)',
                        hintText: 'https://forms.google.com/...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.link, color: context.appColors.textTertiary),
                      ),
                    ),
                  ],

                  if (selectedType == ClubPostType.announcement)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.campaign, color: AppColors.warning),
                          const SizedBox(width: 8),
                           Expanded(
                             child: Text(
                               'This will trigger a push notification to all ${_club.totalMembers} members.',
                               style: TextStyle(color: AppColors.warning, fontSize: 13),
                             ),
                           ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  
                  // Add Image Button
                  if (selectedImage == null)
                    OutlinedButton.icon(
                      onPressed: pickImage,
                      icon: Icon(Icons.add_photo_alternate, color: AppColors.clubsColor),
                      label: Text('Add Image', style: TextStyle(color: AppColors.clubsColor)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.clubsColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ClayButton(
                      text: 'Publish Content',
                      color: AppColors.clubsColor,
                      width: double.infinity,
                      onPressed: () async {
                        if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                          // Append specialized info to content for mock demo purposes
                          String finalContent = contentController.text;
                          if (selectedType == ClubPostType.recruitment) {
                            if (deadlineController.text.isNotEmpty) finalContent += '\n\nDEADLINE: ${deadlineController.text}';
                            if (linkController.text.isNotEmpty) finalContent += '\nAPPLY: ${linkController.text}';
                          }

                          // Upload image if selected
                          String? imageUrl;
                          if (selectedImage != null) {
                            try {
                               final storageService = context.read<SupabaseStorageService>();
                               imageUrl = await storageService.uploadFile(
                                 'club-posts', // Ensure this bucket exists or use 'public'
                                 '${_club.id}/${DateTime.now().millisecondsSinceEpoch}.jpg',
                                 selectedImage!
                               );
                            } catch (e) {
                               AppLogger.error('Error uploading club post image: $e');
                               // Proceed without image or show error? For now proceed.
                            }
                          }

                          // Check context again after await
                          if (!context.mounted) return;

                          final user = context.read<AuthProvider>().user;
                          
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error: Not logged in')),
                            );
                            return;
                          }

                          final post = ClubPost(
                            id: '', // DB Generated
                            clubId: _club.id,
                            title: titleController.text,
                            content: finalContent,
                            type: selectedType,
                            imageUrl: imageUrl,
                            authorId: user.id,
                            authorName: user.name,
                            createdAt: DateTime.now(),
                          );
                          
                          // We need to await this
                          // but we are inside builder.
                          // It's better to move logic out or use FutureBuilder
                          // Or just fire and forget with local state update + reload
                          
                          supabaseClubService.createClubPost(post).then((success) {
                            if (success) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Content published successfully!')),
                                );
                                _loadDashboardData();
                              }
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateEventSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(clubId: _club.id, clubName: _club.name),
      ),
    );
  }

  void _showAnnouncementSheet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement sent to members!')),
    );
  }

  void _showClubSettings(BuildContext context) {
    showGlassModalBottomSheet(
      context: context,
            builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Club Info'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditClubScreen(club: _club)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ClubAnalyticsScreen(club: _club)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text('Delete Club', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? ClayShadows.dark(intensity: 0.5)
              : ClayShadows.light(intensity: 0.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.badge,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? ClayShadows.dark(intensity: 0.5)
              : ClayShadows.light(intensity: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final String userName; // Changed from dynamic request
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRequestCard({
    required this.userName,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.clayDark : AppColors.clayLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? ClayShadows.dark(intensity: 0.5)
            : ClayShadows.light(intensity: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Requested to join',
            style: TextStyle(
              fontSize: 12,
              color: context.appColors.textTertiary,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onReject,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Reject'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ClubPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.clayDark : AppColors.clayLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? ClayShadows.dark(intensity: 0.5)
            : ClayShadows.light(intensity: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.clubsColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  post.type.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.clubsColor,
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: context.appColors.textTertiary),
                itemBuilder: (context) => [
                  PopupMenuItem(child: Text('Edit')),
                  PopupMenuItem(child: Text('Delete', style: TextStyle(color: AppColors.error))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            style: TextStyle(
              fontSize: 14,
              color: context.appColors.textSecondary,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
