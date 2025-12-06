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
      
      if (response != null && _userData != null) {
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
      // Input validation
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        throw Exception('All fields are required');
      }
      
      debugPrint('🟢 [AUTH_PROVIDER] Initial validation passed');

      // Sanitize input
      final sanitizedUsername = SecurityService.sanitizeInput(username);
      final sanitizedEmail = SecurityService.sanitizeInput(email);
      debugPrint('🟢 [AUTH_PROVIDER] Sanitized inputs - Username: $sanitizedUsername, Email: $sanitizedEmail');

      if (!SecurityService.isValidEmail(sanitizedEmail)) {
        throw Exception('Please enter a valid email address');
      }

      if (!SecurityService.isValidUsername(sanitizedUsername)) {
        throw Exception('Username can only contain letters, numbers, and underscores (3-20 characters)');
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

      final response = await supabase.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {
          'username': username.trim(),
        },
      );

      debugPrint('🟢 [AUTH_PROVIDER] Supabase signup response received');
      debugPrint('🟢 [AUTH_PROVIDER] User: ${response.user?.id}');
      debugPrint('🟢 [AUTH_PROVIDER] Session: ${response.session?.accessToken != null ? "Present" : "Null"}');

      if (response.user != null) {
        debugPrint('🟢 [AUTH_PROVIDER] Signup successful! User ID: ${response.user!.id}');
        _currentUser = response.user;
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
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('🔴 [AUTH_PROVIDER] General error during signup: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
    if (errorMessage.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    } else if (errorMessage.contains('Email not confirmed')) {
      return 'Please check your email and click the confirmation link.';
    } else if (errorMessage.contains('User already registered')) {
      return 'An account with this email already exists.';
    } else if (errorMessage.contains('Password should be at least 6 characters')) {
      return 'Password must be at least 6 characters long.';
    } else if (errorMessage.contains('Signup requires a valid password')) {
      return 'Please enter a valid password.';
    } else if (errorMessage.contains('Unable to validate email address: invalid format')) {
      return 'Please enter a valid email address.';
    } else if (errorMessage.contains('For security purposes, you can only request this once every 60 seconds')) {
      return 'Please wait 60 seconds before requesting another password reset.';
    } else {
      return errorMessage.replaceFirst('Exception: ', '');
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
}
