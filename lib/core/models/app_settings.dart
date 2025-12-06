import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  late bool biometricEnabled;

  @HiveField(1)
  late bool notificationsEnabled;

  @HiveField(2)
  late bool darkModeEnabled;

  @HiveField(3)
  late int dailyScreenTimeLimit; // in minutes

  @HiveField(4)
  late bool strictModeEnabled;

  @HiveField(5)
  late bool allowOverride;

  @HiveField(6)
  late String lastSyncAt;

  @HiveField(7)
  late bool offlineModeEnabled;

  AppSettings({
    this.biometricEnabled = false,
    this.notificationsEnabled = true,
    this.darkModeEnabled = true,
    this.dailyScreenTimeLimit = 120, // 2 hours default
    this.strictModeEnabled = false,
    this.allowOverride = true,
    String? lastSyncAt,
    this.offlineModeEnabled = false,
  }) {
    this.lastSyncAt = lastSyncAt ?? DateTime.now().toIso8601String();
  }

  Map<String, dynamic> toJson() {
    return {
      'biometric_enabled': biometricEnabled,
      'notifications_enabled': notificationsEnabled,
      'dark_mode_enabled': darkModeEnabled,
      'daily_screen_time_limit': dailyScreenTimeLimit,
      'strict_mode_enabled': strictModeEnabled,
      'allow_override': allowOverride,
      'last_sync_at': lastSyncAt,
      'offline_mode_enabled': offlineModeEnabled,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      biometricEnabled: json['biometric_enabled'] ?? false,
      notificationsEnabled: json['notifications_enabled'] ?? true,
      darkModeEnabled: json['dark_mode_enabled'] ?? true,
      dailyScreenTimeLimit: json['daily_screen_time_limit'] ?? 120,
      strictModeEnabled: json['strict_mode_enabled'] ?? false,
      allowOverride: json['allow_override'] ?? true,
      lastSyncAt: json['last_sync_at'],
      offlineModeEnabled: json['offline_mode_enabled'] ?? false,
    );
  }
}
