import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium_loading_indicator.dart';

/// Edit Profile Sheet — Bottom sheet for updating user profile
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _bioController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // In a real implementation this would update the user profile via a service
    // For now we'll simulate a save operation
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
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
            'Edit Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Bio
          TextField(
            controller: _bioController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell us a bit about yourself...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            'Social Links',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          _SocialField(
            controller: _instagramController,
            label: 'Instagram',
            icon: Icons.camera_alt_outlined,
            prefix: '@',
          ),
          const SizedBox(height: 12),
          _SocialField(
            controller: _linkedinController,
            label: 'LinkedIn',
            icon: Icons.work_outline,
            prefix: 'linkedin.com/in/',
          ),
          const SizedBox(height: 12),
          _SocialField(
            controller: _websiteController,
            label: 'Website',
            icon: Icons.link,
            prefix: 'https://',
          ),
          
          const Spacer(),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const PremiumLoadingIndicator.small()
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String prefix;

  const _SocialField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
