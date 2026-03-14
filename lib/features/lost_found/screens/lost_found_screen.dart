import '../../../core/widgets/animated_tab_indicator.dart';
import '../../../core/widgets/glassmorphic_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';


import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/premium_loading_indicator.dart';
import '../../../services/supabase_lost_found_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/lost_found_model.dart';

/// Lost & Found Screen
class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseLostFoundService>().fetchItems();
    });
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
      body: RefreshIndicator(
        onRefresh: () => context.read<SupabaseLostFoundService>().fetchItems(),
        child: Consumer<SupabaseLostFoundService>(
            builder: (context, service, _) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.lostFoundColor,
                              AppColors.lostFoundColor.withValues(alpha: 0.7),
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
                                  'Lost & Found',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Help reunite lost items with owners',
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
                    bottom: TabBar(
                      controller: _tabController,
                      indicator: AnimatedPillTabIndicator(color: AppColors.lostFoundColor.withValues(alpha: 0.2)),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: 'Lost Items'),
                        Tab(text: 'Found Items'),
                      ],
                    ),
                  ),

                  // Content
                  if (service.isLoading)
                    const SliverFillRemaining(child: ShimmerList())
                  else
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildItemsList(service.lostItems, 'No lost items reported', 'Lost something? Report it here'),
                          _buildItemsList(service.foundItems, 'No found items reported', 'Found something? Report it here'),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReportSheet(context),
        backgroundColor: AppColors.lostFoundColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildItemsList(List<LostFoundItem> items, String emptyTitle, String emptySubtitle) {
    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) => _LostFoundCard(
        item: items[index],
        onTap: () => _showItemDetail(items[index]),
      ),
    );
  }

  void _showItemDetail(LostFoundItem item) {
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lostFoundColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.category.iconData, color: AppColors.lostFoundColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('${item.category.displayName} • ${item.status.displayName}', style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(item.description, style: TextStyle(fontSize: 14, color: context.appColors.textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: context.appColors.textTertiary),
                const SizedBox(width: 4),
                Text(item.location, style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: context.appColors.textTertiary),
                const SizedBox(width: 4),
                Text('Reported by ${item.userName}', style: TextStyle(fontSize: 13, color: context.appColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReportSheet(onReported: () => supabaseLostFoundService.fetchItems()),
    );
  }
}

// ─── Lost/Found Item Card ──────────────────────────────────────
class _LostFoundCard extends StatelessWidget {
  final LostFoundItem item;
  final VoidCallback onTap;

  const _LostFoundCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? ClayShadows.dark(intensity: 0.5) : ClayShadows.light(intensity: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lostFoundColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.category.iconData, color: AppColors.lostFoundColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.appColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: context.appColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item.location, style: TextStyle(fontSize: 13, color: context.appColors.textTertiary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.category.displayName, style: TextStyle(fontSize: 11, color: AppColors.lostFoundColor, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Report Sheet ──────────────────────────────────────────────
class _ReportSheet extends StatefulWidget {
  final VoidCallback onReported;
  const _ReportSheet({required this.onReported});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  LostFoundStatus _status = LostFoundStatus.lost;
  LostFoundCategory _category = LostFoundCategory.other;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and location')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      await supabaseLostFoundService.reportItem(
        userId: user.id,
        userName: user.name,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: _status.name,
        category: _category.name,
        location: _locationController.text.trim(),
        dateOccurred: DateTime.now(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onReported();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item reported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report Item', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
          const SizedBox(height: 24),
          SegmentedButton<LostFoundStatus>(
            segments: const [
              ButtonSegment(value: LostFoundStatus.lost, label: Text('I lost it')),
              ButtonSegment(value: LostFoundStatus.found, label: Text('I found it')),
            ],
            selected: {_status},
            onSelectionChanged: (s) => setState(() => _status = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Item Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<LostFoundCategory>(
            value: _category,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: LostFoundCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
            onChanged: (v) => setState(() => _category = v ?? LostFoundCategory.other),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lostFoundColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const PremiumLoadingIndicator.small()
                  : const Text('Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
