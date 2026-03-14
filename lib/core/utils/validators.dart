/// Form Validators
/// Reusable validation functions for forms
library;

/// Collection of form validators
class Validators {
  Validators._();

  /// Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    
    return null;
  }

  /// Password validation  
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    return null;
  }

  /// Strong password validation
  static String? strongPassword(String? value) {
    final basicError = password(value);
    if (basicError != null) return basicError;
    
    if (!RegExp(r'[A-Z]').hasMatch(value!)) {
      return 'Password must contain an uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    
    return null;
  }

  /// Required field validation
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Minimum length validation
  static String? minLength(String? value, int length, [String fieldName = 'This field']) {
    if (value == null || value.length < length) {
      return '$fieldName must be at least $length characters';
    }
    return null;
  }

  /// Maximum length validation
  static String? maxLength(String? value, int length, [String fieldName = 'This field']) {
    if (value != null && value.length > length) {
      return '$fieldName must be at most $length characters';
    }
    return null;
  }

  /// Phone number validation
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleaned.length < 10) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  /// URL validation
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  /// Confirm password validation
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      
      if (value != password) {
        return 'Passwords do not match';
      }
      
      return null;
    };
  }

  /// Combine multiple validators
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
