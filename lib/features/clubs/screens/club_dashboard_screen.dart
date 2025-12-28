import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../../../services/user_service.dart';
import '../models/club_model.dart';
import 'member_management_screen.dart';

/// Club Dashboard Screen - Admin view for managing a club
class ClubDashboardScreen extends StatelessWidget {
  final Club club;

  const ClubDashboardScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    return Consumer<MockDataService>(
      builder: (context, dataService, _) {
        final currentClub = dataService.getClubById(club.id) ?? club;
        final pendingRequests = dataService.getPendingRequestsForClub(club.id);
        final posts = dataService.getClubPosts(club.id);
        final user = MockUserService.currentUser;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
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
                                Text(
                                  currentClub.category.icon,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    currentClub.name,
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
                    onPressed: () => _showClubSettings(context, currentClub, dataService),
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
                        value: '${currentClub.totalMembers}',
                        label: 'Members',
                        color: AppColors.clubsColor,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.article,
                        value: '${posts.length}',
                        label: 'Posts',
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.hourglass_empty,
                        value: '${pendingRequests.length}',
                        label: 'Pending',
                        color: pendingRequests.isNotEmpty ? AppColors.warning : Colors.grey,
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
                              onTap: () => _showCreatePostSheet(context, currentClub, dataService),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.event,
                              label: 'Create Event',
                              color: AppColors.eventsColor,
                              onTap: () => _showCreateEventSheet(context, currentClub),
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
                              badge: pendingRequests.isNotEmpty ? '${pendingRequests.length}' : null,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MemberManagementScreen(club: currentClub),
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
                              onTap: () => _showAnnouncementSheet(context, currentClub, dataService),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Pending Requests Section
              if (pendingRequests.isNotEmpty) ...[
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
                            '${pendingRequests.length}',
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
                              builder: (_) => MemberManagementScreen(club: currentClub),
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
                      itemCount: pendingRequests.take(5).length,
                      itemBuilder: (context, index) {
                        final request = pendingRequests[index];
                        return _PendingRequestCard(
                          request: request,
                          onApprove: () => dataService.approveJoinRequest(request.id, user.uid),
                          onReject: () => dataService.rejectJoinRequest(request.id, user.uid),
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

              if (posts.isEmpty)
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
                          ElevatedButton.icon(
                            onPressed: () => _showCreatePostSheet(context, currentClub, dataService),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Post'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.clubsColor,
                              foregroundColor: Colors.white,
                            ),
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
                      final post = posts[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _PostCard(post: post),
                      );
                    },
                    childCount: posts.take(5).length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePostSheet(BuildContext context, Club club, MockDataService dataService) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    ClubPostType selectedType = ClubPostType.general;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
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
                Text(
                  'Create Post',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Post Type
                Text('Post Type', style: TextStyle(fontWeight: FontWeight.w500, color: context.appColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ClubPostType.values.map((type) => ChoiceChip(
                    label: Text(type.displayName),
                    selected: selectedType == type,
                    onSelected: (selected) => setState(() => selectedType = type),
                    selectedColor: AppColors.clubsColor,
                    labelStyle: TextStyle(
                      color: selectedType == type ? Colors.white : context.appColors.textPrimary,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                        final post = ClubPost(
                          id: 'post_${DateTime.now().millisecondsSinceEpoch}',
                          clubId: club.id,
                          title: titleController.text,
                          content: contentController.text,
                          type: selectedType,
                          authorId: MockUserService.currentUser.uid,
                          authorName: MockUserService.currentUser.name,
                          createdAt: DateTime.now(),
                        );
                        dataService.addClubPost(post);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post created!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.clubsColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Post'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateEventSheet(BuildContext context, Club club) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event creation coming soon!')),
    );
  }

  void _showAnnouncementSheet(BuildContext context, Club club, MockDataService dataService) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcements coming soon!')),
    );
  }

  void _showClubSettings(BuildContext context, Club club, MockDataService dataService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Privacy Settings'),
              onTap: () => Navigator.pop(context),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
  final dynamic request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.userName,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.divider),
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
