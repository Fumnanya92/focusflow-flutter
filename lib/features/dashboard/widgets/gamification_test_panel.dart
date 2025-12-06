import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../../core/theme.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../focus/providers/focus_timer_provider.dart';

/// 🎮 Test Panel for demonstrating the points system
/// This will be removed in production
class GamificationTestPanel extends StatelessWidget {
  const GamificationTestPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GamificationProvider, FocusTimerProvider>(
      builder: (context, gamification, timer, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
          padding: EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎮 Points System Demo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              
              SizedBox(height: AppTheme.spaceSmall),
              
              Text(
                'Test the gamification system:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textGrayLight,
                ),
              ),
              
              SizedBox(height: AppTheme.spaceMedium),
              
              // Test buttons grid
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TestButton(
                    label: '+1 Focus Min',
                    color: AppTheme.success,
                    onPressed: () => gamification.awardFocusMinute(),
                  ),
                  _TestButton(
                    label: 'Start 25m Session',
                    color: AppTheme.primaryTeal,
                    onPressed: () => gamification.startFocusSession(25),
                  ),
                  _TestButton(
                    label: 'Complete Session',
                    color: AppTheme.success,
                    onPressed: () => gamification.completeSession(25),
                  ),
                  _TestButton(
                    label: 'Exit Early (15m)',
                    color: Colors.orange,
                    onPressed: () => gamification.exitSessionEarly(15),
                  ),
                  _TestButton(
                    label: 'Emergency (-25)',
                    color: Colors.red,
                    onPressed: () => gamification.emergencyStop(),
                  ),
                  _TestButton(
                    label: 'Set Goal 60m',
                    color: AppTheme.primaryTeal,
                    onPressed: () => gamification.setDailyGoal(60),
                  ),
                  _TestButton(
                    label: 'Add 50 pts',
                    color: AppTheme.success,
                    onPressed: () => gamification.addTestPoints(50),
                  ),
                  _TestButton(
                    label: 'Test 7-day Streak',
                    color: Colors.orange,
                    onPressed: () => _testStreak(context, gamification, 7),
                  ),
                  _TestButton(
                    label: 'Test 30-day Streak',
                    color: Colors.cyan,
                    onPressed: () => _testStreak(context, gamification, 30),
                  ),
                  _TestButton(
                    label: 'Test Dynamic Overlay',
                    color: Colors.purple,
                    onPressed: () => _testDynamicOverlay(context),
                  ),
                  _TestButton(
                    label: 'Reset All',
                    color: Colors.grey,
                    onPressed: () => _showResetDialog(context, gamification),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _testStreak(BuildContext context, GamificationProvider gamification, int days) async {
    // Simulate streak by directly setting it (for testing)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_streak', days);
    
    // Trigger a reload to show the new streak
    // Note: In a real app, you'd have a proper method for this
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🔥 Simulated $days-day streak!')),
      );
    }
  }

  void _testDynamicOverlay(BuildContext context) async {
    try {
      // First check overlay permission
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      
      if (!hasPermission) {
        // Request permission first
        final granted = await FlutterOverlayWindow.requestPermission();
        if (granted != true) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ Overlay permission denied')),
            );
          }
          return;
        }
      }
      
      // Show the dynamic overlay directly
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        overlayTitle: 'FocusFlow Test',
        overlayContent: 'Testing dynamic overlay functionality',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
      );
      
      // Share test data
      await FlutterOverlayWindow.shareData({'appName': 'Test App', 'action': 'initialize'});
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎯 Dynamic overlay launched!')),
        );
      }
    } catch (e) {
      debugPrint('❌ Overlay test error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Overlay test failed: $e')),
        );
      }
    }
  }

  void _showResetDialog(BuildContext context, GamificationProvider gamification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Progress?'),
        content: const Text('This will reset all points, levels, and streaks. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              gamification.resetAll();
              Navigator.of(context).pop();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _TestButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size(0, 36),
          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}