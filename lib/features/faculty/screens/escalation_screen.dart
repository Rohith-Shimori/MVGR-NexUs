import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/user_service.dart';

/// Faculty Escalation Screen - Handle escalated issues
class EscalationScreen extends StatefulWidget {
  const EscalationScreen({super.key});

  @override
  State<EscalationScreen> createState() => _EscalationScreenState();
}

class _EscalationScreenState extends State<EscalationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock escalation data
  final List<_Escalation> _pendingEscalations = [
    _Escalation(
      id: '1',
      title: 'Club dispute - Tech Club vs Coding Club',
      description: 'Both clubs claiming ownership of the same event. Council unable to resolve.',
      type: EscalationType.dispute,
      priority: EscalationPriority.high,
      submittedBy: 'Student Council',
      submittedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    _Escalation(
      id: '2',
      title: 'Misconduct report - Anonymous',
      description: 'Report of inappropriate behavior during cultural event. Needs investigation.',
      type: EscalationType.misconduct,
      priority: EscalationPriority.urgent,
      submittedBy: 'Anonymous',
      submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  final List<_Escalation> _resolvedEscalations = [
    _Escalation(
      id: '3',
      title: 'Budget allocation dispute',
      description: 'Resolved: Budget split equally between departments.',
      type: EscalationType.dispute,
      priority: EscalationPriority.medium,
      submittedBy: 'Finance Committee',
      submittedAt: DateTime.now().subtract(const Duration(days: 3)),
      resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
      resolution: 'Budget allocated 50-50 as per college guidelines.',
    ),
  ];

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
    final user = MockUserService.currentUser;

    if (!user.role.isFaculty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Escalations')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: context.appColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Faculty Access Only',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: context.appColors.textPrimary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Escalation Center'),
        backgroundColor: const Color(0xFF6B4E71),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Pending (${_pendingEscalations.length})'),
            Tab(text: 'Resolved (${_resolvedEscalations.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending
          _pendingEscalations.isEmpty
              ? _buildEmptyState('No pending escalations')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingEscalations.length,
                  itemBuilder: (context, index) {
                    return _EscalationCard(
                      escalation: _pendingEscalations[index],
                      onResolve: () => _showResolveDialog(_pendingEscalations[index]),
                    );
                  },
                ),
          // Resolved
          _resolvedEscalations.isEmpty
              ? _buildEmptyState('No resolved escalations')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _resolvedEscalations.length,
                  itemBuilder: (context, index) {
                    return _EscalationCard(
                      escalation: _resolvedEscalations[index],
                      isResolved: true,
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: context.appColors.textTertiary)),
        ],
      ),
    );
  }

  void _showResolveDialog(_Escalation escalation) {
    final resolutionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Escalation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              escalation.title,
              style: TextStyle(fontWeight: FontWeight.w600, color: context.appColors.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resolutionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Resolution',
                hintText: 'Describe how this was resolved...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _pendingEscalations.removeWhere((e) => e.id == escalation.id);
                _resolvedEscalations.insert(0, escalation.copyWith(
                  resolvedAt: DateTime.now(),
                  resolution: resolutionController.text.isNotEmpty 
                      ? resolutionController.text 
                      : 'Resolved by faculty.',
                ));
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Escalation resolved'), backgroundColor: AppColors.success),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }
}

class _EscalationCard extends StatelessWidget {
  final _Escalation escalation;
  final bool isResolved;
  final VoidCallback? onResolve;

  const _EscalationCard({
    required this.escalation,
    this.isResolved = false,
    this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (escalation.priority) {
      EscalationPriority.urgent => AppColors.error,
      EscalationPriority.high => AppColors.warning,
      EscalationPriority.medium => AppColors.info,
      EscalationPriority.low => AppColors.success,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    escalation.priority.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: priorityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.appColors.divider,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    escalation.type.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                if (isResolved)
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
              ],
            ),
            const SizedBox(height: 12),

            // Title & Description
            Text(
              escalation.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              escalation.description,
              style: TextStyle(
                fontSize: 13,
                color: context.appColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Resolution (if resolved)
            if (isResolved && escalation.resolution != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        escalation.resolution!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Footer
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: context.appColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  escalation.submittedBy,
                  style: TextStyle(fontSize: 11, color: context.appColors.textTertiary),
                ),
                const Spacer(),
                Text(
                  _timeAgo(isResolved ? escalation.resolvedAt! : escalation.submittedAt),
                  style: TextStyle(fontSize: 11, color: context.appColors.textTertiary),
                ),
                if (!isResolved && onResolve != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: onResolve,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

// Models
enum EscalationType { dispute, misconduct, appeal, other }

extension on EscalationType {
  String get displayName => switch (this) {
    EscalationType.dispute => 'Dispute',
    EscalationType.misconduct => 'Misconduct',
    EscalationType.appeal => 'Appeal',
    EscalationType.other => 'Other',
  };
}

enum EscalationPriority { urgent, high, medium, low }

class _Escalation {
  final String id;
  final String title;
  final String description;
  final EscalationType type;
  final EscalationPriority priority;
  final String submittedBy;
  final DateTime submittedAt;
  final DateTime? resolvedAt;
  final String? resolution;

  _Escalation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.submittedBy,
    required this.submittedAt,
    this.resolvedAt,
    this.resolution,
  });

  _Escalation copyWith({DateTime? resolvedAt, String? resolution}) {
    return _Escalation(
      id: id,
      title: title,
      description: description,
      type: type,
      priority: priority,
      submittedBy: submittedBy,
      submittedAt: submittedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
    );
  }
}
