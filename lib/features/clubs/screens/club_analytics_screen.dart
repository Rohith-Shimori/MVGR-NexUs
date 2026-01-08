import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../models/club_model.dart';

/// Club Analytics Screen - View club statistics and engagement
class ClubAnalyticsScreen extends StatelessWidget {
  final Club club;

  const ClubAnalyticsScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    return Consumer<MockDataService>(
      builder: (context, dataService, _) {
        final posts = dataService.getClubPosts(club.id);
        final pendingRequests = dataService.getPendingRequestsForClub(club.id);
        
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Club Analytics'),
            backgroundColor: AppColors.clubsColor,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Overview Stats
              Row(
                children: [
                  _StatCard(
                    icon: Icons.people,
                    value: '${club.memberIds.length}',
                    label: 'Members',
                    color: AppColors.clubsColor,
                    trend: '+12%',
                    isPositive: true,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.article,
                    value: '${posts.length}',
                    label: 'Posts',
                    color: AppColors.primary,
                    trend: '+5',
                    isPositive: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    icon: Icons.pending_actions,
                    value: '${pendingRequests.length}',
                    label: 'Pending',
                    color: AppColors.warning,
                    trend: null,
                    isPositive: true,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.visibility,
                    value: '${(club.memberIds.length * 23).clamp(0, 999)}',
                    label: 'Views',
                    color: AppColors.info,
                    trend: '+18%',
                    isPositive: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Growth Chart Placeholder
              _SectionTitle(title: 'Member Growth'),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _BarChart(height: 40, label: 'Oct'),
                        _BarChart(height: 60, label: 'Nov'),
                        _BarChart(height: 55, label: 'Dec'),
                        _BarChart(height: 80, label: 'Jan', isHighlighted: true),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up, color: AppColors.success, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Growing steadily',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Post Performance
              _SectionTitle(title: 'Post Performance'),
              const SizedBox(height: 12),
              if (posts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.appColors.divider),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.article_outlined, size: 48, color: context.appColors.textTertiary),
                        const SizedBox(height: 12),
                        Text(
                          'No posts yet',
                          style: TextStyle(color: context.appColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...posts.take(5).map((post) => _PostPerformanceItem(post: post)),
              
              const SizedBox(height: 24),

              // Engagement Insights
              _SectionTitle(title: 'Insights'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appColors.divider),
                ),
                child: Column(
                  children: [
                    _InsightItem(
                      icon: Icons.schedule,
                      title: 'Best posting time',
                      value: '6-8 PM',
                      color: AppColors.eventsColor,
                    ),
                    Divider(color: context.appColors.divider),
                    _InsightItem(
                      icon: Icons.article,
                      title: 'Best performing content',
                      value: 'Event announcements',
                      color: AppColors.success,
                    ),
                    Divider(color: context.appColors.divider),
                    _InsightItem(
                      icon: Icons.people,
                      title: 'Active member ratio',
                      value: '78%',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String? trend;
  final bool isPositive;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trend!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: context.appColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: context.appColors.textPrimary,
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final double height;
  final String label;
  final bool isHighlighted;

  const _BarChart({
    required this.height,
    required this.label,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            color: isHighlighted 
                ? AppColors.clubsColor 
                : AppColors.clubsColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.appColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _PostPerformanceItem extends StatelessWidget {
  final ClubPost post;

  const _PostPerformanceItem({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              post.content.length > 50 
                  ? '${post.content.substring(0, 50)}...' 
                  : post.content,
              style: TextStyle(
                fontSize: 13,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(post.content.length * 2) % 50 + 10}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.clubsColor,
                ),
              ),
              Text(
                'views',
                style: TextStyle(
                  fontSize: 10,
                  color: context.appColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: context.appColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
