import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_helpers.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/security_service.dart';
import '../../../core/models/user_data.dart';


class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  UserData? _userData;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  UserData? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  
  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Check for existing session
      _currentUser = supabase.auth.currentUser;
      
      // Load cached user data if available
      if (_currentUser != null) {
        _userData = LocalStorageService.getCurrentUser();
        if (_userData != null && _userData!.id != _currentUser!.id) {
          // User mismatch, clear cache
          await LocalStorageService.clearUserData();
          _userData = null;
        }
      }

      // Listen to auth state changes
      supabase.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final session = data.session;
        
        if (event == AuthChangeEvent.signedIn && session?.user != null) {
          _currentUser = session!.user;
          await _handleUserSignedIn(_currentUser!);
        } else if (event == AuthChangeEvent.signedOut) {
          await _handleUserSignedOut();
        } else if (event == AuthChangeEvent.tokenRefreshed && session?.user != null) {
          _currentUser = session!.user;
          await _updateUserSession();
        }
        
        _isInitialized = true;
        notifyListeners();
      });
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _handleUserSignedIn(User user) async {
    try {
      // Save user data locally
      _userData = UserData(
        id: user.id,
        email: user.email ?? '',
        username: user.userMetadata?['username'] ?? user.userMetadata?['name'],
        avatarUrl: user.userMetadata?['avatar_url'],
        lastLoginAt: DateTime.now(),
        rememberMe: true,
      );
      
      await LocalStorageService.saveUserData(_userData!);
      await LocalStorageService.saveSecureToken(supabase.auth.currentSession?.accessToken ?? '');
      
      // Sync with remote profile if needed
      await _syncUserProfile();
      
    } catch (e) {
      debugPrint('Error handling user sign in: $e');
    }
  }

  Future<void> _handleUserSignedOut() async {
    _currentUser = null;
    _userData = null;
    
    // Clear local storage
    await LocalStorageService.clearUserData();
    await LocalStorageService.clearSecureToken();
  }

  Future<void> _updateUserSession() async {
    if (_currentUser != null && _userData != null) {
      _userData!.lastLoginAt = DateTime.now();
      await LocalStorageService.saveUserData(_userData!);
      await LocalStorageService.saveSecureToken(supabase.auth.currentSession?.accessToken ?? '');
    }
  }

  Future<void> _syncUserProfile() async {
    if (_currentUser == null) return;
    
    try {
      // Try to fetch user profile from database
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', _currentUser!.id)
          .maybeSingle();
      
      if (response != null && response.isNotEmpty && _userData != null) {
        _userData!.username = response['username'];
        _userData!.avatarUrl = response['avatar_url'];
        await LocalStorageService.saveUserData(_userData!);
      }
    } catch (e) {
      debugPrint('Profile sync error: $e');
      // Continue without syncing - offline capability
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    if (_isLoading) return false;
    
    debugPrint('🔵 [AUTH_PROVIDER] Login started for: $email');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Input validation
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }
      
      debugPrint('🔵 [AUTH_PROVIDER] Input validation passed');

      // Sanitize input
      final sanitizedEmail = SecurityService.sanitizeInput(email);
      debugPrint('🔵 [AUTH_PROVIDER] Sanitized email: $sanitizedEmail');
      
      if (!SecurityService.isValidEmail(sanitizedEmail)) {
        throw Exception('Please enter a valid email address');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      
      debugPrint('🔵 [AUTH_PROVIDER] Validation passed, checking rate limit...');

      // Rate limiting check
      if (!SecurityService.checkRateLimit('login_$sanitizedEmail', maxAttempts: 5)) {
        throw Exception('Too many login attempts. Please try again in 15 minutes.');
      }

      debugPrint('🔵 [AUTH_PROVIDER] Rate limit passed, attempting Supabase login...');
      final response = await supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      
      debugPrint('🔵 [AUTH_PROVIDER] Supabase login response received, user: ${response.user?.id}');

      if (response.user != null) {
        debugPrint('🔵 [AUTH_PROVIDER] Login successful! User ID: ${response.user!.id}');
        _currentUser = response.user;
        
        // Update remember me preference
        if (_userData != null) {
          _userData!.rememberMe = rememberMe;
          await LocalStorageService.saveUserData(_userData!);
          debugPrint('🔵 [AUTH_PROVIDER] User data saved with rememberMe: $rememberMe');
        }
      }

      debugPrint('🔵 [AUTH_PROVIDER] Login completed successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('🔴 [AUTH_PROVIDER] Auth error during login: ${e.message}');
      _errorMessage = _getAuthErrorMessage(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } on PostgrestException catch (e) {
      debugPrint('🔴 [AUTH_PROVIDER] Database error during login: ${e.message}');
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('🔴 [AUTH_PROVIDER] General error during login: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String username, String email, String password) async {
    if (_isLoading) return false;
    
    debugPrint('🟢 [AUTH_PROVIDER] Signup started - Username: $username, Email: $email, Password length: ${password.length}');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Input validation with specific error messages
      if (username.trim().isEmpty) {
        throw Exception('Username is required');
      }
      if (email.trim().isEmpty) {
        throw Exception('Email address is required');
      }
      if (password.isEmpty) {
        throw Exception('Password is required');
      }
      
      debugPrint('🟢 [AUTH_PROVIDER] Initial validation passed');

      // Sanitize input
      final sanitizedUsername = SecurityService.sanitizeInput(username.trim());
      final sanitizedEmail = SecurityService.sanitizeInput(email.trim());
      debugPrint('🟢 [AUTH_PROVIDER] Sanitized inputs - Username: $sanitizedUsername, Email: $sanitizedEmail');

      if (!SecurityService.isValidEmail(sanitizedEmail)) {
        throw Exception('Please enter a valid email address (example@email.com)');
      }

      if (!SecurityService.isValidUsername(sanitizedUsername)) {
        throw Exception('Username must be 3-20 characters and contain only letters, numbers, and underscores');
      }

      if (sanitizedUsername.length < 3) {
        throw Exception('Username must be at least 3 characters long');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters long');
      }

      // Enhanced password validation
      final passwordStrength = SecurityService.validatePasswordStrength(password);
      if (passwordStrength == PasswordStrength.weak) {
        throw Exception('Password is too weak. Please use at least 8 characters with uppercase, lowercase, and numbers');
      }
      
      debugPrint('🟢 [AUTH_PROVIDER] All validation passed, password strength: $passwordStrength');

      // Rate limiting check
      if (!SecurityService.checkRateLimit('signup_$sanitizedEmail', maxAttempts: 3)) {
        throw Exception('Too many signup attempts. Please try again in 15 minutes.');
      }
      
      debugPrint('🟢 [AUTH_PROVIDER] Rate limit passed, attempting Supabase signup...');

      // Ensure username is within database constraints (max 15 chars for safety)
      final constrainedUsername = sanitizedUsername.length > 15 
          ? sanitizedUsername.substring(0, 15)
          : sanitizedUsername;
          
      debugPrint('🟢 [AUTH_PROVIDER] Using constrained username: $constrainedUsername (length: ${constrainedUsername.length})');

      // First, try signup without profile creation (in case trigger fails)
      AuthResponse response;
      try {
        response = await supabase.auth.signUp(
          email: email.trim().toLowerCase(),
          password: password,
          data: {
            'username': constrainedUsername,
          },
        );
        debugPrint('🟢 [AUTH_PROVIDER] Supabase signup successful');
      } catch (e) {
        debugPrint('🔴 [AUTH_PROVIDER] Supabase signup failed: $e');
        
        // If signup fails due to database trigger, try without user metadata
        if (e.toString().contains('Database error') || e.toString().contains('constraint')) {
          debugPrint('🟡 [AUTH_PROVIDER] Retrying signup without metadata...');
          response = await supabase.auth.signUp(
            email: email.trim().toLowerCase(),
            password: password,
          );
          debugPrint('🟢 [AUTH_PROVIDER] Retry successful');
        } else {
          rethrow;
        }
      }

      debugPrint('🟢 [AUTH_PROVIDER] Supabase signup response received');
      debugPrint('🟢 [AUTH_PROVIDER] User: ${response.user?.id}');
      debugPrint('🟢 [AUTH_PROVIDER] Session: ${response.session?.accessToken != null ? "Present" : "Null"}');

      if (response.user != null) {
        debugPrint('🟢 [AUTH_PROVIDER] Signup successful! User ID: ${response.user!.id}');
        _currentUser = response.user;
        
        // Always create profile manually to ensure it exists
        try {
          await _createUserProfile(response.user!, constrainedUsername);
          debugPrint('🟢 [AUTH_PROVIDER] Profile created successfully');
        } catch (e) {
          debugPrint('⚠️ [AUTH_PROVIDER] Profile creation failed (may already exist): $e');
          // Don't fail signup if profile creation fails - user account is created
        }
        
        // Additional safety - create other required records
        try {
          await _createUserSettings(response.user!.id);
          await _createUserPoints(response.user!.id);
          debugPrint('🟢 [AUTH_PROVIDER] Additional user records created');
        } catch (e) {
          debugPrint('⚠️ [AUTH_PROVIDER] Additional record creation failed: $e');
          // This is also non-critical for signup success
        }
      }

      debugPrint('🟢 [AUTH_PROVIDER] Signup completed successfully');
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      debugPrint('🔴 [AUTH_PROVIDER] Auth error during signup: ${e.message}');
      _errorMessage = _getAuthErrorMessage(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } on PostgrestException catch (e) {
      debugPrint('🔴 [AUTH_PROVIDER] Database error during signup: ${e.message}');
      if (e.message.contains('duplicate key') || e.message.contains('already exists')) {
        _errorMessage = 'This email or username is already registered. Try signing in instead.';
      } else if (e.message.contains('relation') && e.message.contains('does not exist')) {
        _errorMessage = 'Database setup incomplete. Please try again in a moment.';
      } else {
        _errorMessage = 'Database error: ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('🔴 [AUTH_PROVIDER] General error during signup: $e');
      if (e.toString().contains('timeout') || e.toString().contains('Connection timeout')) {
        _errorMessage = 'Connection timeout. Please check your internet and try again.';
      } else if (e.toString().contains('network') || e.toString().contains('fetch')) {
        _errorMessage = 'Network error. Please check your internet connection.';
      } else {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    // Auth state change listener will handle cleanup
  }

  Future<bool> resetPassword(String email) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (email.isEmpty) {
        throw Exception('Email is required');
      }

      if (!SecurityService.isValidEmail(email)) {
        throw Exception('Please enter a valid email address');
      }

      await supabase.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: 'io.focusflow.app://reset-password',
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } on PostgrestException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }



  String _getAuthErrorMessage(String errorMessage) {
    debugPrint('🔴 [AUTH] Raw error message: $errorMessage');
    
    if (errorMessage.contains('Invalid login credentials')) {
      return 'Incorrect email or password. Please check and try again.';
    } else if (errorMessage.contains('Email not confirmed')) {
      return 'Please check your email inbox and click the confirmation link to activate your account.';
    } else if (errorMessage.contains('User already registered') || errorMessage.contains('Email already registered')) {
      return 'This email is already registered. Try signing in instead.';
    } else if (errorMessage.contains('Password should be at least 6 characters')) {
      return 'Password must be at least 6 characters long.';
    } else if (errorMessage.contains('Signup requires a valid password')) {
      return 'Please enter a strong password with at least 6 characters.';
    } else if (errorMessage.contains('Unable to validate email address: invalid format') || errorMessage.contains('Invalid email')) {
      return 'Please enter a valid email address (example@email.com).';
    } else if (errorMessage.contains('For security purposes, you can only request this once every 60 seconds')) {
      return 'Please wait 60 seconds before requesting another password reset.';
    } else if (errorMessage.contains('fetch')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (errorMessage.contains('timeout')) {
      return 'Request timed out. Please check your internet connection.';
    } else if (errorMessage.contains('Failed to establish') || errorMessage.contains('Connection failed')) {
      return 'Unable to connect. Please check your internet connection.';
    } else if (errorMessage.isEmpty) {
      return 'An unexpected error occurred. Please try again.';
    } else {
      return errorMessage.replaceFirst('Exception: ', '').replaceFirst('Error: ', '');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Method to check if user should stay logged in
  bool shouldAutoLogin() {
    final userData = LocalStorageService.getCurrentUser();
    return userData != null && userData.rememberMe;
  }

  // Method to sync offline data when connection is restored
  Future<void> syncOfflineData() async {
    if (!isAuthenticated) return;

    try {
      final pendingData = LocalStorageService.getPendingSyncData();
      
      for (final entry in pendingData.entries) {
        try {
          // Implement sync logic based on data type
          await _syncDataToRemote(entry.key, entry.value['data']);
          await LocalStorageService.markDataAsSynced(entry.key);
        } catch (e) {
          debugPrint('Failed to sync ${entry.key}: $e');
        }
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> _syncDataToRemote(String key, Map<String, dynamic> data) async {
    // Implement specific sync logic based on data type
    // This would handle user settings, app usage data, etc.
    switch (key) {
      case 'user_settings':
        await supabase.from('user_settings').upsert(data);
        break;
      case 'app_usage':
        await supabase.from('app_usage_sessions').insert(data);
        break;
      // Add more cases as needed
    }
  }

  /// Test database connection and basic functionality
  Future<Map<String, dynamic>> testDatabaseConnection() async {
    try {
      debugPrint('🔍 [AUTH_PROVIDER] Testing database connection...');
      
      // Test 1: Check if we can connect to Supabase
      final user = supabase.auth.currentUser;
      debugPrint('🔍 [AUTH_PROVIDER] Current user: ${user?.id}');
      
      // Test 2: Try to query profiles table
      try {
        await supabase
            .from('profiles')
            .select('id')
            .limit(1);
        debugPrint('🔍 [AUTH_PROVIDER] Profiles table accessible: true');
      } catch (e) {
        debugPrint('🔍 [AUTH_PROVIDER] Profiles table error: $e');
      }
      
      // Test 3: Try to query user_points table  
      try {
        await supabase
            .from('user_points')
            .select('id')
            .limit(1);
        debugPrint('🔍 [AUTH_PROVIDER] User_points table accessible: true');
      } catch (e) {
        debugPrint('🔍 [AUTH_PROVIDER] User_points table error: $e');
      }
      
      return {
        'success': true,
        'message': 'Database connection test completed - check debug logs'
      };
    } catch (e) {
      debugPrint('🔴 [AUTH_PROVIDER] Database connection test failed: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  /// Create user profile manually (fallback for trigger issues)
  Future<void> _createUserProfile(User user, String username) async {
    try {
      // Create profile with only columns that exist in the schema
      await supabase.from('profiles').upsert({
        'id': user.id,
        'username': username,
        'email': user.email,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'notifications_enabled': true,
        'dark_mode': false,
        'sound_enabled': true,
      });
      
      debugPrint('🟢 [AUTH_PROVIDER] User profile created manually');
    } catch (e) {
      debugPrint('⚠️ [AUTH_PROVIDER] Manual profile creation failed: $e');
      // This is a fallback, so we don't throw the error
    }
  }

  /// Create user settings record
  Future<void> _createUserSettings(String userId) async {
    try {
      await supabase.from('user_settings').insert({
        'user_id': userId,
        'daily_screen_time_limit': 0,
        'reward_notifications': true,
        'strict_mode': false,
        'allow_override': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('🟢 [AUTH_PROVIDER] User settings created');
    } catch (e) {
      debugPrint('⚠️ [AUTH_PROVIDER] User settings creation failed (RLS policy): $e');
      // Non-critical - settings can be created later
    }
  }

  /// Create user points record
  Future<void> _createUserPoints(String userId) async {
    try {
      await supabase.from('user_points').insert({
        'user_id': userId,
        'total_points': 0,
        'level': 1,
        'current_streak_days': 0,
        'best_streak_days': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('🟢 [AUTH_PROVIDER] User points created');
    } catch (e) {
      debugPrint('⚠️ [AUTH_PROVIDER] User points creation failed (RLS policy): $e');
      // Non-critical - points can be initialized later
    }
  }
}
