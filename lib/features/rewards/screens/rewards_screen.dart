import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../providers/rewards_provider.dart';
import '../models/badge_model.dart' as badge_model;

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards & Badges'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Consumer<RewardsProvider>(
        builder: (context, rewards, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // XP Progress Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Level ${rewards.level}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        '${rewards.totalXP} XP',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      LinearProgressIndicator(
                        value: rewards.levelProgress,
                        backgroundColor: AppTheme.borderDark,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        '${rewards.xpToNextLevel} XP to Level ${rewards.level + 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textGrayLight,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppTheme.spaceLarge),
                
                // Badges Section
                Text(
                  'Your Badges',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spaceMedium),
                
                // Badge Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: AppTheme.spaceMedium,
                    mainAxisSpacing: AppTheme.spaceMedium,
                  ),
                  itemCount: rewards.badges.length,
                  itemBuilder: (context, index) {
                    final badge = rewards.badges[index];
                    return _BadgeCard(badge: badge);
                  },
                ),
                
                const SizedBox(height: AppTheme.spaceLarge),
                
                // Coming Soon Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
                        Icons.storefront,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: AppTheme.spaceMedium),
                      Text(
                        'Reward Store Coming Soon!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      const Text(
                        'Unlock themes, sounds, and special titles with your points!',
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

class _BadgeCard extends StatelessWidget {
  final badge_model.Badge badge;
  
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: badge.isUnlocked 
          ? AppTheme.surfaceDark 
          : AppTheme.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: badge.isUnlocked 
            ? badge.rarity.color 
            : AppTheme.borderDark,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              badge.type.emoji,
              style: TextStyle(
                fontSize: 28,
                color: badge.isUnlocked 
                  ? null 
                  : AppTheme.textGrayLight.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              badge.title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: badge.isUnlocked 
                  ? badge.rarity.color 
                  : AppTheme.textGrayLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badge.isProgressBased && !badge.isUnlocked) ...[
            const SizedBox(height: 2),
            Text(
              '${badge.progress}/${badge.target}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textGrayLight,
                fontSize: 10,
              ),
            ),
          ],
          if (badge.isUnlocked && badge.unlockedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Unlocked!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.success,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
