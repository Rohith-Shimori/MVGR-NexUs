import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_club_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/utils/helpers.dart';
import '../models/club_model.dart';
import '../widgets/club_widgets.dart';

/// Club Detail Screen - Full club information view
class ClubDetailScreen extends StatefulWidget {
  final Club club;

  const ClubDetailScreen({super.key, required this.club});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  String _selectedFilter = 'All'; // All, Announcements, Recruitment
  bool _isLoading = true;
  bool _isMember = false;
  bool _isAdmin = false;
  bool _isPending = false;
  List<ClubPost> _posts = [];
  late Club _club;

  @override
  void initState() {
    super.initState();
    _club = widget.club;
    _loadClubData();
  }

  Future<void> _loadClubData() async {
    final user = context.watch<AuthProvider>().user;
    if (user != null) {
      final isMember = await supabaseClubService.isMember(_club.id, user.id);
      final isAdmin = await supabaseClubService.isAdmin(_club.id, user.id);
      final isPending = await supabaseClubService.hasPendingRequest(_club.id, user.id);
      final posts = await supabaseClubService.getClubPosts(_club.id);
      
      if (mounted) {
        setState(() {
          _isMember = isMember;
          _isAdmin = isAdmin;
          _isPending = isPending;
          _posts = posts;
          _isLoading = false;
        });
      }
    } else {
      // Guest mode
       final posts = await supabaseClubService.getClubPosts(_club.id);
       if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadClubData();
    // Also refresh the club details itself
    final refreshedClub = supabaseClubService.getClubById(_club.id);
    if (refreshedClub != null && mounted) {
      setState(() {
        _club = refreshedClub;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter posts
    final filteredPosts = _selectedFilter == 'All' 
        ? _posts 
        : _posts.where((p) => p.type.displayName == _selectedFilter).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.clubsColor,
                        AppColors.clubsColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _club.category.iconData,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Club Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _club.name,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: context.appColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (_club.isOfficial) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.verified, color: AppColors.clubsColor),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _club.category.displayName,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.clubsColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      MemberButton(
                        club: _club, 
                        isMember: _isMember,
                        isPending: _isPending,
                        onChange: _refreshData,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.appColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ClubStat(value: '${_club.totalMembers}', label: 'Members'), // Note: totalMembers might be inaccurate if not updated from Supabase count
                        Container(width: 1, height: 30, color: context.appColors.divider),
                        ClubStat(value: '${_posts.length}', label: 'Posts'),
                        Container(width: 1, height: 30, color: context.appColors.divider),
                        ClubStat(value: '12', label: 'Events'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _club.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.appColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Contact
                  if (_club.contactEmail != null || _club.instagramHandle != null) ...[
                    Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_club.contactEmail != null)
                      ContactRow(
                        icon: Icons.email_outlined,
                        value: _club.contactEmail!,
                      ),
                    if (_club.instagramHandle != null)
                      ContactRow(
                        icon: Icons.camera_alt_outlined,
                        value: '@${_club.instagramHandle}',
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Posts Section Header with Filters
                  Row(
                    children: [
                      Text(
                        'Posts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // Add post button only for admins
                      if (_isAdmin)
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.add_circle_outline, color: AppColors.clubsColor),
                          tooltip: 'New Post',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Announcement'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Recruitment'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Event'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Posts List
                  if (_isLoading)
                     const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else if (filteredPosts.isEmpty)
                    ClubEmptyCard(message: 'No ${_selectedFilter.toLowerCase()} posts yet')
                  else
                    ...filteredPosts.map((post) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PostCard(post: post),
                    )),

                  const SizedBox(height: 60),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
         HapticUtils.selection();
         setState(() => _selectedFilter = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.clubsColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.clubsColor : context.appColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
