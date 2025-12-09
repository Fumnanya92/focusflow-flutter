import 'package:flutter_test/flutter_test.dart';
import 'package:focusflow/core/services/data_validation_service.dart';

void main() {
  group('DataValidationService Tests', () {
    test('Email validation works correctly', () {
      expect(DataValidationService.isValidEmail('test@example.com'), true);
      expect(DataValidationService.isValidEmail('invalid-email'), false);
      expect(DataValidationService.isValidEmail('test@'), false);
    });

    test('Username validation works correctly', () {
      expect(DataValidationService.validateUsername('validuser'), null);
      expect(DataValidationService.validateUsername('ab'), 'Username must be at least 3 characters');
      expect(DataValidationService.validateUsername(''), 'Username is required');
      expect(DataValidationService.validateUsername('invalid@user'), 'Username can only contain letters, numbers, and underscores');
    });

    test('Password validation works correctly', () {
      expect(DataValidationService.validatePassword('Password123'), null);
      expect(DataValidationService.validatePassword('weak'), 'Password must be at least 8 characters');
      expect(DataValidationService.validatePassword(''), 'Password is required');
      expect(DataValidationService.validatePassword('alllowercase123'), 'Password must contain uppercase, lowercase, and number');
    });

    test('Input sanitization works correctly', () {
      expect(DataValidationService.sanitizeInput('normal text'), 'normal text');
      expect(DataValidationService.sanitizeInput('<script>alert("xss")</script>'), 'scriptalert(xss)/script');
      expect(DataValidationService.sanitizeInput('  padded text  '), 'padded text');
    });

    test('Task title validation works correctly', () {
      expect(DataValidationService.validateTaskTitle('Valid task'), null);
      expect(DataValidationService.validateTaskTitle(''), 'Task title is required');
      expect(DataValidationService.validateTaskTitle('   '), 'Task title is required');
    });

    test('Points validation works correctly', () {
      expect(DataValidationService.validatePoints(500), 500);
      expect(DataValidationService.validatePoints(-100), 0);
      expect(DataValidationService.validatePoints(1000000), 999999);
    });

    test('Package name validation works correctly', () {
      expect(DataValidationService.isValidPackageName('com.example.app'), true);
      expect(DataValidationService.isValidPackageName('invalid'), false);
      expect(DataValidationService.isValidPackageName('com.Example.App'), false);
    });
  });
}