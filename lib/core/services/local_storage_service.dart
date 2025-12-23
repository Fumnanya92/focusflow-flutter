import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/user_data.dart';
import '../models/app_settings.dart';

class LocalStorageService {
  static const String _userBoxName = 'user_data';
  static const String _settingsBoxName = 'app_settings';
  static const String _cacheBoxName = 'cache_data';
  
  // Generate encryption key from device-specific data
  static Uint8List _getEncryptionKey() {
    const deviceId = 'focusflow_secure_storage'; // In production, use device-specific ID
    final bytes = utf8.encode(deviceId);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  static late Box<UserData> _userBox;
  static late Box<AppSettings> _settingsBox;
  static late Box<dynamic> _cacheBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters only if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserDataAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    
    // Get encryption key for sensitive data
    final encryptionKey = _getEncryptionKey();
    
    // Open boxes with encryption for sensitive user data
    _userBox = await Hive.openBox<UserData>(
      _userBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);
    _cacheBox = await Hive.openBox<dynamic>(_cacheBoxName);
  }

  // User Data Methods
  static Future<void> saveUserData(UserData userData) async {
    await _userBox.put('current_user', userData);
  }

  static UserData? getCurrentUser() {
    return _userBox.get('current_user');
  }

  static Future<void> clearUserData() async {
    // Clear user authentication data
    await _userBox.clear();
    
    // Clear ALL cached data (points, sessions, achievements, etc.)
    // This prevents data leakage between users
    await _cacheBox.clear();
    
    // Note: We keep _settingsBox (app-level settings like theme)
    // If you want to clear app settings too between users, uncomment:
    // await _settingsBox.clear();
  }

  static bool isUserLoggedIn() {
    final userData = getCurrentUser();
    return userData != null && userData.rememberMe;
  }

  // Settings Methods
  static Future<void> saveAppSettings(AppSettings settings) async {
    await _settingsBox.put('app_settings', settings);
  }

  static AppSettings getAppSettings() {
    return _settingsBox.get('app_settings') ?? AppSettings();
  }

  static Future<void> updateAppSettings(AppSettings settings) async {
    settings.lastSyncAt = DateTime.now().toIso8601String();
    await saveAppSettings(settings);
  }

  // Cache Methods
  static Future<void> cacheData(String key, dynamic data) async {
    await _cacheBox.put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static T? getCachedData<T>(String key, {int? maxAge}) {
    final cached = _cacheBox.get(key);
    if (cached == null) return null;

    if (maxAge != null) {
      final timestamp = cached['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > maxAge) {
        _cacheBox.delete(key);
        return null;
      }
    }

    return cached['data'] as T?;
  }

  static Future<void> clearCache() async {
    await _cacheBox.clear();
  }

  // Security Methods
  static Future<void> saveSecureToken(String token) async {
    await _cacheBox.put('auth_token', {
      'token': token,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static String? getSecureToken() {
    final tokenData = _cacheBox.get('auth_token');
    if (tokenData == null) return null;

    // Check if token is older than 24 hours
    final timestamp = tokenData['timestamp'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    const maxAge = 24 * 60 * 60 * 1000; // 24 hours in milliseconds

    if (age > maxAge) {
      _cacheBox.delete('auth_token');
      return null;
    }

    return tokenData['token'] as String?;
  }

  static Future<void> clearSecureToken() async {
    await _cacheBox.delete('auth_token');
  }

  // Sync Methods
  static Future<void> markDataForSync(String key, Map<String, dynamic> data) async {
    final syncQueue = _cacheBox.get('sync_queue', defaultValue: <String, dynamic>{});
    syncQueue[key] = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': false,
    };
    await _cacheBox.put('sync_queue', syncQueue);
  }

  static Map<String, dynamic> getPendingSyncData() {
    final syncQueue = _cacheBox.get('sync_queue', defaultValue: <String, dynamic>{});
    final pending = <String, dynamic>{};
    
    for (final entry in syncQueue.entries) {
      if (!(entry.value['synced'] as bool)) {
        pending[entry.key] = entry.value;
      }
    }
    
    return pending;
  }

  static Future<void> markDataAsSynced(String key) async {
    final syncQueue = _cacheBox.get('sync_queue', defaultValue: <String, dynamic>{});
    if (syncQueue.containsKey(key)) {
      syncQueue[key]['synced'] = true;
      await _cacheBox.put('sync_queue', syncQueue);
    }
  }

  // Cleanup Methods
  static Future<void> clearAllData() async {
    await _userBox.clear();
    await _settingsBox.clear();
    await _cacheBox.clear();
  }

  static Future<void> dispose() async {
    await _userBox.close();
    await _settingsBox.close();
    await _cacheBox.close();
  }
}
