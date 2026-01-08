import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../../../services/user_service.dart';
import '../models/club_model.dart';

/// Member Management Screen - Manage club members and join requests
class MemberManagementScreen extends StatefulWidget {
  final Club club;

  const MemberManagementScreen({super.key, required this.club});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MockDataService>(
      builder: (context, dataService, _) {
        final club = dataService.getClubById(widget.club.id) ?? widget.club;
        final pendingRequests = dataService.getPendingRequestsForClub(club.id);
        final user = MockUserService.currentUser;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Members'),
            backgroundColor: AppColors.clubsColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'Members (${club.totalMembers})'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Requests'),
                      if (pendingRequests.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pendingRequests.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.clubsColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Members Tab
              _MembersTab(club: club, dataService: dataService, currentUserId: user.uid),
              
              // Requests Tab
              _RequestsTab(
                requests: pendingRequests,
                onApprove: (requestId) => dataService.approveJoinRequest(requestId, user.uid),
                onReject: (requestId) => dataService.rejectJoinRequest(requestId, user.uid),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MembersTab extends StatefulWidget {
  final Club club;
  final MockDataService dataService;
  final String currentUserId;

  const _MembersTab({
    required this.club,
    required this.dataService,
    required this.currentUserId,
  });

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allMembers = [...widget.club.adminIds, ...widget.club.memberIds];
    final uniqueMembers = allMembers.toSet().toList();
    
    // Filter members by search query
    final filteredMembers = _searchQuery.isEmpty
        ? uniqueMembers
        : uniqueMembers.where((id) => id.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    if (uniqueMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: context.appColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No members yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search members...',
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
              fillColor: context.appColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // Members list
        Expanded(
          child: filteredMembers.isEmpty
              ? Center(
                  child: Text(
                    'No members found',
                    style: TextStyle(color: context.appColors.textTertiary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final memberId = filteredMembers[index];
                    final isAdmin = widget.club.isAdmin(memberId);
                    final isCurrentUser = memberId == widget.currentUserId;

                    return _MemberTile(
                      memberId: memberId,
                      isAdmin: isAdmin,
                      isCurrentUser: isCurrentUser,
                      onPromote: isAdmin ? null : () => _promoteMember(context, memberId),
                      onRemove: isCurrentUser ? null : () => _removeMember(context, memberId),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _promoteMember(BuildContext context, String memberId) {
    final updatedClub = widget.club.copyWith(
      adminIds: [...widget.club.adminIds, memberId],
    );
    widget.dataService.updateClub(updatedClub);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Member promoted to admin')),
    );
  }

  void _removeMember(BuildContext context, String memberId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member?'),
        content: const Text('Are you sure you want to remove this member from the club?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.dataService.leaveClub(widget.club.id, memberId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Member removed')),
              );
            },
            child: Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String memberId;
  final bool isAdmin;
  final bool isCurrentUser;
  final VoidCallback? onPromote;
  final VoidCallback? onRemove;

  const _MemberTile({
    required this.memberId,
    required this.isAdmin,
    required this.isCurrentUser,
    this.onPromote,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin ? AppColors.clubsColor : AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            Icons.person,
            color: isAdmin ? Colors.white : AppColors.primary,
          ),
        ),
        title: Row(
          children: [
            Text(
              'Member ${memberId.substring(0, 8)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'You',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          isAdmin ? 'Admin' : 'Member',
          style: TextStyle(
            color: isAdmin ? AppColors.clubsColor : context.appColors.textTertiary,
            fontWeight: isAdmin ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: isCurrentUser
            ? null
            : PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  if (!isAdmin)
                    PopupMenuItem(
                      onTap: onPromote,
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 20),
                          SizedBox(width: 8),
                          Text('Promote to Admin'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    onTap: onRemove,
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle_outline, size: 20, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final List<dynamic> requests;
  final void Function(String) onApprove;
  final void Function(String) onReject;

  const _RequestsTab({
    required this.requests,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: context.appColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join requests will appear here',
              style: TextStyle(color: context.appColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _RequestCard(
          request: request,
          onApprove: () => onApprove(request.id),
          onReject: () => onReject(request.id),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final dynamic request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_add, color: AppColors.warning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Requested ${_formatDate(request.requestedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.note != null && request.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.appColors.divider.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${request.note}"',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
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
