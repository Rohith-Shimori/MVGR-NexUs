import 'package:flutter/material.dart';
import '../../../core/widgets/animated_tab_indicator.dart';
import '../../../core/widgets/premium_loading_indicator.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_club_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
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
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final members = await supabaseClubService.getClubMembers(widget.club.id);
    final requests = await supabaseClubService.getPendingRequests(widget.club.id);

    if (mounted) {
      setState(() {
        _members = members;
        _requests = requests;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Members'),
        backgroundColor: AppColors.clubsColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicator: AnimatedPillTabIndicator(color: Colors.white.withValues(alpha: 0.2)),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Members (${_members.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (_requests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_requests.length}',
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
      body: _isLoading 
          ? const Center(child: PremiumLoadingIndicator()) 
          : TabBarView(
              controller: _tabController,
              children: [
                // Members Tab
                _MembersTab(
                  members: _members,
                  currentUserId: context.read<AuthProvider>().user?.id ?? '',
                  onRefresh: _loadData,
                  clubId: widget.club.id,
                ),
                
                // Requests Tab
                _RequestsTab(
                  requests: _requests,
                  onApprove: (requestId, userId, userName) async {
                    await supabaseClubService.approveRequest(requestId, widget.club.id, userId, userName);
                    _loadData();
                  },
                  onReject: (requestId) async {
                    await supabaseClubService.rejectRequest(requestId);
                    _loadData();
                  },
                ),
              ],
            ),
    );
  }
}

class _MembersTab extends StatefulWidget {
  final List<Map<String, dynamic>> members;
  final String currentUserId;
  final VoidCallback onRefresh;
  final String clubId;

  const _MembersTab({
    required this.members,
    required this.currentUserId,
    required this.onRefresh,
    required this.clubId,
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
    // Filter members by search query
    final filteredMembers = _searchQuery.isEmpty
        ? widget.members
        : widget.members.where((m) {
            final name = (m['user_name'] as String?) ?? 'Unknown';
            return name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    if (widget.members.isEmpty) {
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
                    final member = filteredMembers[index];
                    final memberId = member['user_id'] as String;
                    final role = member['role'] as String;
                    final userName = member['user_name'] as String? ?? 'Unknown';
                    
                    final isAdmin = role == 'admin' || role == 'owner';
                    final isCurrentUser = memberId == widget.currentUserId;

                    return _MemberTile(
                      userName: userName,
                      isAdmin: isAdmin,
                      isCurrentUser: isCurrentUser,
                      onPromote: isAdmin ? null : () => _promoteMember(memberId),
                      onRemove: isCurrentUser ? null : () => _removeMember(memberId),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _promoteMember(String memberId) async {
    final success = await supabaseClubService.promoteToAdmin(widget.clubId, memberId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member promoted to admin')),
      );
      widget.onRefresh();
    }
  }

  void _removeMember(String memberId) {
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
            onPressed: () async {
              // Using leaveClub as 'remove' for now as logic is same
              await supabaseClubService.leaveClub(widget.clubId, memberId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Member removed')),
                );
                widget.onRefresh();
              }
            },
            child: Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String userName;
  final bool isAdmin;
  final bool isCurrentUser;
  final VoidCallback? onPromote;
  final VoidCallback? onRemove;

  const _MemberTile({
    required this.userName,
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
            Expanded(
              child: Text(
                userName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
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
                  if (!isAdmin && onPromote != null)
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
                  if (onRemove != null)
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
  final List<Map<String, dynamic>> requests;
  final Function(String, String, String) onApprove;
  final Function(String) onReject;

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
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final userName = request['user_name'] as String? ?? 'Unknown';
        final userId = request['user_id'] as String;
        final requestId = request['id'] as String;
        final note = request['note'] as String?;
        final createdAt = DateTime.parse(request['created_at']);

        return _RequestCard(
          userName: userName,
          note: note,
          requestedAt: createdAt,
          onApprove: () => onApprove(requestId, userId, userName),
          onReject: () => onReject(requestId),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String userName;
  final String? note;
  final DateTime requestedAt;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.userName,
    this.note,
    required this.requestedAt,
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
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Requested ${_formatDate(requestedAt)}',
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
            if (note != null && note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.appColors.divider.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"$note"',
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
