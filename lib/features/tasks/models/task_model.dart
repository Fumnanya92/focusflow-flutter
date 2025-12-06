import 'package:uuid/uuid.dart';

enum TaskPriority { low, medium, high }
enum TaskTag { work, personal, goal, health, learning, other }
enum RecurrenceType { none, daily, weekly, monthly }

class TaskReminder {
  final DateTime reminderTime;
  final bool isEnabled;
  final String? customMessage;
  
  TaskReminder({
    required this.reminderTime,
    this.isEnabled = true,
    this.customMessage,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'reminderTime': reminderTime.toIso8601String(),
      'isEnabled': isEnabled,
      'customMessage': customMessage,
    };
  }
  
  factory TaskReminder.fromJson(Map<String, dynamic> json) {
    return TaskReminder(
      reminderTime: DateTime.parse(json['reminderTime']),
      isEnabled: json['isEnabled'] ?? true,
      customMessage: json['customMessage'],
    );
  }
  
  TaskReminder copyWith({
    DateTime? reminderTime,
    bool? isEnabled,
    String? customMessage,
  }) {
    return TaskReminder(
      reminderTime: reminderTime ?? this.reminderTime,
      isEnabled: isEnabled ?? this.isEnabled,
      customMessage: customMessage ?? this.customMessage,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskTag tag;
  final int? estimatedMinutes;
  final int xpReward;
  final List<TaskReminder> reminders;
  final RecurrenceType recurrence;
  final bool isArchived;
  final String? notes;

  Task({
    String? id,
    required this.title,
    this.description,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.tag = TaskTag.personal,
    this.estimatedMinutes,
    this.xpReward = 10,
    this.reminders = const [],
    this.recurrence = RecurrenceType.none,
    this.isArchived = false,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskTag? tag,
    int? estimatedMinutes,
    int? xpReward,
    List<TaskReminder>? reminders,
    RecurrenceType? recurrence,
    bool? isArchived,
    String? notes,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      tag: tag ?? this.tag,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      xpReward: xpReward ?? this.xpReward,
      reminders: reminders ?? this.reminders,
      recurrence: recurrence ?? this.recurrence,
      isArchived: isArchived ?? this.isArchived,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.name,
      'tag': tag.name,
      'estimatedMinutes': estimatedMinutes,
      'xpReward': xpReward,
      'reminders': reminders.map((r) => r.toJson()).toList(),
      'recurrence': recurrence.name,
      'isArchived': isArchived,
      'notes': notes,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate']) 
          : null,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      tag: TaskTag.values.firstWhere(
        (e) => e.name == json['tag'],
        orElse: () => TaskTag.personal,
      ),
      estimatedMinutes: json['estimatedMinutes'],
      xpReward: json['xpReward'] ?? 10,
      reminders: (json['reminders'] as List<dynamic>?)?.map((r) => TaskReminder.fromJson(r)).toList() ?? [],
      recurrence: RecurrenceType.values.firstWhere(
        (e) => e.name == json['recurrence'],
        orElse: () => RecurrenceType.none,
      ),
      isArchived: json['isArchived'] ?? false,
      notes: json['notes'],
    );
  }
  
  // Utility methods
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year && dueDate!.month == now.month && dueDate!.day == now.day;
  }
  bool get hasPendingReminders => reminders.any((r) => r.isEnabled && r.reminderTime.isAfter(DateTime.now()));
  
  String get priorityEmoji {
    switch (priority) {
      case TaskPriority.high:
        return '🔴';
      case TaskPriority.medium:
        return '🟡';
      case TaskPriority.low:
        return '🟢';
    }
  }
  
  String get tagEmoji {
    switch (tag) {
      case TaskTag.work:
        return '💼';
      case TaskTag.personal:
        return '👤';
      case TaskTag.goal:
        return '🎯';
      case TaskTag.health:
        return '💪';
      case TaskTag.learning:
        return '📚';
      case TaskTag.other:
        return '📋';
    }
  }
}
