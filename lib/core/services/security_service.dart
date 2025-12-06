import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class SecurityService {
  
  // Generate a secure random salt
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  // Hash sensitive data with salt
  static String hashData(String data, String salt) {
    final bytes = utf8.encode(data + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Validate password strength
  static PasswordStrength validatePasswordStrength(String password) {
    if (password.length < 8) {
      return PasswordStrength.weak;
    }

    int score = 0;
    
    // Length check
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;

    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    // No common patterns
    if (!_hasCommonPatterns(password)) score++;

    if (score < 4) return PasswordStrength.weak;
    if (score < 6) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  static bool _hasCommonPatterns(String password) {
    final commonPatterns = [
      'password',
      '123456',
      'qwerty',
      'abc123',
      'admin',
      'letmein',
      'welcome',
    ];

    final lowerPassword = password.toLowerCase();
    
    for (final pattern in commonPatterns) {
      if (lowerPassword.contains(pattern)) {
        return true;
      }
    }

    // Check for repeated characters
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      return true;
    }

    // Check for sequential numbers or letters
    if (RegExp(r'(012|123|234|345|456|567|678|789|890)').hasMatch(password) ||
        RegExp(r'(abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)', caseSensitive: false).hasMatch(password)) {
      return true;
    }

    return false;
  }

  // Sanitize user input
  static String sanitizeInput(String input) {
    // Remove potential XSS characters
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[<>"' "']"), '') // Remove dangerous characters
        .trim();
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate username format
  static bool isValidUsername(String username) {
    // 3-20 characters, alphanumeric and underscore only
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  // Rate limiting for security
  static final Map<String, List<DateTime>> _attempts = {};
  
  static bool checkRateLimit(String identifier, {int maxAttempts = 5, Duration window = const Duration(minutes: 15)}) {
    final now = DateTime.now();
    final windowStart = now.subtract(window);
    
    _attempts[identifier] ??= [];
    
    // Remove old attempts outside the window
    _attempts[identifier]!.removeWhere((attempt) => attempt.isBefore(windowStart));
    
    // Check if under limit
    if (_attempts[identifier]!.length >= maxAttempts) {
      return false;
    }
    
    // Record this attempt
    _attempts[identifier]!.add(now);
    return true;
  }

  // Clear rate limit for identifier
  static void clearRateLimit(String identifier) {
    _attempts.remove(identifier);
  }

  // Generate secure session token
  static String generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  // Validate session token format
  static bool isValidSessionToken(String token) {
    try {
      final decoded = base64Decode(token);
      return decoded.length == 32;
    } catch (e) {
      return false;
    }
  }

  // Secure data transmission helpers
  static Map<String, dynamic> encodeSecureData(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    return {
      'data': base64Encode(bytes),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'checksum': _generateChecksum(jsonString),
    };
  }

  static Map<String, dynamic>? decodeSecureData(Map<String, dynamic> encodedData) {
    try {
      final dataString = utf8.decode(base64Decode(encodedData['data']));
      final timestamp = encodedData['timestamp'] as int;
      final checksum = encodedData['checksum'] as String;
      
      // Verify checksum
      if (_generateChecksum(dataString) != checksum) {
        return null;
      }
      
      // Check if data is not too old (24 hours)
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > 24 * 60 * 60 * 1000) {
        return null;
      }
      
      return jsonDecode(dataString);
    } catch (e) {
      return null;
    }
  }

  static String _generateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Biometric authentication check
  static Future<bool> isBiometricAvailable() async {
    try {
      // This would typically use local_auth package
      // For now, we'll simulate the check
      return false; // Implement with local_auth when needed
    } catch (e) {
      return false;
    }
  }

  // Device security check
  static Future<DeviceSecurityInfo> getDeviceSecurityInfo() async {
    // In a real implementation, this would check:
    // - Root/jailbreak status
    // - App integrity
    // - Device encryption
    // - Screen lock status
    
    return DeviceSecurityInfo(
      isRooted: false, // Would implement actual check
      hasScreenLock: true, // Would implement actual check
      isAppIntegrityValid: true, // Would implement actual check
      isDeviceEncrypted: true, // Would implement actual check
    );
  }

  // Generate OTP for additional security
  static String generateOTP({int length = 6}) {
    final random = Random.secure();
    String otp = '';
    for (int i = 0; i < length; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  // Validate OTP format
  static bool isValidOTP(String otp, {int expectedLength = 6}) {
    return RegExp(r'^\d{' + expectedLength.toString() + r'}$').hasMatch(otp);
  }
}

enum PasswordStrength {
  weak,
  medium,
  strong,
}

class DeviceSecurityInfo {
  final bool isRooted;
  final bool hasScreenLock;
  final bool isAppIntegrityValid;
  final bool isDeviceEncrypted;

  DeviceSecurityInfo({
    required this.isRooted,
    required this.hasScreenLock,
    required this.isAppIntegrityValid,
    required this.isDeviceEncrypted,
  });

  bool get isSecure => !isRooted && hasScreenLock && isAppIntegrityValid && isDeviceEncrypted;
}
