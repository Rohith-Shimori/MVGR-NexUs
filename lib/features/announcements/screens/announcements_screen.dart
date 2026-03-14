import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_announcement_service.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../events/models/event_model.dart';
import '../../council/screens/create_announcement_screen.dart';

/// Premium Announcements Screen with Search
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
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
                        Row(
                          children: [
                            const Text(
                              'Announcements',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.campaign, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Official',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Campus updates & important notices',
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
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search announcements...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // Announcements List
          Consumer<SupabaseAnnouncementService>(
            builder: (context, announcementService, _) {
              var announcements = announcementService.announcements.toList();
              
              // Filter by search query
              if (_searchQuery.isNotEmpty) {
                announcements = announcements.where((a) =>
                    a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    a.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
              }
              
              // Sort: pinned first, then by date
              announcements.sort((a, b) {
                if (a.isPinned && !b.isPinned) return -1;
                if (!a.isPinned && b.isPinned) return 1;
                return b.createdAt.compareTo(a.createdAt);
              });

              if (announcements.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No matching announcements' : 'No announcements yet',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty ? 'Try different search terms' : 'Check back for updates',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: EdgeInsets.only(bottom: index < announcements.length - 1 ? 16 : 0),
                      child: _AnnouncementCard(announcement: announcements[index]),
                    ),
                    childCount: announcements.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // FAB for Council/Faculty to create announcements
      floatingActionButton: context.watch<AuthProvider>().user != null
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateAnnouncementSheet(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.campaign, color: Colors.white),
              label: const Text('Post', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  void _showCreateAnnouncementSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateAnnouncementScreen()),
    );
  }
}

/// Announcement Card
class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.clayDark : AppColors.clayLight,
        borderRadius: BorderRadius.circular(18),
        boxShadow: announcement.isPinned 
            ? SkeuoShadows.floating(AppColors.accent)
            : (isDark 
                ? ClayShadows.dark(intensity: 0.7)
                : ClayShadows.light(intensity: 0.7)),
        border: announcement.isUrgent ? Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
          width: 1.5,
        ) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with badges
          Row(
            children: [
              // Author info
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getRoleColor(announcement.authorRole).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getRoleIcon(announcement.authorRole),
                  color: _getRoleColor(announcement.authorRole),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.authorName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    Text(
                      announcement.authorRole,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getRoleColor(announcement.authorRole),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Badges
              if (announcement.isPinned)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.push_pin, size: 10, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text(
                        'Pinned',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              if (announcement.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.priority_high, size: 10, color: AppColors.error),
                      const SizedBox(width: 2),
                      Text(
                        'Urgent',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            announcement.title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Content
          Text(
            announcement.content,
            style: TextStyle(
              fontSize: 14,
              color: context.appColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          // Footer
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: context.appColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                _formatTime(announcement.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: context.appColors.textTertiary,
                ),
              ),
              if (announcement.expiresAt != null) ...[
                const SizedBox(width: 16),
                Icon(Icons.timer_off_outlined, size: 14, color: context.appColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'Expires ${_formatDate(announcement.expiresAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'faculty':
      case 'academic office':
        return AppColors.info;
      case 'student council':
        return AppColors.primary;
      case 'administration':
        return AppColors.secondary;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'faculty':
      case 'academic office':
        return Icons.school;
      case 'student council':
        return Icons.groups;
      case 'administration':
        return Icons.account_balance;
      default:
        return Icons.campaign;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}


