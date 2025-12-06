import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import '../../features/tasks/models/task_model.dart';

class TaskNotificationService {
  static final _instance = TaskNotificationService._internal();
  factory TaskNotificationService() => _instance;
  TaskNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Android settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();
      
      _isInitialized = true;
      debugPrint('✅ Task notification service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize task notifications: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      debugPrint('⚠️ Notification permission not granted');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Task notification tapped: ${response.payload}');
    // Handle navigation to task details
  }

  /// Schedule reminders for a specific task
  Future<void> scheduleTaskReminders(Task task) async {
    if (!_isInitialized) await initialize();
    
    // Cancel existing notifications for this task
    await cancelTaskReminders(task.id);
    
    for (int i = 0; i < task.reminders.length; i++) {
      final reminder = task.reminders[i];
      if (!reminder.isEnabled || reminder.reminderTime.isBefore(DateTime.now())) {
        continue;
      }

      await _scheduleNotification(
        id: _generateNotificationId(task.id, i),
        title: '📋 Task Reminder',
        body: reminder.customMessage ?? 'Don\'t forget: ${task.title}',
        scheduledTime: reminder.reminderTime,
        payload: 'task_${task.id}',
      );
    }

    // Schedule due date reminder if task has a due date
    if (task.dueDate != null && !task.isCompleted) {
      final dueDateReminder = task.dueDate!.subtract(const Duration(hours: 1));
      if (dueDateReminder.isAfter(DateTime.now())) {
        await _scheduleNotification(
          id: _generateNotificationId(task.id, 999), // Special ID for due date
          title: '⏰ Task Due Soon',
          body: '${task.title} is due in 1 hour!',
          scheduledTime: dueDateReminder,
          payload: 'task_due_${task.id}',
        );
      }
    }

    debugPrint('📅 Scheduled ${task.reminders.length} reminders for task: ${task.title}');
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Reminders for your tasks and deadlines',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
    }
  }

  /// Cancel all reminders for a specific task
  Future<void> cancelTaskReminders(String taskId) async {
    try {
      // Cancel up to 1000 possible reminder notifications for this task
      for (int i = 0; i < 1000; i++) {
        await _notifications.cancel(_generateNotificationId(taskId, i));
      }
      debugPrint('🗑️ Cancelled reminders for task: $taskId');
    } catch (e) {
      debugPrint('❌ Failed to cancel task reminders: $e');
    }
  }

  /// Schedule daily task review reminder
  Future<void> scheduleDailyTaskReview({
    int hour = 9,
    int minute = 0,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      // If time has passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        1001, // Special ID for daily review
        '🎯 Daily Task Review',
        'Ready to plan your day? Review and organize your tasks.',
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_review',
            'Daily Task Review',
            channelDescription: 'Daily reminder to review and plan tasks',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'daily_review',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('📅 Daily task review scheduled for $hour:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('❌ Failed to schedule daily review: $e');
    }
  }

  /// Send immediate notification for task completion
  Future<void> showTaskCompletedNotification(Task task) async {
    if (!_isInitialized) await initialize();

    await _notifications.show(
      2000, // Special ID for completion notifications
      '🎉 Task Completed!',
      'Great job completing "${task.title}"! You earned ${task.xpReward} XP.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_completion',
          'Task Completion',
          channelDescription: 'Celebrations for completed tasks',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'task_completed_${task.id}',
    );
  }

  /// Send focus session task suggestion
  Future<void> showFocusTaskSuggestion(List<Task> suggestedTasks) async {
    if (!_isInitialized || suggestedTasks.isEmpty) return;

    final taskTitles = suggestedTasks.take(3).map((t) => t.title).join(', ');
    
    await _notifications.show(
      3000, // Special ID for focus suggestions
      '🎯 Focus Session Ready',
      'Perfect time to work on: $taskTitles',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'focus_suggestions',
          'Focus Task Suggestions',
          channelDescription: 'Suggestions for tasks to work on during focus sessions',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
      payload: 'focus_suggestion',
    );
  }

  /// Generate unique notification ID for task reminders
  int _generateNotificationId(String taskId, int reminderIndex) {
    // Simple hash to generate consistent IDs
    return (taskId.hashCode + reminderIndex).abs() % 100000;
  }

  /// Clear all task notifications
  Future<void> cancelAllTaskNotifications() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ Cancelled all task notifications');
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}