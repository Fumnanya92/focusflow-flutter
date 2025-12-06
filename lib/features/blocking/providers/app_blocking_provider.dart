import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as flutter_overlay_window;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/blocked_app_model.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/services/task_overlay_service.dart';


class AppBlockingProvider extends ChangeNotifier {
  List<BlockedApp> _blockedApps = [];
  bool _isMonitoring = false;
  Timer? _mainMonitoringTimer; // SINGLE monitoring timer for everything
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
  
  // Warning system
  bool _warningShown = false;
  

  


  List<BlockedApp> get blockedApps => _blockedApps;
  List<BlockedApp> get activelyBlockedApps => 
      _blockedApps.where((app) => app.isBlocked).toList();
  bool get isMonitoring => _isMonitoring;
  int get blocksToday => _blocksToday;
  bool get isFocusModeEnabled => _focusModeEnabled;
  bool get isBlockingActive => _isMonitoring && (_focusModeEnabled || activelyBlockedApps.isNotEmpty);
  
  // Check if all required permissions are granted
  bool get hasRequiredPermissions {
    // CRITICAL: Both usage stats AND overlay permissions are required
    debugPrint('🔑 Permissions check - Usage Stats: $_hasUsageStatsPermission');
    return _hasUsageStatsPermission; // For now, focusing on usage stats as the critical one
  }
  
  // Track usage stats permission status
  bool _hasUsageStatsPermission = false;

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
    {'package': 'com.snapchat.android', 'name': 'Snapchat'},
    {'package': 'com.reddit.frontpage', 'name': 'Reddit'},
    {'package': 'com.pinterest', 'name': 'Pinterest'},
    {'package': 'com.linkedin.android', 'name': 'LinkedIn'},
    {'package': 'com.youtube.android', 'name': 'YouTube'},
  ];

  AppBlockingProvider() {
    _initialize();
  }
  
  void _initialize() async {
    await _loadBlockedApps();
    _loadBlocksToday();
    await _checkPermissionStatus(); // Check permissions on startup
    _setupMethodChannel();
    await _initializeBackgroundService(); // Initialize background service
    startMonitoring(); // Start monitoring after apps are loaded
    _startTaskReminderSystem(); // Start task reminder system
  }
  
  // Check and update permission status from SharedPreferences
  Future<void> _checkPermissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasUsageStatsPermission = prefs.getBool('usage_stats_granted') ?? false;
    
    debugPrint('🔐 Permission Status Check:');
    debugPrint('   Usage Stats Permission: $_hasUsageStatsPermission');
    
    // CRITICAL: If we don't have usage stats permission, app blocking WILL NOT WORK
    if (!_hasUsageStatsPermission) {
      debugPrint('🚨 CRITICAL: Usage stats permission not granted - App blocking DISABLED!');
      debugPrint('💡 User must grant this permission for app blocking to work');
    }
    
    notifyListeners();
  }
  
  // Update permission status (called by permission screen)
  void updatePermissionStatus(bool hasUsageStats) {
    _hasUsageStatsPermission = hasUsageStats;
    notifyListeners();
  }
  
  void _setupMethodChannel() {
    // Method channel setup removed - main.dart now handles all overlay channel communication
    // This prevents conflicts where multiple handlers overwrite each other
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
    notifyListeners();
  }

  Future<void> removeBlockedApp(String packageName) async {
    _blockedApps.removeWhere((app) => app.packageName == packageName);
    await _saveBlockedApps();
    notifyListeners();
  }

  Future<void> toggleAppBlocking(String packageName) async {
    final index = _blockedApps.indexWhere((app) => app.packageName == packageName);
    if (index != -1) {
      _blockedApps[index] = _blockedApps[index].copyWith(
        isBlocked: !_blockedApps[index].isBlocked,
      );
      await _saveBlockedApps();
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

  static const MethodChannel _appMonitorChannel = MethodChannel('app.focusflow/monitor');
  
  // Cache for installed apps to avoid frequent system calls
  List<Map<String, dynamic>>? _installedApps;
  DateTime? _lastInstalledAppsUpdate;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // SINGLE UNIFIED MONITORING TIMER - checks everything at once
    _mainMonitoringTimer = Timer.periodic(
      const Duration(seconds: 1), // Reasonable 1-second interval to prevent overheating
      (_) => _unifiedMonitoringCheck(),
    );
    
    // Ensure background service is running
    await _ensureBackgroundServiceRunning();
    
    notifyListeners();
    debugPrint('🔍 Started UNIFIED monitoring system (checking every 1 second)');
    debugPrint('🔄 Background service status: $_backgroundServiceRunning');
    debugPrint('📋 Monitoring ${_blockedApps.where((app) => app.isBlocked).length} blocked apps: ${_blockedApps.where((app) => app.isBlocked).map((app) => app.appName).join(", ")}');
    
    // Validate blocked apps after a delay
    Future.delayed(const Duration(seconds: 5), () {
      _validateBlockedApps();
    });
  }
  
  // Validate that all blocked apps are actually installed
  void _validateBlockedApps() async {
    try {
      final installedApps = await getInstalledApps();
      final installedPackages = installedApps.map((app) => app['packageName']).toSet();
      
      final invalidApps = _blockedApps.where(
        (app) => !installedPackages.contains(app.packageName)
      ).toList();
      
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

  void stopMonitoring() {
    _isMonitoring = false;
    _mainMonitoringTimer?.cancel();
    _mainMonitoringTimer = null;
    notifyListeners();
    debugPrint('⏹️ Stopped unified monitoring system');
  }
  
  // UNIFIED MONITORING CHECK - handles everything in one place
  Future<void> _unifiedMonitoringCheck() async {
    if (!_isMonitoring) return;
    
    try {
      // 1. Clean up expired grace periods
      _cleanupExpiredGracePeriods();
      
      // 2. Get current foreground app
      final String? foregroundPackage = await _appMonitorChannel.invokeMethod('getForegroundApp');
      
      if (foregroundPackage == null || foregroundPackage.isEmpty) return;
      if (foregroundPackage == 'com.example.focusflow') return; // Skip our own app
      
      // 3. Find if this is a blocked app
      final blockedApp = _blockedApps.firstWhere(
        (app) => app.packageName == foregroundPackage && app.isBlocked,
        orElse: () => BlockedApp(packageName: '', appName: ''),
      );
      
      if (blockedApp.packageName.isEmpty) return; // Not a blocked app
      
      // 4. Check if we should show 5-minute warning
      await _checkAndShowWarning(blockedApp);
      
      // 5. Check if app should be blocked now
      final shouldBlockNow = _isAppBlockedNow(blockedApp);
      
      if (shouldBlockNow) {
        debugPrint('🚫 BLOCKING: ${blockedApp.appName} - Immediate interruption');
        await _blockAppImmediately(blockedApp);
      }
      
    } catch (e) {
      debugPrint('❌ Error in unified monitoring: $e');
    }
  }
  
  // Check and show 5-minute warning before blocking time
  Future<void> _checkAndShowWarning(BlockedApp app) async {
    if (!_enableTimeSchedule || _blockingStartTime == null) return;
    
    final now = DateTime.now();
    final todayBlockingStart = DateTime(
      now.year, now.month, now.day,
      _blockingStartTime!.hour, _blockingStartTime!.minute
    );
    
    // Show warning 5 minutes before blocking time
    final warningTime = todayBlockingStart.subtract(const Duration(minutes: 5));
    final timeUntilWarning = warningTime.difference(now).inSeconds;
    
    // Show warning if we're within 1 minute of the 5-minute warning time
    if (timeUntilWarning >= -30 && timeUntilWarning <= 30 && !_warningShown) {
      _warningShown = true;
      
      await _sendWarningNotification(app.appName, 5);
      debugPrint('⚠️ 5-minute warning shown for ${app.appName}');
      
      // Reset warning flag after blocking time passes
      Timer(const Duration(minutes: 10), () {
        _warningShown = false;
      });
    }
  }
  
  // Send warning notification
  Future<void> _sendWarningNotification(String appName, int minutesRemaining) async {
    try {
      await _appMonitorChannel.invokeMethod('sendNotification', {
        'title': '⚠️ Focus Time Starting Soon',
        'body': 'You have $minutesRemaining minutes remaining before $appName gets blocked. Finish up!',
        'type': 'warning'
      });
      debugPrint('📬 Warning notification sent');
    } catch (e) {
      debugPrint('❌ Error sending warning notification: $e');
    }
  }
  
  // Block app immediately with proper overlay
  Future<void> _blockAppImmediately(BlockedApp app) async {
    try {
      // Force close the app
      await _forceCloseApp(app.packageName);
      
      // Show blocking overlay
      await _triggerBlockOverlay(app);
      
      // Increment blocks today
      _incrementBlocksToday();
      
    } catch (e) {
      debugPrint('❌ Error blocking app immediately: $e');
    }
  }
  
  // Force close a blocked app - simplified version
  Future<void> _forceCloseApp(String packageName) async {
    try {
      await _appMonitorChannel.invokeMethod('closeApp', {'packageName': packageName});
      debugPrint('🔒 FORCE CLOSED $packageName');
    } catch (e) {
      debugPrint('❌ Error force closing app: $e');
    }
  }



  bool _isAppBlockedNow(BlockedApp app) {
    if (!app.isBlocked) return false;
    
    // Check if app is in grace period (even focus mode respects grace periods)
    if (_gracePeriodApps.containsKey(app.packageName)) {
      final graceEndTime = _gracePeriodApps[app.packageName]!;
      final now = DateTime.now();
      if (now.isBefore(graceEndTime)) {
        final remainingSeconds = graceEndTime.difference(now).inSeconds;
        debugPrint('😌 ${app.appName} in grace period - ${remainingSeconds}s remaining (until ${graceEndTime.toIso8601String()})');
        return false; // Don't block during grace period
      } else {
        // Grace period expired, remove it
        _gracePeriodApps.remove(app.packageName);
        debugPrint('🚨⏰ GRACE PERIOD EXPIRED for ${app.appName} - NOW BLOCKING!');
        notifyListeners(); // Update UI immediately
      }
    }
    
    // PRIORITY: Focus mode overrides all other settings
    if (_focusModeEnabled) {
      debugPrint('🎯 ${app.appName} BLOCKED - Focus mode is active (overrides time schedule)');
      return true;
    }
    
    // Check if time scheduling is enabled
    final timeScheduleEnabled = _isTimeScheduleEnabled();
    
    if (timeScheduleEnabled) {
      // Only block during scheduled time window
      final inBlockingWindow = _isInBlockingTimeWindow();
      final now = TimeOfDay.now();
      debugPrint('⏰ Time schedule enabled. Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}, Start: ${_blockingStartTime?.hour}:${_blockingStartTime?.minute.toString().padLeft(2, '0')}, End: ${_blockingEndTime?.hour}:${_blockingEndTime?.minute.toString().padLeft(2, '0')}, In blocking window: $inBlockingWindow');
      
      if (!inBlockingWindow) {
        debugPrint('⏰ ${app.appName} not blocked - outside time window');
        return false;
      } else {
        debugPrint('� ${app.appName} BLOCKED - within time window');
        return true;
      }
    } else {
      // Block all the time when time schedule is disabled
      debugPrint('🚨 App ${app.appName} is marked for blocking - BLOCKED (no time schedule, 24/7 blocking)');
      return true;
    }
  }
  
  bool _isTimeScheduleEnabled() {
    // Check if time schedule is explicitly enabled AND we have valid time windows
    final enabled = _enableTimeSchedule && _blockingStartTime != null && _blockingEndTime != null;
    debugPrint('⏰ Time schedule enabled: $_enableTimeSchedule, Has times: ${_blockingStartTime != null && _blockingEndTime != null}, Final enabled: $enabled');
    return enabled;
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
    
    // CRITICAL FIX: Handle midnight (00:00) properly
    // When end time is 00:00 (midnight), it means block until end of day
    if (_blockingEndTime!.hour == 0 && _blockingEndTime!.minute == 0) {
      // Special case: blocking until midnight (end of day)
      inWindow = nowMinutes >= startMinutes;
      debugPrint('⏰ Blocking until midnight (00:00) - Currently in window: $inWindow');
    } else if (startMinutes < endMinutes) {
      // Normal case: start to end within same day (e.g., 9 AM to 5 PM)
      inWindow = nowMinutes >= startMinutes && nowMinutes <= endMinutes;
      debugPrint('⏰ Same-day schedule: $inWindow');
    } else {
      // Crosses midnight (e.g., 10 PM to 6 AM next day)
      inWindow = nowMinutes >= startMinutes || nowMinutes <= endMinutes;
      debugPrint('⏰ Cross-midnight schedule: $inWindow');
    }
    
    return inWindow;
  }


  Future<void> _triggerBlockOverlay(BlockedApp app) async {
    try {
      debugPrint('🛡️ BLOCKING: ${app.appName}');
      
      // Send block notification
      await _sendBlockNotification(app.appName);
      
      // Use native Android overlay for immediate, unescapable blocking
      await _showNativeOverlay(app.appName);
      
    } catch (e) {
      debugPrint('❌ Error triggering overlay: $e');
    }
  }

  Future<void> _showNativeOverlay(String appName) async {
    try {
      // Use the native Android overlay system for immediate blocking
      await _appMonitorChannel.invokeMethod('showBlockOverlay', {
        'appName': appName,
        'title': 'Time to Focus!',
        'message': '$appName is blocked during your focus time. Stay disciplined to earn points!',
      });
      
      debugPrint('🎯 Native blocking overlay shown for $appName');
    } catch (e) {
      debugPrint('❌ Error showing native overlay: $e');
      // Fallback to Flutter overlay system
      _currentlyBlockedApp = appName;
      notifyListeners();
    }
  }

  // Add field to track currently blocked app
  String? _currentlyBlockedApp;
  String? get currentlyBlockedApp => _currentlyBlockedApp;

  void clearCurrentlyBlockedApp() {
    _currentlyBlockedApp = null;
    notifyListeners();
  }



  
  // Get list of installed apps from the system
  Future<List<Map<String, dynamic>>> getInstalledApps({bool forceRefresh = false}) async {
    try {
      // Use cache if available and not expired (refresh every 5 minutes)
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
  
  // Get usage statistics for a specific app
  Future<Map<String, dynamic>> getAppUsageStats(String packageName, {int days = 7}) async {
    try {
      debugPrint('📊 Getting usage stats for $packageName (last $days days)');
      
      final Map<dynamic, dynamic> result = await _appMonitorChannel.invokeMethod('getAppUsageStats', {
        'packageName': packageName,
        'days': days,
      }) ?? {};
      
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
  
  // Check if an app is actually installed on the device
  Future<bool> isAppInstalled(String packageName) async {
    try {
      final installedApps = await getInstalledApps();
      return installedApps.any((app) => app['packageName'] == packageName);
    } catch (e) {
      debugPrint('❌ Error checking if app is installed: $e');
      return false;
    }
  }
  
  // Get all social media apps that are actually installed
  Future<List<Map<String, String>>> getInstalledSocialMediaApps() async {
    try {
      final installedApps = await getInstalledApps();
      final socialMediaApps = <Map<String, String>>[];
      
      for (final popularApp in popularApps) {
        final isInstalled = installedApps.any(
          (app) => app['packageName'] == popularApp['package']
        );
        
        if (isInstalled) {
          socialMediaApps.add({
            'package': popularApp['package']!,
            'name': popularApp['name']!,
          });
        }
      }
      
      debugPrint('📱 Found ${socialMediaApps.length} installed social media apps: ${socialMediaApps.map((app) => app['name']).join(', ')}');
      
      // Check specifically for Facebook variants
      final facebookVariants = [
        'com.facebook.katana', 
        'com.facebook.lite', 
        'com.facebook.mlite',
        'com.facebook.android',
        'com.facebook.pages.app'
      ];
      for (final variant in facebookVariants) {
        final isInstalled = installedApps.any((app) => app['packageName'] == variant);
        if (isInstalled) {
          debugPrint('📘 Found Facebook variant: $variant');
        }
      }
      
      return socialMediaApps;
    } catch (e) {
      debugPrint('❌ Error getting installed social media apps: $e');
      return [];
    }
  }



  void _incrementBlocksToday() {
    final today = DateTime.now();
    
    // Reset counter if it's a new day
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
    _saveBlockedApps(); // Save updated counter
    
    debugPrint('📊 Blocks today: $_blocksToday');
  }

  // Add custom app to blocking list from package name
  Future<void> addCustomApp(String packageName, String customName) async {
    try {
      // Check if app is actually installed
      final isInstalled = await isAppInstalled(packageName);
      
      if (!isInstalled) {
        debugPrint('❌ App not installed: $packageName');
        throw Exception('App with package name "$packageName" is not installed on this device');
      }
      
      // Check if already in blocked list
      if (_blockedApps.any((app) => app.packageName == packageName)) {
        debugPrint('⚠️ App already in blocked list: $packageName');
        throw Exception('This app is already in your blocked list');
      }
      
      // Add to blocked apps
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
    
    debugPrint('⏰ Blocking schedule set and ENABLED: ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}');
    debugPrint('⏰ Time schedule is now active - apps will only be blocked during these hours');
    
    // Monitoring will automatically pick up the new schedule
    
    // Send reminder notification
    await _sendScheduleReminderNotification(startTime);
    
    notifyListeners();
  }
  
  void disableTimeSchedule() async {
    _enableTimeSchedule = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableTimeSchedule', false);
    
    debugPrint('⏰ Time schedule DISABLED - blocking now active 24/7 (all day, every day)');
    debugPrint('⏰ Kept time window for reference: ${_blockingStartTime?.hour}:${_blockingStartTime?.minute.toString().padLeft(2, '0')} - ${_blockingEndTime?.hour}:${_blockingEndTime?.minute.toString().padLeft(2, '0')}');
    
    // Monitoring will automatically adjust to 24/7 blocking
    
    notifyListeners();
  }

  /// Enable focus mode (blocks all selected apps regardless of time schedule)
  void enableFocusMode() {
    _focusModeEnabled = true;
    
    // Monitoring will automatically respect focus mode
    
    notifyListeners();
    debugPrint('🎯 Focus mode ENABLED - All selected apps will be blocked');
  }

  /// Disable focus mode (revert to normal time-based blocking)
  void disableFocusMode() {
    _focusModeEnabled = false;
    
    // Monitoring will automatically revert to normal schedule
    
    notifyListeners();
    debugPrint('🎯 Focus mode DISABLED - Normal blocking rules apply');
  }
  
  // Getters for time schedule
  TimeOfDay? get blockingStartTime => _blockingStartTime;
  TimeOfDay? get blockingEndTime => _blockingEndTime;
  bool get enableTimeSchedule => _enableTimeSchedule;

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
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
        
        // Reset if it's a new day
        if (!_isSameDay(DateTime.now(), _lastBlockDate!)) {
          _blocksToday = 0;
        }
      }
      
      // Load time schedule preferences
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
      
      // Debug: Check for Facebook variants
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
      
      // Also save block counts
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
        
        // Reset if it's a new day
        if (!_isSameDay(DateTime.now(), _lastBlockDate!)) {
          _blocksToday = 0;
        }
      }
    } catch (e) {
      debugPrint('Error loading blocks today: $e');
    }
  }

  // Debug method to check what Facebook variants are installed
  Future<void> _checkFacebookVariants() async {
    try {
      final installedApps = await getInstalledApps();
      final facebookApps = installedApps.where((app) => 
        app['packageName']?.toString().toLowerCase().contains('facebook') == true
      ).toList();
      
      debugPrint('📘 === FACEBOOK APP DETECTION DEBUG ===');
      debugPrint('📘 Found ${facebookApps.length} Facebook-related apps:');
      
      for (final app in facebookApps) {
        final packageName = app['packageName']?.toString() ?? 'Unknown';
        final appName = app['appName']?.toString() ?? 'Unknown';
        debugPrint('📘   - $appName: $packageName');
        
        // Check if this package is in our blocked list
        final isBlocked = _blockedApps.any((blocked) => blocked.packageName == packageName);
        if (isBlocked) {
          debugPrint('📘     ✅ This package IS in blocked list');
        } else {
          debugPrint('📘     ❌ This package is NOT in blocked list');
        }
      }
      
      debugPrint('📘 === END FACEBOOK DEBUG ===');
      
    } catch (e) {
      debugPrint('❌ Error checking Facebook variants: $e');
    }
  }

  /// Start a grace period for a specific app with countdown
  void startGracePeriod(String appPackage, {int minutes = 2}) {
    final graceEndTime = DateTime.now().add(Duration(minutes: minutes));
    _gracePeriodApps[appPackage] = graceEndTime;
    
    final app = _blockedApps.firstWhere((app) => app.packageName == appPackage, 
        orElse: () => BlockedApp(packageName: appPackage, appName: 'Unknown'));
    
    debugPrint('😌 Started $minutes-minute grace period for ${app.appName}');
    
    // Send notification about grace period starting
    _sendGracePeriodNotification(app.appName, minutes);
    
    // Schedule automatic blocking when grace period expires
    Timer(Duration(minutes: minutes), () async {
      if (_gracePeriodApps.containsKey(appPackage)) {
        debugPrint('⏰ Grace period expired for ${app.appName} - checking if user is still on app');
        
        // Check if user is currently on this app
        final currentApp = await _appMonitorChannel.invokeMethod('getForegroundApp');
        if (currentApp == appPackage) {
          debugPrint('🚫 User still on ${app.appName} - blocking immediately');
          await _blockAppImmediately(app);
        }
        
        // Clean up grace period
        _gracePeriodApps.remove(appPackage);
        notifyListeners();
      }
    });
    
    notifyListeners();
  }
  
  /// Send grace period notification
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

  /// Check if an app is currently in grace period
  bool isInGracePeriod(String appPackage) {
    if (!_gracePeriodApps.containsKey(appPackage)) return false;
    
    final graceEndTime = _gracePeriodApps[appPackage]!;
    if (DateTime.now().isBefore(graceEndTime)) {
      return true;
    } else {
      // Grace period expired, remove it
      _gracePeriodApps.remove(appPackage);
      debugPrint('⏰ GRACE PERIOD EXPIRED for $appPackage - removing from grace list');
      return false;
    }
  }
  
  /// Clean up all expired grace periods
  void _cleanupExpiredGracePeriods() {
    final now = DateTime.now();
    final expiredApps = <String>[];
    
    _gracePeriodApps.forEach((packageName, graceEndTime) {
      if (now.isAfter(graceEndTime)) {
        expiredApps.add(packageName);
      }
    });
    
    for (final packageName in expiredApps) {
      _gracePeriodApps.remove(packageName);
      final app = _blockedApps.firstWhere(
        (app) => app.packageName == packageName,
        orElse: () => BlockedApp(packageName: packageName, appName: 'Unknown'),
      );
      debugPrint('🚨 GRACE PERIOD EXPIRED: ${app.appName} ($packageName) - NOW ELIGIBLE FOR BLOCKING!');
    }
    
    if (expiredApps.isNotEmpty) {
      notifyListeners(); // Notify UI that grace periods changed
    }
  }

  // Notification methods
  Future<void> _sendBlockNotification(String appName) async {
    try {
      await _appMonitorChannel.invokeMethod('sendNotification', {
        'title': '🚫 App Blocked',
        'body': '$appName has been blocked. Focus time is active!',
        'type': 'block'
      });
      debugPrint('📬 Block notification sent for $appName');
    } catch (e) {
      debugPrint('❌ Error sending block notification: $e');
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




  

  

  

  


  /// Initialize background service for continuous monitoring
  Future<void> _initializeBackgroundService() async {
    try {
      // Initialize the foreground task with basic configuration
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'focusflow_foreground',
          channelName: 'FocusFlow Background Service',
          channelDescription: 'Keeps FocusFlow running to monitor and block apps effectively',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.nothing(),
        ),
      );
      
      debugPrint('🔄 Background service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing background service: $e');
    }
  }
  
  /// Ensure background service is running
  Future<void> _ensureBackgroundServiceRunning() async {
    try {
      final isRunning = await FlutterForegroundTask.isRunningService;
      if (!isRunning) {
        await FlutterForegroundTask.startService(
          notificationTitle: 'FocusFlow Active',
          notificationText: 'Monitoring apps to keep you focused',
          callback: _backgroundTaskCallback,
        );
        
        _backgroundServiceRunning = true;
        debugPrint('✅ Background service started successfully');
      } else {
        _backgroundServiceRunning = true;
        debugPrint('✅ Background service already running');
      }
    } catch (e) {
      debugPrint('❌ Error ensuring background service: $e');
    }
  }
  
  /// Background task callback
  @pragma('vm:entry-point')
  static void _backgroundTaskCallback() {
    debugPrint('🔄 Background task running - keeping app monitoring active');
    
    // Update the notification to show current status
    FlutterForegroundTask.updateService(
      notificationTitle: 'FocusFlow Active',
      notificationText: 'Monitoring ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} - Stay focused!',
    );
  }
  
  /// Start task reminder system
  void _startTaskReminderSystem() {
    // Check for morning task reminder at 9:30 AM daily
    _scheduleNextMorningReminder();
    
    // Also check for end-of-focus-time reminders
    _taskReminderTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkEndOfFocusTimeReminder();
    });
    
    debugPrint('📝 Task reminder system started - Morning reminder at 9:30 AM, End-of-focus reminders enabled');
  }
  
  /// Schedule the next morning reminder at 9:30 AM
  void _scheduleNextMorningReminder() {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 9, 30); // 9:30 AM today
    
    // If it's already past 9:30 AM today, schedule for tomorrow
    if (now.isAfter(target)) {
      target = target.add(const Duration(days: 1));
    }
    
    final delay = target.difference(now);
    
    Timer(delay, () async {
      await _checkMorningTaskReminder();
      // Schedule the next day's reminder
      _scheduleNextMorningReminder();
    });
    
    debugPrint('📝 Morning task reminder scheduled for ${target.day}/${target.month} at 9:30 AM');
  }
  
  /// Check and show morning task reminder at 9:30 AM
  Future<void> _checkMorningTaskReminder() async {
    try {
      final now = DateTime.now();
      
      // Only show if it's around 9:30 AM (within 5 minutes)
      if (now.hour != 9 || (now.minute < 25 || now.minute > 35)) return;
      
      // Don't show if currently snoozed
      if (_taskReminderSnoozed) {
        debugPrint('📝 9:30 AM reminder snoozed, skipping');
        return;
      }
      
      // Check if user has tasks for today
      final hasTasksToday = _taskProvider?.todayTasks.isNotEmpty ?? false;
      
      // Show reminder only if user hasn't listed tasks yet
      if (!hasTasksToday) {
        debugPrint('📝 9:30 AM - User has no tasks listed, showing morning reminder');
        await _showTaskReminderOverlay();
        _lastTaskReminderShown = now;
      } else {
        debugPrint('📝 9:30 AM - User already has tasks listed (${_taskProvider?.todayTasks.length}), skipping morning reminder');
      }
      
    } catch (e) {
      debugPrint('❌ Error checking morning task reminder: $e');
    }
  }
  
  /// Check for end-of-focus-time reminder
  Future<void> _checkEndOfFocusTimeReminder() async {
    try {
      final now = DateTime.now();
      
      // Only check if we have a time schedule
      if (!_enableTimeSchedule || _blockingEndTime == null) return;
      
      // Check if we're within 5 minutes after the focus time ends
      final endTime = _blockingEndTime!;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      final nowMinutes = now.hour * 60 + now.minute;
      
      // Handle midnight crossing
      final timeAfterEnd = endMinutes == 0 ? 
        (nowMinutes >= 0 && nowMinutes <= 5) : // Within 5 min after midnight
        (nowMinutes >= endMinutes && nowMinutes <= endMinutes + 5); // Within 5 min after end time
      
      if (timeAfterEnd) {
        // Don't show more than once every 2 hours
        if (_lastTaskReminderShown != null && 
            now.difference(_lastTaskReminderShown!).inHours < 2) {
          return;
        }
        
        // Check if user has tasks
        final hasTasksToday = _taskProvider?.todayTasks.isNotEmpty ?? false;
        
        if (hasTasksToday) {
          debugPrint('📝 Focus time ended - User has tasks, showing progress reminder');
          await _showEndOfFocusProgressReminder();
        } else {
          debugPrint('📝 Focus time ended - User has no tasks, showing task planning reminder');
          await _showTaskReminderOverlay();
        }
        
        _lastTaskReminderShown = now;
      }
      
    } catch (e) {
      debugPrint('❌ Error checking end-of-focus reminder: $e');
    }
  }
  
  /// Show end-of-focus progress reminder
  Future<void> _showEndOfFocusProgressReminder() async {
    try {
      debugPrint('📝 Showing end-of-focus progress reminder');
      
      final hasPermission = await flutter_overlay_window.FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        await flutter_overlay_window.FlutterOverlayWindow.requestPermission();
        return;
      }
      
      await flutter_overlay_window.FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        overlayTitle: 'FocusFlow - Focus Session Complete',
        overlayContent: 'Great focus session! How did your tasks go?',
        flag: flutter_overlay_window.OverlayFlag.defaultFlag,
        visibility: flutter_overlay_window.NotificationVisibility.visibilityPublic,
        positionGravity: flutter_overlay_window.PositionGravity.auto,
        height: 400,
        width: 350,
      );
      
      await flutter_overlay_window.FlutterOverlayWindow.shareData({
        'type': 'focus_progress',
        'action': 'show',
        'completedTasks': _taskProvider?.completedTasks.length ?? 0,
        'totalTasks': _taskProvider?.todayTasks.length ?? 0,
      });
      
    } catch (e) {
      debugPrint('❌ Error showing focus progress reminder: $e');
    }
  }
  
  /// Set task provider reference for reminders
  void setTaskProvider(TaskProvider taskProvider) {
    _taskProvider = taskProvider;
  }
  

  
  /// Show task reminder overlay
  Future<void> _showTaskReminderOverlay() async {
    try {
      debugPrint('📝 Showing beautiful Flutter task reminder overlay');
      
      // Use the new Flutter-based overlay for better UX
      await TaskOverlayService.showTaskReminderOverlay(
        title: 'Good Morning! 🌅',
        message: 'What are your main goals for today? Planning your tasks helps you stay focused!',
        hasTasksToday: _taskProvider?.todayTasks.isNotEmpty ?? false,
        taskCount: _taskProvider?.todayTasks.length ?? 0,
      );
      
      debugPrint('📝 ✨ Beautiful task reminder overlay shown');
    } catch (e) {
      debugPrint('❌ Error showing task reminder overlay: $e');
      // Fallback: Send notification instead
      await _sendTaskReminderNotification();
    }
  }
  
  /// Public method to test task reminder overlay (DEV ONLY)
  Future<void> showTaskReminder() async {
    debugPrint('🧪 TEST: Triggering task reminder overlay');
    await _showTaskReminderOverlay();
  }
  
  /// Navigate to task planning screen

  
  /// Get navigator context (simplified version - using method channel instead)

  
  /// Send task reminder notification as fallback
  Future<void> _sendTaskReminderNotification() async {
    try {
      await _appMonitorChannel.invokeMethod('sendNotification', {
        'title': '📝 Daily Task Planning',
        'body': 'Good morning! Take a moment to plan your tasks for today. What are your main goals?',
        'type': 'task_reminder'
      });
      debugPrint('📬 Task reminder notification sent as fallback');
    } catch (e) {
      debugPrint('❌ Error sending task reminder notification: $e');
    }
  }
  
  /// Snooze task reminder for 10 minutes
  void snoozeTaskReminder() {
    debugPrint('😴 ===== SNOOZING TASK REMINDER =====');
    debugPrint('😴 Previous snoozed state: $_taskReminderSnoozed');
    debugPrint('😴 Last shown: $_lastTaskReminderShown');
    
    _taskReminderSnoozed = true;
    _lastTaskReminderShown = DateTime.now();
    
    debugPrint('😴 New snoozed state: $_taskReminderSnoozed');
    debugPrint('😴 New last shown: $_lastTaskReminderShown');
    
    // Schedule to show again in 10 minutes
    Timer(const Duration(minutes: 10), () async {
      debugPrint('⏰ Snooze timer expired - checking if we should show reminder again');
      _taskReminderSnoozed = false;
      final hasTasksToday = _taskProvider?.todayTasks.isNotEmpty ?? false;
      debugPrint('⏰ Has tasks today: $hasTasksToday');
      if (!hasTasksToday) {
        debugPrint('⏰ Showing reminder after snooze period');
        await _showTaskReminderOverlay();
      } else {
        debugPrint('⏰ Not showing reminder - user already has tasks');
      }
    });
    
    debugPrint('😴 Task reminder snoozed for 10 minutes');
    debugPrint('😴 ===== END SNOOZE =====');
  }
  
  /// Set task reminder (called from overlay)
  Future<void> setTaskReminder(int minutes) async {
    try {
      final reminderTime = DateTime.now().add(Duration(minutes: minutes));
      
      // Schedule a one-time reminder
      Timer(Duration(minutes: minutes), () async {
        await _showTaskReminderOverlay();
      });
      
      debugPrint('⏰ Task reminder set for $minutes minutes (${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')})');
      
      // Send notification about reminder set
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
    
    // Stop background service
    FlutterForegroundTask.stopService();
    
    super.dispose();
  }
}
