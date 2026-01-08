import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../models/club_model.dart';

/// Edit Club Screen - For club admins to modify club details
class EditClubScreen extends StatefulWidget {
  final Club club;

  const EditClubScreen({super.key, required this.club});

  @override
  State<EditClubScreen> createState() => _EditClubScreenState();
}

class _EditClubScreenState extends State<EditClubScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _taglineController;
  late ClubCategory _category;
  late bool _isPrivate;
  bool _isSubmitting = false;
  File? _selectedIcon;
  File? _selectedCover;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.club.name);
    _descriptionController = TextEditingController(text: widget.club.description);
    _taglineController = TextEditingController();
    _category = widget.club.category;
    _isPrivate = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isCover) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isCover) {
          _selectedCover = File(pickedFile.path);
        } else {
          _selectedIcon = File(pickedFile.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Club'),
        backgroundColor: AppColors.clubsColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _saveChanges,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.white.withValues(alpha: _isSubmitting ? 0.5 : 1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Cover Image Picker
          GestureDetector(
            onTap: () => _pickImage(true),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.appColors.divider),
                image: _selectedCover != null
                    ? DecorationImage(image: FileImage(_selectedCover!), fit: BoxFit.cover)
                    : (widget.club.coverImageUrl != null
                        ? DecorationImage(image: NetworkImage(widget.club.coverImageUrl!), fit: BoxFit.cover)
                        : null),
              ),
              child: _selectedCover == null && widget.club.coverImageUrl == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40, color: context.appColors.textTertiary),
                          const SizedBox(height: 8),
                          Text(
                            'Add Cover Image',
                            style: TextStyle(color: context.appColors.textTertiary),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Club Icon Picker
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.clubsColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.clubsColor.withValues(alpha: 0.3)),
                      image: _selectedIcon != null
                          ? DecorationImage(image: FileImage(_selectedIcon!), fit: BoxFit.cover)
                          : (widget.club.logoUrl != null
                              ? DecorationImage(image: NetworkImage(widget.club.logoUrl!), fit: BoxFit.cover)
                              : null),
                    ),
                    child: _selectedIcon == null && widget.club.logoUrl == null
                        ? Center(
                            child: Icon(_category.iconData, size: 48, color: AppColors.clubsColor),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Club Icon',
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Name
          _buildSectionTitle('Basic Info'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration('Club Name', 'Enter club name', Icons.groups),
          ),
          const SizedBox(height: 16),

          // Tagline
          TextFormField(
            controller: _taglineController,
            decoration: _inputDecoration('Tagline', 'A short catchy tagline', Icons.short_text),
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: _inputDecoration('Description', 'What does your club do?', Icons.description),
          ),
          const SizedBox(height: 24),

          // Category
          _buildSectionTitle('Category'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ClubCategory.values.map((cat) {
              final isSelected = _category == cat;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(cat.displayName),
                  ],
                ),
                selected: isSelected,
                selectedColor: AppColors.clubsColor,
                onSelected: (_) => setState(() => _category = cat),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Privacy Settings
          _buildSectionTitle('Privacy'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appColors.divider),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.public),
                      label: Text('Public'),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.lock),
                      label: Text('Private'),
                    ),
                  ],
                  selected: {_isPrivate},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() => _isPrivate = selection.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.clubsColor;
                      }
                      return null;
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isPrivate 
                      ? 'Requires admin approval to join' 
                      : 'Anyone can join instantly',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.clubsColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),

          // Danger Zone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _showDeleteConfirmation(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_forever, size: 18),
                      SizedBox(width: 8),
                      Text('Delete Club'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.appColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.clubsColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Theme.of(context).cardColor,
    );
  }

  void _saveChanges() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Club name is required')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate image upload by generating random URLs if files selected
    String? newLogoUrl = widget.club.logoUrl;
    if (_selectedIcon != null) {
      // Mock upload result
      newLogoUrl = 'https://picsum.photos/200?random=${DateTime.now().millisecondsSinceEpoch}';
    }

    String? newCoverUrl = widget.club.coverImageUrl;
    if (_selectedCover != null) {
      // Mock upload result
      newCoverUrl = 'https://picsum.photos/800/400?random=${DateTime.now().millisecondsSinceEpoch}';
    }

    final updatedClub = widget.club.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
      category: _category,
      logoUrl: newLogoUrl,
      coverImageUrl: newCoverUrl,
      isApproved: widget.club.isApproved, // Maintain status
    );

    context.read<MockDataService>().updateClub(updatedClub);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Club updated successfully!'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Club?'),
        content: Text(
          'This will permanently delete "${widget.club.name}" and all its posts. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Actually delete the club
              context.read<MockDataService>().deleteClub(widget.club.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              Navigator.pop(context); // Pop dashboard too
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.club.name} deleted'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
