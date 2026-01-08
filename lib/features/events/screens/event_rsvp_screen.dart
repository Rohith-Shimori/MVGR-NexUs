import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';
import '../../../services/user_service.dart';
import '../models/event_model.dart';

/// Event RSVP Screen - Full registration form for events
class EventRSVPScreen extends StatefulWidget {
  final Event event;

  const EventRSVPScreen({super.key, required this.event});

  @override
  State<EventRSVPScreen> createState() => _EventRSVPScreenState();
}

class _EventRSVPScreenState extends State<EventRSVPScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  String _dietaryPreference = 'none';
  bool _needsTransport = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final user = MockUserService.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Event Registration'),
        backgroundColor: AppColors.eventsColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Event Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.eventsColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.eventsColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(event.category.icon, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(event.eventDate)} • ${event.venue}',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Registering As
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appColors.divider),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle, color: AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact Info
            _buildSectionTitle('Contact Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'For event updates',
                prefixIcon: Icon(Icons.phone, color: AppColors.eventsColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Phone is required' : null,
            ),
            const SizedBox(height: 24),

            // Preferences
            if (event.category == EventCategory.cultural || 
                event.category == EventCategory.seminar) ...[
              _buildSectionTitle('Preferences'),
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
                      leading: Icon(Icons.restaurant, color: AppColors.eventsColor),
                      title: const Text('Dietary Preference'),
                      trailing: DropdownButton<String>(
                        value: _dietaryPreference,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'none', child: Text('No preference')),
                          DropdownMenuItem(value: 'veg', child: Text('Vegetarian')),
                          DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                        ],
                        onChanged: (v) => setState(() => _dietaryPreference = v!),
                      ),
                    ),
                    Divider(height: 1, color: context.appColors.divider),
                    SwitchListTile(
                      secondary: Icon(Icons.directions_bus, color: AppColors.eventsColor),
                      title: const Text('Need Transport'),
                      subtitle: const Text('Shuttle service if available'),
                      value: _needsTransport,
                      onChanged: (v) => setState(() => _needsTransport = v),
                      activeTrackColor: AppColors.eventsColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Additional Notes
            _buildSectionTitle('Additional Notes (Optional)'),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any special requirements or questions...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 32),

            // Confirm Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _confirmRSVP,
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline),
                        SizedBox(width: 8),
                        Text('Confirm Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'You can cancel your registration anytime',
                style: TextStyle(fontSize: 12, color: context.appColors.textTertiary),
              ),
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

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  void _confirmRSVP() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final user = MockUserService.currentUser;
    context.read<MockDataService>().rsvpWithDetails(
      eventId: widget.event.id,
      eventTitle: widget.event.title,
      userId: user.uid,
      userName: user.name,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 You\'re registered! See you there.'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
    Navigator.pop(context); // Pop detail screen
  }
}
