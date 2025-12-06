import 'package:flutter/material.dart';

enum BadgeType {
  focus('Focus Master', Icons.timer, '🎯'),
  streak('Streak Keeper', Icons.local_fire_department, '🔥'),
  challenge('Challenge Winner', Icons.emoji_events, '🏆'),
  blocking('Distraction Blocker', Icons.block, '🛡️'),
  task('Task Completer', Icons.check_circle, '✅'),
  social('Social Challenger', Icons.group, '👥'),
  milestone('Milestone Achiever', Icons.star, '⭐'),
  dedication('Dedication Award', Icons.military_tech, '🎖️');

  const BadgeType(this.title, this.icon, this.emoji);
  final String title;
  final IconData icon;
  final String emoji;
}

enum BadgeRarity {
  bronze(0xFF8B5A2B, 'Bronze'),
  silver(0xFFC0C0C0, 'Silver'),
  gold(0xFFFFD700, 'Gold'),
  platinum(0xFF00CED1, 'Platinum'),
  diamond(0xFFB9F2FF, 'Diamond');

  const BadgeRarity(this.colorValue, this.name);
  final int colorValue;
  final String name;

  Color get color => Color(colorValue);
}

class Badge {
  final String id;
  final BadgeType type;
  final BadgeRarity rarity;
  final String title;
  final String description;
  final int xpReward;
  final DateTime? unlockedAt;
  final bool isUnlocked;
  final int? progress;
  final int? target;

  Badge({
    required this.id,
    required this.type,
    required this.rarity,
    required this.title,
    required this.description,
    required this.xpReward,
    this.unlockedAt,
    this.isUnlocked = false,
    this.progress,
    this.target,
  });

  Badge copyWith({
    String? id,
    BadgeType? type,
    BadgeRarity? rarity,
    String? title,
    String? description,
    int? xpReward,
    DateTime? unlockedAt,
    bool? isUnlocked,
    int? progress,
    int? target,
  }) {
    return Badge(
      id: id ?? this.id,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      target: target ?? this.target,
    );
  }

  double get progressPercentage {
    if (target == null || progress == null) return 0.0;
    return (progress! / target!).clamp(0.0, 1.0);
  }

  bool get isProgressBased => target != null && progress != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'rarity': rarity.name,
      'title': title,
      'description': description,
      'xpReward': xpReward,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isUnlocked': isUnlocked,
      'progress': progress,
      'target': target,
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      type: BadgeType.values.firstWhere((e) => e.name == json['type']),
      rarity: BadgeRarity.values.firstWhere((e) => e.name == json['rarity']),
      title: json['title'],
      description: json['description'],
      xpReward: json['xpReward'],
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'])
          : null,
      isUnlocked: json['isUnlocked'] ?? false,
      progress: json['progress'],
      target: json['target'],
    );
  }

  static List<Badge> getDefaultBadges() {
    return [
      // 🚀 LIGHTWEIGHT VERSION 1 - Easy badges for milestone dopamine
      
      // First Step: Completed first focus session
      Badge(
        id: 'first_step',
        type: BadgeType.focus,
        rarity: BadgeRarity.bronze,
        title: 'First Step',
        description: 'Completed first focus session',
        xpReward: 50,
        target: 1,
        progress: 0,
      ),
      
      // Consistency First: 7-day streak
      Badge(
        id: 'consistency_first',
        type: BadgeType.streak,
        rarity: BadgeRarity.silver,
        title: 'Consistency First',
        description: '7-day focus streak achieved',
        xpReward: 100,
        target: 7,
        progress: 0,
      ),
      
      // Comeback Kid: Returned after missing 2 days
      Badge(
        id: 'comeback_kid',
        type: BadgeType.dedication,
        rarity: BadgeRarity.gold,
        title: 'Comeback Kid',
        description: 'Returned after missing 2 days',
        xpReward: 75,
      ),
      
      // Marathon Mode: 2 hours in one session
      Badge(
        id: 'marathon_mode',
        type: BadgeType.focus,
        rarity: BadgeRarity.gold,
        title: 'Marathon Mode',
        description: '2 hours in one focus session',
        xpReward: 200,
        target: 120, // 120 minutes = 2 hours
        progress: 0,
      ),
      
      // Focus Beast: 1000 total points
      Badge(
        id: 'focus_beast',
        type: BadgeType.milestone,
        rarity: BadgeRarity.platinum,
        title: 'Focus Beast',
        description: '1000 total points earned',
        xpReward: 150,
        target: 1000,
        progress: 0,
      ),
    ];
  }
}
