import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../gamification/widgets/streak_display.dart';

/// 🎮 Gamification Stats Card for Dashboard
/// Shows points, level, streak, and daily progress
class GamificationStatsCard extends StatelessWidget {
  const GamificationStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationProvider>(
      builder: (context, gamification, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
          padding: EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primary.withValues(alpha: 0.1),
                AppTheme.primaryTeal.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    'Your Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      gamification.levelDisplay,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: AppTheme.spaceMedium),
              
              // Points and Level Progress
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${gamification.pointsDisplay} Points',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Next level: ${gamification.pointsForNextLevel} pts',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textGrayLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Level progress indicator
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: gamification.levelProgress,
                            strokeWidth: 6,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              '${gamification.currentLevel}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: AppTheme.spaceMedium),
              
              // Daily Goal Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Goal',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        gamification.dailyProgressDisplay,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: gamification.isDailyGoalReached 
                            ? AppTheme.success 
                            : AppTheme.textGrayLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: gamification.dailyGoalProgress,
                    backgroundColor: AppTheme.backgroundLight.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      gamification.isDailyGoalReached 
                        ? AppTheme.success 
                        : AppTheme.primaryTeal,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              
              SizedBox(height: AppTheme.spaceMedium),
              
              // Powerful Streak Display
              Row(
                children: [
                  Expanded(
                    child: StreakDisplay(
                      streakDays: gamification.currentStreak,
                      onTap: () {
                        // Could navigate to streak details
                      },
                    ),
                  ),
                  SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.star,
                      label: 'Today',
                      value: '${gamification.dailyPoints} pts',
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spaceSmall),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGrayLight,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}