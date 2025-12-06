import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// 🔥 Streak Display Widget - Psychology Weapon
/// Makes breaking streaks feel EXPENSIVE and painful
class StreakDisplay extends StatefulWidget {
  final int streakDays;
  final bool isLarge;
  final VoidCallback? onTap;

  const StreakDisplay({
    super.key,
    required this.streakDays,
    this.isLarge = false,
    this.onTap,
  });

  @override
  State<StreakDisplay> createState() => _StreakDisplayState();
}

class _StreakDisplayState extends State<StreakDisplay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));

    // Start animations for high streaks
    if (widget.streakDays >= 7) {
      _pulseController.repeat(reverse: true);
      _sparkleController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streakDays == 0) {
      return _buildNoStreak(context);
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _sparkleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.streakDays >= 7 ? _pulseAnimation.value : 1.0,
            child: Container(
              padding: EdgeInsets.all(widget.isLarge ? 16 : 12),
              decoration: BoxDecoration(
                gradient: _getStreakGradient(),
                borderRadius: BorderRadius.circular(widget.isLarge ? 16 : 12),
                border: Border.all(
                  color: _getStreakBorderColor(),
                  width: widget.streakDays >= 30 ? 2 : 1,
                ),
                boxShadow: widget.streakDays >= 7 ? [
                  BoxShadow(
                    color: _getStreakColor().withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStreakIcons(),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getStreakText(),
                        style: (widget.isLarge 
                          ? Theme.of(context).textTheme.titleLarge 
                          : Theme.of(context).textTheme.titleMedium)?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getStreakTextColor(),
                        ),
                      ),
                      if (widget.streakDays >= 7) ...[
                        SizedBox(height: 2),
                        Text(
                          _getStreakSubtitle(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getStreakTextColor().withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (widget.streakDays >= 30) ...[
                    SizedBox(width: 8),
                    _buildSparkleEffect(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoStreak(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.isLarge ? 16 : 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(widget.isLarge ? 16 : 12),
        border: Border.all(
          color: AppTheme.textGrayLight.withValues(alpha: 0.3),
        ),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              color: AppTheme.textGrayLight,
              size: widget.isLarge ? 24 : 20,
            ),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Start your streak!',
                style: (widget.isLarge 
                  ? Theme.of(context).textTheme.titleMedium 
                  : Theme.of(context).textTheme.bodyMedium)?.copyWith(
                  color: AppTheme.textGrayLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakIcons() {
    List<Widget> icons = [];
    
    if (widget.streakDays >= 1) {
      icons.add(Icon(
        Icons.local_fire_department,
        color: _getStreakColor(),
        size: widget.isLarge ? 28 : 24,
      ));
    }
    
    if (widget.streakDays >= 14) {
      icons.add(Icon(
        Icons.flash_on,
        color: Colors.yellow[600],
        size: widget.isLarge ? 24 : 20,
      ));
    }
    
    if (widget.streakDays >= 30) {
      icons.add(Icon(
        Icons.diamond,
        color: Colors.cyan[400],
        size: widget.isLarge ? 20 : 16,
      ));
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: icons,
    );
  }

  Widget _buildSparkleEffect() {
    return Transform.rotate(
      angle: _sparkleAnimation.value * 6.28, // Full rotation
      child: Icon(
        Icons.auto_awesome,
        color: Colors.cyan[400]?.withValues(alpha: _sparkleAnimation.value),
        size: widget.isLarge ? 20 : 16,
      ),
    );
  }

  LinearGradient _getStreakGradient() {
    if (widget.streakDays >= 90) {
      // Gold Streak - Ultimate prestige
      return LinearGradient(
        colors: [
          Colors.amber[300]!.withValues(alpha: 0.2),
          Colors.orange[400]!.withValues(alpha: 0.2),
          Colors.red[400]!.withValues(alpha: 0.2),
        ],
      );
    } else if (widget.streakDays >= 30) {
      // Silver Streak - Premium look
      return LinearGradient(
        colors: [
          Colors.cyan[200]!.withValues(alpha: 0.2),
          Colors.blue[300]!.withValues(alpha: 0.2),
        ],
      );
    } else if (widget.streakDays >= 7) {
      // Bronze Streak - First milestone
      return LinearGradient(
        colors: [
          Colors.orange[200]!.withValues(alpha: 0.2),
          Colors.deepOrange[300]!.withValues(alpha: 0.2),
        ],
      );
    } else {
      // Basic streak
      return LinearGradient(
        colors: [
          Colors.orange[100]!.withValues(alpha: 0.2),
          Colors.red[100]!.withValues(alpha: 0.2),
        ],
      );
    }
  }

  Color _getStreakColor() {
    if (widget.streakDays >= 90) return Colors.amber[600]!;
    if (widget.streakDays >= 30) return Colors.cyan[500]!;
    if (widget.streakDays >= 7) return Colors.orange[600]!;
    return Colors.orange[500]!;
  }

  Color _getStreakBorderColor() {
    return _getStreakColor().withValues(alpha: 0.5);
  }

  Color _getStreakTextColor() {
    if (widget.streakDays >= 30) return Colors.white;
    return _getStreakColor();
  }

  String _getStreakText() {
    if (widget.streakDays == 1) return '1 day';
    return '${widget.streakDays} days';
  }

  String _getStreakSubtitle() {
    if (widget.streakDays >= 90) return 'GOLD LEGEND';
    if (widget.streakDays >= 30) return 'SILVER MASTER';
    if (widget.streakDays >= 14) return 'ON FIRE';
    if (widget.streakDays >= 7) return 'BRONZE STREAK';
    return 'BUILDING';
  }
}

/// 🔥 Streak Warning Widget - Shows the cost of breaking
class StreakWarningDialog extends StatelessWidget {
  final int currentStreak;
  final VoidCallback onBreakStreak;
  final VoidCallback onKeepStreak;

  const StreakWarningDialog({
    super.key,
    required this.currentStreak,
    required this.onBreakStreak,
    required this.onKeepStreak,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red[400]!, width: 2),
      ),
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[400], size: 28),
          SizedBox(width: 12),
          Text(
            '⚠️ STREAK DANGER',
            style: TextStyle(
              color: Colors.red[400],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreakDisplay(streakDays: currentStreak, isLarge: true),
          SizedBox(height: 16),
          Text(
            'You\'re about to LOSE your $currentStreak-day streak!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red[400],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'All that progress will be GONE.\nYou\'ll have to start over from day 1.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textGrayLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (currentStreak >= 7) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[900]?.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💔 You\'ll lose your ${_getStreakBadge()} badge!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red[300],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onBreakStreak,
          style: TextButton.styleFrom(
            foregroundColor: Colors.red[400],
          ),
          child: Text('Break Streak 💔'),
        ),
        ElevatedButton(
          onPressed: onKeepStreak,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
          child: Text('Keep Streak! 🔥'),
        ),
      ],
    );
  }

  String _getStreakBadge() {
    if (currentStreak >= 90) return 'Gold Legend';
    if (currentStreak >= 30) return 'Silver Master';
    if (currentStreak >= 7) return 'Bronze Streak';
    return 'Streak';
  }
}