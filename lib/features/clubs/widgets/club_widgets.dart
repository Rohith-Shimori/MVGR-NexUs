import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

import '../../../services/supabase_club_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/club_model.dart';

/// Club Card — Main card displayed in the clubs list
class ClubCard extends StatelessWidget {
  final Club club;
  final VoidCallback? onTap;

  const ClubCard({super.key, required this.club, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? AppColors.clayDark : AppColors.clayLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark ? ClayShadows.dark(intensity: 0.5) : ClayShadows.light(intensity: 0.5),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 85,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.clubsColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: club.logoUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: club.logoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Icon(club.category.iconData, size: 36, color: AppColors.clubsColor),
                        errorWidget: (_, __, ___) => Icon(club.category.iconData, size: 36, color: AppColors.clubsColor),
                      ),
                    )
                  : Center(child: Icon(club.category.iconData, size: 36, color: AppColors.clubsColor)),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      club.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      club.description,
                      style: TextStyle(fontSize: 13, color: context.appColors.textTertiary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.clubsColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            club.category.displayName,
                            style: TextStyle(fontSize: 11, color: AppColors.clubsColor, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.people, size: 14, color: context.appColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${club.totalMembers}',
                          style: TextStyle(fontSize: 12, color: context.appColors.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Member Button — Join/Leave/Pending button for club detail
class MemberButton extends StatefulWidget {
  final Club club;
  final bool isMember;
  final bool isPending;
  final VoidCallback onChange;

  const MemberButton({
    super.key,
    required this.club,
    required this.isMember,
    required this.isPending,
    required this.onChange,
  });

  @override
  State<MemberButton> createState() => _MemberButtonState();
}

class _MemberButtonState extends State<MemberButton> {
  bool _isLoading = false;

  Future<void> _toggleMembership() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      if (widget.isMember) {
        await supabaseClubService.leaveClub(widget.club.id, user.id);
      } else if (!widget.isPending) {
        await supabaseClubService.requestToJoin(widget.club.id, user.id, user.name);
      }
      widget.onChange();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String label;
    Color bgColor;

    if (widget.isMember) {
      label = 'Joined';
      bgColor = Colors.green;
    } else if (widget.isPending) {
      label = 'Pending';
      bgColor = Colors.orange;
    } else {
      label = 'Join';
      bgColor = AppColors.clubsColor;
    }

    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (widget.isPending ? null : _toggleMembership),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: _isLoading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Club Stat — Value/Label stat display
class ClubStat extends StatelessWidget {
  final String value;
  final String label;

  const ClubStat({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.appColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Contact Row — Icon + text row for contact info
class ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const ContactRow({super.key, required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.appColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: context.appColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Club Empty Card — Placeholder when no posts
class ClubEmptyCard extends StatelessWidget {
  final String message;

  const ClubEmptyCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.clayDark : AppColors.clayLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? ClayShadows.dark(intensity: 0.3) : ClayShadows.light(intensity: 0.3),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.article_outlined, size: 48, color: context.appColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 15, color: context.appColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Post Card — Displays a club post
class PostCard extends StatelessWidget {
  final ClubPost post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _postTypeColor(post.type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  post.type.displayName,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _postTypeColor(post.type)),
                ),
              ),
              if (post.isPinned) ...[
                const SizedBox(width: 8),
                Icon(Icons.push_pin, size: 14, color: AppColors.clubsColor),
              ],
              const Spacer(),
              Text(
                _formatDate(post.createdAt),
                style: TextStyle(fontSize: 11, color: context.appColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.appColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            post.content,
            style: TextStyle(fontSize: 14, color: context.appColors.textSecondary, height: 1.4),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(height: 180, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'by ${post.authorName}',
            style: TextStyle(fontSize: 12, color: context.appColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Color _postTypeColor(ClubPostType type) {
    switch (type) {
      case ClubPostType.announcement:
        return Colors.orange;
      case ClubPostType.event:
        return AppColors.eventsColor;
      case ClubPostType.recruitment:
        return Colors.green;
      case ClubPostType.general:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}

/// Create Club Sheet — Bottom sheet for creating new clubs
class CreateClubSheet extends StatefulWidget {
  const CreateClubSheet({super.key});

  @override
  State<CreateClubSheet> createState() => _CreateClubSheetState();
}

class _CreateClubSheetState extends State<CreateClubSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  ClubCategory _category = ClubCategory.technical;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a club name')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      await supabaseClubService.createClub(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _category.name,
        creatorId: user.id,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club created! Waiting for approval.')),
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
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Club', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.appColors.textPrimary)),
          const SizedBox(height: 24),
          TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Club Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextField(controller: _descController, maxLines: 3, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          DropdownButtonFormField<ClubCategory>(
            value: _category,
            decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: ClubCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
            onChanged: (v) => setState(() => _category = v ?? ClubCategory.technical),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.clubsColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
