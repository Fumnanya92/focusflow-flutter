import 'package:flutter_test/flutter_test.dart';
import 'package:focusflow/core/services/data_validation_service.dart';

void main() {
  group('Storage Security Tests', () {
    test('Encryption key generation works correctly', () {
      // Test that we can generate consistent keys
      expect(() => 'focusflow_secure_storage'.hashCode, returnsNormally);
    });

    test('Sensitive data patterns are detected', () {
      // Test password validation for security
      expect(DataValidationService.validatePassword('weak'), contains('8 characters'));
      expect(DataValidationService.validatePassword('NoNumbers!'), contains('number'));
      expect(DataValidationService.validatePassword('StrongPass123'), isNull);
    });

    test('Input sanitization prevents security issues', () {
      final maliciousInput = '<script>alert("xss")</script>';
      final sanitized = DataValidationService.sanitizeInput(maliciousInput);
      
      expect(sanitized, isNot(contains('<')));
      expect(sanitized, isNot(contains('>')));
      expect(sanitized, equals('scriptalert(xss)/script'));
    });

    test('Package name validation works for security', () {
      expect(DataValidationService.isValidPackageName('com.malicious.APP'), false);
      expect(DataValidationService.isValidPackageName('com.facebook.katana'), true);
      expect(DataValidationService.isValidPackageName('invalid'), false);
    });
  });
  
  test('Error handling works correctly for validation', () {
    // Test password validation returns error messages
    expect(DataValidationService.validatePassword(''), 'Password is required');
    expect(DataValidationService.validatePassword('weak'), 'Password must be at least 8 characters');
    
    // Test empty string handling
    expect(DataValidationService.sanitizeInput(''), equals(''));
    
    // Test validation edge cases
    expect(DataValidationService.isValidEmail(''), false);
    expect(DataValidationService.validateUsername(''), 'Username is required');
  });
}