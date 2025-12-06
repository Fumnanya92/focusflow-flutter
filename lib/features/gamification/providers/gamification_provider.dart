import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/points_service.dart';
import '../../rewards/providers/rewards_provider.dart';

/// 🎮 Provider for managing the comprehensive points system
class GamificationProvider extends ChangeNotifier {
  late final PointsService _pointsService;
  
  // Current state
  int _totalPoints = 0;
  int _currentLevel = 1;
  int _dailyPoints = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _dailyGoalMinutes = 60;
  int _focusMinutesToday = 0;
  int _sessionsCompletedToday = 0;
  DateTime? _lastActivityDate;
  
  // Session tracking
  DateTime? _currentSessionStart;
  int _currentSessionPlannedMinutes = 0;
  bool _hasEarnedMorningBonus = false;
  bool _hasEarnedNightBonus = false;
  
  // Getters
  int get totalPoints => _totalPoints;
  int get currentLevel => _currentLevel;
  int get dailyPoints => _dailyPoints;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  int get dailyGoalMinutes => _dailyGoalMinutes;
  int get focusMinutesToday => _focusMinutesToday;
  int get sessionsCompletedToday => _sessionsCompletedToday;
  DateTime? get lastActivityDate => _lastActivityDate;
  
  // Progress calculations
  double get dailyGoalProgress => _dailyGoalMinutes > 0 ? (_focusMinutesToday / _dailyGoalMinutes).clamp(0.0, 1.0) : 0.0;
  bool get isDailyGoalReached => _focusMinutesToday >= _dailyGoalMinutes;
  
  int get pointsForNextLevel => _pointsService.getPointsForNextLevel(_currentLevel);
  int get pointsForCurrentLevel => _currentLevel > 1 ? _pointsService.getPointsForNextLevel(_currentLevel - 1) : 0;
  double get levelProgress {
    final currentLevelPoints = pointsForCurrentLevel;
    final nextLevelPoints = pointsForNextLevel;
    final progress = (_totalPoints - currentLevelPoints) / (nextLevelPoints - currentLevelPoints);
    return progress.clamp(0.0, 1.0);
  }
  
  GamificationProvider(RewardsProvider rewardsProvider) {
    _pointsService = PointsService(rewardsProvider);
    _loadState();
    _resetDailyBonuses();
  }

  // ===========================================
  // 📊 SESSION TRACKING
  // ===========================================

  /// Start a focus session
  Future<void> startFocusSession(int plannedMinutes) async {
    _currentSessionStart = DateTime.now();
    _currentSessionPlannedMinutes = plannedMinutes;
    
    // Check for morning starter achievement
    if (!_hasEarnedMorningBonus) {
      await _pointsService.checkMorningStarterAchievement();
      _hasEarnedMorningBonus = true;
      await _saveDailyBonuses();
    }
    
    // Check comeback bonus
    await _pointsService.checkComebackBonus();
    
    // Update streak status
    await _pointsService.updateStreakStatus();
    
    await _loadState();
    notifyListeners();
  }

  /// Award points for each minute of focus
  Future<void> awardFocusMinute() async {
    await _pointsService.awardFocusMinutePoints(1);
    await _loadState();
    notifyListeners();
  }

  /// Complete a focus session successfully
  Future<void> completeSession(int actualMinutes) async {
    if (_currentSessionStart == null) return;
    
    debugPrint('✅ SESSION COMPLETE: $actualMinutes minutes');
    
    // Award session completion bonus
    await _pointsService.awardSessionCompletionBonus(_currentSessionPlannedMinutes, actualMinutes);
    
    // This counts as daily activity - streak is maintained!
    await _markDailyActivityComplete();
    
    // Check daily goal bonus
    await _pointsService.checkDailyGoalBonus();
    
    // Check for night warrior achievement
    if (!_hasEarnedNightBonus) {
      await _pointsService.checkNightWarriorAchievement();
      _hasEarnedNightBonus = true;
      await _saveDailyBonuses();
    }
    
    // Check milestone badges
    await _pointsService.checkMilestoneBadges();
    
    _currentSessionStart = null;
    _currentSessionPlannedMinutes = 0;
    
    await _loadState();
    notifyListeners();
  }

  /// Handle early exit from session
  Future<void> exitSessionEarly(int actualMinutes) async {
    if (_currentSessionStart == null) return;
    
    debugPrint('🚨 EARLY EXIT: $actualMinutes/$_currentSessionPlannedMinutes minutes');
    await _pointsService.applyEarlyExitPenalty(_currentSessionPlannedMinutes, actualMinutes);
    
    // DON'T count this as completing daily activity - streak might be at risk
    
    _currentSessionStart = null;
    _currentSessionPlannedMinutes = 0;
    
    await _loadState();
    notifyListeners();
  }

  /// Handle emergency stop
  Future<void> emergencyStop() async {
    await _pointsService.applyEmergencyStopPenalty();
    
    _currentSessionStart = null;
    _currentSessionPlannedMinutes = 0;
    
    await _loadState();
    notifyListeners();
  }

  // ===========================================
  // ⚙️ SETTINGS & CONFIGURATION
  // ===========================================

  /// Set daily focus goal
  Future<void> setDailyGoal(int minutes) async {
    _dailyGoalMinutes = minutes;
    await _pointsService.setDailyGoal(minutes);
    notifyListeners();
  }

  /// Get formatted level display
  String get levelDisplay => 'Level $_currentLevel';
  
  /// Get formatted points display
  String get pointsDisplay {
    if (_totalPoints >= 1000000) {
      return '${(_totalPoints / 1000000).toStringAsFixed(1)}M';
    } else if (_totalPoints >= 1000) {
      return '${(_totalPoints / 1000).toStringAsFixed(1)}K';
    } else {
      return _totalPoints.toString();
    }
  }

  /// Get streak display
  String get streakDisplay {
    if (_currentStreak == 0) return 'Start your streak!';
    if (_currentStreak == 1) return '1 day streak';
    return '$_currentStreak day streak';
  }
  
  /// Check if today's activity is complete (for streak)
  bool get isDailyActivityComplete {
    final prefs = SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    return prefs.then((p) => p.getString('daily_activity_date') == today).toString() == 'true';
  }
  
  /// Mark daily activity as complete (maintains streak)
  Future<void> _markDailyActivityComplete() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('daily_activity_date', today);
    
    // Update streak
    await _updateStreakProgress();
  }
  
  /// Update streak progress based on daily activity
  Future<void> _updateStreakProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    final lastStreakDate = prefs.getString('last_streak_date');
    
    if (lastStreakDate == null) {
      // First ever session
      _currentStreak = 1;
      await prefs.setString('last_streak_date', todayStr);
      debugPrint('🔥 STREAK STARTED: Day 1');
    } else if (lastStreakDate == todayStr) {
      // Already completed today - no change
      return;
    } else {
      final lastDate = DateTime.parse('${lastStreakDate}T00:00:00');
      final daysDiff = today.difference(lastDate).inDays;
      
      if (daysDiff == 1) {
        // Consecutive day - increment streak
        _currentStreak++;
        await prefs.setString('last_streak_date', todayStr);
        
        // Update best streak
        if (_currentStreak > _bestStreak) {
          _bestStreak = _currentStreak;
          await prefs.setInt('best_streak', _bestStreak);
        }
        
        // Check for streak milestones
        await _checkStreakMilestones();
        
        debugPrint('🔥 STREAK EXTENDED: Day $_currentStreak');
      } else {
        // Streak broken - reset to 1
        final oldStreak = _currentStreak;
        _currentStreak = 1;
        await prefs.setString('last_streak_date', todayStr);
        
        debugPrint('💔 STREAK BROKEN: Was $oldStreak days, now starting fresh');
      }
    }
    
    await prefs.setInt('current_streak', _currentStreak);
  }
  
  /// Check for streak milestone achievements
  Future<void> _checkStreakMilestones() async {
    if (_currentStreak == 7) {
      await _pointsService.checkStreakBonus(); // Bronze Badge
      debugPrint('🥉 BRONZE STREAK ACHIEVED: 7 days!');
    } else if (_currentStreak == 30) {
      await _pointsService.checkStreakBonus(); // Silver Badge
      debugPrint('🥈 SILVER STREAK ACHIEVED: 30 days!');
    } else if (_currentStreak == 90) {
      await _pointsService.checkStreakBonus(); // Gold Badge
      debugPrint('🥇 GOLD STREAK ACHIEVED: 90 days!');
    }
  }

  /// Get daily goal display
  String get dailyGoalDisplay {
    final hours = _dailyGoalMinutes ~/ 60;
    final minutes = _dailyGoalMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Get daily progress display
  String get dailyProgressDisplay {
    final hours = _focusMinutesToday ~/ 60;
    final minutes = _focusMinutesToday % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m / $dailyGoalDisplay';
    } else if (hours > 0) {
      return '${hours}h / $dailyGoalDisplay';
    } else {
      return '${minutes}m / $dailyGoalDisplay';
    }
  }

  // ===========================================
  // 🔄 STATE MANAGEMENT
  // ===========================================

  Future<void> _loadState() async {
    try {
      _totalPoints = await _pointsService.getTotalPoints();
      _currentLevel = await _pointsService.getCurrentLevel();
      _dailyPoints = await _pointsService.getDailyPoints();
      
      final prefs = await SharedPreferences.getInstance();
      _currentStreak = prefs.getInt('current_streak') ?? 0;
      _bestStreak = prefs.getInt('best_streak') ?? 0;
      _dailyGoalMinutes = prefs.getInt('daily_goal_minutes') ?? 60;
      _focusMinutesToday = prefs.getInt('focus_minutes_today') ?? 0;
      _sessionsCompletedToday = prefs.getInt('sessions_completed_today') ?? 0;
      
      final lastActivityStr = prefs.getString('last_activity_date');
      _lastActivityDate = lastActivityStr != null ? DateTime.parse(lastActivityStr) : null;
      
      // Check if streak should be broken (missed yesterday)
      await _checkForStreakBreak();
      
      await _loadDailyBonuses();
    } catch (e) {
      debugPrint('Error loading gamification state: $e');
    }
  }
  
  /// Check if streak should be broken due to missed days
  Future<void> _checkForStreakBreak() async {
    if (_currentStreak == 0) return;
    
    final prefs = await SharedPreferences.getInstance();
    final lastStreakDate = prefs.getString('last_streak_date');
    
    if (lastStreakDate != null) {
      final lastDate = DateTime.parse('${lastStreakDate}T00:00:00');
      final today = DateTime.now();
      final daysDiff = today.difference(lastDate).inDays;
      
      if (daysDiff > 1) {
        // Streak is broken - user missed days
        final oldStreak = _currentStreak;
        _currentStreak = 0;
        await prefs.setInt('current_streak', 0);
        await prefs.remove('last_streak_date');
        debugPrint('💔 STREAK AUTO-BROKEN: Was $oldStreak days, missed ${daysDiff - 1} days');
      }
    }
  }

  Future<void> _resetDailyBonuses() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastBonusDate = prefs.getString('last_bonus_date');
    
    if (lastBonusDate != today) {
      _hasEarnedMorningBonus = false;
      _hasEarnedNightBonus = false;
      await _saveDailyBonuses();
    }
  }

  Future<void> _loadDailyBonuses() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastBonusDate = prefs.getString('last_bonus_date');
    
    if (lastBonusDate == today) {
      _hasEarnedMorningBonus = prefs.getBool('earned_morning_bonus') ?? false;
      _hasEarnedNightBonus = prefs.getBool('earned_night_bonus') ?? false;
    } else {
      _hasEarnedMorningBonus = false;
      _hasEarnedNightBonus = false;
    }
  }

  Future<void> _saveDailyBonuses() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    await prefs.setString('last_bonus_date', today);
    await prefs.setBool('earned_morning_bonus', _hasEarnedMorningBonus);
    await prefs.setBool('earned_night_bonus', _hasEarnedNightBonus);
  }

  // ===========================================
  // 🎮 TESTING & DEBUG
  // ===========================================

  /// Reset all gamification data (for testing)
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all points data
    await prefs.remove('total_points');
    await prefs.remove('current_level');
    await prefs.remove('daily_points');
    await prefs.remove('current_streak');
    await prefs.remove('best_streak');
    await prefs.remove('focus_minutes_today');
    await prefs.remove('sessions_completed_today');
    await prefs.remove('last_activity_date');
    await prefs.remove('daily_goal_earned_date');
    await prefs.remove('last_bonus_date');
    await prefs.remove('earned_morning_bonus');
    await prefs.remove('earned_night_bonus');
    
    // Reset daily stats through service
    await _pointsService.resetDailyStats();
    
    // Reset state
    _totalPoints = 0;
    _currentLevel = 1;
    _dailyPoints = 0;
    _currentStreak = 0;
    _bestStreak = 0;
    _focusMinutesToday = 0;
    _sessionsCompletedToday = 0;
    _lastActivityDate = null;
    _hasEarnedMorningBonus = false;
    _hasEarnedNightBonus = false;
    
    notifyListeners();
    debugPrint('🔄 All gamification data reset');
  }

  /// Add test points (for demonstration)
  Future<void> addTestPoints(int points) async {
    await _pointsService.awardFocusMinutePoints(points);
    await _loadState();
    notifyListeners();
  }

  /// Apply grace period penalty (blocking system integration)
  Future<void> applyGracePeriodPenalty() async {
    await _pointsService.applyGracePeriodPenalty();
    await _loadState();
    notifyListeners();
  }

  /// Apply app blocking emergency unlock penalty
  Future<void> applyEmergencyUnlockPenalty() async {
    await _pointsService.applyEmergencyStopPenalty();
    await _loadState();
    notifyListeners();
  }

  /// Award points for proper app closure
  Future<void> awardProperAppClosure() async {
    await _pointsService.awardProperAppClosure();
    await _loadState();
    notifyListeners();
  }
}