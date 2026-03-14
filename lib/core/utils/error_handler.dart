/// Error Handler Utility
/// Centralized error handling with user-friendly messages
library;

import 'package:flutter/material.dart';
import '../errors/app_exception.dart';

/// Centralized error handler for consistent error UI
class ErrorHandler {
  ErrorHandler._();

  /// Show error snackbar with appropriate message
  static void showError(BuildContext context, dynamic error) {
    final message = _getErrorMessage(error);
    
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    
    if (error is NetworkException) {
      return error.message;
    }
    
    if (error is AppAuthException) {
      return error.message;
    }
    
    if (error is ValidationException) {
      return error.message;
    }
    
    if (error is DataException) {
      return error.message;
    }
    
    // Generic error
    final message = error.toString();
    
    // Clean up common Supabase/network errors
    if (message.contains('SocketException') || message.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network.';
    }
    
    if (message.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    
    if (message.contains('401') || message.contains('Unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    
    if (message.contains('403') || message.contains('Forbidden')) {
      return 'You don\'t have permission for this action.';
    }
    
    if (message.contains('404') || message.contains('not found')) {
      return 'The requested resource was not found.';
    }
    
    if (message.contains('500') || message.contains('Internal Server')) {
      return 'Server error. Please try again later.';
    }
    
    // Return a generic message for unknown errors
    return 'Something went wrong. Please try again.';
  }

  /// Show error dialog for critical errors
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
  }) async {
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
