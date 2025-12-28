import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../../../services/user_service.dart';
import '../models/club_model.dart';
import '../widgets/club_widgets.dart';

/// Club Detail Screen - Full club information view
class ClubDetailScreen extends StatelessWidget {
  final Club club;

  const ClubDetailScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    return Consumer<MockDataService>(
      builder: (context, dataService, _) {
        final currentClub = dataService.getClubById(club.id) ?? club;
        final user = MockUserService.currentUser;
        final isMember = currentClub.isMember(user.uid);
        final posts = dataService.getClubPosts(currentClub.id);

        return Scaffold(
          body: CustomScrollView(
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
                      child: Text(
                        currentClub.category.icon,
                        style: TextStyle(fontSize: 80),
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
                                      currentClub.name,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: context.appColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (currentClub.isOfficial) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.verified, color: AppColors.clubsColor),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentClub.category.displayName,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.clubsColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        MemberButton(club: currentClub, isMember: isMember),
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
                          ClubStat(value: '${currentClub.totalMembers}', label: 'Members'),
                          Container(width: 1, height: 30, color: context.appColors.divider),
                          ClubStat(value: '${posts.length}', label: 'Posts'),
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
                      currentClub.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.appColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact
                    if (currentClub.contactEmail != null || currentClub.instagramHandle != null) ...[
                      Text(
                        'Contact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (currentClub.contactEmail != null)
                        ContactRow(
                          icon: Icons.email_outlined,
                          value: currentClub.contactEmail!,
                        ),
                      if (currentClub.instagramHandle != null)
                        ContactRow(
                          icon: Icons.camera_alt_outlined,
                          value: '@${currentClub.instagramHandle}',
                        ),
                      const SizedBox(height: 24),
                    ],

                    // Recent Posts
                    Text(
                      'Recent Posts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (posts.isEmpty)
                      ClubEmptyCard(message: 'No posts yet')
                    else
                      ...posts.take(3).map((post) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PostCard(post: post),
                      )),

                    const SizedBox(height: 60),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
