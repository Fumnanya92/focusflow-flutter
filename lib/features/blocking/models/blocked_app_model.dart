import 'package:flutter/material.dart';

class BlockedApp {
  final String packageName;
  final String appName;
  final String? iconPath;
  final bool isBlocked;
  final int dailyLimit; // in minutes, 0 means completely blocked
  final int usedMinutesToday;
  final List<TimeWindow>? blockedTimeWindows;

  BlockedApp({
    required this.packageName,
    required this.appName,
    this.iconPath,
    this.isBlocked = false,
    this.dailyLimit = 0,
    this.usedMinutesToday = 0,
    this.blockedTimeWindows,
  });

  bool get isLimitReached => dailyLimit > 0 && usedMinutesToday >= dailyLimit;
  bool get isCurrentlyBlocked {
    if (!isBlocked) return false;
    if (dailyLimit == 0) return true; // Completely blocked
    if (isLimitReached) return true;
    
    // Check if current time is within any blocked window
    if (blockedTimeWindows != null) {
      final now = DateTime.now();
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
      return blockedTimeWindows!.any((window) => window.contains(currentTime));
    }
    
    return false;
  }

  BlockedApp copyWith({
    String? packageName,
    String? appName,
    String? iconPath,
    bool? isBlocked,
    int? dailyLimit,
    int? usedMinutesToday,
    List<TimeWindow>? blockedTimeWindows,
  }) {
    return BlockedApp(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      iconPath: iconPath ?? this.iconPath,
      isBlocked: isBlocked ?? this.isBlocked,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      usedMinutesToday: usedMinutesToday ?? this.usedMinutesToday,
      blockedTimeWindows: blockedTimeWindows ?? this.blockedTimeWindows,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'iconPath': iconPath,
      'isBlocked': isBlocked,
      'dailyLimit': dailyLimit,
      'usedMinutesToday': usedMinutesToday,
      'blockedTimeWindows': blockedTimeWindows?.map((w) => w.toJson()).toList(),
    };
  }

  factory BlockedApp.fromJson(Map<String, dynamic> json) {
    return BlockedApp(
      packageName: json['packageName'],
      appName: json['appName'],
      iconPath: json['iconPath'],
      isBlocked: json['isBlocked'] ?? false,
      dailyLimit: json['dailyLimit'] ?? 0,
      usedMinutesToday: json['usedMinutesToday'] ?? 0,
      blockedTimeWindows: json['blockedTimeWindows'] != null
          ? (json['blockedTimeWindows'] as List)
              .map((w) => TimeWindow.fromJson(w))
              .toList()
          : null,
    );
  }
}

class TimeWindow {
  final TimeOfDay start;
  final TimeOfDay end;

  TimeWindow({required this.start, required this.end});

  bool contains(TimeOfDay time) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final timeMinutes = time.hour * 60 + time.minute;

    if (startMinutes <= endMinutes) {
      // Normal case: start to end within same day
      return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
    } else {
      // Crosses midnight
      return timeMinutes >= startMinutes || timeMinutes <= endMinutes;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'startHour': start.hour,
      'startMinute': start.minute,
      'endHour': end.hour,
      'endMinute': end.minute,
    };
  }

  factory TimeWindow.fromJson(Map<String, dynamic> json) {
    return TimeWindow(
      start: TimeOfDay(hour: json['startHour'], minute: json['startMinute']),
      end: TimeOfDay(hour: json['endHour'], minute: json['endMinute']),
    );
  }
}


