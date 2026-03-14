import '../../../core/widgets/glassmorphic_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/premium_loading_indicator.dart';
import '../../../services/supabase_play_buddy_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/play_buddy_model.dart';

/// Play Buddy / Teams Screen — Find teammates
class PlayBuddyScreen extends StatefulWidget {
  const PlayBuddyScreen({super.key});

  @override
  State<PlayBuddyScreen> createState() => _PlayBuddyScreenState();
}

class _PlayBuddyScreenState extends State<PlayBuddyScreen> {
  String _selectedCategory = 'All';

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabasePlayBuddyService>().fetchTeams();
    });
  }

  List<TeamRequest> _getFilteredTeams(List<TeamRequest> teams) {
    if (_selectedCategory == 'All') return teams;
    return teams.where((t) => t.category.displayName == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => context.read<SupabasePlayBuddyService>().fetchTeams(),
        child: Consumer<SupabasePlayBuddyService>(
          builder: (context, service, _) {
            final filteredTeams = _getFilteredTeams(service.activeTeams);
            return CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                  SliverAppBar(
                    expandedHeight: 180,
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.playBuddyColor,
                              AppColors.playBuddyColor.withValues(alpha: 0.7),
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
                                  'Find Teammates',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Build your dream team',
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

                  // Category Filters
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: ['All', ...TeamCategory.values.map((c) => c.displayName)].map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                HapticUtils.selection();
                                setState(() => _selectedCategory = cat);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.playBuddyColor : (isDark ? AppColors.clayDark : AppColors.clayLight),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: isSelected ? null : (isDark ? ClayShadows.dark(intensity: 0.4) : ClayShadows.light(intensity: 0.4)),
                                ),
                                child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : context.appColors.textSecondary)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Content
                  if (service.isLoading)
                    const SliverFillRemaining(child: ShimmerList())
                  else if (filteredTeams.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.groups,
                        title: 'No team requests',
                        subtitle: 'Create a team request to find teammates',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _TeamCard(
                          team: filteredTeams[index],
                          onTap: () => _showTeamDetail(filteredTeams[index]),
                        ),
                        childCount: filteredTeams.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTeamSheet(context),
        backgroundColor: AppColors.playBuddyColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showTeamDetail(TeamRequest team) {
    final user = context.read<AuthProvider>().user;
    showGlassModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.playBuddyColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(team.category.iconData, color: AppColors.playBuddyColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('${team.category.displayName} • ${team.currentMembers}/${team.teamSize} members', style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (team.description.isNotEmpty)
              Text(team.description, style: TextStyle(fontSize: 14, color: context.appColors.textSecondary)),
            if (team.eventName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: context.appColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(team.eventName!, style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text('Created by ${team.creatorName}', style: TextStyle(fontSize: 12, color: context.appColors.textTertiary)),
            const SizedBox(height: 24),
            if (user != null && !team.isMember(user.id) && team.spotsLeft > 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await supabasePlayBuddyService.joinTeam(teamId: team.id, userId: user.id, userName: user.name);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Joined the team!' : 'Error joining')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.playBuddyColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Join Team'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateTeamSheet(BuildContext context) {
    showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateTeamSheet(onCreated: () => supabasePlayBuddyService.fetchTeams()),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamRequest team;
  final VoidCallback onTap;

  const _TeamCard({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? ClayShadows.dark(intensity: 0.5) : ClayShadows.light(intensity: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.playBuddyColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(team.category.iconData, color: AppColors.playBuddyColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.appColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(team.category.displayName, style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.playBuddyColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('${team.currentMembers}/${team.teamSize}', style: TextStyle(fontSize: 12, color: AppColors.playBuddyColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTeamSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateTeamSheet({required this.onCreated});

  @override
  State<_CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends State<_CreateTeamSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TeamCategory _category = TeamCategory.hackathon;
  int _teamSize = 4;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      await supabasePlayBuddyService.createTeam(
        creatorId: user.id,
        creatorName: user.name,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category.name,
        spotsTotal: _teamSize,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team created!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
          const SizedBox(height: 24),
          TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Team Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: _descController, maxLines: 2, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          DropdownButtonFormField<TeamCategory>(
            value: _category,
            decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: TeamCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
            onChanged: (v) => setState(() => _category = v ?? TeamCategory.hackathon),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Team Size: $_teamSize', style: TextStyle(color: context.appColors.textPrimary)),
              Expanded(
                child: Slider(
                  min: 2, max: 10, divisions: 8,
                  value: _teamSize.toDouble(),
                  onChanged: (v) => setState(() => _teamSize = v.round()),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.playBuddyColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isSubmitting ? const PremiumLoadingIndicator.small() : const Text('Create', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
