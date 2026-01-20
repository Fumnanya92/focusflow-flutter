import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../../../core/services/task_notification_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<Task> _dailyTasks = [];
  bool _isLoading = false;
  final TaskNotificationService _notificationService = TaskNotificationService();

  List<Task> get tasks => _tasks.where((t) => !t.isArchived).toList();
  List<Task> get activeTasks => _tasks.where((t) => !t.isCompleted && !t.isArchived).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.isCompleted && !t.isArchived).toList();
  List<Task> get archivedTasks => _tasks.where((t) => t.isArchived).toList();
  List<Task> get dailyTasks => _dailyTasks;
  List<Task> get overdueTasks => _tasks.where((t) => t.isOverdue && !t.isArchived).toList();
  List<Task> get todayTasks => _tasks.where((t) => t.isDueToday && !t.isArchived).toList();
  List<Task> get upcomingTasks => _tasks.where((t) => 
    t.dueDate != null && 
    t.dueDate!.isAfter(DateTime.now().add(const Duration(days: 1))) && 
    !t.isCompleted && 
    !t.isArchived
  ).toList();
  List<Task> get tasksWithReminders => _tasks.where((t) => t.hasPendingReminders && !t.isArchived).toList();
  List<Task> get allTasks => _tasks;
  List<Task> get pendingTasks => _tasks.where((t) => !t.isCompleted && !t.isArchived).toList();
  bool get isLoading => _isLoading;
  
  // Enhanced statistics
  int get totalTasksToday => _dailyTasks.length;
  int get completedTasksToday => _dailyTasks.where((t) => t.isCompleted).length;
  int get totalActiveTasks => activeTasks.length;
  int get totalOverdueTasks => overdueTasks.length;
  int get totalTasksThisWeek => _getTasksInWeek().length;
  int get completedTasksThisWeek => _getTasksInWeek().where((t) => t.isCompleted).length;
  
  double get todayProgress {
    if (_dailyTasks.isEmpty) return 0;
    return completedTasksToday / totalTasksToday;
  }
  
  double get weeklyProgress {
    final weekTasks = _getTasksInWeek();
    if (weekTasks.isEmpty) return 0;
    return weekTasks.where((t) => t.isCompleted).length / weekTasks.length;
  }

  List<Task> getTodayTasks() => todayTasks;
  int getCompletedTasksToday() => completedTasksToday;
  
  int get totalXPEarned => completedTasks.fold(0, (sum, task) => sum + task.xpReward);
  
  List<Task> _getTasksInWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return _tasks.where((task) => 
      task.createdAt.isAfter(startOfWeek) && 
      task.createdAt.isBefore(endOfWeek.add(const Duration(days: 1)))
    ).toList();
  }

  TaskProvider() {
    _loadTasks();
    _initializeNotifications();
  }
  
  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.scheduleDailyTaskReview();
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    
    // Schedule notifications for this task
    if (task.reminders.isNotEmpty) {
      await _notificationService.scheduleTaskReminders(task);
    }
    
    await _saveTasks();
    notifyListeners();
  }

  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      final oldTask = _tasks[index];
      _tasks[index] = updatedTask;
      
      // Also update in daily tasks if present
      final dailyIndex = _dailyTasks.indexWhere((t) => t.id == updatedTask.id);
      if (dailyIndex != -1) {
        _dailyTasks[dailyIndex] = updatedTask;
      }
      
      // Update notifications if reminders changed
      if (oldTask.reminders != updatedTask.reminders) {
        await _notificationService.scheduleTaskReminders(updatedTask);
      }
      
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    
    // Show completion notification and cancel reminders if completing
    if (!task.isCompleted && updatedTask.isCompleted) {
      await _notificationService.showTaskCompletedNotification(updatedTask);
      await _notificationService.cancelTaskReminders(taskId);
    } else if (task.isCompleted && !updatedTask.isCompleted) {
      // Re-schedule reminders if uncompleting
      await _notificationService.scheduleTaskReminders(updatedTask);
    }
    
    await updateTask(updatedTask);
  }

  Future<void> deleteTask(String taskId) async {
    await _notificationService.cancelTaskReminders(taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    _dailyTasks.removeWhere((t) => t.id == taskId);
    await _saveTasks();
    notifyListeners();
  }
  
  Future<void> archiveTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final archivedTask = task.copyWith(isArchived: true);
    await _notificationService.cancelTaskReminders(taskId);
    await updateTask(archivedTask);
  }
  
  Future<void> unarchiveTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final unarchivedTask = task.copyWith(isArchived: false);
    if (unarchivedTask.reminders.isNotEmpty) {
      await _notificationService.scheduleTaskReminders(unarchivedTask);
    }
    await updateTask(unarchivedTask);
  }
  
  Future<void> addReminderToTask(String taskId, TaskReminder reminder) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final updatedReminders = [...task.reminders, reminder];
    final updatedTask = task.copyWith(reminders: updatedReminders);
    await updateTask(updatedTask);
  }
  
  Future<void> removeReminderFromTask(String taskId, int reminderIndex) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final updatedReminders = [...task.reminders];
    updatedReminders.removeAt(reminderIndex);
    final updatedTask = task.copyWith(reminders: updatedReminders);
    await updateTask(updatedTask);
  }
  
  Future<void> snoozeTaskReminder(String taskId, int reminderIndex, Duration snoozeDuration) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final updatedReminders = [...task.reminders];
    final reminder = updatedReminders[reminderIndex];
    updatedReminders[reminderIndex] = reminder.copyWith(
      reminderTime: reminder.reminderTime.add(snoozeDuration)
    );
    final updatedTask = task.copyWith(reminders: updatedReminders);
    await updateTask(updatedTask);
  }

  Future<void> setDailyTasks(List<Task> tasks) async {
    _dailyTasks = tasks;
    
    // Also add to main tasks list if not already there
    for (final task in tasks) {
      if (!_tasks.any((t) => t.id == task.id)) {
        _tasks.add(task);
      }
    }
    
    await _saveTasks();
    await _saveDailyTasks();
    notifyListeners();
  }

  Future<void> clearDailyTasks() async {
    _dailyTasks.clear();
    await _saveDailyTasks();
    notifyListeners();
  }

  List<Task> getTasksByTag(TaskTag tag) {
    return _tasks.where((t) => t.tag == tag && !t.isCompleted && !t.isArchived).toList();
  }

  List<Task> getTasksDueToday() {
    return todayTasks;
  }
  
  List<Task> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((t) => t.priority == priority && !t.isCompleted && !t.isArchived).toList();
  }
  
  List<Task> searchTasks(String query) {
    final lowerQuery = query.toLowerCase();
    return _tasks.where((t) => 
      !t.isArchived &&
      (t.title.toLowerCase().contains(lowerQuery) ||
       (t.description?.toLowerCase().contains(lowerQuery) ?? false) ||
       (t.notes?.toLowerCase().contains(lowerQuery) ?? false))
    ).toList();
  }
  
  List<Task> getSmartTaskSuggestions({int limit = 5}) {
    final suggestions = <Task>[];
    
    // Priority 1: Overdue tasks
    suggestions.addAll(overdueTasks.take(2));
    
    // Priority 2: Due today
    suggestions.addAll(todayTasks.where((t) => !suggestions.contains(t)).take(2));
    
    // Priority 3: High priority tasks
    suggestions.addAll(getTasksByPriority(TaskPriority.high)
        .where((t) => !suggestions.contains(t)).take(1));
    
    // Fill remaining slots with other active tasks, sorted by creation date
    final remaining = activeTasks
        .where((t) => !suggestions.contains(t))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    suggestions.addAll(remaining.take(limit - suggestions.length));
    
    return suggestions.take(limit).toList();
  }
  
  Future<void> suggestTasksForFocusSession() async {
    final suggestions = getSmartTaskSuggestions(limit: 3);
    if (suggestions.isNotEmpty) {
      await _notificationService.showFocusTaskSuggestion(suggestions);
    }
  }

  Future<void> _loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString('tasks');
      final dailyTasksJson = prefs.getString('dailyTasks');

      if (tasksJson != null) {
        final List<dynamic> decoded = jsonDecode(tasksJson);
        _tasks = decoded.map((json) => Task.fromJson(json)).toList();
      }

      if (dailyTasksJson != null) {
        final List<dynamic> decoded = jsonDecode(dailyTasksJson);
        _dailyTasks = decoded.map((json) => Task.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString('tasks', tasksJson);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  Future<void> _saveDailyTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dailyTasksJson = jsonEncode(_dailyTasks.map((t) => t.toJson()).toList());
      await prefs.setString('dailyTasks', dailyTasksJson);
    } catch (e) {
      debugPrint('Error saving daily tasks: $e');
    }
  }
  
  // Bulk operations
  Future<void> markMultipleTasksCompleted(List<String> taskIds) async {
    for (final taskId in taskIds) {
      await toggleTaskCompletion(taskId);
    }
  }
  
  Future<void> archiveMultipleTasks(List<String> taskIds) async {
    for (final taskId in taskIds) {
      await archiveTask(taskId);
    }
  }
  
  Future<void> deleteMultipleTasks(List<String> taskIds) async {
    for (final taskId in taskIds) {
      await deleteTask(taskId);
    }
  }
  
  Future<void> updateTaskPriority(String taskId, TaskPriority priority) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(priority: priority);
    await updateTask(updatedTask);
  }
  
  Future<void> updateTaskDueDate(String taskId, DateTime? dueDate) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(dueDate: dueDate);
    await updateTask(updatedTask);
  }
  
  Future<void> duplicateTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final duplicatedTask = Task(
      title: '${task.title} (Copy)',
      description: task.description,
      priority: task.priority,
      tag: task.tag,
      estimatedMinutes: task.estimatedMinutes,
      xpReward: task.xpReward,
      notes: task.notes,
    );
    await addTask(duplicatedTask);
  }
}
