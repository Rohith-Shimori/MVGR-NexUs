import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/widgets/empty_state_widget.dart';

/// Lost & Found Management Screen — Admin controls
class LostFoundManagementScreen extends StatelessWidget {
  const LostFoundManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found Management'),
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
      body: const Center(
        child: EmptyStateWidget(
          icon: Icons.search_off,
          title: 'Management Tools',
          subtitle: 'Admin tools for lost & found items will appear here',
        ),
      ),
    );
  }
}
