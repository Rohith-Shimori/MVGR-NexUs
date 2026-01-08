import 'package:flutter_test/flutter_test.dart';
import 'package:mvgr_nexus/core/utils/helpers.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('returns null for valid email', () {
        expect(Validators.email('test@example.com'), isNull);
        expect(Validators.email('user.name@domain.co.in'), isNull);
      });

      test('returns error for empty email', () {
        expect(Validators.email(null), 'Email is required');
        expect(Validators.email(''), 'Email is required');
      });

      test('returns error for invalid email format', () {
        expect(Validators.email('notanemail'), isNotNull);
        expect(Validators.email('missing@'), isNotNull);
        expect(Validators.email('@nodomain.com'), isNotNull);
        expect(Validators.email('spaces in@email.com'), isNotNull);
      });
    });

    group('collegeEmail', () {
      test('returns null for valid MVGR email', () {
        expect(Validators.collegeEmail('student@mvgrce.edu.in'), isNull);
        expect(Validators.collegeEmail('user@student.mvgrce.edu.in'), isNull);
        expect(Validators.collegeEmail('UPPER@MVGRCE.EDU.IN'), isNull);
      });

      test('returns error for empty email', () {
        expect(Validators.collegeEmail(null), 'College email is required');
        expect(Validators.collegeEmail(''), 'College email is required');
      });

      test('returns error for non-college email', () {
        expect(Validators.collegeEmail('user@gmail.com'), isNotNull);
        expect(Validators.collegeEmail('user@other.edu.in'), isNotNull);
        expect(Validators.collegeEmail('user@mvgr.com'), isNotNull);
      });
    });

    group('required', () {
      test('returns null for non-empty value', () {
        expect(Validators.required('some value'), isNull);
        expect(Validators.required('a'), isNull);
      });

      test('returns error for empty value', () {
        expect(Validators.required(null), 'This field is required');
        expect(Validators.required(''), 'This field is required');
      });

      test('uses custom field name in error message', () {
        expect(Validators.required('', 'Name'), 'Name is required');
        expect(Validators.required(null, 'Email'), 'Email is required');
      });
    });

    group('password', () {
      test('returns null for valid password (8+ chars)', () {
        expect(Validators.password('12345678'), isNull);
        expect(Validators.password('longerpassword'), isNull);
        expect(Validators.password('Password123!'), isNull);
      });

      test('returns error for empty password', () {
        expect(Validators.password(null), 'Password is required');
        expect(Validators.password(''), 'Password is required');
      });

      test('returns error for short password', () {
        expect(Validators.password('1234567'), isNotNull);
        expect(Validators.password('short'), isNotNull);
        expect(Validators.password('a'), isNotNull);
      });
    });

    group('confirmPassword', () {
      test('returns null when passwords match', () {
        expect(Validators.confirmPassword('password123', 'password123'), isNull);
        expect(Validators.confirmPassword('test', 'test'), isNull);
      });

      test('returns error for empty confirmation', () {
        expect(Validators.confirmPassword(null, 'password'), 'Please confirm your password');
        expect(Validators.confirmPassword('', 'password'), 'Please confirm your password');
      });

      test('returns error when passwords do not match', () {
        expect(Validators.confirmPassword('password1', 'password2'), 'Passwords do not match');
        expect(Validators.confirmPassword('abc', 'def'), 'Passwords do not match');
      });
    });

    group('phone', () {
      test('returns null for valid 10-digit phone starting with 6-9', () {
        expect(Validators.phone('9876543210'), isNull);
        expect(Validators.phone('6123456789'), isNull);
        expect(Validators.phone('7000000000'), isNull);
        expect(Validators.phone('8999999999'), isNull);
      });

      test('returns error for empty phone', () {
        expect(Validators.phone(null), 'Phone number is required');
        expect(Validators.phone(''), 'Phone number is required');
      });

      test('returns error for invalid phone format', () {
        expect(Validators.phone('1234567890'), isNotNull); // Starts with 1
        expect(Validators.phone('5123456789'), isNotNull); // Starts with 5
        expect(Validators.phone('987654321'), isNotNull);  // 9 digits
        expect(Validators.phone('98765432100'), isNotNull); // 11 digits
        expect(Validators.phone('abcdefghij'), isNotNull);  // Letters
      });
    });

    group('rollNumber', () {
      test('returns null for valid MVGR roll number format', () {
        expect(Validators.rollNumber('21BCE7100'), isNull);
        expect(Validators.rollNumber('22CSE1234'), isNull);
        expect(Validators.rollNumber('20EEE5678'), isNull);
        expect(Validators.rollNumber('23mec9999'), isNull); // lowercase should work
      });

      test('returns error for empty roll number', () {
        expect(Validators.rollNumber(null), 'Roll number is required');
        expect(Validators.rollNumber(''), 'Roll number is required');
      });

      test('returns error for invalid roll number format', () {
        expect(Validators.rollNumber('BCE21710'), isNotNull); // Wrong order
        expect(Validators.rollNumber('2BCE7100'), isNotNull);  // 1 digit year
        expect(Validators.rollNumber('21BC7100'), isNotNull);  // 2 letter branch
        expect(Validators.rollNumber('21BCE710'), isNotNull);  // 3 digit number
        expect(Validators.rollNumber('21BCE71000'), isNotNull); // 5 digit number
      });
    });

    group('minLength', () {
      test('returns null when value meets minimum length', () {
        expect(Validators.minLength('hello', 3), isNull);
        expect(Validators.minLength('abc', 3), isNull);
        expect(Validators.minLength('longer text', 5), isNull);
      });

      test('returns error for empty value', () {
        expect(Validators.minLength(null, 3), 'This field is required');
        expect(Validators.minLength('', 3), 'This field is required');
      });

      test('returns error when value is too short', () {
        expect(Validators.minLength('ab', 3), isNotNull);
        expect(Validators.minLength('hi', 5), isNotNull);
      });

      test('uses custom field name in error message', () {
        expect(Validators.minLength('ab', 3, 'Username'), contains('Username'));
      });
    });

    group('maxLength', () {
      test('returns null when value is within max length', () {
        expect(Validators.maxLength('hi', 5), isNull);
        expect(Validators.maxLength('hello', 5), isNull);
        expect(Validators.maxLength(null, 5), isNull); // null is ok
      });

      test('returns error when value exceeds max length', () {
        expect(Validators.maxLength('toolong', 5), isNotNull);
        expect(Validators.maxLength('exceeds limit', 5), isNotNull);
      });

      test('uses custom field name in error message', () {
        expect(Validators.maxLength('toolong', 5, 'Bio'), contains('Bio'));
      });
    });
  });
}
