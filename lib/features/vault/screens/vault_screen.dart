import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../../../services/user_service.dart';
import '../models/vault_model.dart';

/// Premium Vault Screen - Library-like aesthetic
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedBranch;
  String? _selectedYear;
  String? _selectedType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
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
                      AppColors.vaultColor,
                      AppColors.vaultColor.withValues(alpha: 0.8),
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
                        const SizedBox(height: 4),
                        Text(
                          'Academic resources shared by students',
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
                icon: const Icon(Icons.upload_outlined, color: Colors.white),
                onPressed: () => _showUploadSheet(context),
                tooltip: 'Upload Resource',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Search and Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.appColors.divider),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search notes, papers, textbooks...',
                        hintStyle: TextStyle(color: context.appColors.textTertiary),
                        prefixIcon: Icon(Icons.search, color: context.appColors.textTertiary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: _selectedBranch ?? 'Branch',
                          isSelected: _selectedBranch != null,
                          onTap: () => _showBranchPicker(),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _selectedYear ?? 'Year',
                          isSelected: _selectedYear != null,
                          onTap: () => _showYearPicker(),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _selectedType ?? 'Type',
                          isSelected: _selectedType != null,
                          onTap: () => _showTypePicker(),
                        ),
                        if (_selectedBranch != null || _selectedYear != null || _selectedType != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() {
                              _selectedBranch = null;
                              _selectedYear = null;
                              _selectedType = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.error,
                                ),
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
          ),

          // Resources List
          Consumer<MockDataService>(
            builder: (context, dataService, _) {
              var items = dataService.vaultItems.where((item) {
                final matchesSearch = _searchQuery.isEmpty ||
                    item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    item.subject.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchesBranch = _selectedBranch == null || item.branch == _selectedBranch;
                final matchesYear = _selectedYear == null || item.year.toString() == _selectedYear;
                final matchesType = _selectedType == null || item.type.displayName == _selectedType;
                return matchesSearch && matchesBranch && matchesYear && matchesType;
              }).toList();

              if (items.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'No resources found',
                    subtitle: 'Try adjusting your filters or search query',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ResourceCard(item: items[index]),
                    ),
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),

          // Bottom Padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showBranchPicker() {
    _showPickerSheet(
      context: context,
      title: 'Select Branch',
      options: ['CSE', 'ECE', 'EEE', 'MECH', 'CIVIL', 'IT'],
      currentValue: _selectedBranch,
      onSelect: (value) => setState(() => _selectedBranch = value),
    );
  }

  void _showYearPicker() {
    _showPickerSheet(
      context: context,
      title: 'Select Year',
      options: ['1st Year', '2nd Year', '3rd Year', '4th Year'],
      currentValue: _selectedYear,
      onSelect: (value) => setState(() => _selectedYear = value),
    );
  }

  void _showTypePicker() {
    _showPickerSheet(
      context: context,
      title: 'Select Type',
      options: VaultItemType.values.map((t) => t.displayName).toList(),
      currentValue: _selectedType,
      onSelect: (value) => setState(() => _selectedType = value),
    );
  }

  void _showPickerSheet({
    required BuildContext context,
    required String title,
    required List<String> options,
    String? currentValue,
    required void Function(String?) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((option) => ListTile(
              title: Text(option),
              trailing: currentValue == option
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                onSelect(currentValue == option ? null : option);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _UploadSheet(),
    );
  }
}

/// Filter Chip
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.appColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : context.appColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: isSelected ? Colors.white : context.appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Resource Card
class _ResourceCard extends StatelessWidget {
  final VaultItem item;

  const _ResourceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTypeColor(item.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getTypeIcon(item.type),
                    color: _getTypeColor(item.type),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subject,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.appColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            
            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Tag(label: item.branch, color: AppColors.clubsColor),
                _Tag(label: 'Year ${item.year}', color: AppColors.eventsColor),
                _Tag(label: item.type.displayName, color: _getTypeColor(item.type)),
              ],
            ),
            const SizedBox(height: 14),
            
            // Footer
            Row(
              children: [
                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Downloads
                Row(
                  children: [
                    Icon(Icons.download_outlined, size: 16, color: context.appColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${item.downloadCount}',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Download Button
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading ${item.title}...'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(VaultItemType type) {
    switch (type) {
      case VaultItemType.notes:
        return AppColors.forumColor;
      case VaultItemType.pyq:
        return AppColors.eventsColor;
      case VaultItemType.handwritten:
        return AppColors.clubsColor;
      case VaultItemType.assignment:
        return AppColors.studyBuddyColor;
      case VaultItemType.slides:
        return AppColors.vaultColor;
      case VaultItemType.lab:
        return AppColors.playBuddyColor;
      case VaultItemType.other:
        return AppColors.textSecondaryLight;
    }
  }

  IconData _getTypeIcon(VaultItemType type) {
    switch (type) {
      case VaultItemType.notes:
        return Icons.note_outlined;
      case VaultItemType.pyq:
        return Icons.assignment_outlined;
      case VaultItemType.handwritten:
        return Icons.draw_outlined;
      case VaultItemType.assignment:
        return Icons.edit_document;
      case VaultItemType.slides:
        return Icons.slideshow_outlined;
      case VaultItemType.lab:
        return Icons.science_outlined;
      case VaultItemType.other:
        return Icons.folder_outlined;
    }
  }
}

/// Tag
class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

/// Empty State
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: context.appColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: context.appColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Upload Sheet
class _UploadSheet extends StatefulWidget {
  const _UploadSheet();

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  String _branch = 'CSE';
  String _year = '1st Year';
  VaultItemType _type = VaultItemType.notes;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                'Share a Resource',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help your fellow students by sharing study materials',
                style: TextStyle(
                  fontSize: 14,
                  color: context.appColors.textTertiary,
                ),
              ),
              const SizedBox(height: 24),

              // Form Fields
              _FormField(
                controller: _titleController,
                label: 'Title',
                hint: 'e.g. Data Structures Notes - Unit 1',
                validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              
              _FormField(
                controller: _subjectController,
                label: 'Subject',
                hint: 'e.g. Data Structures',
                validator: (v) => v?.isEmpty ?? true ? 'Subject is required' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _DropdownField(
                      label: 'Branch',
                      value: _branch,
                      items: ['CSE', 'ECE', 'EEE', 'MECH', 'CIVIL', 'IT'],
                      onChanged: (v) => setState(() => _branch = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DropdownField(
                      label: 'Year',
                      value: _year,
                      items: ['1st Year', '2nd Year', '3rd Year', '4th Year'],
                      onChanged: (v) => setState(() => _year = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _DropdownField<VaultItemType>(
                label: 'Type',
                value: _type,
                items: VaultItemType.values,
                displayBuilder: (v) => v.displayName,
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 24),
              
              // Upload Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.upload),
                  label: Text(_isLoading ? 'Uploading...' : 'Upload Resource'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vaultColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
      await Future.delayed(const Duration(seconds: 1));
      
      final user = MockUserService.currentUser;
      final item = VaultItem(
        id: 'vault_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text,
        subject: _subjectController.text,
        branch: _branch,
        year: int.tryParse(_year.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
        semester: 1,
        type: _type,
        uploaderId: user.uid,
        uploaderName: user.name,
        fileUrl: 'https://example.com/file.pdf',
        fileName: '${_titleController.text.replaceAll(' ', '_')}.pdf',
        fileSizeBytes: 1024 * 1024,
        createdAt: DateTime.now(),
      );
      
      if (!mounted) return;
      context.read<MockDataService>().addVaultItem(item);
      
      setState(() => _isLoading = false);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resource uploaded successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

/// Form Field
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
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
          maxLines: 1,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

/// Dropdown Field
class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T)? displayBuilder;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    this.displayBuilder,
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
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(displayBuilder?.call(item) ?? item.toString()),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
