import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/utils/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../services/supabase_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/supabase_announcement_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../events/models/event_model.dart';

/// Create Announcement Screen - For council members to create announcements
class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isPinned = false;
  bool _isUrgent = false;
  bool _isSubmitting = false;
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Announcement'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitAnnouncement,
            child: Text(
              'Post',
              style: TextStyle(
                color: Colors.white.withValues(alpha: _isSubmitting ? 0.5 : 1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Options
            Text(
              'Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appColors.divider),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Pin to top'),
                    subtitle: const Text('Keep this announcement visible'),
                    value: _isPinned,
                    onChanged: (value) => setState(() => _isPinned = value),
                    thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : null),
                  ),
                  Divider(height: 1, color: context.appColors.divider),
                  SwitchListTile(
                    title: const Text('Mark as Urgent'),
                    subtitle: const Text('Highlight with urgent styling'),
                    value: _isUrgent,
                    onChanged: (value) => setState(() => _isUrgent = value),
                    thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.error : null),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Image Picker
            Text(
              'Image (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
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
                            'Add Image',
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

            // Title
            Text(
              'Title',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Announcement title...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),

            const SizedBox(height: 24),

            // Content
            Text(
              'Content',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Write your announcement...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),

            const SizedBox(height: 32),

            // Preview Card
            Text(
              'Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _PreviewCard(
              title: _titleController.text.isEmpty ? 'Announcement Title' : _titleController.text,
              content: _contentController.text.isEmpty ? 'Your announcement content will appear here...' : _contentController.text,
              isUrgent: _isUrgent,
              isPinned: _isPinned,
              imageFile: _selectedImage,
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAnnouncement() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = context.read<AuthProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    String? imageUrl;
    if (_selectedImage != null) {
       final storageService = context.read<SupabaseStorageService>();
       try {
         // Assuming 'announcements' bucket exists, or uses 'public' or similar. 
         // For now let's use 'announcements' bucket name.
         imageUrl = await storageService.uploadFile(
            'announcements', 
            '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg',
            _selectedImage!
         );
       } catch (e) {
         AppLogger.error('Error uploading image: $e');
       }
    }
    
    final announcement = Announcement(
      id: '',
      title: _titleController.text,
      content: _contentController.text,
      createdAt: DateTime.now(),
      authorId: user.id,
      authorName: user.name,
      authorRole: user.role.displayName,
      isPinned: _isPinned,
      isUrgent: _isUrgent,
      imageUrl: imageUrl,
    );

    await supabaseAnnouncementService.createAnnouncement(announcement);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement posted!')),
      );
      Navigator.pop(context);
    }
  }
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isUrgent;
  final bool isPinned;
  final File? imageFile;

  const _PreviewCard({
    required this.title,
    required this.content,
    required this.isUrgent,
    required this.isPinned,
    this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isUrgent ? AppColors.error : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageFile != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.file(
                imageFile!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: imageFile != null 
                  ? BorderRadius.zero 
                  : const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.campaign, color: accentColor, size: 20),
                const SizedBox(width: 8),
                if (isUrgent)
                  Text(
                    'URGENT',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                const Spacer(),
                if (isPinned)
                  Icon(Icons.push_pin, size: 16, color: accentColor),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.appColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
