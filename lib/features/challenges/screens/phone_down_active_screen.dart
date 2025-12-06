import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../providers/challenge_provider.dart';

class PhoneDownActiveScreen extends StatelessWidget {
  const PhoneDownActiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    final challenge = challengeProvider.currentChallenge;

    if (challenge == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Challenge')),
        body: const Center(child: Text('No active challenge')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _showCancelDialog(context);
                    },
                  ),
                  Text(
                    'Phone-Down Challenge',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Timer Display
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      challengeProvider.timeRemaining,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      'Time Remaining',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark ? AppTheme.textGreen : AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceXLarge),

                    // Participants Status
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withAlpha((0.1 * 255).round()),
                        border: Border.all(
                          color: AppTheme.primary,
                          width: 4,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${challenge.activeParticipantsCount}',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            'Still in',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Participants List
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLarge),
                  topRight: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participants',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  ...challenge.participants.map((participant) {
                    return _ParticipantItem(
                      name: participant.name,
                      isEliminated: participant.isEliminated,
                      isDark: isDark,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Challenge?'),
        content: const Text(
          'Are you sure you want to cancel this challenge? All progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () {
              final challengeProvider = Provider.of<ChallengeProvider>(
                context,
                listen: false,
              );
              challengeProvider.cancelChallenge();
              Navigator.pop(context);
              context.go('/dashboard');
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantItem extends StatelessWidget {
  final String name;
  final bool isEliminated;
  final bool isDark;

  const _ParticipantItem({
    required this.name,
    required this.isEliminated,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isEliminated
                ? AppTheme.textSecondary
                : AppTheme.primary,
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: AppTheme.backgroundDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceMedium),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyLarge?.copyWith(
                decoration: isEliminated
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: isEliminated ? AppTheme.textSecondary : null,
              ),
            ),
          ),
          if (isEliminated)
            const Icon(
              Icons.cancel,
              color: AppTheme.error,
              size: 24,
            )
          else
            const Icon(
              Icons.check_circle,
              color: AppTheme.primary,
              size: 24,
            ),
        ],
      ),
    );
  }
}
