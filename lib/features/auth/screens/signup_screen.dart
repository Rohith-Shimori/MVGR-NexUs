/// Signup Screen for MVGR NexUs
/// Handles new user registration
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_field.dart';
import '../../../core/utils/helpers.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback? onSignupSuccess;

  const SignupScreen({super.key, this.onSignupSuccess});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String _selectedDepartment = 'Computer Science';
  int _selectedYear = 1;

  static const List<String> _departments = [
    'Computer Science',
    'Information Technology',
    'Electronics',
    'Electrical',
    'Mechanical',
    'Civil',
    'Chemical',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _rollNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // Check password match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );

    if (result.isSuccess) {
      await authProvider.updateProfile(
        department: _selectedDepartment,
        year: _selectedYear,
        rollNumber: _rollNumberController.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    result.fold(
      onSuccess: (_) {
        HapticUtils.success();
        UIHelpers.showSuccessSnackBar(
          context,
          'Account created successfully! Please verify your email.',
        );
        widget.onSignupSuccess?.call();
        Navigator.pop(context);
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
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(theme),
                
                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null) ...[
                  _buildErrorBanner(),
                  const SizedBox(height: 16),
                ],

                // Name field
                AuthFormField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icons.person_outlined,
                  validator: Validators.required,
                  textInputAction: TextInputAction.next,
                ),
                
                const SizedBox(height: 16),

                // Email field
                AuthFormField(
                  controller: _emailController,
                  label: 'College Email',
                  hint: 'your.email@mvgrce.edu.in',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.collegeEmail,
                  textInputAction: TextInputAction.next,
                ),
                
                const SizedBox(height: 16),

                // Roll number field
                AuthFormField(
                  controller: _rollNumberController,
                  label: 'Roll Number',
                  hint: '22BQ1A0501',
                  prefixIcon: Icons.badge_outlined,
                  validator: Validators.rollNumber,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                ),
                
                const SizedBox(height: 16),

                // Department dropdown
                _buildDepartmentDropdown(theme),
                
                const SizedBox(height: 16),

                // Year dropdown
                _buildYearDropdown(theme),
                
                const SizedBox(height: 16),

                // Password field
                AuthFormField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a strong password',
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword 
                          ? Icons.visibility_outlined 
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                ),
                
                const SizedBox(height: 16),

                // Confirm password field
                AuthFormField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword 
                          ? Icons.visibility_outlined 
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (value) => Validators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSignup(),
                ),
                
                const SizedBox(height: 32),

                // Signup button
                FilledButton(
                  onPressed: _isLoading ? null : _handleSignup,
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                
                const SizedBox(height: 24),

                // Terms
                Text(
                  'By signing up, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            Icons.person_add_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Join MVGR NexUs',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Create your student account',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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

  Widget _buildDepartmentDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedDepartment,
      decoration: InputDecoration(
        labelText: 'Department',
        prefixIcon: const Icon(Icons.school_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: _departments.map((dept) {
        return DropdownMenuItem(value: dept, child: Text(dept));
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedDepartment = value);
      },
    );
  }

  Widget _buildYearDropdown(ThemeData theme) {
    return DropdownButtonFormField<int>(
      initialValue: _selectedYear,
      decoration: InputDecoration(
        labelText: 'Year',
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: [1, 2, 3, 4].map((year) {
        return DropdownMenuItem(
          value: year,
          child: Text('$year${_getYearSuffix(year)} Year'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedYear = value);
      },
    );
  }

  String _getYearSuffix(int year) {
    switch (year) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}
