import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../models/event_model.dart';

/// Edit Event Screen - For modifying existing events
class EditEventScreen extends StatefulWidget {
  final Event event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _venueController;
  late TextEditingController _capacityController;
  
  late EventCategory _category;
  late DateTime _eventDate;
  late TimeOfDay _eventTime;
  late bool _requiresRegistration;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _venueController = TextEditingController(text: widget.event.venue);
    _capacityController = TextEditingController(
      text: widget.event.maxParticipants?.toString() ?? '',
    );
    _category = widget.event.category;
    _eventDate = widget.event.eventDate;
    _eventTime = TimeOfDay.fromDateTime(widget.event.eventDate);
    _requiresRegistration = widget.event.requiresRegistration;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Event'),
        backgroundColor: AppColors.eventsColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _saveEvent,
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
            // Event Title
            _buildSectionTitle('Event Details'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration(
                'Event Title',
                'Enter a catchy title',
                Icons.event,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _inputDecoration(
                'Description',
                'What\'s this event about?',
                Icons.description,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Description is required' : null,
            ),
            const SizedBox(height: 24),

            // Category
            _buildSectionTitle('Category'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EventCategory.values.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Text(cat.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _category = cat);
                  },
                  selectedColor: AppColors.eventsColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : context.appColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Date & Time
            _buildSectionTitle('Date & Time'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPickerField(
                    icon: Icons.calendar_today,
                    label: _formatDate(_eventDate),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerField(
                    icon: Icons.access_time,
                    label: _eventTime.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Venue & Capacity
            _buildSectionTitle('Location'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _venueController,
              decoration: _inputDecoration(
                'Venue',
                'Where will it be held?',
                Icons.location_on,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Venue is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                'Capacity (Optional)',
                'Max attendees',
                Icons.people,
              ),
            ),
            const SizedBox(height: 24),

            // Registration toggle
            _buildSectionTitle('Registration'),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(
                'Require Registration',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
              ),
              subtitle: Text(
                _requiresRegistration
                    ? 'Attendees must RSVP'
                    : 'Open to all without RSVP',
                style: TextStyle(color: context.appColors.textTertiary),
              ),
              value: _requiresRegistration,
              onChanged: (v) => setState(() => _requiresRegistration = v),
              activeTrackColor: AppColors.eventsColor.withValues(alpha: 0.5),
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.eventsColor;
                }
                return null;
              }),
            ),
            const SizedBox(height: 32),

            // Delete Event Button
            OutlinedButton.icon(
              onPressed: _showDeleteConfirmation,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Event'),
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
      prefixIcon: Icon(icon, color: AppColors.eventsColor),
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
        borderSide: const BorderSide(color: AppColors.eventsColor, width: 1.5),
      ),
    );
  }

  Widget _buildPickerField({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.eventsColor, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: context.appColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _eventTime,
    );
    if (picked != null) {
      setState(() => _eventTime = picked);
    }
  }

  void _saveEvent() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final updatedEvent = Event(
      id: widget.event.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      eventDate: DateTime(
        _eventDate.year,
        _eventDate.month,
        _eventDate.day,
        _eventTime.hour,
        _eventTime.minute,
      ),
      venue: _venueController.text.trim(),
      maxParticipants: int.tryParse(_capacityController.text),
      requiresRegistration: _requiresRegistration,
      authorId: widget.event.authorId,
      authorName: widget.event.authorName,
      clubId: widget.event.clubId,
      clubName: widget.event.clubName,
      rsvpIds: widget.event.rsvpIds,
      createdAt: widget.event.createdAt,
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    context.read<MockDataService>().updateEvent(updatedEvent);

    setState(() => _isSubmitting = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${updatedEvent.title} updated!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text(
          'This will permanently delete "${widget.event.title}". This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MockDataService>().deleteEvent(widget.event.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              Navigator.pop(context); // Pop dashboard too
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.event.title} deleted'),
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
