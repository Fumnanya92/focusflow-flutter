import 'package:flutter/foundation.dart';
import '../../../core/services/hybrid_database_service.dart';
import '../../../core/services/local_storage_service.dart';
import '../../rewards/providers/rewards_provider.dart';

/// 🎮 FocusFlow Points System - Fun, Fair & Addictive
/// 
/// Every minute you stay focused, you level up — just like gaining XP in your favorite game.
class PointsService {
  final RewardsProvider _rewardsProvider;
  final HybridDatabaseService _db = HybridDatabaseService();
  
  PointsService(this._rewardsProvider);

  // ===========================================
  // ⭐ EARN POINTS (Level Up Fast)
  // ===========================================

  /// +1 point → Every focused minute
  /// Stay focused, keep earning — simple.
  Future<void> awardFocusMinutePoints(int minutes) async {
    final points = minutes * 1; // 1 point per minute
    await _addPoints(points, 'Focused for $minutes ${minutes == 1 ? 'minute' : 'minutes'}');
    
    // Update daily stats
    await _updateDailyFocusMinutes(minutes);
    
    debugPrint('🎯 +$points points for $minutes minutes of focus');
  }

  /// +10 points → Finish a scheduled block
  /// If you plan a 30-min session and complete it, boom — bonus.
  Future<void> awardSessionCompletionBonus(int plannedMinutes, int actualMinutes) async {
    if (actualMinutes >= plannedMinutes) {
      const bonusPoints = 10;
      await _addPoints(bonusPoints, 'Completed $plannedMinutes-minute session');
      
      // Update sessions completed today
      await _incrementSessionsCompleted();
      
      // Check for Marathon Mode badge (2+ hours)
      await checkMarathonModeBadge(actualMinutes);
      
      // Save focus session to cloud for analytics
      await _db.saveFocusSessionToCloud({
        'planned_duration': plannedMinutes,
        'actual_duration': actualMinutes,
        'type': 'scheduled',
        'status': 'completed',
        'started_at': DateTime.now().subtract(Duration(minutes: actualMinutes)).toIso8601String(),
        'ended_at': DateTime.now().toIso8601String(),
        'points_earned': bonusPoints,
        'points_lost': 0,
      });
      
      debugPrint('🎉 +$bonusPoints bonus points for completing planned session');
    }
  }

  /// +20 points → Hit your daily goal
  /// If your daily target is 60 mins, reach it = extra points.
  Future<void> checkDailyGoalBonus() async {
    final dailyGoal = await _getDailyGoalMinutes();
    final focusToday = await _getFocusMinutesToday();
    
    if (focusToday >= dailyGoal) {
      const bonusPoints = 20;
      final hasAlreadyEarned = await _hasEarnedDailyGoalToday();
      
      if (!hasAlreadyEarned) {
        await _addPoints(bonusPoints, 'Hit daily goal of $dailyGoal minutes');
        await _markDailyGoalEarned();
        
        // Check for Perfect Day achievement
        await _checkPerfectDayAchievement();
        
        debugPrint('🎯 +$bonusPoints points for hitting daily goal!');
      }
    }
  }

  /// +100 points → Weekly streak bonus
  /// Stay consistent for 7 days → MAJOR reward.
  Future<void> checkStreakBonus() async {
    final streak = await _getCurrentStreak();
    
    // Award streak bonuses at milestones
    if (streak == 7) {
      const bonusPoints = 100;
      await _addPoints(bonusPoints, '7-day streak achieved!');
      await _unlockAchievement('Weekly Streak Master', bonusPoints);
      
      // Check for Consistency First badge
      await checkConsistencyFirstBadge();
      
      debugPrint('🔥 +$bonusPoints points for 7-day streak!');
    } else if (streak == 30) {
      const bonusPoints = 300;
      await _addPoints(bonusPoints, '30-day streak achieved!');
      await _unlockAchievement('Streak Master', bonusPoints);
      debugPrint('🔥 +$bonusPoints points for 30-day streak!');
    } else if (streak == 90) {
      const bonusPoints = 1000;
      await _addPoints(bonusPoints, '90-day streak achieved!');
      await _unlockAchievement('Streak Legend', bonusPoints);
      debugPrint('🔥 +$bonusPoints points for 90-day streak!');
    }
  }

  // ===========================================
  // 💥 LOSE POINTS (Tiny Penalties That Keep You Honest)
  // ===========================================

  /// –10 points → Leaving a session early
  /// Your phone wins… you lose a little.
  Future<void> applyEarlyExitPenalty(int plannedMinutes, int actualMinutes) async {
    if (actualMinutes < plannedMinutes) {
      const penaltyPoints = -10;
      await _addPoints(penaltyPoints, 'Left session ${plannedMinutes - actualMinutes} min early');
      debugPrint('📱 -10 points for early exit');
    }
  }

  /// –25 points → Emergency Stop
  /// When you hit the panic button, you pay in points.
  Future<void> applyEmergencyStopPenalty() async {
    const penaltyPoints = -25;
    await _addPoints(penaltyPoints, 'Used emergency stop');
    debugPrint('🚨 -25 points for emergency stop');
  }

  /// –5 points → Using grace period (app blocking)
  /// Small penalty for using grace period when app is blocked
  Future<void> applyGracePeriodPenalty() async {
    const penaltyPoints = -5;
    await _addPoints(penaltyPoints, 'Used grace period for blocked app');
    debugPrint('⏰ -5 points for grace period');
  }

  /// +2 points → Proper app closure (blocking system)
  /// Reward for closing blocked app properly instead of forcing through
  Future<void> awardProperAppClosure() async {
    const bonusPoints = 2;
    await _addPoints(bonusPoints, 'Closed blocked app properly');
    debugPrint('✅ +2 points for closing app properly');
  }

  // ===========================================
  // 🎁 BONUS ACHIEVEMENTS (Gamified Motivation)
  // ===========================================

  /// 🌅 Morning Starter — First session before 12pm
  Future<void> checkMorningStarterAchievement() async {
    final now = DateTime.now();
    if (now.hour < 12) {
      const bonusPoints = 25;
      await _addPoints(bonusPoints, 'Morning Starter bonus');
      await _unlockAchievement('Morning Starter', bonusPoints);
      debugPrint('🌅 +$bonusPoints points for Morning Starter!');
    }
  }

  /// 🌙 Night Warrior — Last session after 8pm
  Future<void> checkNightWarriorAchievement() async {
    final now = DateTime.now();
    if (now.hour >= 20) {
      const bonusPoints = 25;
      await _addPoints(bonusPoints, 'Night Warrior bonus');
      await _unlockAchievement('Night Warrior', bonusPoints);
      debugPrint('🌙 +$bonusPoints points for Night Warrior!');
    }
  }

  /// 💪 Comeback Bonus — Missed a day? Return = reward
  Future<void> checkComebackBonus() async {
    final lastActivityDate = await _getLastActivityDate();
    final today = DateTime.now();
    
    if (lastActivityDate != null) {
      final daysDifference = today.difference(lastActivityDate).inDays;
      
      if (daysDifference == 2) { // Missed exactly one day
        const bonusPoints = 30;
        await _addPoints(bonusPoints, 'Comeback after missing a day');
        await _unlockAchievement('Comeback Bonus', bonusPoints);
        debugPrint('💪 +$bonusPoints points for comeback!');
      }
      
      // Check for Comeback Kid badge (missed 2 days, back on 3rd)
      await checkComebackKidBadge();
    }
  }

  /// 🔥 Perfect Day — Completed 100% of your goals
  Future<void> _checkPerfectDayAchievement() async {
    // This is called when daily goal is hit
    const bonusPoints = 50;
    await _unlockAchievement('Perfect Day', bonusPoints);
    debugPrint('🔥 +$bonusPoints points for Perfect Day!');
  }

  // ===========================================
  // 📊 PROGRESS TRACKING & MILESTONES
  // ===========================================

  /// Check and award milestone badges (Lightweight Version 1)
  Future<void> checkMilestoneBadges() async {
    final totalPoints = await getTotalPoints();
    final sessionsCompleted = await _getTotalSessionsCompleted();
    
    // First Step: Completed first focus session
    if (sessionsCompleted >= 1 && !await _hasUnlockedBadge('first_step')) {
      await _rewardsProvider.unlockBadge('first_step');
      debugPrint('🏆 FIRST STEP badge unlocked!');
    }
    
    // Focus Beast: 1000 total points
    if (totalPoints >= 1000 && !await _hasUnlockedBadge('focus_beast')) {
      await _rewardsProvider.unlockBadge('focus_beast');
      debugPrint('🏆 FOCUS BEAST badge unlocked!');
    }
  }
  
  /// Check for Consistency First badge (7-day streak)
  Future<void> checkConsistencyFirstBadge() async {
    final streak = await _getCurrentStreak();
    if (streak >= 7 && !await _hasUnlockedBadge('consistency_first')) {
      await _rewardsProvider.unlockBadge('consistency_first');
      debugPrint('🏆 CONSISTENCY FIRST badge unlocked!');
    }
  }
  
  /// Check for Marathon Mode badge (2 hours in one session)
  Future<void> checkMarathonModeBadge(int sessionMinutes) async {
    if (sessionMinutes >= 120 && !await _hasUnlockedBadge('marathon_mode')) {
      await _rewardsProvider.unlockBadge('marathon_mode');
      debugPrint('🏆 MARATHON MODE badge unlocked!');
    }
  }
  
  /// Check for Comeback Kid badge (returned after missing 2 days)
  Future<void> checkComebackKidBadge() async {
    final lastActivityDate = await _getLastActivityDate();
    final today = DateTime.now();
    
    if (lastActivityDate != null) {
      final daysDifference = today.difference(lastActivityDate).inDays;
      
      // Exactly 3 days (missed 2 days, back on 3rd)
      if (daysDifference == 3 && !await _hasUnlockedBadge('comeback_kid')) {
        await _rewardsProvider.unlockBadge('comeback_kid');
        debugPrint('🏆 COMEBACK KID badge unlocked!');
      }
    }
  }
  
  /// Helper to determine transaction type from reason
  String _getTransactionType(String reason) {
    if (reason.contains('minute')) return 'focus_minute';
    if (reason.contains('session')) return 'session_complete';
    if (reason.contains('daily goal')) return 'daily_goal';
    if (reason.contains('streak')) return 'streak_bonus';
    if (reason.contains('early')) return 'early_exit_penalty';
    if (reason.contains('emergency')) return 'emergency_stop_penalty';
    if (reason.contains('grace')) return 'grace_period_penalty';
    if (reason.contains('Morning')) return 'morning_starter';
    if (reason.contains('Night')) return 'night_warrior';
    if (reason.contains('Comeback')) return 'comeback_bonus';
    return 'other';
  }

  // ===========================================
  // 🔄 STREAK MANAGEMENT
  // ===========================================

  /// Update user's streak based on daily activity
  Future<void> updateStreakStatus() async {
    final lastActivityDate = await _getLastActivityDate();
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    
    if (lastActivityDate == null) {
      // First time user
      await _setCurrentStreak(1);
      await _setLastActivityDate(todayDateOnly);
      return;
    }
    
    final lastDateOnly = DateTime(lastActivityDate.year, lastActivityDate.month, lastActivityDate.day);
    final daysDifference = todayDateOnly.difference(lastDateOnly).inDays;
    
    if (daysDifference == 1) {
      // Consecutive day - increment streak
      final currentStreak = await _getCurrentStreak();
      final newStreak = currentStreak + 1;
      await _setCurrentStreak(newStreak);
      
      // Update best streak if needed
      final bestStreak = await _getBestStreak();
      if (newStreak > bestStreak) {
        await _setBestStreak(newStreak);
      }
      
      // Check for streak milestones
      await checkStreakBonus();
      
    } else if (daysDifference > 1) {
      // Streak broken
      await _setCurrentStreak(1);
      debugPrint('💔 Streak broken - starting fresh');
    }
    // If daysDifference == 0, it's the same day, no change needed
    
    await _setLastActivityDate(todayDateOnly);
  }

  // ===========================================
  // 📈 LEVEL SYSTEM
  // ===========================================

  /// Calculate user level based on total points
  int calculateLevel(int totalPoints) {
    if (totalPoints < 100) return 1;
    if (totalPoints < 300) return 2;
    if (totalPoints < 600) return 3;
    if (totalPoints < 1000) return 4;
    if (totalPoints < 1500) return 5;
    if (totalPoints < 2100) return 6;
    if (totalPoints < 2800) return 7;
    if (totalPoints < 3600) return 8;
    if (totalPoints < 4500) return 9;
    if (totalPoints < 5500) return 10;
    
    // For levels beyond 10, use a more gradual progression
    return 10 + ((totalPoints - 5500) ~/ 1000);
  }

  /// Get points needed for next level
  int getPointsForNextLevel(int currentLevel) {
    switch (currentLevel) {
      case 1: return 100;
      case 2: return 300;
      case 3: return 600;
      case 4: return 1000;
      case 5: return 1500;
      case 6: return 2100;
      case 7: return 2800;
      case 8: return 3600;
      case 9: return 4500;
      case 10: return 5500;
      default: return 5500 + ((currentLevel - 10) * 1000);
    }
  }

  // ===========================================
  // 🔧 HELPER METHODS
  // ===========================================

  Future<void> _addPoints(int points, String reason) async {
    final currentPoints = await getTotalPoints();
    final newTotal = (currentPoints + points).clamp(0, double.infinity).toInt();
    
    await _db.setTotalPoints(newTotal);
    
    // Update level
    final newLevel = calculateLevel(newTotal);
    final currentLevel = await getCurrentLevel();
    
    // Check for level up
    if (newLevel > currentLevel) {
      debugPrint('🎉 LEVEL UP! Reached level $newLevel');
      // Award level up bonus
      await _rewardsProvider.addXP(newLevel * 10, reason: 'Level $newLevel achieved');
    }
    
    // Update daily points if positive
    if (points > 0) {
      await _updateDailyPoints(points);
    }
    
    // Award XP to rewards provider
    if (points > 0) {
      await _rewardsProvider.addXP(points, reason: reason);
    }
    
    // Save transaction to cloud for analytics
    await _db.savePointsTransactionToCloud({
      'points': points,
      'type': _getTransactionType(reason),
      'description': reason,
    });
  }

  Future<void> _updateDailyPoints(int points) async {
    final today = DateTime.now();
    final lastActivity = await _getLastActivityDate();
    
    // Reset daily points if new day
    if (lastActivity == null || !_isSameDay(today, lastActivity)) {
      await _db.setDailyPoints(points);
    } else {
      final currentDaily = await _db.getDailyPoints();
      await _db.setDailyPoints(currentDaily + points);
    }
  }

  Future<void> _updateDailyFocusMinutes(int minutes) async {
    final today = DateTime.now();
    final lastActivity = await _getLastActivityDate();
    
    // Reset daily minutes if new day
    if (lastActivity == null || !_isSameDay(today, lastActivity)) {
      await LocalStorageService.cacheData('focus_minutes_today', minutes);
    } else {
      final currentMinutes = await _getFocusMinutesToday();
      await LocalStorageService.cacheData('focus_minutes_today', currentMinutes + minutes);
    }
  }

  Future<void> _incrementSessionsCompleted() async {
    final currentSessions = await _getTotalSessionsCompleted();
    await LocalStorageService.cacheData('total_sessions_completed', currentSessions + 1);
  }

  Future<void> _unlockAchievement(String achievementName, int points) async {
    // This could be expanded to store achievements in a database
    debugPrint('🏆 Achievement unlocked: $achievementName (+$points points)');
    
    // Award to rewards provider
    await _rewardsProvider.addXP(points, reason: 'Achievement: $achievementName');
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Getters for public access
  Future<int> getTotalPoints() async {
    return await _db.getTotalPoints();
  }

  Future<int> getCurrentLevel() async {
    final totalPoints = await getTotalPoints();
    return calculateLevel(totalPoints);
  }

  Future<int> getDailyPoints() async {
    return await _db.getDailyPoints();
  }

  Future<int> _getCurrentStreak() async {
    return await _db.getStreakCount();
  }

  Future<int> _getBestStreak() async {
    // Best streak stored locally for now - can be moved to cloud later
    return LocalStorageService.getCachedData<int>('best_streak') ?? 0;
  }

  Future<DateTime?> _getLastActivityDate() async {
    return await _db.getLastSessionDate();
  }

  Future<int> _getDailyGoalMinutes() async {
    return await _db.getDailyGoalMinutes();
  }

  Future<int> _getFocusMinutesToday() async {
    // Focus minutes for today - local storage
    return LocalStorageService.getCachedData<int>('focus_minutes_today') ?? 0;
  }

  Future<int> _getTotalSessionsCompleted() async {
    // Sessions completed - local storage
    return LocalStorageService.getCachedData<int>('total_sessions_completed') ?? 0;
  }

  // Setters for internal use
  Future<void> _setCurrentStreak(int streak) async {
    await _db.setStreakCount(streak);
  }

  Future<void> _setBestStreak(int streak) async {
    await LocalStorageService.cacheData('best_streak', streak);
  }

  Future<void> _setLastActivityDate(DateTime date) async {
    await _db.setLastSessionDate(date);
  }

  Future<bool> _hasEarnedDailyGoalToday() async {
    final lastEarned = LocalStorageService.getCachedData<String>('daily_goal_earned_date');
    final today = DateTime.now().toIso8601String().split('T')[0];
    return lastEarned == today;
  }

  Future<void> _markDailyGoalEarned() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await LocalStorageService.cacheData('daily_goal_earned_date', today);
  }

  Future<bool> _hasUnlockedBadge(String badgeId) async {
    // This would check with the rewards provider
    final badge = _rewardsProvider.getBadge(badgeId);
    return badge?.isUnlocked ?? false;
  }

  /// Set daily goal (called from settings)
  Future<void> setDailyGoal(int minutes) async {
    await _db.setDailyGoalMinutes(minutes);
  }

  /// Reset daily stats (for testing or new day)
  Future<void> resetDailyStats() async {
    await _db.setDailyPoints(0);
    await LocalStorageService.cacheData('focus_minutes_today', 0);
    await LocalStorageService.cacheData('total_sessions_completed', 0);
    await LocalStorageService.cacheData('daily_goal_earned_date', null);
  }
}