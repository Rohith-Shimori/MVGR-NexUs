import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../../events/models/event_model.dart';

/// Edit Announcement Screen - For modifying existing announcements
class EditAnnouncementScreen extends StatefulWidget {
  final Announcement announcement;

  const EditAnnouncementScreen({super.key, required this.announcement});

  @override
  State<EditAnnouncementScreen> createState() => _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState extends State<EditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  
  late bool _isUrgent;
  late bool _isPinned;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _contentController = TextEditingController(text: widget.announcement.content);
    _isUrgent = widget.announcement.isUrgent;
    _isPinned = widget.announcement.isPinned;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Announcement'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _saveAnnouncement,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            _buildSectionTitle('Announcement Details'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration(
                'Title',
                'Announcement title',
                Icons.title,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Content
            TextFormField(
              controller: _contentController,
              maxLines: 6,
              decoration: _inputDecoration(
                'Content',
                'What do you want to announce?',
                Icons.description,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Content is required' : null,
            ),
            const SizedBox(height: 24),

            // Options
            _buildSectionTitle('Options'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(
                'Mark as Urgent',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Displays with red highlight',
                style: TextStyle(color: context.appColors.textTertiary),
              ),
              value: _isUrgent,
              onChanged: (v) => setState(() => _isUrgent = v),
              activeTrackColor: AppColors.error.withValues(alpha: 0.5),
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.error;
                }
                return null;
              }),
            ),
            SwitchListTile(
              title: Text(
                'Pin to Top',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Keeps announcement at top of list',
                style: TextStyle(color: context.appColors.textTertiary),
              ),
              value: _isPinned,
              onChanged: (v) => setState(() => _isPinned = v),
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return null;
              }),
            ),
            const SizedBox(height: 32),

            // Delete Button
            OutlinedButton.icon(
              onPressed: _showDeleteConfirmation,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Announcement'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
      prefixIcon: Icon(icon, color: AppColors.primary),
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
    );
  }

  void _saveAnnouncement() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final updatedAnnouncement = Announcement(
      id: widget.announcement.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      authorId: widget.announcement.authorId,
      authorName: widget.announcement.authorName,
      authorRole: widget.announcement.authorRole,
      isUrgent: _isUrgent,
      isPinned: _isPinned,
      createdAt: widget.announcement.createdAt,
      expiresAt: widget.announcement.expiresAt,
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    context.read<MockDataService>().updateAnnouncement(updatedAnnouncement);

    setState(() => _isSubmitting = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Announcement updated!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: Text(
          'This will permanently delete "${widget.announcement.title}". This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MockDataService>().deleteAnnouncement(widget.announcement.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Announcement deleted'),
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
