import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';

/// Radio Management Screen — Admin controls for campus radio
class RadioManagementScreen extends StatefulWidget {
  const RadioManagementScreen({super.key});

  @override
  State<RadioManagementScreen> createState() => _RadioManagementScreenState();
}

class _RadioManagementScreenState extends State<RadioManagementScreen> {
  // In a real implementation this would fetch tracks/schedule from a service
  final List<String> _tracks = []; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radio Management'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: context.appColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: context.appColors.textPrimary),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _tracks.isEmpty
          ? const Center(
              child: EmptyStateWidget(
                icon: Icons.radio,
                title: 'No schedules yet',
                subtitle: 'Add shows or tracks to the schedule',
              ),
            )
          : ListView.builder(
              itemCount: _tracks.length,
              itemBuilder: (context, index) => ListTile(
                title: Text('Track ${index + 1}'),
                subtitle: const Text('Scheduled for later'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {},
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Placeholder for adding schedule functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule management coming soon')),
          );
        },
        backgroundColor: Colors.purple, // Radio theme color
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Schedule', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
