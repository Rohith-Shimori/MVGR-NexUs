import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../../../services/user_service.dart';
import '../models/event_model.dart';

/// Full Create Event Screen with all form fields
class CreateEventScreen extends StatefulWidget {
  final String? clubId;
  final String? clubName;

  const CreateEventScreen({super.key, this.clubId, this.clubName});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _capacityController = TextEditingController();
  
  EventCategory _category = EventCategory.workshop;
  DateTime _eventDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _eventTime = const TimeOfDay(hour: 10, minute: 0);
  bool _requiresRegistration = true;
  bool _isSubmitting = false;
  File? _coverImage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _coverImage = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: AppColors.eventsColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _createEvent,
            child: Text(
              'Create',
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
            // Cover Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.appColors.divider),
                  image: _coverImage != null
                      ? DecorationImage(image: FileImage(_coverImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _coverImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, 
                               size: 48, color: AppColors.eventsColor),
                          const SizedBox(height: 8),
                          Text(
                            'Add Event Cover Image',
                            style: TextStyle(
                              color: AppColors.eventsColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),

            // Event Title
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
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(cat.displayName),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.eventsColor,
                  onSelected: (_) => setState(() => _category = cat),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Date & Time
            _buildSectionTitle('When'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DatePickerTile(
                    label: 'Date',
                    value: _formatDate(_eventDate),
                    icon: Icons.calendar_today,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerTile(
                    label: 'Time',
                    value: _formatTime(_eventTime),
                    icon: Icons.access_time,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Venue
            _buildSectionTitle('Where'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _venueController,
              decoration: _inputDecoration(
                'Venue',
                'e.g., Seminar Hall A, Room 301',
                Icons.location_on,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Venue is required' : null,
            ),
            const SizedBox(height: 24),

            // Capacity & Settings
            _buildSectionTitle('Settings'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appColors.divider),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.people, color: AppColors.eventsColor),
                    title: const Text('Max Capacity'),
                    subtitle: const Text('Leave empty for unlimited'),
                    trailing: SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: _capacityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '∞',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: context.appColors.divider),
                  SwitchListTile(
                    secondary: Icon(Icons.app_registration, color: AppColors.eventsColor),
                    title: const Text('Require Registration'),
                    subtitle: const Text('Attendees must RSVP'),
                    value: _requiresRegistration,
                    onChanged: (v) => setState(() => _requiresRegistration = v),
                    activeTrackColor: AppColors.eventsColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Organizing As (Enhanced)
            if (widget.clubName != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.clubsColor.withValues(alpha: 0.15),
                      AppColors.clubsColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.clubsColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.clubsColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.groups, color: AppColors.clubsColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Organizing as',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.appColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.clubName!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.clubsColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: AppColors.clubsColor, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Create Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _createEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.eventsColor,
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
                  : const Text('Create Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 40),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Theme.of(context).cardColor,
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _eventDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _eventTime,
    );
    if (time != null) setState(() => _eventTime = time);
  }

  void _createEvent() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    String? imageUrl;
    if (_coverImage != null) {
      // Mock upload result
      imageUrl = 'https://picsum.photos/800/400?random=${DateTime.now().millisecondsSinceEpoch}';
    }

    final user = MockUserService.currentUser;
    final eventDateTime = DateTime(
      _eventDate.year,
      _eventDate.month,
      _eventDate.day,
      _eventTime.hour,
      _eventTime.minute,
    );

    final event = Event(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text,
      description: _descriptionController.text,
      eventDate: eventDateTime,
      venue: _venueController.text,
      category: _category,
      imageUrl: imageUrl,
      authorId: user.uid,
      authorName: user.name,
      clubId: widget.clubId,
      clubName: widget.clubName,
      createdAt: DateTime.now(),
      requiresRegistration: _requiresRegistration,
      rsvpIds: [],
    );

    context.read<MockDataService>().addEvent(event);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event created successfully!'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.eventsColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                    ),
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
