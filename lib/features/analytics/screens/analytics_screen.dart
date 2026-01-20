import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/tutorial_back_button.dart';
import '../../gamification/providers/gamification_provider.dart';
import '../../focus/providers/focus_timer_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: const TutorialBackButton(
          defaultRoute: '/dashboard',
        ),
      ),
      body: Consumer2<GamificationProvider, FocusTimerProvider>(
        builder: (context, gamification, timer, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's Stats
                Text(
                  'Today\'s Progress',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Points Earned',
                        value: '${gamification.dailyPoints}',
                        icon: Icons.star,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMedium),
                    Expanded(
                      child: _StatCard(
                        title: 'Focus Minutes',
                        value: '${timer.totalFocusMinutesToday}',
                        icon: Icons.timer,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spaceMedium),
                
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Current Streak',
                        value: '${gamification.currentStreak}',
                        icon: Icons.local_fire_department,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMedium),
                    Expanded(
                      child: _StatCard(
                        title: 'Sessions',
                        value: '${timer.totalSessionsToday}',
                        icon: Icons.play_circle,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.spaceLarge),
                
                // Overall Stats
                Text(
                  'Overall Progress',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Points:', style: theme.textTheme.bodyLarge),
                          Text(
                            '${gamification.totalPoints}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Current Level:', style: theme.textTheme.bodyLarge),
                          Text(
                            'Level ${gamification.currentLevel}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Best Streak:', style: theme.textTheme.bodyLarge),
                          Text(
                            '${gamification.bestStreak} days',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spaceLarge),
                
                // Coming Soon Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spaceLarge),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.insights,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      Text(
                        'Advanced Analytics Coming Soon!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      const Text(
                        'Weekly trends, productivity insights, and detailed progress charts!',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGrayLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
