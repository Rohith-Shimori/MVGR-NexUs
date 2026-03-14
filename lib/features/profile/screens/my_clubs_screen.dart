import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/supabase_club_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../clubs/models/club_model.dart';
import '../../clubs/screens/club_detail_screen.dart';
import '../../clubs/screens/club_dashboard_screen.dart';

/// My Clubs Screen - Shows clubs user is a member of
class MyClubsScreen extends StatefulWidget {
  const MyClubsScreen({super.key});

  @override
  State<MyClubsScreen> createState() => _MyClubsScreenState();
}

class _MyClubsScreenState extends State<MyClubsScreen> {
  List<Club> _myClubs = [];
  List<Club> _adminClubs = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final user = context.read<AuthProvider>().user;
    
    if (user != null) {
      final myClubs = await supabaseClubService.getMyClubs(user.id);
      final adminClubs = await supabaseClubService.getAdminClubs(user.id);
      final pendingRequests = await supabaseClubService.getMyJoinRequests(user.id);
      
      if (mounted) {
        setState(() {
          _myClubs = myClubs;
          _adminClubs = adminClubs;
          _pendingRequests = pendingRequests;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    final success = await supabaseClubService.cancelJoinRequest(requestId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled')),
      );
      _loadData();
    }
  }

  Future<void> _leaveClub(Club club) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final success = await supabaseClubService.leaveClub(club.id, user.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Left ${club.name}')),
      );
      _loadData();
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Clubs'),
        backgroundColor: AppColors.clubsColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    if (_myClubs.isEmpty && _pendingRequests.isEmpty) {
      return _EmptyState(
        icon: Icons.groups_outlined,
        title: 'No clubs yet',
        subtitle: 'Join clubs to see them here',
        actionLabel: 'Browse Clubs',
        onAction: () => Navigator.pushNamed(context, '/clubs'),
      );
    }

    // Filter member clubs to exclude admin clubs (since they are shown separately)
    final memberClubs = _myClubs.where((c) => !_adminClubs.any((a) => a.id == c.id)).toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Pending Requests
              if (_pendingRequests.isNotEmpty) ...[
                const _SectionHeader(title: 'Pending Requests'),
                const SizedBox(height: 12),
                ..._pendingRequests.map((request) {
                  final clubInfo = request['clubs'] as Map<String, dynamic>? ?? {};
                  final clubName = clubInfo['name'] as String? ?? 'Unknown Club';
                  final createdAt = DateTime.parse(request['created_at']);
                  
                  return _PendingRequestCard(
                    clubName: clubName,
                    requestedAt: createdAt,
                    onCancel: () => _cancelRequest(request['id']),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Admin Clubs - Navigate to Dashboard
              if (_adminClubs.isNotEmpty) ...[
                const _SectionHeader(title: 'Clubs You Manage'),
                const SizedBox(height: 12),
                ..._adminClubs.map((club) => _ClubTile(
                  club: club,
                  isAdmin: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ClubDashboardScreen(club: club)),
                  ),
                )),
                const SizedBox(height: 24),
              ],

              // Member Clubs
              if (memberClubs.isNotEmpty) ...[
                const _SectionHeader(title: 'Member Of'),
                const SizedBox(height: 12),
                ...memberClubs.map((club) => _ClubTile(
                  club: club,
                  isAdmin: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ClubDetailScreen(club: club)),
                  ),
                  onLeave: () => _showLeaveDialog(context, club),
                )),
              ],

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  void _showLeaveDialog(BuildContext context, Club club) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Club?'),
        content: Text('Are you sure you want to leave ${club.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Pop dialog first
              _leaveClub(club);
            },
            child: Text('Leave', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.appColors.textPrimary,
      ),
    );
  }
}

class _ClubTile extends StatelessWidget {
  final Club club;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onLeave;

  const _ClubTile({
    required this.club,
    required this.isAdmin,
    required this.onTap,
    this.onLeave,
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? ClayShadows.dark(intensity: 0.6)
              : ClayShadows.light(intensity: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.clubsColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(club.category.iconData, size: 24, color: AppColors.clubsColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          club.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.clubsColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${club.totalMembers} members',
                    style: TextStyle(color: context.appColors.textTertiary, fontSize: 13),
                  ),
                ],
              ),
            ),
            isAdmin
                ? const Icon(Icons.chevron_right)
                : PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: onLeave,
                        child: Row(
                          children: [
                            Icon(Icons.exit_to_app, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Text('Leave', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final String clubName;
  final DateTime requestedAt;
  final VoidCallback onCancel;

  const _PendingRequestCard({
    required this.clubName,
    required this.requestedAt,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.warning.withValues(alpha: 0.05),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.hourglass_empty, color: AppColors.warning),
        ),
        title: Text(
          clubName,
          style: TextStyle(fontWeight: FontWeight.w600, color: context.appColors.textPrimary),
        ),
        subtitle: Text(
          'Requested ${_formatDate(requestedAt)}',
          style: TextStyle(color: context.appColors.textTertiary, fontSize: 12),
        ),
        trailing: TextButton(
          onPressed: onCancel,
          child: Text('Cancel', style: TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: context.appColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: context.appColors.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.clubsColor,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
