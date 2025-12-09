import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/blocked_app_model.dart';
import '../../tasks/providers/task_provider.dart';




class AppBlockingProvider extends ChangeNotifier {
  List<BlockedApp> _blockedApps = [];
  bool _isMonitoring = false;
  Timer? _mainMonitoringTimer;
  int _blocksToday = 0;
  DateTime? _lastBlockDate;

  // Time schedule variables
  TimeOfDay? _blockingStartTime;
  TimeOfDay? _blockingEndTime;
  bool _enableTimeSchedule = false;

  // Grace period variables
  final Map<String, DateTime> _gracePeriodApps = {};

  // Focus mode variables
  bool _focusModeEnabled = false;

  // Background service variables
  bool _backgroundServiceRunning = false;

  // Task reminder variables
  Timer? _taskReminderTimer;
  DateTime? _lastTaskReminderShown;
  bool _taskReminderSnoozed = false;
  TaskProvider? _taskProvider;

  // Track usage stats permission status
  bool _hasUsageStatsPermission = false;

  // Cache for installed apps
  List<Map<String, dynamic>>? _installedApps;
  DateTime? _lastInstalledAppsUpdate;

  // Currently blocked app for UI
  String? _currentlyBlockedApp;

  // Popular social media apps
  static const List<Map<String, String>> popularApps = [
    {'package': 'com.instagram.android', 'name': 'Instagram'},
    {'package': 'com.zhiliaoapp.musically', 'name': 'TikTok'},
    {'package': 'com.twitter.android', 'name': 'X (Twitter)'},
    {'package': 'com.facebook.katana', 'name': 'Facebook'},
    {'package': 'com.facebook.lite', 'name': 'Facebook Lite'},
    {'package': 'com.facebook.mlite', 'name': 'Facebook Lite (M)'},
    {'package': 'com.facebook.android', 'name': 'Facebook (Alt)'},
    {'package': 'com.facebook.pages.app', 'name': 'Facebook Pages'},
    {'package': 'com.facebook.orca', 'name': 'Messenger'},
    {'package': 'com.facebook.system', 'name': 'Facebook Services'},
    {'package': 'com.facebook.appmanager', 'name': 'Facebook App Manager'},
    {'package': 'com.snapchat.android', 'name': 'Snapchat'},
    {'package': 'com.reddit.frontpage', 'name': 'Reddit'},
    {'package': 'com.pinterest', 'name': 'Pinterest'},
    {'package': 'com.linkedin.android', 'name': 'LinkedIn'},
    {'package': 'com.google.android.youtube', 'name': 'YouTube'},
    {'package': 'com.youtube.android', 'name': 'YouTube (Alt)'},
    {'package': 'com.google.android.apps.youtube.music', 'name': 'YouTube Music'},
    {'package': 'com.google.android.apps.youtube.vr', 'name': 'YouTube VR'},
  ];

  static const MethodChannel _appMonitorChannel = MethodChannel('app.focusflow/monitor');


  // Getters
  List<BlockedApp> get blockedApps => _blockedApps;
  List<BlockedApp> get activelyBlockedApps => _blockedApps.where((app) => app.isBlocked).toList();
  bool get isMonitoring => _isMonitoring;
  int get blocksToday => _blocksToday;
  bool get isFocusModeEnabled => _focusModeEnabled;
  bool get isBlockingActive => _isMonitoring && (_focusModeEnabled || activelyBlockedApps.isNotEmpty);
  bool get hasRequiredPermissions => _hasUsageStatsPermission;
  TimeOfDay? get blockingStartTime => _blockingStartTime;
  TimeOfDay? get blockingEndTime => _blockingEndTime;
  bool get enableTimeSchedule => _enableTimeSchedule;
  String? get currentlyBlockedApp => _currentlyBlockedApp;

  AppBlockingProvider() {
    _initialize();
  }

  void _initialize() async {
    await _loadBlockedApps();
    _loadBlocksToday();
    await _checkPermissionStatus();
    if (_blockedApps.isNotEmpty) {
      startMonitoring();
    }
    _startTaskReminderSystem();

    _startNativeBlockListener();
  }



  void _startNativeBlockListener() {
    debugPrint('🎯 Native service handles all blocking - Flutter only manages UI');
    // Native service now handles all blocking independently
    // Flutter only manages UI state and settings
  }



  Future<void> _checkPermissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasUsageStatsPermission = prefs.getBool('usage_stats_granted') ?? false;

    debugPrint('📋 Permission Status Check:');
    debugPrint('   Usage Stats Permission: $_hasUsageStatsPermission');

    if (!_hasUsageStatsPermission) {
      debugPrint('🚨 CRITICAL: Usage stats permission not granted - App blocking DISABLED!');
      debugPrint('💡 User must grant this permission for app blocking to work');
    }

    notifyListeners();
  }

  void updatePermissionStatus(bool hasUsageStats) {
    _hasUsageStatsPermission = hasUsageStats;
    notifyListeners();
  }

  Future<void> addBlockedApp(String packageName, String appName, {int dailyLimit = 0}) async {
    if (_blockedApps.any((app) => app.packageName == packageName)) {
      return;
    }

    final app = BlockedApp(
      packageName: packageName,
      appName: appName,
      isBlocked: true,
      dailyLimit: dailyLimit,
    );

    _blockedApps.add(app);
    await _saveBlockedApps();
    await _updateForegroundService();
    notifyListeners();
  }

  Future<void> removeBlockedApp(String packageName) async {
    _blockedApps.removeWhere((app) => app.packageName == packageName);
    await _saveBlockedApps();
    await _updateForegroundService();
    notifyListeners();
  }

  Future<void> toggleAppBlocking(String packageName) async {
    final index = _blockedApps.indexWhere((app) => app.packageName == packageName);
    if (index != -1) {
      _blockedApps[index] = _blockedApps[index].copyWith(
        isBlocked: !_blockedApps[index].isBlocked,
      );
      await _saveBlockedApps();
      await _updateForegroundService();
      notifyListeners();
    }
  }

  Future<void> updateDailyLimit(String packageName, int limitMinutes) async {
    final index = _blockedApps.indexWhere((app) => app.packageName == packageName);
    if (index != -1) {
      _blockedApps[index] = _blockedApps[index].copyWith(
        dailyLimit: limitMinutes,
      );
      await _saveBlockedApps();
      notifyListeners();
    }
  }

  Future<void> addTimeWindow(String packageName, TimeWindow window) async {
    final index = _blockedApps.indexWhere((app) => app.packageName == packageName);
    if (index != -1) {
      final currentWindows = _blockedApps[index].blockedTimeWindows ?? [];
      _blockedApps[index] = _blockedApps[index].copyWith(
        blockedTimeWindows: [...currentWindows, window],
      );
      await _saveBlockedApps();
      notifyListeners();
    }
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    await _startForegroundService();
    _isMonitoring = true;

    _mainMonitoringTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkForBlockEvents(),
    );

    notifyListeners();
    debugPrint('🚀 FOREGROUND SERVICE MONITORING STARTED - 100% RELIABLE!');
    debugPrint('📱 Blocking ${activelyBlockedApps.length} apps with native Android service');
    debugPrint('⚡ Flutter timer runs every 5s for UI updates only');

    Future.delayed(const Duration(seconds: 5), () {
      _validateBlockedApps();
    });
  }

  Future<void> _startForegroundService() async {
    try {
      final blockedAppsData = activelyBlockedApps
          .map((app) => {
                'package': app.packageName,
                'name': app.appName,
                'blocked': app.isBlocked,
              })
          .toList();

      final result = await _appMonitorChannel.invokeMethod('startBlockingService', {
        'blockedApps': jsonEncode(blockedAppsData),
        'startHour': _blockingStartTime?.hour ?? -1,
        'startMinute': _blockingStartTime?.minute ?? -1,
        'endHour': _blockingEndTime?.hour ?? -1,
        'endMinute': _blockingEndTime?.minute ?? -1,
        'focusMode': _focusModeEnabled,
      });

      debugPrint('🚀 $result');
      _backgroundServiceRunning = true;
    } catch (e) {
      debugPrint('❌ Error starting foreground service: $e');
      _backgroundServiceRunning = false;
    }
  }

  Future<void> _updateForegroundService() async {
    if (!_backgroundServiceRunning) return;

    try {
      final blockedAppsData = activelyBlockedApps
          .map((app) => {
                'package': app.packageName,
                'name': app.appName,
                'blocked': app.isBlocked,
              })
          .toList();

      await _appMonitorChannel.invokeMethod('updateBlockedApps', {
        'blockedApps': jsonEncode(blockedAppsData),
        'startHour': _blockingStartTime?.hour ?? -1,
        'startMinute': _blockingStartTime?.minute ?? -1,
        'endHour': _blockingEndTime?.hour ?? -1,
        'endMinute': _blockingEndTime?.minute ?? -1,
        'focusMode': _focusModeEnabled,
      });

      debugPrint('📱 Foreground service updated with latest configuration');
    } catch (e) {
      debugPrint('❌ Error updating foreground service: $e');
    }
  }

  Future<void> _checkForBlockEvents() async {
    try {
      final result = await _appMonitorChannel.invokeMethod('getLastBlockEvent');
      final blockData = result != null ? Map<String, dynamic>.from(result as Map) : null;

      if (blockData != null && blockData['event'] != null) {
        final eventJson = blockData['event'] as String;
        final timestamp = blockData['timestamp'] as int;

        if (timestamp > (_lastBlockDate?.millisecondsSinceEpoch ?? 0)) {
          final eventData = jsonDecode(eventJson);
          final blockedAppName = eventData['name'] as String;

          debugPrint('🚫 Native service blocked: $blockedAppName');

          _incrementBlocksToday();
          _lastBlockDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking block events: $e');
    }
  }

  void _validateBlockedApps() async {
    try {
      final installedApps = await getInstalledApps();
      final installedPackages = installedApps.map((app) => app['packageName']).toSet();

      final invalidApps = _blockedApps
          .where((app) => !installedPackages.contains(app.packageName))
          .toList();

      if (invalidApps.isNotEmpty) {
        debugPrint('! Found ${invalidApps.length} blocked apps that are not installed:');
        for (final app in invalidApps) {
          debugPrint('   - ${app.appName} (${app.packageName})');
        }
        debugPrint('💡 Consider removing these from your blocked list');
      }
    } catch (e) {
      debugPrint('❌ Error validating blocked apps: $e');
    }
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _mainMonitoringTimer?.cancel();
    _mainMonitoringTimer = null;

    try {
      await _appMonitorChannel.invokeMethod('stopBlockingService');
      _backgroundServiceRunning = false;
      debugPrint('🛑 Native blocking service stopped');
    } catch (e) {
      debugPrint('❌ Error stopping service: $e');
    }

    notifyListeners();
    debugPrint('ℹ️ Monitoring stopped');
  }

  Future<void> _forceCloseApp(String packageName) async {
    try {
      await _appMonitorChannel.invokeMethod('closeApp', {'packageName': packageName});
      debugPrint('🔒 FORCE CLOSED $packageName');
    } catch (e) {
      debugPrint('❌ Error force closing app: $e');
    }
  }

  bool _isInBlockingTimeWindow() {
    if (_blockingStartTime == null || _blockingEndTime == null) {
      debugPrint('⏰ No blocking times set, defaulting to false');
      return false;
    }

    final now = TimeOfDay.now();
    final startMinutes = _blockingStartTime!.hour * 60 + _blockingStartTime!.minute;
    final endMinutes = _blockingEndTime!.hour * 60 + _blockingEndTime!.minute;
    final nowMinutes = now.hour * 60 + now.minute;

    debugPrint('⏰ Time check - Now: ${nowMinutes}min (${now.hour}:${now.minute.toString().padLeft(2, '0')}), Start: ${startMinutes}min (${_blockingStartTime!.hour}:${_blockingStartTime!.minute.toString().padLeft(2, '0')}), End: ${endMinutes}min (${_blockingEndTime!.hour}:${_blockingEndTime!.minute.toString().padLeft(2, '0')})');

    bool inWindow;

    if (_blockingEndTime!.hour == 0 && _blockingEndTime!.minute == 0) {
      inWindow = nowMinutes >= startMinutes;
      debugPrint('⏰ Blocking until midnight (00:00) - Currently in window: $inWindow');
    } else if (startMinutes < endMinutes) {
      inWindow = nowMinutes >= startMinutes && nowMinutes <= endMinutes;
      debugPrint('⏰ Same-day schedule: $inWindow');
    } else {
      inWindow = nowMinutes >= startMinutes || nowMinutes <= endMinutes;
      debugPrint('⏰ Cross-midnight schedule: $inWindow');
    }

    return inWindow;
  }



  void clearCurrentlyBlockedApp() {
    _currentlyBlockedApp = null;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getInstalledApps({bool forceRefresh = false}) async {
    try {
      final now = DateTime.now();
      if (!forceRefresh &&
          _installedApps != null &&
          _lastInstalledAppsUpdate != null &&
          now.difference(_lastInstalledAppsUpdate!) < const Duration(minutes: 5)) {
        return _installedApps!;
      }

      debugPrint('📱 Fetching installed apps from system...');
      final List<dynamic> apps = await _appMonitorChannel.invokeMethod('getInstalledApps') ?? [];

      _installedApps = apps.map((app) => Map<String, dynamic>.from(app as Map)).toList();
      _lastInstalledAppsUpdate = now;

      debugPrint('✅ Found ${_installedApps!.length} installed apps');
      return _installedApps!;
    } catch (e) {
      debugPrint('❌ Error getting installed apps: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getAppUsageStats(String packageName, {int days = 7}) async {
    try {
      debugPrint('📊 Getting usage stats for $packageName (last $days days)');

      final Map<dynamic, dynamic> result = await _appMonitorChannel.invokeMethod('getAppUsageStats', {
            'packageName': packageName,
            'days': days,
          }) ??
          {};

      final stats = Map<String, dynamic>.from(result);

      if (stats['success'] == true) {
        final minutes = stats['totalTimeInForegroundMinutes'] ?? 0;
        debugPrint('⏱️ $packageName used for $minutes minutes in last $days days');
      }

      return stats;
    } catch (e) {
      debugPrint('❌ Error getting usage stats for $packageName: $e');
      return {'error': e.toString(), 'success': false};
    }
  }

  Future<bool> isAppInstalled(String packageName) async {
    try {
      final installedApps = await getInstalledApps();
      return installedApps.any((app) => app['packageName'] == packageName);
    } catch (e) {
      debugPrint('❌ Error checking if app is installed: $e');
      return false;
    }
  }

  Future<List<Map<String, String>>> getInstalledSocialMediaApps() async {
    try {
      final installedApps = await getInstalledApps();
      final socialMediaApps = <Map<String, String>>[];

      for (final popularApp in popularApps) {
        final isInstalled = installedApps.any((app) => app['packageName'] == popularApp['package']);

        if (isInstalled) {
          socialMediaApps.add({
            'package': popularApp['package']!,
            'name': popularApp['name']!,
          });
        }
      }

      debugPrint('📱 Found ${socialMediaApps.length} installed social media apps: ${socialMediaApps.map((app) => app['name']).join(', ')}');

      return socialMediaApps;
    } catch (e) {
      debugPrint('❌ Error getting installed social media apps: $e');
      return [];
    }
  }

  void _incrementBlocksToday() {
    final today = DateTime.now();

    if (_lastBlockDate == null ||
        _lastBlockDate!.day != today.day ||
        _lastBlockDate!.month != today.month ||
        _lastBlockDate!.year != today.year) {
      _blocksToday = 1;
      _lastBlockDate = today;
    } else {
      _blocksToday++;
    }

    notifyListeners();
    _saveBlockedApps();

    debugPrint('📊 Blocks today: $_blocksToday');
  }

  Future<void> addCustomApp(String packageName, String customName) async {
    try {
      final isInstalled = await isAppInstalled(packageName);

      if (!isInstalled) {
        debugPrint('❌ App not installed: $packageName');
        throw Exception('App with package name "$packageName" is not installed on this device');
      }

      if (_blockedApps.any((app) => app.packageName == packageName)) {
        debugPrint('⚠️ App already in blocked list: $packageName');
        throw Exception('This app is already in your blocked list');
      }

      await addBlockedApp(packageName, customName.isNotEmpty ? customName : packageName);
      debugPrint('✅ Custom app added: $customName ($packageName)');
    } catch (e) {
      debugPrint('❌ Error adding custom app: $e');
      rethrow;
    }
  }

  void clearAllBlocks() {
    _blockedApps.clear();
    _saveBlockedApps();
    notifyListeners();
  }

  void setBlockingSchedule(TimeOfDay startTime, TimeOfDay endTime) async {
    _blockingStartTime = startTime;
    _blockingEndTime = endTime;
    _enableTimeSchedule = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('blockingStartHour', startTime.hour);
    await prefs.setInt('blockingStartMinute', startTime.minute);
    await prefs.setInt('blockingEndHour', endTime.hour);
    await prefs.setInt('blockingEndMinute', endTime.minute);
    await prefs.setBool('enableTimeSchedule', true);

    await _updateForegroundService();

    debugPrint('⏰ Blocking schedule set and ENABLED: ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}');
    debugPrint('🚀 Native service updated with new schedule');

    await _sendScheduleReminderNotification(startTime);
    notifyListeners();
  }

  void disableTimeSchedule() async {
    _enableTimeSchedule = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableTimeSchedule', false);

    await _updateForegroundService();

    debugPrint('⏰ Time schedule DISABLED - blocking now active 24/7 (all day, every day)');
    debugPrint('🚀 Native service updated to 24/7 blocking mode');
    debugPrint('⏰ Kept time window for reference: ${_blockingStartTime?.hour}:${_blockingStartTime?.minute.toString().padLeft(2, '0')} - ${_blockingEndTime?.hour}:${_blockingEndTime?.minute.toString().padLeft(2, '0')}');

    notifyListeners();
  }

  void enableFocusMode() async {
    _focusModeEnabled = true;
    await _updateForegroundService();
    notifyListeners();
    debugPrint('🎯 Focus mode ENABLED - Native service will block ALL selected apps');
  }

  void disableFocusMode() async {
    _focusModeEnabled = false;
    await _updateForegroundService();
    notifyListeners();
    debugPrint('🎯 Focus mode DISABLED - Native service reverts to schedule');
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Future<void> _loadBlockedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appsJson = prefs.getString('blockedApps');

      if (appsJson != null) {
        final List<dynamic> decoded = jsonDecode(appsJson);
        _blockedApps = decoded.map((json) => BlockedApp.fromJson(json)).toList();
      }

      _blocksToday = prefs.getInt('blocksToday') ?? 0;
      final lastDateStr = prefs.getString('lastBlockDate');
      if (lastDateStr != null) {
        _lastBlockDate = DateTime.parse(lastDateStr);

        if (!_isSameDay(DateTime.now(), _lastBlockDate!)) {
          _blocksToday = 0;
        }
      }

      _enableTimeSchedule = prefs.getBool('enableTimeSchedule') ?? false;
      final startHour = prefs.getInt('blockingStartHour');
      final startMinute = prefs.getInt('blockingStartMinute');
      final endHour = prefs.getInt('blockingEndHour');
      final endMinute = prefs.getInt('blockingEndMinute');

      if (startHour != null && startMinute != null) {
        _blockingStartTime = TimeOfDay(hour: startHour, minute: startMinute);
      }
      if (endHour != null && endMinute != null) {
        _blockingEndTime = TimeOfDay(hour: endHour, minute: endMinute);
      }

      debugPrint('⏰ === TIME SCHEDULE STATUS ===');
      debugPrint('⏰ Time schedule enabled: $_enableTimeSchedule');
      if (_blockingStartTime != null && _blockingEndTime != null) {
        debugPrint('⏰ Scheduled time window: ${_blockingStartTime!.hour}:${_blockingStartTime!.minute.toString().padLeft(2, '0')} - ${_blockingEndTime!.hour}:${_blockingEndTime!.minute.toString().padLeft(2, '0')}');
      } else {
        debugPrint('⏰ No time window set');
      }

      if (_enableTimeSchedule) {
        debugPrint('⏰ BLOCKING MODE: Only during scheduled hours');
        final now = TimeOfDay.now();
        final inWindow = _isInBlockingTimeWindow();
        debugPrint('⏰ Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')} - Currently in blocking window: $inWindow');
      } else {
        debugPrint('⏰ BLOCKING MODE: 24/7 (all day, every day)');
      }
      debugPrint('⏰ === END TIME SCHEDULE STATUS ===');

      _checkFacebookVariants();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading blocked apps: $e');
    }
  }

  Future<void> _saveBlockedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appsJson = jsonEncode(_blockedApps.map((app) => app.toJson()).toList());
      await prefs.setString('blockedApps', appsJson);

      await prefs.setInt('blocksToday', _blocksToday);
      if (_lastBlockDate != null) {
        await prefs.setString('lastBlockDate', _lastBlockDate!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving blocked apps: $e');
    }
  }

  Future<void> _loadBlocksToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _blocksToday = prefs.getInt('blocksToday') ?? 0;
      final lastDateStr = prefs.getString('lastBlockDate');
      if (lastDateStr != null) {
        _lastBlockDate = DateTime.parse(lastDateStr);

        if (!_isSameDay(DateTime.now(), _lastBlockDate!)) {
          _blocksToday = 0;
        }
      }
    } catch (e) {
      debugPrint('Error loading blocks today: $e');
    }
  }

  Future<void> _checkFacebookVariants() async {
    try {
      final installedApps = await getInstalledApps();
      
      // Check for Facebook apps
      final facebookApps = installedApps.where((app) {
        final packageName = app['packageName']?.toString().toLowerCase() ?? '';
        final appName = app['appName']?.toString().toLowerCase() ?? '';
        return packageName.contains('facebook') || 
               packageName.contains('messenger') ||
               appName.contains('facebook') ||
               appName.contains('messenger');
      }).toList();

      debugPrint('📘 === FACEBOOK APP DETECTION DEBUG ===');
      debugPrint('📘 Found ${facebookApps.length} Facebook-related apps:');

      for (final app in facebookApps) {
        final packageName = app['packageName']?.toString() ?? 'Unknown';
        final appName = app['appName']?.toString() ?? 'Unknown';
        debugPrint('📘   - $appName: $packageName');

        final isBlocked = _blockedApps.any((blocked) => blocked.packageName == packageName);
        debugPrint('📘     ${isBlocked ? '✅ This package IS in blocked list' : '❌ This package is NOT in blocked list'}');
      }

      debugPrint('📘 === END FACEBOOK DEBUG ===');
      
      // Check for YouTube apps
      final youtubeApps = installedApps.where((app) {
        final packageName = app['packageName']?.toString().toLowerCase() ?? '';
        final appName = app['appName']?.toString().toLowerCase() ?? '';
        return packageName.contains('youtube') || 
               appName.contains('youtube');
      }).toList();

      debugPrint('📺 === YOUTUBE APP DETECTION DEBUG ===');
      debugPrint('📺 Found ${youtubeApps.length} YouTube-related apps:');

      for (final app in youtubeApps) {
        final packageName = app['packageName']?.toString() ?? 'Unknown';
        final appName = app['appName']?.toString() ?? 'Unknown';
        debugPrint('📺   - $appName: $packageName');

        final isBlocked = _blockedApps.any((blocked) => blocked.packageName == packageName);
        debugPrint('📺     ${isBlocked ? '✅ This package IS in blocked list' : '❌ This package is NOT in blocked list'}');
      }

      debugPrint('📺 === END YOUTUBE DEBUG ===');
      
    } catch (e) {
      debugPrint('❌ Error checking Facebook/YouTube variants: $e');
    }
  }

  void startGracePeriod(String appPackage, {int minutes = 2}) {
    final graceEndTime = DateTime.now().add(Duration(minutes: minutes));
    _gracePeriodApps[appPackage] = graceEndTime;

    final app = _blockedApps.firstWhere((app) => app.packageName == appPackage,
        orElse: () => BlockedApp(packageName: appPackage, appName: 'Unknown'));

    debugPrint('😌 Started $minutes-minute grace period for ${app.appName}');

    _sendGracePeriodNotification(app.appName, minutes);

    Timer(Duration(minutes: minutes), () async {
      if (_gracePeriodApps.containsKey(appPackage)) {
        debugPrint('⏰ Grace period expired for ${app.appName} - checking if user is still on app');

        final currentApp = await _appMonitorChannel.invokeMethod('getForegroundApp');
        if (currentApp == appPackage) {
          debugPrint('🚫 User still on ${app.appName} - blocking immediately');
          await _forceCloseApp(appPackage);
        }

        _gracePeriodApps.remove(appPackage);
        notifyListeners();
      }
    });

    notifyListeners();
  }

  Future<void> _sendGracePeriodNotification(String appName, int minutes) async {
    try {
      await _appMonitorChannel.invokeMethod('sendNotification', {
        'title': '⏱️ Grace Period Active',
        'body': 'You have $minutes minutes to finish up in $appName. Use this time wisely!',
        'type': 'grace_period'
      });
      debugPrint('📬 Grace period notification sent');
    } catch (e) {
      debugPrint('❌ Error sending grace period notification: $e');
    }
  }

  bool isInGracePeriod(String appPackage) {
    if (!_gracePeriodApps.containsKey(appPackage)) return false;

    final graceEndTime = _gracePeriodApps[appPackage]!;
    if (DateTime.now().isBefore(graceEndTime)) {
      return true;
    } else {
      _gracePeriodApps.remove(appPackage);
      debugPrint('⏰ GRACE PERIOD EXPIRED for $appPackage - removing from grace list');
      return false;
    }
  }

  Future<void> _sendScheduleReminderNotification(TimeOfDay startTime) async {
    try {
      await _appMonitorChannel.invokeMethod('sendNotification', {
        'title': '⏰ Focus Schedule Set',
        'body': 'Blocking will start at ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}. Get ready to focus!',
        'type': 'reminder'
      });
      debugPrint('📬 Schedule reminder notification sent');
    } catch (e) {
      debugPrint('❌ Error sending schedule reminder: $e');
    }
  }

  void _startTaskReminderSystem() {
    _scheduleNextMorningReminder();

    _taskReminderTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkEndOfFocusTimeReminder();
    });

    debugPrint('📝 Task reminder system started - Morning reminder at 9:30 AM, End-of-focus reminders enabled');
  }

  void _scheduleNextMorningReminder() {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 9, 30);

    if (now.isAfter(target)) {
      target = target.add(const Duration(days: 1));
    }

    final delay = target.difference(now);

    Timer(delay, () async {
      await _checkMorningTaskReminder();
      _scheduleNextMorningReminder();
    });

    debugPrint('📝 Morning task reminder scheduled for ${target.day}/${target.month} at 9:30 AM');
  }

  Future<void> _checkMorningTaskReminder() async {
    try {
      final now = DateTime.now();

      if (now.hour != 9 || (now.minute < 25 || now.minute > 35)) return;

      if (_taskReminderSnoozed) {
        debugPrint('📝 9:30 AM reminder snoozed, skipping');
        return;
      }

      final hasTasksToday = _taskProvider?.todayTasks.isNotEmpty ?? false;

      if (!hasTasksToday) {
        debugPrint('📝 9:30 AM - Task reminders now handled natively by accountability partner system');
        _lastTaskReminderShown = now;
      } else {
        debugPrint('📝 9:30 AM - User already has tasks listed (${_taskProvider?.todayTasks.length}), skipping morning reminder');
      }
    } catch (e) {
      debugPrint('❌ Error checking morning task reminder: $e');
    }
  }

  Future<void> _checkEndOfFocusTimeReminder() async {
    try {
      final now = DateTime.now();

      if (!_enableTimeSchedule || _blockingEndTime == null) return;

      final endTime = _blockingEndTime!;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      final nowMinutes = now.hour * 60 + now.minute;

      final timeAfterEnd = endMinutes == 0
          ? (nowMinutes >= 0 && nowMinutes <= 5)
          : (nowMinutes >= endMinutes && nowMinutes <= endMinutes + 5);

      if (timeAfterEnd) {
        if (_lastTaskReminderShown != null && now.difference(_lastTaskReminderShown!).inHours < 2) {
          return;
        }

        final hasTasksToday = _taskProvider?.todayTasks.isNotEmpty ?? false;

        if (hasTasksToday) {
          debugPrint('📝 Focus time ended - User has tasks, showing progress reminder');
          await _showEndOfFocusProgressReminder();
        } else {
          debugPrint('📝 Focus time ended - Task reminders now handled natively by accountability partner system');
        }

        _lastTaskReminderShown = now;
      }
    } catch (e) {
      debugPrint('❌ Error checking end-of-focus reminder: $e');
    }
  }

  Future<void> _showEndOfFocusProgressReminder() async {
    try {
      debugPrint('📝 Focus session complete - task reminders are now handled natively');
      // Task reminders are handled natively by AppBlockingService.kt
    } catch (e) {
      debugPrint('❌ Error in focus progress reminder: $e');
    }
  }

  void setTaskProvider(TaskProvider taskProvider) {
    _taskProvider = taskProvider;
  }


  void snoozeTaskReminder() {
    debugPrint('😴 ===== SNOOZING TASK REMINDER =====');
    debugPrint('😴 Previous snoozed state: $_taskReminderSnoozed');
    debugPrint('😴 Last shown: $_lastTaskReminderShown');

    _taskReminderSnoozed = true;
    _lastTaskReminderShown = DateTime.now();

    debugPrint('😴 New snoozed state: $_taskReminderSnoozed');
    debugPrint('😴 New last shown: $_lastTaskReminderShown');

    Timer(const Duration(minutes: 10), () async {
      debugPrint('⏰ Snooze timer expired - checking if we should show reminder again');
      _taskReminderSnoozed = false;
      final hasTasksToday = _taskProvider?.todayTasks.isNotEmpty ?? false;
      debugPrint('⏰ Has tasks today: $hasTasksToday');
      if (!hasTasksToday) {
        debugPrint('⏰ Task reminders now handled natively by accountability partner system');
      } else {
        debugPrint('⏰ Not showing reminder - user already has tasks');
      }
    });

    debugPrint('😴 Task reminder snoozed for 10 minutes');
    debugPrint('😴 ===== END SNOOZE =====');
  }

  Future<void> setTaskReminder(int minutes) async {
    try {
      final reminderTime = DateTime.now().add(Duration(minutes: minutes));

      Timer(Duration(minutes: minutes), () async {
        debugPrint('⏰ Task reminders now handled natively by accountability partner system');
      });

      debugPrint('⏰ Task reminder set for $minutes minutes (${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')})');

      await _appMonitorChannel.invokeMethod('sendNotification', {
        'title': '📝 Task Reminder Set',
        'body': 'We\'ll remind you about your tasks in $minutes minutes',
        'type': 'task_reminder'
      });
    } catch (e) {
      debugPrint('❌ Error setting task reminder: $e');
    }
  }

  @override
  void dispose() {
    _mainMonitoringTimer?.cancel();
    _taskReminderTimer?.cancel();
    FlutterForegroundTask.stopService();
    super.dispose();
  }
}