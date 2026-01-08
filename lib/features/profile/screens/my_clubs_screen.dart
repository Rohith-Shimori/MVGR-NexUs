import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../../../services/user_service.dart';
import '../../clubs/models/club_model.dart';
import '../../clubs/screens/club_detail_screen.dart';
import '../../clubs/screens/club_dashboard_screen.dart';

/// My Clubs Screen - Shows clubs user is a member of
class MyClubsScreen extends StatelessWidget {
  const MyClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockUserService.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Clubs'),
        backgroundColor: AppColors.clubsColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<MockDataService>(
        builder: (context, dataService, _) {
          final myClubs = dataService.getMyClubs(user.uid);
          final adminClubs = dataService.getAdminClubs(user.uid);
          final pendingRequests = dataService.getMyJoinRequests(user.uid)
              .where((r) => r.isPending)
              .toList();

          if (myClubs.isEmpty && pendingRequests.isEmpty) {
            return _EmptyState(
              icon: Icons.groups_outlined,
              title: 'No clubs yet',
              subtitle: 'Join clubs to see them here',
              actionLabel: 'Browse Clubs',
              onAction: () => Navigator.pushNamed(context, '/clubs'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pending Requests
              if (pendingRequests.isNotEmpty) ...[
                _SectionHeader(title: 'Pending Requests'),
                const SizedBox(height: 12),
                ...pendingRequests.map((request) => _PendingRequestCard(
                  clubName: request.clubName,
                  requestedAt: request.requestedAt,
                  onCancel: () => dataService.cancelJoinRequest(request.id),
                )),
                const SizedBox(height: 24),
              ],

              // Admin Clubs - Navigate to Dashboard
              if (adminClubs.isNotEmpty) ...[
                _SectionHeader(title: 'Clubs You Manage'),
                const SizedBox(height: 12),
                ...adminClubs.map((club) => _ClubTile(
                  club: club,
                  isAdmin: true,
                  pendingCount: dataService.getPendingRequestsForClub(club.id).length,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ClubDashboardScreen(club: club)),
                  ),
                )),
                const SizedBox(height: 24),
              ],

              // Member Clubs
              if (myClubs.where((c) => !adminClubs.contains(c)).isNotEmpty) ...[
                _SectionHeader(title: 'Member Of'),
                const SizedBox(height: 12),
                ...myClubs.where((c) => !adminClubs.contains(c)).map((club) => _ClubTile(
                  club: club,
                  isAdmin: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ClubDetailScreen(club: club)),
                  ),
                  onLeave: () => _showLeaveDialog(context, dataService, club, user.uid),
                )),
              ],

              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, MockDataService dataService, Club club, String userId) {
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
              dataService.leaveClub(club.id, userId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Left ${club.name}')),
              );
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
  final int? pendingCount;
  final VoidCallback onTap;
  final VoidCallback? onLeave;

  const _ClubTile({
    required this.club,
    required this.isAdmin,
    this.pendingCount,
    required this.onTap,
    this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
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
        title: Row(
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
        subtitle: Row(
          children: [
            Text(
              '${club.totalMembers} members',
              style: TextStyle(color: context.appColors.textTertiary, fontSize: 13),
            ),
            if (pendingCount != null && pendingCount! > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pendingCount pending',
                  style: TextStyle(color: AppColors.warning, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
        trailing: isAdmin
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
