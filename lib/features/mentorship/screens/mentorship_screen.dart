import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';


import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/premium_loading_indicator.dart';
import '../../../core/widgets/glassmorphic_sheet.dart';
import '../../../services/supabase_mentorship_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'mentorship_dashboard_screen.dart';

/// Mentorship Screen — Browse mentors and book sessions
class MentorshipScreen extends StatefulWidget {
  const MentorshipScreen({super.key});

  @override
  State<MentorshipScreen> createState() => _MentorshipScreenState();
}

class _MentorshipScreenState extends State<MentorshipScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseMentorshipService>().fetchMentors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => context.read<SupabaseMentorshipService>().fetchMentors(),
        child: Consumer<SupabaseMentorshipService>(
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
                              AppColors.mentorshipColor,
                              AppColors.mentorshipColor.withValues(alpha: 0.7),
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
                                  'Mentorship',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Connect with experienced mentors',
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
                    actions: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MentorshipDashboardScreen()),
                          );
                        },
                        icon: const Icon(Icons.dashboard_outlined, color: Colors.white),
                        tooltip: 'My Sessions',
                      ),
                    ],
                  ),

                  // Content
                  if (service.isLoading)
                    const SliverFillRemaining(child: ShimmerList())
                  else if (service.mentors.isEmpty)
                    const SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.school,
                        title: 'No mentors available',
                        subtitle: 'Check back later or register as a mentor',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _MentorCard(
                          mentor: service.mentors[index],
                          onTap: () => _showMentorDetail(service.mentors[index]),
                        ),
                        childCount: service.mentors.length,
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterSheet(context),
        backgroundColor: AppColors.mentorshipColor,
        icon: const Icon(Icons.school, color: Colors.white),
        label: const Text('Become a Mentor', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showMentorDetail(Mentor mentor) {
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
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.mentorshipColor.withValues(alpha: 0.2),
                  child: Text(mentor.name.isNotEmpty ? mentor.name[0] : 'M', style: TextStyle(fontSize: 24, color: AppColors.mentorshipColor, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mentor.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
                      if (mentor.company != null) Text('${mentor.position ?? ''} at ${mentor.company}', style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (mentor.bio != null) Text(mentor.bio!, style: TextStyle(fontSize: 14, color: context.appColors.textSecondary)),
            if (mentor.expertise.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: mentor.expertise.map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.mentorshipColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(e, style: TextStyle(fontSize: 12, color: AppColors.mentorshipColor, fontWeight: FontWeight.w500)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 24),
            if (user != null && user.id != mentor.userId)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showBookingDialog(mentor),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.mentorshipColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Book Session'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(Mentor mentor) {
    final topicController = TextEditingController();
    Navigator.pop(context); // Close detail sheet
    showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        bool isBooking = false;
        return StatefulBuilder(
          builder: (context, setSheetState) => Container(
            height: MediaQuery.of(context).size.height * 0.5,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book Session with ${mentor.name}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
                const SizedBox(height: 24),
                TextField(controller: topicController, decoration: InputDecoration(labelText: 'Topic', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const Spacer(),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: isBooking ? null : () async {
                      final user = context.read<AuthProvider>().user;
                      if (user == null || topicController.text.trim().isEmpty) return;
                      setSheetState(() => isBooking = true);
                      try {
                        await supabaseMentorshipService.bookSession(
                          mentorId: mentor.userId,
                          menteeId: user.id,
                          menteeName: user.name,
                          topic: topicController.text.trim(),
                          scheduledAt: DateTime.now().add(const Duration(days: 3)),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session booked!')));
                        }
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.mentorshipColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: isBooking ? const PremiumLoadingIndicator.small() : const Text('Book', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    topicController.dispose();
  }

  void _showRegisterSheet(BuildContext context) {
    showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _RegisterMentorSheet(),
    );
  }
}

class _MentorCard extends StatelessWidget {
  final Mentor mentor;
  final VoidCallback onTap;

  const _MentorCard({required this.mentor, required this.onTap});

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
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.mentorshipColor.withValues(alpha: 0.15),
              child: Text(mentor.name.isNotEmpty ? mentor.name[0] : 'M', style: TextStyle(fontSize: 18, color: AppColors.mentorshipColor, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mentor.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.appColors.textPrimary)),
                  if (mentor.company != null) Text(mentor.company!, style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
                  if (mentor.expertise.isNotEmpty)
                    Text(mentor.expertise.take(3).join(', '), style: TextStyle(fontSize: 12, color: AppColors.mentorshipColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.mentorshipColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(mentor.mentorType, style: TextStyle(fontSize: 11, color: AppColors.mentorshipColor, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterMentorSheet extends StatefulWidget {
  const _RegisterMentorSheet();

  @override
  State<_RegisterMentorSheet> createState() => _RegisterMentorSheetState();
}

class _RegisterMentorSheetState extends State<_RegisterMentorSheet> {
  final _bioController = TextEditingController();
  final _expertiseController = TextEditingController();
  String _mentorType = 'academic';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _bioController.dispose();
    _expertiseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Register as Mentor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
          const SizedBox(height: 24),
          TextField(controller: _bioController, maxLines: 3, decoration: InputDecoration(labelText: 'Bio', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: _expertiseController, decoration: InputDecoration(labelText: 'Expertise (comma-separated)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _mentorType,
            decoration: InputDecoration(labelText: 'Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: const [
              DropdownMenuItem(value: 'academic', child: Text('Academic')),
              DropdownMenuItem(value: 'industry', child: Text('Industry')),
              DropdownMenuItem(value: 'alumni', child: Text('Alumni')),
            ],
            onChanged: (v) => setState(() => _mentorType = v ?? 'academic'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () async {
                final user = context.read<AuthProvider>().user;
                if (user == null) return;
                setState(() => _isSubmitting = true);
                try {
                  await supabaseMentorshipService.registerAsMentor(
                    userId: user.id,
                    name: user.name,
                    bio: _bioController.text.trim(),
                    mentorType: _mentorType,
                    expertise: _expertiseController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered as mentor!')));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mentorshipColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isSubmitting ? const PremiumLoadingIndicator.small() : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
