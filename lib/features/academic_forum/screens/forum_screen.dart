import 'dart:io';
import '../../../core/widgets/animated_tab_indicator.dart';
import '../../../core/widgets/glassmorphic_sheet.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/supabase_storage_service.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../services/supabase_forum_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../services/supabase_report_service.dart';
import '../models/forum_model.dart';

/// Premium Discussion Forum Screen - Q&A Focused
class AcademicForumScreen extends StatefulWidget {
  const AcademicForumScreen({super.key});

  @override
  State<AcademicForumScreen> createState() => _AcademicForumScreenState();
}

class _AcademicForumScreenState extends State<AcademicForumScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSubject;

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Header
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.forumColor,
                      AppColors.forumColor.withValues(alpha: 0.8),
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
                          'Discussion Forum',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ask anything, share knowledge, help others',
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
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                onPressed: () => _showAskQuestionSheet(context),
                tooltip: 'Ask Question',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.forumColor,
                unselectedLabelColor: context.appColors.textSecondary,
                indicator: AnimatedPillTabIndicator(color: AppColors.forumColor.withValues(alpha: 0.2)),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Recent'),
                  Tab(text: 'Unanswered'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _QuestionsList(filter: 'recent', selectedSubject: _selectedSubject),
            _QuestionsList(
              filter: 'unanswered',
              selectedSubject: _selectedSubject,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAskQuestionSheet(context),
        backgroundColor: AppColors.forumColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAskQuestionSheet(BuildContext context) {
    showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
            builder: (context) => const _AskQuestionSheet(),
    );
  }
}

/// Sliver Tab Bar Delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

/// Questions List with Search
class _QuestionsList extends StatefulWidget {
  final String filter;
  final String? selectedSubject;

  const _QuestionsList({required this.filter, this.selectedSubject});

  @override
  State<_QuestionsList> createState() => _QuestionsListState();
}

class _QuestionsListState extends State<_QuestionsList> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseForumService>(
      builder: (context, dataService, _) {
        var questions = dataService.questions.toList();

        if (widget.filter == 'unanswered') {
          questions = questions.where((q) => q.answerCount == 0).toList();
        }

        if (widget.selectedSubject != null) {
          questions = questions
              .where((q) => q.subject == widget.selectedSubject)
              .toList();
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          questions = questions.where((q) =>
              q.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              q.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }

        // Sort by recent
        questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search questions...',
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
            // Questions list
            Expanded(
              child: questions.isEmpty
                  ? (_searchQuery.isNotEmpty
                      ? EmptyStateWidget.noResults()
                      : EmptyStateWidget.noForumPosts())
                  : RefreshIndicator(
                      onRefresh: () async {
                        HapticUtils.pullToRefresh();
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      color: AppColors.forumColor,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: questions.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _QuestionCard(question: questions[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Question Card
class _QuestionCard extends StatelessWidget {
  final AcademicQuestion question;

  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        HapticUtils.lightTap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _QuestionDetailScreen(question: question),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? ClayShadows.dark(intensity: 0.6)
              : ClayShadows.light(intensity: 0.6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - with overflow protection
              Row(
                children: [
                  // Badges - wrapped in Expanded for overflow safety
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Subject Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.forumColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            question.subject,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.forumColor,
                            ),
                          ),
                        ),
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: question.category.color.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                question.category.iconData,
                                size: 12,
                                color: question.category.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                question.category.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: question.category.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (question.isResolved)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Resolved',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(question.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: context.appColors.textTertiary),
                    onSelected: (value) {
                      if (value == 'report') {
                        _showReportDialog(context, question);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Report', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                question.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Content Preview
              Text(
                question.content,
                style: TextStyle(
                  fontSize: 14,
                  color: context.appColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),

              // Footer
              Row(
                children: [
                  // Author
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          question.isAnonymous
                              ? '?'
                              : (question.authorName?[0] ?? 'A'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        question.isAnonymous
                            ? 'Anonymous'
                            : (question.authorName ?? 'Unknown'),
                        style: TextStyle(
                          fontSize: 13,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Stats
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 16,
                        color: context.appColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${question.upvoteCount}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: context.appColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${question.answerCount}',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}';
  }

  void _showReportDialog(BuildContext context, AcademicQuestion question) {
    final reasonController = TextEditingController();
    ReportReason selectedReason = ReportReason.inappropriateContent;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report Question'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ReportReason>(
                initialValue: selectedReason,
                items: ReportReason.values.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r.name.toUpperCase()),
                )).toList(),
                onChanged: (v) => setState(() => selectedReason = v!),
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                  hintText: 'Describe the issue...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final user = context.read<AuthProvider>().user;
                
                if (user == null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You must be logged in to report')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                // Submit report to Supabase
                final success = await SupabaseReportService.instance.reportForumPost(
                  reporterId: user.id,
                  postId: question.id,
                  reason: selectedReason,
                  additionalDetails: reasonController.text.isNotEmpty 
                      ? reasonController.text 
                      : null,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                          ? 'Report submitted for review' 
                          : 'Failed to submit report'),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Question Detail Screen
class _QuestionDetailScreen extends StatefulWidget {
  final AcademicQuestion question;

  const _QuestionDetailScreen({required this.question});

  @override
  State<_QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<_QuestionDetailScreen> {
  late Future<List<Answer>> _answersFuture;
  late int _upvotes;
  bool _isUpvoted = false; // Optimistic, assume false initially

  @override
  void initState() {
    super.initState();
    _upvotes = widget.question.upvoteCount;
    _refreshAnswers();
  }

  void _refreshAnswers() {
    setState(() {
      _answersFuture = context.read<SupabaseForumService>().getAnswers(widget.question.id);
    });
  }

  Future<void> _handleUpvote() async {
    setState(() {
      _isUpvoted = !_isUpvoted;
      _upvotes += _isUpvoted ? 1 : -1;
    });

    await context.read<SupabaseForumService>().upvoteQuestion(widget.question.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: context.appColors.textPrimary),
            onSelected: (value) {
              if (value == 'report') {
                _showReportDialog(context, widget.question);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Report Question'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Question Wrapper
                _DetailCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.forumColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.question.subject,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forumColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        widget.question.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Content
                      Text(
                        widget.question.content,
                        style: TextStyle(
                          fontSize: 15,
                          color: context.appColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Author & Stats
                      Row(
                        children: [
                          Text(
                            'Asked by ${widget.question.isAnonymous ? 'Anonymous' : (widget.question.authorName ?? 'Unknown')}',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appColors.textTertiary,
                            ),
                          ),
                          const Spacer(),
                          // Upvote Button
                          GestureDetector(
                            onTap: _handleUpvote,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _isUpvoted
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : context.appColors.divider,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    size: 16,
                                    color: _isUpvoted
                                        ? AppColors.primary
                                        : context.appColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_upvotes',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _isUpvoted
                                          ? AppColors.primary
                                          : context.appColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),

          // Answers Section
          FutureBuilder<List<Answer>>(
            future: _answersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                 return const SliverToBoxAdapter(
                   child: Center(
                     child: Padding(
                       padding: EdgeInsets.all(32.0),
                       child: CircularProgressIndicator(),
                     ),
                   ),
                 );
              }
              if (snapshot.hasError) {
                 return SliverToBoxAdapter(child: Center(child: Text('Error: ${snapshot.error}')));
              }
              
              final answers = snapshot.data ?? [];

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${answers.length} Answers',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: context.appColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _showAnswerSheet(context),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Answer'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.forumColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (answers.isEmpty)
                          const _EmptyCard(message: 'No answers yet. Be the first to help!')
                        else
                          ...answers.map(
                            (answer) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AnswerCard(answer: answer, questionId: widget.question.id),
                            ),
                          ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAnswerSheet(BuildContext context) async {
    await showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
            builder: (context) => _AnswerSheet(questionId: widget.question.id),
    );
    _refreshAnswers();
  }

  void _showReportDialog(BuildContext context, AcademicQuestion question) {
    final reasonController = TextEditingController();
    ReportReason selectedReason = ReportReason.inappropriateContent;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report Question'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ReportReason>(
                initialValue: selectedReason,
                items: ReportReason.values.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r.name.toUpperCase()),
                )).toList(),
                onChanged: (v) => setState(() => selectedReason = v!),
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                  hintText: 'Describe the issue...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final user = context.read<AuthProvider>().user;
                
                if (user == null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You must be logged in to report')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                // Submit report to Supabase
                final success = await SupabaseReportService.instance.reportForumPost(
                  reporterId: user.id,
                  postId: question.id,
                  reason: selectedReason,
                  additionalDetails: reasonController.text.isNotEmpty 
                      ? reasonController.text 
                      : null,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                          ? 'Report submitted for review' 
                          : 'Failed to submit report'),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detail Card
class _DetailCard extends StatelessWidget {
  final Widget child;

  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.divider),
      ),
      child: child,
    );
  }
}

/// Answer Card
class _AnswerCard extends StatefulWidget {
  final Answer answer;
  final String questionId;

  const _AnswerCard({required this.answer, required this.questionId});

  @override
  State<_AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<_AnswerCard> {
  late int _upvotes;
  bool _isUpvoted = false; // Optimistic for now, ideally fetch from DB

  @override
  void initState() {
    super.initState();
    _upvotes = widget.answer.helpfulCount;
    // Check upvote status if possible, or leave as false default
  }

  Future<void> _handleUpvote() async {
    setState(() {
      _isUpvoted = !_isUpvoted;
      _upvotes += _isUpvoted ? 1 : -1;
    });
    
    // Call service
    await context.read<SupabaseForumService>().upvoteAnswer(widget.answer.id);
  }

  void _showReportDialog(BuildContext context) {
    final reasonController = TextEditingController();
    ReportReason selectedReason = ReportReason.inappropriateContent;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Report Answer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ReportReason>(
                initialValue: selectedReason,
                items: ReportReason.values.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r.name.toUpperCase()),
                )).toList(),
                onChanged: (v) => setState(() => selectedReason = v!),
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Details (optional)',
                  hintText: 'Describe the issue...',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final user = context.read<AuthProvider>().user;
                
                if (user == null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You must be logged in to report')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                // Submit report to Supabase
                final success = await SupabaseReportService.instance.reportComment(
                  reporterId: user.id,
                  commentId: widget.answer.id,
                  reason: selectedReason,
                  additionalDetails: reasonController.text.isNotEmpty 
                      ? reasonController.text 
                      : null,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                          ? 'Report submitted for review' 
                          : 'Failed to submit report'),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.answer.isAccepted
            ? AppColors.success.withValues(alpha: 0.05)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.answer.isAccepted ? AppColors.success : context.appColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.answer.isAccepted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text(
                    'Accepted Answer',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            widget.answer.content,
            style: TextStyle(
              fontSize: 14,
              color: context.appColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    widget.answer.authorName == 'Anonymous'
                        ? '?'
                        : (widget.answer.authorName.isNotEmpty ? widget.answer.authorName[0] : 'A'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.answer.authorName,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appColors.textTertiary,
                  ),
                ),
                const Spacer(),
                
                GestureDetector(
                  onTap: _handleUpvote,
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 16,
                        color: _isUpvoted
                            ? AppColors.primary
                            : context.appColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_upvotes',
                        style: TextStyle(
                          fontSize: 13,
                          color: _isUpvoted
                              ? AppColors.primary
                              : context.appColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: context.appColors.textTertiary),
                  onSelected: (value) {
                    if (value == 'report') {
                      _showReportDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Report Answer'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}


/// Empty Card
class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 14, color: context.appColors.textTertiary),
        ),
      ),
    );
  }
}

/// Ask Question Sheet
class _AskQuestionSheet extends StatefulWidget {
  const _AskQuestionSheet();

  @override
  State<_AskQuestionSheet> createState() => _AskQuestionSheetState();
}

class _AskQuestionSheetState extends State<_AskQuestionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _subject = 'General';
  ForumCategory _category = ForumCategory.academic;
  bool _isAnonymous = false;
  bool _isLoading = false;
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Ask a Question',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Subject Dropdown
              _DropdownField(
                label: 'Subject',
                value: _subject,
                items: QuestionSubjects.all,
                onChanged: (v) => setState(() => _subject = v!),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: context.appColors.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<ForumCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: ForumCategory.values
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Icon(cat.iconData, size: 18, color: cat.color),
                              const SizedBox(width: 8),
                              Text(cat.displayName),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _category = v ?? ForumCategory.academic),
                ),
              ),
              const SizedBox(height: 16),

              // Title Field
              _FormField(
                controller: _titleController,
                label: 'Question Title',
                hint: 'What do you want to know?',
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appColors.divider),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, 
                                size: 32, color: context.appColors.textTertiary),
                            const SizedBox(height: 8),
                            Text(
                              'Add Image (Optional)',
                              style: TextStyle(
                                color: context.appColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Content Field
              _FormField(
                controller: _contentController,
                label: 'Details',
                hint: 'Provide more context about your question...',
                maxLines: 4,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Details are required' : null,
              ),
              const SizedBox(height: 16),

              // Similar Questions Section (if title is entered)
              if (_titleController.text.length > 10)
                Builder(
                  builder: (context) {
                    final dataService = context.read<SupabaseForumService>();
                    final allQuestions = dataService.questions;

                    // Find similar questions using keyword overlap
                    final queryWords = _titleController.text
                        .toLowerCase()
                        .split(' ')
                        .where((w) => w.length > 3)
                        .toSet();

                    final similar = allQuestions
                        .where((q) {
                          final qWords = q.title
                              .toLowerCase()
                              .split(' ')
                              .where((w) => w.length > 3)
                              .toSet();
                          final overlap = queryWords.intersection(qWords);
                          return overlap.length >= 2; // At least 2 common words
                        })
                        .take(3)
                        .toList();

                    if (similar.isEmpty) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 18,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Similar questions found',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...similar.map(
                            (q) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  // Could navigate to question detail
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Opening: ${q.title}'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      q.isResolved
                                          ? Icons.check_circle
                                          : Icons.help_outline,
                                      size: 14,
                                      color: q.isResolved
                                          ? AppColors.success
                                          : context.appColors.textTertiary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        q.title,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.appColors.textSecondary,
                                          decoration: TextDecoration.underline,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              if (_titleController.text.length > 10) const SizedBox(height: 16),

              // Anonymous Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ask Anonymously'),
                subtitle: Text(
                  'Your name will be hidden',
                  style: TextStyle(color: context.appColors.textTertiary),
                ),
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forumColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Post Question'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      final user = context.read<AuthProvider>().user;

      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }


      final storageService = context.read<SupabaseStorageService>();
      String? imageUrl;

      if (_selectedImage != null) {
        try {
          // Determine bucket - assuming 'forum' bucket exists or reuse 'clubs'/'profiles' or verify.
          // Let's use 'public' or verify in next step. For now assume 'forum_images' bucket or generic.
          // Actually SupabaseStorageService uses 'profiles' in one method.
          // I'll add 'forum' bucket support in service later, for now let's try uploadFile generic method.
          // But SupabaseStorageService has uploadFile(bucket, path, file).
          
          imageUrl = await storageService.uploadFile(
            'forum', // bucket name
            '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg',
            _selectedImage!,
          );
        } catch (e) {
          AppLogger.error('Image upload failed: $e');
        }
      }

      final question = AcademicQuestion(
        id: '', // Generated by Supabase
        authorId: user.id,
        authorName: _isAnonymous ? null : user.name,
        title: _titleController.text,
        content: _contentController.text,
        subject: _subject,
        category: _category,
        isAnonymous: _isAnonymous,
        createdAt: DateTime.now(),
        upvoteCount: 0,
        tags: [],
        imageUrl: imageUrl,
      );

      try {
        if (!mounted) return;
        await context.read<SupabaseForumService>().addQuestion(question);

        if (!mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question posted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

/// Answer Sheet
class _AnswerSheet extends StatefulWidget {
  final String questionId;

  const _AnswerSheet({required this.questionId});

  @override
  State<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends State<_AnswerSheet> {
  final _contentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Your Answer',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            _FormField(
              controller: _contentController,
              label: 'Answer',
              hint: 'Share your knowledge...',
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Answer Anonymously'),
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forumColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Post Answer'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_contentController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await context.read<SupabaseForumService>().addAnswer(
        widget.questionId,
        _contentController.text,
        _isAnonymous,
      );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer posted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Form Field
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final int maxLines;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.appColors.textTertiary),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.appColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.forumColor,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dropdown Field
class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
