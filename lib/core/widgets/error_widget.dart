/// Error Display Widget
/// Shows user-friendly error messages with retry option
library;

import 'package:flutter/material.dart';
import '../errors/app_exception.dart';

/// Error widget with retry button
class AppErrorWidget extends StatelessWidget {
  final AppException? error;
  final String? message;
  final VoidCallback? onRetry;
  final bool showRetry;
  final bool compact;

  const AppErrorWidget({
    super.key,
    this.error,
    this.message,
    this.onRetry,
    this.showRetry = true,
    this.compact = false,
  });

  factory AppErrorWidget.network({VoidCallback? onRetry}) => AppErrorWidget(
        error: NetworkException.noConnection(),
        onRetry: onRetry,
      );

  factory AppErrorWidget.notFound(String resource, {VoidCallback? onRetry}) => AppErrorWidget(
        error: DataException.notFound(resource),
        onRetry: onRetry,
        showRetry: false,
      );

  factory AppErrorWidget.generic(String message, {VoidCallback? onRetry}) => AppErrorWidget(
        message: message,
        onRetry: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayMessage = message ?? error?.message ?? 'An unexpected error occurred';
    final icon = _getIcon();

    if (compact) {
      return _buildCompact(theme, displayMessage, icon);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getTitle(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              displayMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(ThemeData theme, String displayMessage, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayMessage,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
          if (showRetry && onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: onRetry,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    if (error is NetworkException) {
      final code = (error as NetworkException).code;
      if (code == 'NO_CONNECTION') return Icons.wifi_off_rounded;
      if (code == 'TIMEOUT') return Icons.timer_off_rounded;
      return Icons.cloud_off_rounded;
    }
    if (error is AppAuthException) {
      return Icons.lock_outlined;
    }
    if (error is DataException) {
      final code = (error as DataException).code;
      if (code == 'NOT_FOUND') return Icons.search_off_rounded;
      if (code == 'PERMISSION_DENIED') return Icons.block_rounded;
      return Icons.error_outline;
    }
    return Icons.error_outline;
  }

  String _getTitle() {
    if (error is NetworkException) {
      final code = (error as NetworkException).code;
      if (code == 'NO_CONNECTION') return 'No Connection';
      if (code == 'TIMEOUT') return 'Request Timed Out';
      return 'Network Error';
    }
    if (error is AppAuthException) {
      return 'Authentication Error';
    }
    if (error is DataException) {
      final code = (error as DataException).code;
      if (code == 'NOT_FOUND') return 'Not Found';
      if (code == 'PERMISSION_DENIED') return 'Access Denied';
      return 'Error';
    }
    return 'Something Went Wrong';
  }
}

/// Empty state widget
class AppEmptyWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppEmptyWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
