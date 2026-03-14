/// Forgot Password Screen for MVGR NexUs
/// Handles password reset requests
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_field.dart';
import '../../../core/utils/helpers.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await context.read<AuthProvider>().sendPasswordReset(_emailController.text.trim());

    setState(() => _isLoading = false);

    result.fold(
      onSuccess: (_) {
        HapticUtils.success();
        setState(() => _emailSent = true);
      },
      onFailure: (error) {
        HapticUtils.error();
        setState(() => _errorMessage = error.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessState(theme) : _buildForm(theme),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // Header
          _buildHeader(theme),

          const SizedBox(height: 32),

          // Error message
          if (_errorMessage != null) ...[
            _buildErrorBanner(),
            const SizedBox(height: 16),
          ],

          // Email field
          AuthFormField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your registered email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: Validators.email,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
          ),

          const SizedBox(height: 24),

          // Reset button
          FilledButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Send Reset Link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),

          const SizedBox(height: 24),

          // Back to login
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),

        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            boxShadow: ClayShadows.light(intensity: 0.4),
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 44,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Email Sent!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'We\'ve sent a password reset link to:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          _emailController.text.trim(),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Please check your inbox and follow the link to reset your password.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Login'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 16),

        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _errorMessage = null;
            });
          },
          child: const Text('Try a different email'),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: SkeuoShadows.raised(AppColors.primary, elevation: 1.0),
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Forgot Password?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email and we\'ll send you a link to reset your password.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? ClayShadows.dark(intensity: 0.3)
            : ClayShadows.light(intensity: 0.3),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.error_outline, color: Colors.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
