import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';

/// 🚀 OPTIMIZED Hybrid Database Service - Fixed Architecture
/// 
/// LOCAL (Hive/SharedPrefs): Real-time, frequent access data
/// CLOUD (Supabase): Cross-device sync, backup, analytics summaries
class OptimizedHybridDatabaseService {
  static final _instance = OptimizedHybridDatabaseService._internal();
  factory OptimizedHybridDatabaseService() => _instance;
  OptimizedHybridDatabaseService._internal();

  SupabaseClient? _supabaseClient;
  Timer? _syncTimer;
  
  SupabaseClient get supabase {
    try {
      _supabaseClient ??= Supabase.instance.client;
      return _supabaseClient!;
    } catch (e) {
      debugPrint('⚠️ Supabase not initialized, working in local-only mode: $e');
      throw Exception('Supabase not initialized');
    }
  }

  /// Initialize the optimized service
  static Future<void> initializeService() async {
    await _instance.initialize();
  }

  // ===========================================
  // 🏠 LOCAL STORAGE (Speed-Critical)
  // ===========================================
  
  /// Focus timer sessions - LOCAL ONLY (real-time access needed)
  Future<Map<String, dynamic>?> getActiveSession() async {
    return LocalStorageService.getCachedData<Map<String, dynamic>>('active_session');
  }
  
  Future<void> setActiveSession(Map<String, dynamic> session) async {
    await LocalStorageService.cacheData('active_session', session);
  }
  
  Future<void> clearActiveSession() async {
    await LocalStorageService.cacheData('active_session', null);
  }

  /// App usage tracking - LOCAL ONLY (too frequent for cloud)
  Future<List<Map<String, dynamic>>> getLocalAppUsageSessions() async {
    return LocalStorageService.getCachedData<List<Map<String, dynamic>>>('app_usage_sessions') ?? [];
  }
  
  Future<void> addLocalAppUsageSession(Map<String, dynamic> session) async {
    final sessions = await getLocalAppUsageSessions();
    sessions.add(session);
    await LocalStorageService.cacheData('app_usage_sessions', sessions);
  }

  /// Daily calculations - LOCAL CACHE (calculated from local data)
  Future<Map<String, int>> calculateDailyUsage() async {
    final sessions = await getLocalAppUsageSessions();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final todaySessions = sessions.where((s) => 
        s['date'] == today).toList();
    
    Map<String, int> breakdown = {};
    int totalMinutes = 0;
    
    for (var session in todaySessions) {
      final app = session['app_name'] as String;
      final minutes = (session['duration_seconds'] as int) ~/ 60;
      breakdown[app] = (breakdown[app] ?? 0) + minutes;
      totalMinutes += minutes;
    }
    
    breakdown['_total'] = totalMinutes;
    return breakdown;
  }

  /// Daily points - LOCAL STORAGE (for UI responsiveness)
  Future<int> getDailyPoints() async {
    return LocalStorageService.getCachedData<int>('daily_points') ?? 0;
  }
  
  Future<void> setDailyPoints(int points) async {
    await LocalStorageService.cacheData('daily_points', points);
    _markForSync('daily_points', points);
  }

  /// Streak management - LOCAL STORAGE (for instant access)
  Future<int> getStreakCount() async {
    return LocalStorageService.getCachedData<int>('streak_count') ?? 0;
  }
  
  Future<void> setStreakCount(int streak) async {
    await LocalStorageService.cacheData('streak_count', streak);
    _markForSync('streak_count', streak);
  }

  /// Last session date - LOCAL STORAGE (for streak calculations)
  Future<DateTime?> getLastSessionDate() async {
    final dateStr = LocalStorageService.getCachedData<String>('last_session_date');
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }
  
  Future<void> setLastSessionDate(DateTime date) async {
    final dateStr = date.toIso8601String();
    await LocalStorageService.cacheData('last_session_date', dateStr);
    _markForSync('last_session_date', dateStr);
  }

  /// Daily goal minutes - LOCAL STORAGE (user setting)
  Future<int> getDailyGoalMinutes() async {
    return LocalStorageService.getCachedData<int>('daily_goal_minutes') ?? 60;
  }
  
  Future<void> setDailyGoalMinutes(int minutes) async {
    await LocalStorageService.cacheData('daily_goal_minutes', minutes);
    _markForSync('daily_goal_minutes', minutes);
  }

  // ===========================================
  // ☁️ CLOUD STORAGE (Cross-Device Sync)
  // ===========================================
  
  /// User points - HYBRID (local cache + cloud sync)
  Future<int> getTotalPoints() async {
    // Try local first for speed
    final localPoints = LocalStorageService.getCachedData<int>('total_points') ?? 0;
    return localPoints;
  }
  
  Future<void> setTotalPoints(int points) async {
    // Update local immediately
    await LocalStorageService.cacheData('total_points', points);
    // Mark for cloud sync
    _markForSync('total_points', points);
  }

  /// Sync user points to cloud (for cross-device access)
  Future<void> syncUserPointsToCloud() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      final totalPoints = await getTotalPoints();
      final currentStreak = LocalStorageService.getCachedData<int>('streak_count') ?? 0;
      final dailyGoal = LocalStorageService.getCachedData<int>('daily_goal_minutes') ?? 60;
      
      await supabase.from('user_points').upsert({
        'user_id': user.id,
        'total_points': totalPoints,
        'current_streak_days': currentStreak,
        'daily_goal_minutes': dailyGoal,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ User points synced to cloud');
    } catch (e) {
      debugPrint('❌ Failed to sync user points: $e');
    }
  }

  /// Save focus session summary to cloud (not real-time data)
  Future<void> saveFocusSessionSummary(Map<String, dynamic> session) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      // Only save completed sessions to cloud (not active/temp data)
      if (session['completion_status'] == 'completed') {
        await supabase.from('focus_sessions').insert({
          'user_id': user.id,
          'planned_duration_minutes': session['planned_duration'],
          'actual_duration_minutes': session['actual_duration'],
          'session_type': session['type'] ?? 'quick_focus',
          'completion_status': session['status'] ?? 'completed',
          'started_at': session['started_at'],
          'ended_at': session['ended_at'],
          'points_earned': session['points_earned'] ?? 0,
          'points_lost': session['points_lost'] ?? 0,
        });
        
        debugPrint('✅ Focus session summary saved to cloud');
      }
    } catch (e) {
      debugPrint('❌ Failed to save focus session: $e');
    }
  }

  /// Alias for backward compatibility with PointsService
  Future<void> saveFocusSessionToCloud(Map<String, dynamic> session) async {
    await saveFocusSessionSummary(session);
  }

  /// Save points transaction for analytics
  Future<void> savePointsTransactionToCloud(Map<String, dynamic> transaction) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      await supabase.from('points_transactions').insert({
        'user_id': user.id,
        'points_change': transaction['points'],
        'transaction_type': transaction['type'],
        'description': transaction['description'],
        'session_id': transaction['session_id'],
        'created_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Points transaction saved to cloud');
    } catch (e) {
      debugPrint('❌ Failed to save points transaction: $e');
    }
  }

  /// Sync daily usage summary to cloud (not individual sessions)
  Future<void> syncDailySummaryToCloud() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      final dailyUsage = await calculateDailyUsage();
      final totalMinutes = dailyUsage.remove('_total') ?? 0;
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Find most used app
      String? mostUsedApp;
      int maxMinutes = 0;
      dailyUsage.forEach((app, minutes) {
        if (minutes > maxMinutes) {
          maxMinutes = minutes;
          mostUsedApp = app;
        }
      });
      
      await supabase.from('app_usage_summaries').upsert({
        'user_id': user.id,
        'date': today,
        'total_minutes': totalMinutes,
        'most_used_app': mostUsedApp,
        'app_breakdown': dailyUsage,
        'sessions_count': (await getLocalAppUsageSessions()).length,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Daily usage summary synced to cloud');
    } catch (e) {
      debugPrint('❌ Failed to sync daily summary: $e');
    }
  }

  /// Save achievement unlock to cloud
  Future<void> saveAchievementToCloud(Map<String, dynamic> achievement) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      await supabase.from('achievements').insert({
        'user_id': user.id,
        'achievement_type': achievement['type'],
        'achievement_name': achievement['name'],
        'points_awarded': achievement['points'],
        'date_earned': achievement['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      });
      
      debugPrint('✅ Achievement saved to cloud');
    } catch (e) {
      debugPrint('❌ Failed to save achievement: $e');
    }
  }

  /// Badge system - CLOUD (cross-device achievements)
  Future<void> unlockBadgeInCloud(String badgeId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      final badgeResponse = await supabase
          .from('badges')
          .select('id')
          .eq('title', badgeId)
          .maybeSingle();
      
      if (badgeResponse != null) {
        await supabase.from('user_badges').insert({
          'user_id': user.id,
          'badge_id': badgeResponse['id'],
        });
        
        debugPrint('✅ Badge $badgeId unlocked in cloud');
      }
    } catch (e) {
      debugPrint('❌ Failed to unlock badge: $e');
    }
  }

  // ===========================================
  // 🔄 OPTIMIZED SYNC MANAGEMENT
  // ===========================================
  
  void _markForSync(String key, dynamic value) {
    LocalStorageService.markDataForSync(key, {
      'value': value,
      'type': 'user_data',
    });
  }
  
  /// Lightweight sync (only summaries, not real-time data)
  void startOptimizedSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        // Only sync summaries and achievements (not real-time data)
        await syncUserPointsToCloud();
        await syncDailySummaryToCloud();
        debugPrint('🔄 Optimized sync completed');
      } catch (e) {
        debugPrint('⚠️ Sync failed: $e');
      }
    });
  }
  
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Backup critical user data only
  Future<void> backupEssentialUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      final userData = LocalStorageService.getCurrentUser();
      if (userData != null) {
        await supabase.from('user_profiles').upsert({
          'user_id': user.id,
          'username': userData.username,
          'email': userData.email,
          'avatar_url': userData.avatarUrl,
          'points': userData.points,
          'unlocked_badges': userData.unlockedBadges,
          'last_backup': DateTime.now().toIso8601String(),
        });
      }
      
      debugPrint('✅ Essential user data backed up');
    } catch (e) {
      debugPrint('❌ Backup failed: $e');
    }
  }

  /// Initialize optimized service
  Future<void> initialize() async {
    try {
      if (supabase.auth.currentUser != null) {
        // Load critical data from cloud
        await loadUserPointsFromCloud();
        
        // Start lightweight sync
        startOptimizedSync();
      }
      debugPrint('✅ OptimizedHybridDatabaseService initialized');
    } catch (e) {
      debugPrint('⚠️ OptimizedHybridDatabaseService initialization failed (local-only mode): $e');
    }
  }

  /// Load essential data from cloud on login
  Future<void> loadUserPointsFromCloud() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      final response = await supabase
          .from('user_points')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (response != null) {
        // Update local cache with cloud data
        await LocalStorageService.cacheData('total_points', response['total_points'] ?? 0);
        await LocalStorageService.cacheData('streak_count', response['current_streak_days'] ?? 0);
        await LocalStorageService.cacheData('daily_goal_minutes', response['daily_goal_minutes'] ?? 60);
        
        debugPrint('✅ User points loaded from cloud');
      }
    } catch (e) {
      debugPrint('❌ Failed to load user points: $e');
    }
  }
  
  void dispose() {
    stopSync();
  }
}