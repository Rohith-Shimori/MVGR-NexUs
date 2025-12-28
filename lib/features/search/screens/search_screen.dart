import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';

/// Global Search Screen - Search across all features
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Clubs',
    'Events',
    'Vault',
    'Lost & Found',
    'Study Buddy',
    'Teams',
    'Meetups',
    'Mentors',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, 
            color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildSearchField(isDark),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // Category Chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                    backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? AppColors.primary 
                          : (isDark ? AppColors.textSecondaryDark : context.appColors.textSecondary),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected 
                            ? AppColors.primary 
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          
          // Search Results
          Expanded(
            child: _query.isEmpty
                ? _buildEmptyState(isDark)
                : _buildSearchResults(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
        style: TextStyle(
          color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search anything...',
          hintStyle: TextStyle(
            color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary,
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                    color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 80,
            color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Search across MVGR NexUs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find clubs, events, study materials, and more',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return Consumer<MockDataService>(
      builder: (context, dataService, _) {
        final results = <_SearchResult>[];
        
        // Search Clubs
        if (_selectedCategory == 'All' || _selectedCategory == 'Clubs') {
          for (final club in dataService.clubs) {
            if (club.name.toLowerCase().contains(_query) ||
                club.description.toLowerCase().contains(_query)) {
              results.add(_SearchResult(
                title: club.name,
                subtitle: club.category.displayName,
                icon: club.category.iconData,
                iconColor: AppColors.clubsColor,
                type: 'Club',
                route: '/clubs',
              ));
            }
          }
        }

        // Search Events
        if (_selectedCategory == 'All' || _selectedCategory == 'Events') {
          for (final event in dataService.upcomingEvents) {
            if (event.title.toLowerCase().contains(_query) ||
                event.description.toLowerCase().contains(_query)) {
              results.add(_SearchResult(
                title: event.title,
                subtitle: event.category.displayName,
                icon: event.category.iconData,
                iconColor: AppColors.eventsColor,
                type: 'Event',
                route: '/events',
              ));
            }
          }
        }

        // Search Vault Items
        if (_selectedCategory == 'All' || _selectedCategory == 'Vault') {
          for (final item in dataService.vaultItems) {
            if (item.title.toLowerCase().contains(_query) ||
                item.subject.toLowerCase().contains(_query)) {
              results.add(_SearchResult(
                title: item.title,
                subtitle: '${item.subject} • ${item.type.displayName}',
                icon: item.type.iconData,
                iconColor: AppColors.vaultColor,
                type: 'Vault',
                route: '/vault',
              ));
            }
          }
        }

        // Search Lost & Found
        if (_selectedCategory == 'All' || _selectedCategory == 'Lost & Found') {
          for (final item in dataService.lostFoundItems) {
            if (item.title.toLowerCase().contains(_query) ||
                item.description.toLowerCase().contains(_query)) {
              results.add(_SearchResult(
                title: item.title,
                subtitle: '${item.status.displayName} • ${item.category.displayName}',
                icon: item.category.iconData,
                iconColor: AppColors.lostFoundColor,
                type: 'Lost & Found',
                route: '/lost_found',
              ));
            }
          }
        }

        // Search Study Buddy Requests
        if (_selectedCategory == 'All' || _selectedCategory == 'Study Buddy') {
          for (final request in dataService.studyRequests) {
            if (request.subject.toLowerCase().contains(_query) ||
                request.topic.toLowerCase().contains(_query) ||
                request.description.toLowerCase().contains(_query)) {
              results.add(_SearchResult(
                title: '${request.subject}: ${request.topic}',
                subtitle: request.preferredMode.displayName,
                icon: request.preferredMode.iconData,
                iconColor: AppColors.studyBuddyColor,
                type: 'Study Buddy',
                route: '/study_buddy',
              ));
            }
          }
        }

        // Search Team Requests
        if (_selectedCategory == 'All' || _selectedCategory == 'Teams') {
          for (final team in dataService.teamRequests) {
            if (team.title.toLowerCase().contains(_query) ||
                team.description.toLowerCase().contains(_query) ||
                (team.eventName?.toLowerCase().contains(_query) ?? false)) {
              results.add(_SearchResult(
                title: team.title,
                subtitle: '${team.category.displayName} • ${team.spotsLeft} spots left',
                icon: team.category.iconData,
                iconColor: AppColors.playBuddyColor,
                type: 'Team',
                route: '/teams',
              ));
            }
          }
        }

        // Search Meetups
        if (_selectedCategory == 'All' || _selectedCategory == 'Meetups') {
          for (final meetup in dataService.meetups) {
            if (meetup.title.toLowerCase().contains(_query) ||
                meetup.description.toLowerCase().contains(_query) ||
                meetup.venue.toLowerCase().contains(_query)) {
              results.add(_SearchResult(
                title: meetup.title,
                subtitle: '${meetup.category.displayName} • ${meetup.venue}',
                icon: meetup.category.iconData,
                iconColor: AppColors.meetupsColor,
                type: 'Meetup',
                route: '/meetups',
              ));
            }
          }
        }

        // Search Mentors
        if (_selectedCategory == 'All' || _selectedCategory == 'Mentors') {
          for (final mentor in dataService.mentors) {
            if (mentor.name.toLowerCase().contains(_query) ||
                mentor.bio.toLowerCase().contains(_query) ||
                mentor.expertise.any((e) => e.toLowerCase().contains(_query))) {
              results.add(_SearchResult(
                title: mentor.name,
                subtitle: mentor.type.displayName,
                icon: mentor.type.iconData,
                iconColor: AppColors.mentorshipColor,
                type: 'Mentor',
                route: '/mentorship',
              ));
            }
          }
        }

        if (results.isEmpty) {
          return _buildNoResults(isDark);
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final result = results[index];
            return _SearchResultCard(result: result, isDark: isDark);
          },
        );
      },
    );
  }

  Widget _buildNoResults(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: isDark ? AppColors.textTertiaryDark : context.appColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or category',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : context.appColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search result model
class _SearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String type;
  final String route;

  _SearchResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.type,
    required this.route,
  });
}

/// Search result card widget
class _SearchResultCard extends StatelessWidget {
  final _SearchResult result;
  final bool isDark;

  const _SearchResultCard({required this.result, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, result.route),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: result.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  result.icon,
                  color: result.iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : context.appColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: result.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: result.iconColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
