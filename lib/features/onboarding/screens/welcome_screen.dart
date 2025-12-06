import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            children: [
              // Logo
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.spa,
                  size: 36,
                  color: AppTheme.primary,
                ),
              ),
              
              const SizedBox(height: AppTheme.spaceLarge),

              // Welcome Text
              Text(
                'Welcome to',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              
              Text(
                'FocusFlow',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppTheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppTheme.spaceMedium),

              Text(
                'Reduce scroll. Take back focus.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppTheme.textGreen : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spaceXLarge),

              // Feature Cards
              Expanded(
                child: ListView(
                  children: [
                    _FeatureCard(
                      icon: Icons.block,
                      title: 'Smart App Blocking',
                      description: 'Block distracting apps and stay focused on what matters.',
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    _FeatureCard(
                      icon: Icons.timer,
                      title: 'Focus Timer',
                      description: 'Use Pomodoro and Deep Focus modes to maximize productivity.',
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    _FeatureCard(
                      icon: Icons.emoji_events,
                      title: 'Rewards & Streaks',
                      description: 'Earn XP, badges, and maintain streaks to build lasting habits.',
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    _FeatureCard(
                      icon: Icons.people,
                      title: 'Phone-Down Challenge',
                      description: 'Compete with friends to stay phone-free longer.',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spaceMedium),

              // Sign Up Button (Primary)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/signup');
                  },
                  child: const Text('Create Account'),
                ),
              ),

              const SizedBox(height: AppTheme.spaceSmall),

              // Login Link (Secondary)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  child: const Text('Sign In'),
                ),
              ),

              const SizedBox(height: AppTheme.spaceSmall),

              // Explanation text
              Text(
                'Authentication required to sync your progress and ensure data security',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.textGreen.withValues(alpha: 0.8) : AppTheme.textSecondary.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spaceXSmall),
                Text(
                  description,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
