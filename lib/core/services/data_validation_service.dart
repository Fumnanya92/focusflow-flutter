/// 🛡️ Data Validation Service - Critical for App Store Security
/// 
/// Validates and sanitizes all user input to prevent crashes and security issues
class DataValidationService {
  
  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  /// Validate username (App Store guidelines)
  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required';
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (username.length > 20) {
      return 'Username must be less than 20 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }
  
  /// Validate password strength (App Store requirements)
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      return 'Password must contain uppercase, lowercase, and number';
    }
    return null;
  }
  
  /// Sanitize text input to prevent injection attacks
  static String sanitizeInput(String input) {
    final cleanInput = input
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
    return cleanInput.length > 1000 ? cleanInput.substring(0, 1000) : cleanInput;
  }
  
  /// Validate task title
  static String? validateTaskTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Task title is required';
    }
    if (title.length > 100) {
      return 'Task title must be less than 100 characters';
    }
    return null;
  }
  
  /// Validate points value to prevent overflow
  static int validatePoints(int points) {
    return points.clamp(0, 999999); // Prevent overflow issues
  }
  
  /// Validate numeric input ranges
  static int validateNumericRange(int value, int min, int max, int defaultValue) {
    if (value < min || value > max) {
      return defaultValue;
    }
    return value;
  }
  
  /// Validate app package name
  static bool isValidPackageName(String packageName) {
    return RegExp(r'^[a-z0-9._]+$').hasMatch(packageName) && 
           packageName.contains('.') &&
           packageName.length <= 100;
  }
}