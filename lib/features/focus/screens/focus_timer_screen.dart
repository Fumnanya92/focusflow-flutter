import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/tutorial_back_button.dart';
import '../providers/focus_timer_provider.dart';

class FocusTimerScreen extends StatelessWidget {
  const FocusTimerScreen({super.key});

  void _showTimerSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timer Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Timer settings coming soon!'),
            const SizedBox(height: 16),
            const Text('Current features:'),
            const Text('• Pomodoro Mode: 25 minutes'),
            const Text('• Deep Focus: 60 minutes'),
            const Text('• Points per minute of focus'),
            const Text('• Streak tracking'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timerProvider = Provider.of<FocusTimerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
        leading: const TutorialBackButton(
          defaultRoute: '/dashboard',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Show timer settings modal
              _showTimerSettings(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mode Selector
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: 'Pomodoro',
                        isSelected: timerProvider.focusMode == FocusMode.pomodoro,
                        onTap: () => timerProvider.setFocusMode(FocusMode.pomodoro),
                        isDark: isDark,
                      ),
                    ),
                    Expanded(
                      child: _ModeButton(
                        label: 'Deep Focus',
                        isSelected: timerProvider.focusMode == FocusMode.deepFocus,
                        onTap: () => timerProvider.setFocusMode(FocusMode.deepFocus),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Timer Display
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceLarge),
                  child: _CircularTimer(
                    progress: timerProvider.progress,
                    timeDisplay: timerProvider.timeDisplay,
                    isDark: isDark,
                  ),
                ),
              ),
            ),

            // Session Progress
            if (timerProvider.focusMode == FocusMode.pomodoro)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: timerProvider.currentSession / timerProvider.totalSessions,
                      backgroundColor: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      '${timerProvider.currentSession} of ${timerProvider.totalSessions} sessions',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppTheme.spaceMedium),

            // Reward Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: isDark 
                  ? AppTheme.borderDark.withAlpha((0.3 * 255).round())
                  : AppTheme.borderLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.park,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: Text(
                      'Tree will grow',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '+10',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceLarge),

            // Control Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (timerProvider.timerState == TimerState.running) {
                          timerProvider.pauseTimer();
                        } else {
                          timerProvider.startTimer();
                        }
                      },
                      child: Text(
                        timerProvider.timerState == TimerState.running
                            ? 'Pause'
                            : timerProvider.timerState == TimerState.paused
                                ? 'Resume'
                                : 'Start',
                      ),
                    ),
                  ),
                  if (timerProvider.timerState != TimerState.idle)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spaceSmall),
                      child: TextButton(
                        onPressed: () {
                          timerProvider.stopTimer();
                        },
                        child: const Text('End Session'),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceLarge),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSmall),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).round()),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? (isDark ? AppTheme.textWhite : AppTheme.textPrimary)
                : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _CircularTimer extends StatelessWidget {
  final double progress;
  final String timeDisplay;
  final bool isDark;

  const _CircularTimer({
    required this.progress,
    required this.timeDisplay,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size.width * 0.7;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _CircleProgressPainter(
                progress: progress,
                backgroundColor: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                progressColor: AppTheme.primary,
              ),
            ),
          ),

          // Time Display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeDisplay,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                'Time to Focus',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.textGreen : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _CircleProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
