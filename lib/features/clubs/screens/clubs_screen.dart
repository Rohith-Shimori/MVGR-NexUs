import 'package:flutter/material.dart';
import '../../../core/widgets/glassmorphic_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/widgets/claymorphic_widgets.dart';
import '../../../services/supabase_club_service.dart';
import '../models/club_model.dart';
import '../widgets/club_widgets.dart';
import 'club_detail_screen.dart';

/// Premium Clubs Screen - Discovery Focused
class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ClubCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Fetch clubs when screen loads
    if (supabaseClubService.clubs.isEmpty) {
      supabaseClubService.fetchClubs();
    }
  }

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
                      AppColors.clubsColor,
                      AppColors.clubsColor.withValues(alpha: 0.8),
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
                        const Text(
                          'Clubs & Committees',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find your community',
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
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final user = auth.user;
                  if (user != null && user.role.canCreateClub) {
                    return IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      onPressed: () => _showCreateClubSheet(context),
                      tooltip: 'Create Club',
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Pull to refresh
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              HapticUtils.pullToRefresh();
              await supabaseClubService.fetchClubs();
            },
          ),

          // Search and Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.appColors.divider),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search clubs...',
                        hintStyle: TextStyle(color: context.appColors.textTertiary),
                        prefixIcon: Icon(Icons.search, color: context.appColors.textTertiary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Chips (Clay 3D design)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ClayChip(
                          label: 'All',
                          isSelected: _selectedCategory == null,
                          onTap: () => setState(() => _selectedCategory = null),
                        ),
                        ...ClubCategory.values.map((category) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ClayChip(
                            label: category.displayName,
                            icon: category.iconData,
                            isSelected: _selectedCategory == category,
                            onTap: () => setState(() => _selectedCategory = category),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Clubs List
          ListenableBuilder(
            listenable: supabaseClubService,
            builder: (context, _) {
              if (supabaseClubService.isLoading && supabaseClubService.clubs.isEmpty) {
                return SliverFillRemaining(
                  child: _buildClubSkeleton(),
                );
              }

              var clubs = supabaseClubService.approvedClubs.where((club) {
                final matchesSearch = _searchQuery.isEmpty ||
                    club.name.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchesCategory = _selectedCategory == null ||
                    club.category == _selectedCategory;
                return matchesSearch && matchesCategory;
              }).toList();

                if (clubs.isEmpty) {
                  return SliverFillRemaining(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: ClubEmptyCard(
                        message: supabaseClubService.error != null
                            ? 'Error loading clubs: ${supabaseClubService.error}'
                            : 'No clubs found. Try adjusting your search or filters.',
                      ),
                    ),
                  );
                }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => StaggeredListAnimation(
                      index: index,
                      baseDelay: const Duration(milliseconds: 50),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClubCard(
                          club: clubs[index],
                          onTap: () => Navigator.push(
                            context,
                            AppPageTransitions.scaleFade(
                              page: ClubDetailScreen(club: clubs[index]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    childCount: clubs.length,
                  ),
                ),
              );
            },
          ),

          // Bottom Padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showCreateClubSheet(BuildContext context) {
    showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
            builder: (context) => const CreateClubSheet(),
    );
  }

  Widget _buildClubSkeleton() {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
