import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage_service.dart';

/// 🔄 Database Migration Service - Critical for App Store Updates
/// 
/// Handles versioning and migration of local database schema
/// Essential for preventing data loss during app updates
class DatabaseMigrationService {
  static const String _versionKey = 'database_version';
  static const int _currentVersion = 1;

  /// Initialize and run any pending migrations
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_versionKey) ?? 0;
      
      if (currentVersion < _currentVersion) {
        await _runMigrations(currentVersion, _currentVersion);
        await prefs.setInt(_versionKey, _currentVersion);
        debugPrint('✅ Database migrated from v$currentVersion to v$_currentVersion');
      }
    } catch (e) {
      debugPrint('❌ Database migration failed: $e');
      
      // Critical: Attempt recovery if migration fails
      try {
        debugPrint('🔄 Attempting database recovery...');
        await _attemptRecovery();
        debugPrint('✅ Database recovery successful');
      } catch (recoveryError) {
        debugPrint('❌ Database recovery failed: $recoveryError');
        // Still don't rethrow - app should start in degraded mode
      }
    }
  }
  
  /// Attempt to recover from database corruption
  static Future<void> _attemptRecovery() async {
    // Clear corrupted data and reinitialize with safe defaults
    await LocalStorageService.clearAllData();
    await LocalStorageService.initialize();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_versionKey, _currentVersion);
  }

  /// Run migrations between versions
  static Future<void> _runMigrations(int fromVersion, int toVersion) async {
    for (int version = fromVersion + 1; version <= toVersion; version++) {
      await _runMigration(version);
    }
  }

  /// Execute specific migration
  static Future<void> _runMigration(int version) async {
    switch (version) {
      case 1:
        await _migrationV1();
        break;
      default:
        debugPrint('⚠️ Unknown migration version: $version');
    }
  }

  /// Migration v1: Initialize encrypted storage
  static Future<void> _migrationV1() async {
    try {
      // Ensure LocalStorageService is initialized with encryption
      await LocalStorageService.initialize();
      
      // Add any additional v1 migration logic here
      debugPrint('✅ Migration v1 completed: Encrypted storage initialized');
    } catch (e) {
      debugPrint('❌ Migration v1 failed: $e');
      rethrow;
    }
  }

  /// Get current database version
  static Future<int> getCurrentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_versionKey) ?? 0;
  }

  /// Force reset database (for testing or recovery)
  static Future<void> resetDatabase() async {
    try {
      await LocalStorageService.clearAllData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_versionKey);
      debugPrint('🔄 Database reset completed');
    } catch (e) {
      debugPrint('❌ Database reset failed: $e');
    }
  }
}