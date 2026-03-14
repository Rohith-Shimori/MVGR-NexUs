import '../../../core/widgets/animated_tab_indicator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';


import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/frosted_app_bar.dart';
import '../../../core/widgets/claymorphic_widgets.dart';

import '../../../services/supabase_mentorship_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

/// Mentorship Dashboard Screen — View pending/completed sessions and stats
class MentorshipDashboardScreen extends StatefulWidget {
  const MentorshipDashboardScreen({super.key});

  @override
  State<MentorshipDashboardScreen> createState() => _MentorshipDashboardScreenState();
}

class _MentorshipDashboardScreenState extends State<MentorshipDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<MentorshipSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await supabaseMentorshipService.fetchMySessions(user.id);
      _sessions = supabaseMentorshipService.sessions;
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<MentorshipSession> get _pendingSessions =>
      _sessions.where((s) => s.status == 'pending' || s.status == 'confirmed').toList();

  List<MentorshipSession> get _completedSessions =>
      _sessions.where((s) => s.status == 'completed').toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            FrostedSliverAppBar(
              title: 'My Sessions',
              bottom: TabBar(
                controller: _tabController,
                indicator: AnimatedPillTabIndicator(color: AppColors.mentorshipColor.withValues(alpha: 0.2)),
                labelColor: context.appColors.textPrimary,
                unselectedLabelColor: context.appColors.textTertiary,
                tabs: const [Tab(text: 'Pending'), Tab(text: 'Completed'), Tab(text: 'Stats')],
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(child: ShimmerList())
            else
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSessionsList(_pendingSessions, 'No pending sessions', 'Book a session with a mentor to get started'),
                    _buildSessionsList(_completedSessions, 'No completed sessions', 'Sessions you finish will appear here'),
                    _buildStats(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(List<MentorshipSession> sessions, String emptyTitle, String emptySubtitle) {
    if (sessions.isEmpty) {
      return EmptyStateWidget(icon: Icons.event_busy, title: emptyTitle, subtitle: emptySubtitle);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: sessions.length,
      itemBuilder: (context, index) => _SessionCard(session: sessions[index]),
    );
  }

  Widget _buildStats() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _StatCard(value: '${_sessions.length}', label: 'Total', icon: Icons.calendar_today, isDark: isDark),
                    const SizedBox(height: 8),
                    const ClayProgressIndicator(progress: 1.0, progressColor: AppColors.mentorshipColor),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _StatCard(value: '${_pendingSessions.length}', label: 'Pending', icon: Icons.hourglass_empty, isDark: isDark),
                    const SizedBox(height: 8),
                    ClayProgressIndicator(
                      progress: _sessions.isEmpty ? 0 : _pendingSessions.length / _sessions.length,
                      progressColor: Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _StatCard(value: '${_completedSessions.length}', label: 'Completed', icon: Icons.check_circle, isDark: isDark),
                    const SizedBox(height: 8),
                    ClayProgressIndicator(
                      progress: _sessions.isEmpty ? 0 : _completedSessions.length / _sessions.length,
                      progressColor: Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _StatCard(value: '0', label: 'Hours', icon: Icons.access_time, isDark: isDark),
                    const SizedBox(height: 8),
                    const ClayProgressIndicator(progress: 0.3, progressColor: Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final MentorshipSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.clayDark : AppColors.clayLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? ClayShadows.dark(intensity: 0.5) : ClayShadows.light(intensity: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(session.topic, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.appColors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(session.status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(session.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _statusColor(session.status))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: context.appColors.textTertiary),
              const SizedBox(width: 4),
              Text(_formatDate(session.scheduledAt), style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
              const Spacer(),
              Icon(Icons.access_time, size: 14, color: context.appColors.textTertiary),
              const SizedBox(width: 4),
              Text('${session.durationMinutes} min', style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isDark;

  const _StatCard({required this.value, required this.label, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.clayDark : AppColors.clayLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? ClayShadows.dark(intensity: 0.5) : ClayShadows.light(intensity: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.mentorshipColor),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
        ],
      ),
    );
  }
}
