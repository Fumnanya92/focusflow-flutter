import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _dashboardTutorialKey = 'dashboard_tutorial_completed';
  static const String _appBlockingTutorialKey = 'app_blocking_tutorial_completed';
  static const String _focusTimerTutorialKey = 'focus_timer_tutorial_completed';

  /// Check if the main tutorial has been completed
  static Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }

  /// Mark the main tutorial as completed
  static Future<void> markTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }

  /// Check if dashboard tutorial has been completed
  static Future<bool> isDashboardTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_dashboardTutorialKey) ?? false;
    debugPrint('🎯 [TUTORIAL_SERVICE] Dashboard tutorial completed: $completed');
    return completed;
  }

  /// Mark dashboard tutorial as completed
  static Future<void> markDashboardTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dashboardTutorialKey, true);
    debugPrint('🎯 [TUTORIAL_SERVICE] Dashboard tutorial marked as completed');
  }

  /// Check if app blocking tutorial has been completed
  static Future<bool> isAppBlockingTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_appBlockingTutorialKey) ?? false;
  }

  /// Mark app blocking tutorial as completed
  static Future<void> markAppBlockingTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appBlockingTutorialKey, true);
  }

  /// Check if focus timer tutorial has been completed
  static Future<bool> isFocusTimerTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_focusTimerTutorialKey) ?? false;
  }

  /// Mark focus timer tutorial as completed
  static Future<void> markFocusTimerTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_focusTimerTutorialKey, true);
  }

  /// Reset all tutorial states (for testing)
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, false);
    await prefs.setBool(_dashboardTutorialKey, false);
    await prefs.setBool(_appBlockingTutorialKey, false);
    await prefs.setBool(_focusTimerTutorialKey, false);
    debugPrint('🎯 [TUTORIAL_SERVICE] All tutorials reset');
  }

  /// Show tutorial completion celebration
  static void showTutorialCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                size: 40,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tutorial Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You\'re now ready to use FocusFlow to boost your productivity!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                markTutorialCompleted();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Let\'s Go!'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom showcase widget with better styling
class CustomShowcaseWidget extends StatelessWidget {
  final Widget child;
  final String title;
  final String description;
  final bool showArrow;
  final ShapeBorder? targetShapeBorder;

  const CustomShowcaseWidget({
    super.key,
    required this.child,
    required this.title,
    required this.description,
    this.showArrow = true,
    this.targetShapeBorder,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}