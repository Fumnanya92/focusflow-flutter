import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/task_reminder_overlay.dart';

class TaskOverlayService {
  static final TaskOverlayService _instance = TaskOverlayService._internal();
  factory TaskOverlayService() => _instance;
  TaskOverlayService._internal();

  static const MethodChannel _channel = MethodChannel('app_blocking');
  OverlayEntry? _overlayEntry;
  
  /// Show the Flutter-based task reminder overlay
  static Future<void> showTaskReminderOverlay({
    required String title,
    required String message,
    required bool hasTasksToday,
    required int taskCount,
  }) async {
    final context = NavigatorService.navigatorKey.currentContext;
    if (context == null) return;
    
    final overlay = Overlay.of(context);
    
    // Remove existing overlay if present
    _instance._overlayEntry?.remove();
    
    _instance._overlayEntry = OverlayEntry(
      builder: (context) => TaskReminderOverlay(
        title: title,
        message: message,
        hasTasksToday: hasTasksToday,
        taskCount: taskCount,
        onDismiss: () {
          _instance._overlayEntry?.remove();
          _instance._overlayEntry = null;
        },
      ),
    );
    
    overlay.insert(_instance._overlayEntry!);
  }
  
  /// Hide the current overlay
  static void hideOverlay() {
    _instance._overlayEntry?.remove();
    _instance._overlayEntry = null;
  }
  
  /// Initialize the overlay service with method channel handlers
  static void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  /// Handle method calls from native Android
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'showTaskReminderOverlay':
          final args = call.arguments as Map<String, dynamic>? ?? {};
          await showTaskReminderOverlay(
            title: args['title'] ?? 'Task Reminder',
            message: args['message'] ?? 'Time to plan your tasks!',
            hasTasksToday: args['hasTasksToday'] ?? false,
            taskCount: args['taskCount'] ?? 0,
          );
          return {'success': true, 'message': 'Overlay shown successfully'};
        case 'hideTaskReminderOverlay':
          hideOverlay();
          return {'success': true, 'message': 'Overlay hidden successfully'};
        default:
          throw PlatformException(
            code: 'UNIMPLEMENTED',
            message: 'Method ${call.method} not implemented',
          );
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

/// Global navigator service for getting build context
class NavigatorService {
  // Use the global navigator key from main.dart
  static GlobalKey<NavigatorState>? _navigatorKey;
  
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }
  
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey!;
  static NavigatorState? get navigator => _navigatorKey?.currentState;
  static BuildContext? get context => _navigatorKey?.currentContext;
}