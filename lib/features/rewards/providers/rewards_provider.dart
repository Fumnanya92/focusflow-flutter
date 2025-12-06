import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/badge_model.dart';
import '../../../core/services/local_storage_service.dart';

class RewardsProvider extends ChangeNotifier {
  int _totalXP = 0;
  int _level = 1;
  List<Badge> _badges = [];
  List<String> _recentlyUnlockedBadges = [];

  
  // XP needed for each level (exponential growth)
  static const List<int> levelThresholds = [
    0,      // Level 1
    100,    // Level 2
    250,    // Level 3
    450,    // Level 4
    700,    // Level 5
    1000,   // Level 6
    1350,   // Level 7
    1750,   // Level 8
    2200,   // Level 9
    2700,   // Level 10
    3250,   // Level 11
    3850,   // Level 12
    4500,   // Level 13
    5200,   // Level 14
    5950,   // Level 15
    6750,   // Level 16
    7600,   // Level 17
    8500,   // Level 18
    9450,   // Level 19
    10450,  // Level 20
    12000,  // Level 21
    14000,  // Level 22
    16500,  // Level 23
    19500,  // Level 24
    23000,  // Level 25
    27000,  // Level 26
    32000,  // Level 27
    38000,  // Level 28
    45000,  // Level 29
    53000,  // Level 30
    65000,  // Level 31+
  ];

  int get totalXP => _totalXP;
  int get level => _level;
  List<Badge> get badges => _badges;
  List<Badge> get unlockedBadges => _badges.where((b) => b.isUnlocked).toList();
  List<Badge> get lockedBadges => _badges.where((b) => !b.isUnlocked).toList();
  List<String> get recentlyUnlockedBadges => _recentlyUnlockedBadges;

  // XP needed for current level
  int get xpForCurrentLevel {
    if (_level >= levelThresholds.length) {
      return levelThresholds.last + ((_level - levelThresholds.length) * 15000);
    }
    return levelThresholds[_level - 1];
  }

  // XP needed for next level
  int get xpForNextLevel {
    if (_level >= levelThresholds.length) {
      return levelThresholds.last + ((_level - levelThresholds.length + 1) * 15000);
    }
    return levelThresholds[_level];
  }

  // Current progress to next level (0.0 to 1.0)
  double get levelProgress {
    final currentLevelXP = xpForCurrentLevel;
    final nextLevelXP = xpForNextLevel;
    final progressXP = _totalXP - currentLevelXP;
    final levelRange = nextLevelXP - currentLevelXP;
    return (progressXP / levelRange).clamp(0.0, 1.0);
  }

  // XP remaining to next level
  int get xpToNextLevel => (xpForNextLevel - _totalXP).clamp(0, double.infinity).toInt();

  RewardsProvider() {
    _initializeBadges();
    _loadRewards();
  }

  // Initialize default badges
  void _initializeBadges() {
    _badges = Badge.getDefaultBadges();
  }

  // Add XP and check for level ups and badge unlocks
  Future<void> addXP(int xp, {String? reason}) async {
    if (xp <= 0) return;

    final oldLevel = _level;
    _totalXP += xp;
    
    // Update level
    _updateLevel();
    
    // Check for badge unlocks
    await _checkBadgeUnlocks();
    
    // Save to storage
    await _saveRewards();
    
    // Notify UI
    notifyListeners();
    
    // Log XP gain
    debugPrint('XP gained: +$xp${reason != null ? ' for $reason' : ''}. Total: $_totalXP (Level $_level)');
    
    // Check if leveled up
    if (_level > oldLevel) {
      debugPrint('🎉 Level up! Reached level $_level');
    }
  }

  // Update level based on current XP
  void _updateLevel() {
    int newLevel = 1;
    
    for (int i = 0; i < levelThresholds.length; i++) {
      if (_totalXP >= levelThresholds[i]) {
        newLevel = i + 1;
      } else {
        break;
      }
    }
    
    // Handle levels beyond the threshold array
    if (_totalXP >= levelThresholds.last) {
      final extraLevels = ((_totalXP - levelThresholds.last) / 15000).floor();
      newLevel = levelThresholds.length + extraLevels;
    }
    
    _level = newLevel;
  }

  // Check and unlock badges based on progress
  Future<void> _checkBadgeUnlocks() async {
    final newlyUnlocked = <String>[];
    
    for (int i = 0; i < _badges.length; i++) {
      final badge = _badges[i];
      
      if (!badge.isUnlocked) {
        bool shouldUnlock = false;
        
        switch (badge.id) {
          case 'focus_rookie':
            // This would be triggered from FocusTimerProvider
            break;
          case 'focus_master':
            // This would be triggered from FocusTimerProvider
            break;
          case 'thousand_pointer':
            shouldUnlock = _totalXP >= 1000;
            break;
          case 'xp_legend':
            shouldUnlock = _totalXP >= 50000;
            break;
          // Add more badge unlock conditions here
        }
        
        if (shouldUnlock) {
          _badges[i] = badge.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );
          newlyUnlocked.add(badge.id);
          
          // Award XP for unlocking badge (but don't recurse)
          _totalXP += badge.xpReward;
          
          debugPrint('🏆 Badge unlocked: ${badge.title} (+${badge.xpReward} XP)');
        }
      }
    }
    
    // Add to recently unlocked list
    _recentlyUnlockedBadges.addAll(newlyUnlocked);
    
    // Keep only last 5 recently unlocked badges
    if (_recentlyUnlockedBadges.length > 5) {
      _recentlyUnlockedBadges = _recentlyUnlockedBadges.take(5).toList();
    }
  }

  // Update badge progress manually (called from other providers)
  Future<void> updateBadgeProgress(String badgeId, int newProgress) async {
    final index = _badges.indexWhere((b) => b.id == badgeId);
    if (index == -1) return;
    
    final badge = _badges[index];
    if (badge.isUnlocked) return;
    
    _badges[index] = badge.copyWith(progress: newProgress);
    
    // Check if badge should be unlocked
    if (badge.target != null && newProgress >= badge.target!) {
      _badges[index] = _badges[index].copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      
      _recentlyUnlockedBadges.add(badge.id);
      await addXP(badge.xpReward, reason: 'badge: ${badge.title}');
      
      debugPrint('🏆 Badge unlocked: ${badge.title}');
    }
    
    await _saveRewards();
    notifyListeners();
  }

  // Unlock specific badge
  Future<void> unlockBadge(String badgeId) async {
    final index = _badges.indexWhere((b) => b.id == badgeId);
    if (index == -1) return;
    
    final badge = _badges[index];
    if (badge.isUnlocked) return;
    
    _badges[index] = badge.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
    
    _recentlyUnlockedBadges.add(badge.id);
    await addXP(badge.xpReward, reason: 'badge: ${badge.title}');
    
    await _saveRewards();
    notifyListeners();
  }

  // Clear recently unlocked badges
  void clearRecentlyUnlocked() {
    _recentlyUnlockedBadges.clear();
    notifyListeners();
  }

  // Get badge by ID
  Badge? getBadge(String badgeId) {
    try {
      return _badges.firstWhere((b) => b.id == badgeId);
    } catch (e) {
      return null;
    }
  }

  // Get badges by type
  List<Badge> getBadgesByType(BadgeType type) {
    return _badges.where((b) => b.type == type).toList();
  }

  // Get badges by rarity
  List<Badge> getBadgesByRarity(BadgeRarity rarity) {
    return _badges.where((b) => b.rarity == rarity).toList();
  }

  // Reset all rewards (for testing)
  Future<void> resetRewards() async {
    _totalXP = 0;
    _level = 1;
    _recentlyUnlockedBadges.clear();
    _initializeBadges(); // Reset badges to default state
    
    await _saveRewards();
    notifyListeners();
  }

  // Load rewards from storage
  Future<void> _loadRewards() async {
    try {
      _totalXP = LocalStorageService.getCachedData<int>('totalXP') ?? 0;
      _level = LocalStorageService.getCachedData<int>('level') ?? 1;
      
      final badgesJson = LocalStorageService.getCachedData<String>('badges');
      if (badgesJson != null) {
        final List<dynamic> decoded = jsonDecode(badgesJson);
        _badges = decoded.map((json) => Badge.fromJson(json)).toList();
      }
      
      final recentJson = LocalStorageService.getCachedData<String>('recentlyUnlockedBadges');
      if (recentJson != null) {
        _recentlyUnlockedBadges = List<String>.from(jsonDecode(recentJson));
      }
      
      // Ensure level is correct based on XP
      _updateLevel();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading rewards: $e');
    }
  }

  // Save rewards to storage
  Future<void> _saveRewards() async {
    try {
      await LocalStorageService.cacheData('totalXP', _totalXP);
      await LocalStorageService.cacheData('level', _level);
      
      final badgesJson = jsonEncode(_badges.map((b) => b.toJson()).toList());
      await LocalStorageService.cacheData('badges', badgesJson);
      
      final recentJson = jsonEncode(_recentlyUnlockedBadges);
      await LocalStorageService.cacheData('recentlyUnlockedBadges', recentJson);
    } catch (e) {
      debugPrint('Error saving rewards: $e');
    }
  }
}
