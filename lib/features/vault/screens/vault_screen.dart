import '../../../core/widgets/glassmorphic_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/premium_loading_indicator.dart';
import '../../../services/supabase_vault_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/vault_model.dart';

/// The Vault — Academic resources: notes, PYQs, textbooks
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _searchController = TextEditingController();
  VaultItemType? _selectedType;
  String? _selectedBranch;
  bool _isLoading = true;
  List<VaultItem> _items = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<SupabaseVaultService>();
      await service.fetchItems(
        type: _selectedType,
        branch: _selectedBranch,
      );
      if (mounted) {
        setState(() {
          _items = service.items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<VaultItem> get _filteredItems {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((i) =>
      i.title.toLowerCase().contains(q) ||
      i.subject.toLowerCase().contains(q) ||
      i.branch.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadItems,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Header
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
                        AppColors.vaultColor,
                        AppColors.vaultColor.withValues(alpha: 0.7),
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
                            'The Vault',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Notes, PYQs & study materials',
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

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search notes, papers, textbooks...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.appColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.appColors.divider),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.clayDark : Colors.white,
                  ),
                ),
              ),
            ),

            // Type Filters
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    _buildFilterChip('All', _selectedType == null, () {
                      setState(() => _selectedType = null);
                      _loadItems();
                    }, isDark),
                    ...VaultItemType.values.map((t) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildFilterChip(t.displayName, _selectedType == t, () {
                        setState(() => _selectedType = t);
                        _loadItems();
                      }, isDark),
                    )),
                  ],
                ),
              ),
            ),

            // Content
            if (_isLoading)
              const SliverFillRemaining(child: ShimmerList())
            else if (_filteredItems.isEmpty)
              SliverFillRemaining(
                child: EmptyStateWidget(
                  icon: Icons.folder_open_outlined,
                  title: 'No resources found',
                  subtitle: _searchQuery.isNotEmpty
                      ? 'Try a different search term'
                      : 'Be the first to upload study material',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _VaultItemCard(
                    item: _filteredItems[index],
                    onTap: () => _showItemDetail(_filteredItems[index]),
                  ),
                  childCount: _filteredItems.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadSheet(context),
        backgroundColor: AppColors.vaultColor,
        child: const Icon(Icons.upload, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticUtils.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.vaultColor : (isDark ? AppColors.clayDark : AppColors.clayLight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? null : (isDark ? ClayShadows.dark(intensity: 0.4) : ClayShadows.light(intensity: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showItemDetail(VaultItem item) {
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
                    color: AppColors.vaultColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.type.iconData, color: AppColors.vaultColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.type.displayName} • ${item.subject}',
                        style: TextStyle(fontSize: 13, color: context.appColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (item.description.isNotEmpty) ...[
              Text(item.description, style: TextStyle(fontSize: 14, color: context.appColors.textSecondary)),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                _DetailChip(label: item.branch, icon: Icons.school),
                const SizedBox(width: 8),
                _DetailChip(label: 'Year ${item.year}', icon: Icons.calendar_today),
                const SizedBox(width: 8),
                _DetailChip(label: 'Sem ${item.semester}', icon: Icons.book),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.download, size: 16, color: context.appColors.textTertiary),
                const SizedBox(width: 4),
                Text('${item.downloadCount} downloads', style: TextStyle(fontSize: 12, color: context.appColors.textTertiary)),
                const Spacer(),
                Text('by ${item.uploaderName}', style: TextStyle(fontSize: 12, color: context.appColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await supabaseVaultService.recordDownload(item.id);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Download started')),
                    );
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vaultColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showGlassModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UploadSheet(onUploaded: _loadItems),
    );
  }
}

// ─── Vault Item Card ───────────────────────────────────────────
class _VaultItemCard extends StatelessWidget {
  final VaultItem item;
  final VoidCallback onTap;

  const _VaultItemCard({required this.item, required this.onTap});

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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.vaultColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.type.iconData, color: AppColors.vaultColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.appColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subject,
                    style: TextStyle(fontSize: 13, color: context.appColors.textTertiary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(item.branch, style: TextStyle(fontSize: 11, color: AppColors.vaultColor, fontWeight: FontWeight.w500)),
                      Text(' • ', style: TextStyle(color: context.appColors.textTertiary)),
                      Text(item.type.displayName, style: TextStyle(fontSize: 11, color: context.appColors.textTertiary)),
                      const Spacer(),
                      Icon(Icons.download, size: 14, color: context.appColors.textTertiary),
                      const SizedBox(width: 4),
                      Text('${item.downloadCount}', style: TextStyle(fontSize: 11, color: context.appColors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _DetailChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.vaultColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.vaultColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.vaultColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Upload Sheet ──────────────────────────────────────────────
class _UploadSheet extends StatefulWidget {
  final VoidCallback onUploaded;
  const _UploadSheet({required this.onUploaded});

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController();
  VaultItemType _type = VaultItemType.notes;
  String _branch = 'CSE';
  int _year = 2;
  int _semester = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and subject')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final item = VaultItem(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        fileUrl: '',
        fileName: '',
        fileSizeBytes: 0,
        type: _type,
        subject: _subjectController.text.trim(),
        branch: _branch,
        year: _year,
        semester: _semester,
        uploaderId: user.id,
        uploaderName: user.name,
        createdAt: DateTime.now(),
      );

      await supabaseVaultService.addItem(item);
      if (mounted) {
        Navigator.pop(context);
        widget.onUploaded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource uploaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Resource',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.appColors.textPrimary),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<VaultItemType>(
                  value: _type,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: VaultItemType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                  onChanged: (v) => setState(() => _type = v ?? VaultItemType.notes),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _branch,
                  decoration: InputDecoration(
                    labelText: 'Branch',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: Branches.all.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) => setState(() => _branch = v ?? 'CSE'),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vaultColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const PremiumLoadingIndicator.small()
                  : const Text('Upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
