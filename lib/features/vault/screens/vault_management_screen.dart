import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';

/// Vault Management Screen — Admin controls for vault items
class VaultManagementScreen extends StatelessWidget {
  const VaultManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Management'),
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
          icon: Icons.folder_special,
          title: 'Vault Management',
          subtitle: 'Admin tools for managing vault resources will appear here',
        ),
      ),
    );
  }
}
