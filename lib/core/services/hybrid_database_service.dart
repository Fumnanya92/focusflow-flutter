import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_storage_service.dart';

/// 🔥 Hybrid Database Service - Speed-Critical Local + Cloud Sync
/// 
/// Local (Hive): Speed-critical stuff that needs instant updates
/// Supabase: Cross-device sync and data features
class HybridDatabaseService {
  static final _instance = HybridDatabaseService._internal();
  factory HybridDatabaseService() => _instance;
  HybridDatabaseService._internal();

  SupabaseClient? _supabaseClient;
  Timer? _syncTimer;
  
  SupabaseClient get supabase {
    try {
      _supabaseClient ??= Supabase.instance.client;
      return _supabaseClient!;
    } catch (e) {
      // If Supabase is not initialized, we'll work in local-only mode
      debugPrint('⚠️ Supabase not initialized, working in local-only mode: $e');
      throw Exception('Supabase not initialized');
    }
  }

  /// Initialize the hybrid database service (static entry point)
  static Future<void> initializeService() async {
    // Initialize the singleton instance 
    await _instance.initialize();
  }

  // ===========================================
  // 📱 LOCAL STORAGE (Speed-Critical)
  // ===========================================
  
  /// Daily points - needs instant updates for UI
  Future<int> getDailyPoints() async {
    return LocalStorageService.getCachedData<int>('daily_points') ?? 0;
  }
  
  Future<void> setDailyPoints(int points) async {
    await LocalStorageService.cacheData('daily_points', points);
    _markForSync('daily_points', points);
  }
  
  /// Total points - needs instant updates for UI
  Future<int> getTotalPoints() async {
    return LocalStorageService.getCachedData<int>('total_points') ?? 0;
  }
  
  Future<void> setTotalPoints(int points) async {
    await LocalStorageService.cacheData('total_points', points);
    _markForSync('total_points', points);
  }
  
  /// Streak count - needs instant updates for psychology
  Future<int> getStreakCount() async {
    return LocalStorageService.getCachedData<int>('streak_count') ?? 0;
  }
  
  Future<void> setStreakCount(int streak) async {
    await LocalStorageService.cacheData('streak_count', streak);
    _markForSync('streak_count', streak);
  }
  
  /// Last session date - needed for streak calculations
  Future<DateTime?> getLastSessionDate() async {
    final dateStr = LocalStorageService.getCachedData<String>('last_session_date');
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }
  
  Future<void> setLastSessionDate(DateTime date) async {
    final dateStr = date.toIso8601String();
    await LocalStorageService.cacheData('last_session_date', dateStr);
    _markForSync('last_session_date', dateStr);
  }
  
  /// Daily goal minutes - user setting that affects UI calculations
  Future<int> getDailyGoalMinutes() async {
    return LocalStorageService.getCachedData<int>('daily_goal_minutes') ?? 60;
  }
  
  Future<void> setDailyGoalMinutes(int minutes) async {
    await LocalStorageService.cacheData('daily_goal_minutes', minutes);
    _markForSync('daily_goal_minutes', minutes);
  }
  
  /// Session timers - critical for live session tracking
  Future<Map<String, dynamic>?> getActiveSession() async {
    return LocalStorageService.getCachedData<Map<String, dynamic>>('active_session');
  }
  
  Future<void> setActiveSession(Map<String, dynamic> session) async {
    await LocalStorageService.cacheData('active_session', session);
  }
  
  Future<void> clearActiveSession() async {
    await LocalStorageService.cacheData('active_session', null);
  }
  
  /// Animation triggers - UI state that must be instant
  Future<List<String>> getPendingAnimations() async {
    return LocalStorageService.getCachedData<List<String>>('pending_animations')?.cast<String>() ?? [];
  }
  
  Future<void> addPendingAnimation(String animationType) async {
    final animations = await getPendingAnimations();
    animations.add(animationType);
    await LocalStorageService.cacheData('pending_animations', animations);
  }
  
  Future<void> clearPendingAnimations() async {
    await LocalStorageService.cacheData('pending_animations', <String>[]);
  }
  
  /// Badge unlock notifications - instant dopamine hits
  Future<List<String>> getPendingBadgeUnlocks() async {
    return LocalStorageService.getCachedData<List<String>>('pending_badge_unlocks')?.cast<String>() ?? [];
  }
  
  Future<void> addPendingBadgeUnlock(String badgeId) async {
    final badges = await getPendingBadgeUnlocks();
    badges.add(badgeId);
    await LocalStorageService.cacheData('pending_badge_unlocks', badges);
  }
  
  Future<void> clearPendingBadgeUnlocks() async {
    await LocalStorageService.cacheData('pending_badge_unlocks', <String>[]);
  }

  // ===========================================
  // ☁️ SUPABASE STORAGE (Cross-Device Sync)
  // ===========================================
  
  /// Sync user points to cloud for backup and cross-device
  Future<void> syncUserPointsToCloud() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      final totalPoints = await getTotalPoints();
      final currentStreak = await getStreakCount();
      final dailyGoal = await getDailyGoalMinutes();
      final lastActivity = await getLastSessionDate();
      
      await supabase.from('user_points').upsert({
        'user_id': user.id,
        'total_points': totalPoints,
        'current_streak_days': currentStreak,
        'daily_goal_minutes': dailyGoal,
        'last_activity_date': lastActivity?.toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ User points synced to cloud');
    } catch (e) {
      debugPrint('❌ Failed to sync user points: $e');
    }
  }
  
  /// Load user points from cloud on login
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
        // Only update local if cloud data is newer
        final cloudUpdated = DateTime.parse(response['updated_at']);
        final localLastSync = LocalStorageService.getCachedData<String>('last_cloud_sync');
        final localLastSyncDate = localLastSync != null ? DateTime.parse(localLastSync) : DateTime(2000);
        
        if (cloudUpdated.isAfter(localLastSyncDate)) {
          await setTotalPoints(response['total_points'] ?? 0);
          await setStreakCount(response['current_streak_days'] ?? 0);
          await setDailyGoalMinutes(response['daily_goal_minutes'] ?? 60);
          
          if (response['last_activity_date'] != null) {
            await setLastSessionDate(DateTime.parse(response['last_activity_date']));
          }
          
          await LocalStorageService.cacheData('last_cloud_sync', DateTime.now().toIso8601String());
          debugPrint('✅ User points loaded from cloud');
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to load user points: $e');
    }
  }
  
  /// Save focus session to cloud for analytics
  Future<void> saveFocusSessionToCloud(Map<String, dynamic> session) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
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
      
      debugPrint('✅ Focus session saved to cloud');
    } catch (e) {
      debugPrint('❌ Failed to save focus session: $e');
    }
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
      });
      
      debugPrint('✅ Points transaction saved to cloud');
    } catch (e) {
      debugPrint('❌ Failed to save points transaction: $e');
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
  
  /// Unlock badge in cloud
  Future<void> unlockBadgeInCloud(String badgeId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      
      // First get the badge ID from the badges table
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
  
  /// Get user's unlocked badges from cloud
  Future<List<String>> getUserBadgesFromCloud() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];
      
      final response = await supabase
          .from('user_badges')
          .select('badges(title)')
          .eq('user_id', user.id);
      
      return response.map<String>((item) => item['badges']['title'] as String).toList();
    } catch (e) {
      debugPrint('❌ Failed to get user badges: $e');
      return [];
    }
  }

  // ===========================================
  // 🔄 SYNC MANAGEMENT
  // ===========================================
  
  void _markForSync(String key, dynamic value) {
    LocalStorageService.markDataForSync(key, {
      'value': value,
      'type': 'user_data',
    });
  }
  
  /// Start automatic sync timer (every 30 seconds when online)
  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _performBackgroundSync();
    });
  }
  
  void stopAutoSync() {
    _syncTimer?.cancel();
  }
  
  Future<void> _performBackgroundSync() async {
    try {
      final pendingSync = LocalStorageService.getPendingSyncData();
      if (pendingSync.isEmpty) return;
      
      // Batch sync user data
      bool hasUserDataChanges = false;
      for (final entry in pendingSync.entries) {
        if (entry.value['type'] == 'user_data') {
          hasUserDataChanges = true;
          LocalStorageService.markDataAsSynced(entry.key);
        }
      }
      
      if (hasUserDataChanges) {
        await syncUserPointsToCloud();
      }
      
    } catch (e) {
      debugPrint('❌ Background sync failed: $e');
    }
  }
  
  /// Force immediate sync (call on app pause/resume)
  Future<void> forceSyncNow() async {
    await _performBackgroundSync();
    debugPrint('🔄 Force sync completed');
  }
  
  /// Initialize sync system
  Future<void> initialize() async {
    try {
      // Load initial data from cloud if user is logged in
      if (supabase.auth.currentUser != null) {
        await loadUserPointsFromCloud();
        startAutoSync();
      }
      debugPrint('✅ HybridDatabaseService initialized successfully');
    } catch (e) {
      debugPrint('⚠️ HybridDatabaseService initialization failed (local-only mode): $e');
      // Continue in local-only mode
    }
  }
  
  /// Cleanup on app termination
  void dispose() {
    stopAutoSync();
  }
}
