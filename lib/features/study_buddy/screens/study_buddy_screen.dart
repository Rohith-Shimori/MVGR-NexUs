import '../../../core/widgets/glassmorphic_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/premium_loading_indicator.dart';
import '../../../services/supabase_study_buddy_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/study_buddy_model.dart';

/// Study Buddy Screen — Find study partners
class StudyBuddyScreen extends StatefulWidget {
  const StudyBuddyScreen({super.key});

  @override
  State<StudyBuddyScreen> createState() => _StudyBuddyScreenState();
}

class _StudyBuddyScreenState extends State<StudyBuddyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseStudyBuddyService>().fetchRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => context.read<SupabaseStudyBuddyService>().fetchRequests(),
        child: Consumer<SupabaseStudyBuddyService>(
          builder: (context, service, _) {
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
                              AppColors.studyBuddyColor,
                              AppColors.studyBuddyColor.withValues(alpha: 0.7),
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
                                  'Study Buddy',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Find study partners by topic',
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

                  // Content
                  if (service.isLoading)
                    const SliverFillRemaining(child: ShimmerList())
                  else if (service.activeRequests.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.school,
                        title: 'No study requests',
                        subtitle: 'Be the first to request a study buddy',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _StudyRequestCard(
                          request: service.activeRequests[index],
                          onTap: () => _showRequestDetail(service.activeRequests[index]),
                        ),
                        childCount: service.activeRequests.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRequestSheet(context),
        backgroundColor: AppColors.studyBuddyColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showRequestDetail(StudyRequest request) {
    final user = context.read<AuthProvider>().user;
    showGlassModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.topic, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
            const SizedBox(height: 4),
            Text(request.subject, style: TextStyle(fontSize: 14, color: AppColors.studyBuddyColor, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            if (request.description.isNotEmpty)
              Text(request.description, style: TextStyle(fontSize: 14, color: context.appColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: context.appColors.textTertiary),
                const SizedBox(width: 4),
                Text(request.userName, style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
                const Spacer(),
                Icon(Icons.laptop, size: 16, color: context.appColors.textTertiary),
                const SizedBox(width: 4),
                Text(request.preferredMode.displayName, style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 24),
            if (user != null && !request.isOwnedBy(user.id))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await supabaseStudyBuddyService.respondToRequest(
                      requestId: request.id,
                      responderId: user.id,
                      responderName: user.name,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Response sent!' : 'Error responding')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.studyBuddyColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('I want to study together'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateRequestSheet(BuildContext context) {
    showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateStudyRequestSheet(
        onCreated: () => supabaseStudyBuddyService.fetchRequests(),
      ),
    );
  }
}

class _StudyRequestCard extends StatelessWidget {
  final StudyRequest request;
  final VoidCallback onTap;

  const _StudyRequestCard({required this.request, required this.onTap});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.studyBuddyColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book, color: AppColors.studyBuddyColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.topic, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.appColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(request.subject, style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.studyBuddyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(request.preferredMode.displayName, style: TextStyle(fontSize: 11, color: AppColors.studyBuddyColor, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            if (request.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.description, style: TextStyle(fontSize: 13, color: context.appColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Text('by ${request.userName}', style: TextStyle(fontSize: 11, color: context.appColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _CreateStudyRequestSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateStudyRequestSheet({required this.onCreated});

  @override
  State<_CreateStudyRequestSheet> createState() => _CreateStudyRequestSheetState();
}

class _CreateStudyRequestSheetState extends State<_CreateStudyRequestSheet> {
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  final _descController = TextEditingController();
  StudyMode _mode = StudyMode.inPerson;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _topicController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectController.text.trim().isEmpty || _topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in subject and topic')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      await supabaseStudyBuddyService.createRequest(
        userId: user.id,
        userName: user.name,
        subject: _subjectController.text.trim(),
        topic: _topicController.text.trim(),
        description: _descController.text.trim(),
        preferredMode: _mode,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study request created!')),
        );
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
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Find Study Buddy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
          const SizedBox(height: 24),
          TextField(controller: _subjectController, decoration: InputDecoration(labelText: 'Subject', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: _topicController, decoration: InputDecoration(labelText: 'Topic', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: _descController, maxLines: 2, decoration: InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          DropdownButtonFormField<StudyMode>(
            value: _mode,
            decoration: InputDecoration(labelText: 'Study Mode', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: StudyMode.values.map((m) => DropdownMenuItem(value: m, child: Text(m.displayName))).toList(),
            onChanged: (v) => setState(() => _mode = v ?? StudyMode.inPerson),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.studyBuddyColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isSubmitting ? const PremiumLoadingIndicator.small() : const Text('Post Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
