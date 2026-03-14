import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/claymorphic_widgets.dart';
import '../../../services/supabase_club_service.dart';
import '../../../services/supabase_event_service.dart';
import '../../../services/supabase_vault_service.dart';

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
  bool _isLoading = false;
  List<_SearchResult> _results = [];

  final List<String> _categories = [
    'All',
    'Clubs',
    'Events',
    'Vault',
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

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _query = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _query = query.toLowerCase();
    });

    final results = <_SearchResult>[];
    final clubService = context.read<SupabaseClubService>();
    final eventService = context.read<SupabaseEventService>();
    final vaultService = context.read<SupabaseVaultService>();

    // Search Clubs
    if (_selectedCategory == 'All' || _selectedCategory == 'Clubs') {
      for (final club in clubService.clubs) {
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
      for (final event in eventService.events) {
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
      for (final item in vaultService.items) {
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

    setState(() {
      _results = results;
      _isLoading = false;
    });
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
                  child: ClayChip(
                    label: category,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedCategory = category);
                      _performSearch(_searchController.text);
                    },
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
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? _buildNoResults(isDark)
                        : _buildSearchResults(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      height: 46,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.clayDark : AppColors.clayLight,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? ClayShadows.dark(intensity: 0.4)
            : ClayShadows.light(intensity: 0.4),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _performSearch,
        style: TextStyle(
          color: isDark ? AppColors.textPrimaryDark : context.appColors.textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Search clubs, events, vault...',
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
                    _performSearch('');
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
            'Find clubs, events, and study materials',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : context.appColors.textSecondary,
            ),
          ),
        ],
      ),
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

  Widget _buildSearchResults(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final result = _results[index];
        return _SearchResultCard(result: result, isDark: isDark);
      },
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
    return GestureDetector(
      onTap: () {
        HapticUtils.lightTap();
        Navigator.pushNamed(context, result.route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? ClayShadows.dark(intensity: 0.5)
              : ClayShadows.light(intensity: 0.5),
        ),
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
