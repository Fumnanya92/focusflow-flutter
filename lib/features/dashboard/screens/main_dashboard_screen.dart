import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../focus/providers/focus_timer_provider.dart';
import '../../blocking/providers/app_blocking_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/models/task_model.dart';
import '../../challenges/providers/challenge_provider.dart';
import '../widgets/gamification_stats_card.dart';

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<FocusTimerProvider, AppBlockingProvider, AuthProvider, TaskProvider>(
      builder: (context, timerProvider, blockingProvider, authProvider, taskProvider, child) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          body: SafeArea(
            child: Stack(
              children: [
                // Main scrollable content
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.all(AppTheme.spaceMedium),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${_getGreeting()}, ${authProvider.userData?.username ?? 'Focus Champion'}',
                                style: theme.textTheme.headlineMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: AppTheme.spaceSmall),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.settings,
                                    size: 28,
                                    color: AppTheme.textGrayLight,
                                  ),
                                  onPressed: () {
                                    context.go('/settings');
                                  },
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.account_circle,
                                    size: 32,
                                    color: AppTheme.textGrayLight,
                                  ),
                                  color: AppTheme.surfaceDark,
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'profile',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.person, color: AppTheme.textGrayLight),
                                          const SizedBox(width: 8),
                                          Text('Profile', style: TextStyle(color: AppTheme.textGrayLight)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'logout',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.logout, color: AppTheme.error),
                                          const SizedBox(width: 8),
                                          Text('Logout', style: TextStyle(color: AppTheme.error)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) async {
                                    if (value == 'logout') {
                                      await authProvider.logout();
                                      if (context.mounted) {
                                        context.go('/welcome');
                                      }
                                    } else if (value == 'profile') {
                                      context.go('/settings');
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppTheme.spaceSmall),

                      // Welcome message
                      if (authProvider.userData?.username != null)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(AppTheme.spaceMedium),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
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
                            child: Row(
                              children: [
                                Icon(
                                  Icons.waving_hand,
                                  color: AppTheme.primary,
                                  size: 24,
                                ),
                                SizedBox(width: AppTheme.spaceSmall),
                                Expanded(
                                  child: Text(
                                    'Ready to focus and be productive today?',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textGrayLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      SizedBox(height: AppTheme.spaceMedium),

                      // Gamification Stats Card
                      const GamificationStatsCard(),

                      SizedBox(height: AppTheme.spaceLarge),

                      // Stats Cards
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
                        child: Row(
                          children: [
                            Expanded(
                              child: _LiveFocusTimeCard(timerProvider: timerProvider),
                            ),
                            SizedBox(width: AppTheme.spaceMedium),
                            Expanded(
                              child: Consumer<AppBlockingProvider>(
                                builder: (context, provider, child) => _StatCard(
                                  title: 'Distractions\nBlocked',
                                  value: '${provider.blocksToday}',
                                  subtitle: provider.isBlockingActive ? 'Active Now' : 'Standby',
                                  color: provider.isBlockingActive ? AppTheme.error : AppTheme.textGray,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppTheme.spaceLarge),

                      // Quick Actions Section
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Actions',
                              style: theme.textTheme.titleLarge,
                            ),
                            SizedBox(height: AppTheme.spaceMedium),
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.psychology,
                                    title: 'Focus Timer',
                                    subtitle: 'Start a session',
                                    color: AppTheme.primaryTeal,
                                    onTap: () => context.go('/focus-timer'),
                                  ),
                                ),
                                SizedBox(width: AppTheme.spaceSmall),
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.task_alt,
                                    title: 'My Tasks',
                                    subtitle: 'View & manage',
                                    color: AppTheme.primary,
                                    onTap: () => context.go('/tasks'),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppTheme.spaceSmall),
                            Row(
                              children: [
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.phone_android_outlined,
                                    title: 'App Blocking',
                                    subtitle: 'Manage blocks',
                                    color: AppTheme.error,
                                    onTap: () => context.go('/app-selection'),
                                  ),
                                ),
                                SizedBox(width: AppTheme.spaceSmall),
                                Expanded(
                                  child: _QuickActionCard(
                                    icon: Icons.emoji_events,
                                    title: 'Challenges',
                                    subtitle: 'Join new ones',
                                    color: const Color(0xFFFFB800),
                                    onTap: () => context.go('/challenge-setup'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppTheme.spaceLarge),

                      // Today's Tasks Section
                      _TodayTasksSection(taskProvider: taskProvider),

                      SizedBox(height: AppTheme.spaceLarge),

                      // Active Challenges Section
                      const _LiveActiveChallengesSection(),

                      SizedBox(height: 120), // Space for FAB and bottom nav
                    ],
                  ),
                ),

                // Test Task Reminder Button (DEV ONLY)
                Positioned(
                  bottom: 90,
                  left: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () async {
                      // Test the task reminder overlay
                      await blockingProvider.showTaskReminder();
                    },
                    backgroundColor: AppTheme.primary,
                    icon: const Icon(Icons.bug_report, color: Colors.white),
                    label: const Text(
                      'Test Reminder',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                // Retractable Focus Button
                Positioned(
                  bottom: 90, // Just above the bottom nav
                  right: 0,
                  child: _RetractableFocusButton(),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _BottomNavBar(currentIndex: 0),
        );
      },
    );
  }
}

class _LiveFocusTimeCard extends StatefulWidget {
  final FocusTimerProvider timerProvider;
  
  const _LiveFocusTimeCard({required this.timerProvider});
  
  @override
  State<_LiveFocusTimeCard> createState() => _LiveFocusTimeCardState();
}

class _LiveActiveChallengesSection extends StatelessWidget {
  const _LiveActiveChallengesSection();
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeProvider>(
      builder: (context, challengeProvider, child) {
        final currentChallenge = challengeProvider.currentChallenge;
        final isChallengeActive = challengeProvider.isChallengeActive;
        
        if (currentChallenge == null || !isChallengeActive) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
            child: Container(
              padding: EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_task_outlined,
                    size: 32,
                    color: AppTheme.primary.withValues(alpha: 0.7),
                  ),
                  SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    'No Active Challenges',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textGray,
                    ),
                  ),
                  SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    'Start a challenge to boost your focus and build better habits.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textGrayLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
              child: Text(
                'Active Challenge',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(height: AppTheme.spaceMedium),
            
            // Current Challenge Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: EdgeInsets.all(AppTheme.spaceMedium),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: challengeProvider.isChallengeActive 
                    ? Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        width: 2,
                      )
                    : null,
                  boxShadow: challengeProvider.isChallengeActive 
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentChallenge.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: AppTheme.spaceSmall),
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 16,
                                color: AppTheme.textGray,
                              ),
                              const SizedBox(width: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  key: ValueKey(currentChallenge.activeParticipantsCount),
                                  '${currentChallenge.activeParticipantsCount} participants',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (challengeProvider.remainingSeconds > 0) ...[
                            SizedBox(height: AppTheme.spaceSmall),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                key: ValueKey(challengeProvider.remainingSeconds),
                                'Time remaining: ${challengeProvider.timeRemaining}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: AppTheme.spaceMedium),
                    // Challenge icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LiveFocusTimeCardState extends State<_LiveFocusTimeCard> {
  late String _displayValue;
  Timer? _updateTimer;
  
  @override
  void initState() {
    super.initState();
    _updateDisplayValue();
    _startLiveUpdates();
  }

  @override
  void didUpdateWidget(_LiveFocusTimeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateDisplayValue();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startLiveUpdates() {
    // Update display every second when timer is running
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && widget.timerProvider.timerState == TimerState.running) {
        setState(() {
          _updateDisplayValue();
        });
      } else if (widget.timerProvider.timerState != TimerState.running) {
        timer.cancel();
        _updateTimer = null;
      }
    });
  }

  void _updateDisplayValue() {
    final timerProvider = widget.timerProvider;
    int totalMinutes = timerProvider.totalFocusMinutesToday;
    
    // If timer is running, add the current session time
    if (timerProvider.timerState == TimerState.running) {
      final sessionMinutes = _getCurrentSessionMinutes(timerProvider);
      totalMinutes += sessionMinutes;
      
      // Ensure we have live updates running
      if (_updateTimer == null || !_updateTimer!.isActive) {
        _startLiveUpdates();
      }
    }
    
    _displayValue = _formatFocusTime(totalMinutes);
  }

  int _getCurrentSessionMinutes(FocusTimerProvider timerProvider) {
    final totalSessionSeconds = _getCurrentModeMinutes(timerProvider) * 60;
    final elapsedSeconds = totalSessionSeconds - timerProvider.remainingSeconds;
    return (elapsedSeconds / 60).floor();
  }

  int _getCurrentModeMinutes(FocusTimerProvider timerProvider) {
    return timerProvider.focusMode == FocusMode.pomodoro ? 25 : 60;
  }

  String _formatFocusTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FocusTimerProvider>(
      builder: (context, timerProvider, child) {
        final theme = Theme.of(context);
        final isActive = timerProvider.timerState == TimerState.running;
        
        // Update display value with latest data
        _updateDisplayValue();
        
        // Start live updates if timer is active and we don't have them running
        if (isActive && (_updateTimer == null || !_updateTimer!.isActive)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startLiveUpdates();
          });
        }

        return Container(
          padding: EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isActive ? AppTheme.primaryTeal.withValues(alpha: 0.5) : AppTheme.borderNavy,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Focus Time\nToday',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textGray,
                      height: 1.3,
                    ),
                  ),
                  if (isActive) ...[
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: AppTheme.spaceSmall),
              Text(
                _displayValue,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppTheme.primaryTeal : null,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 4),
                Text(
                  'Session in progress',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color? color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.borderNavy,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textGray,
              height: 1.3,
            ),
          ),
          SizedBox(height: AppTheme.spaceSmall),
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color?.withValues(alpha: 0.8) ?? AppTheme.textGrayLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const _BottomNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderNavy,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: AppTheme.spaceSmall,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => context.go('/dashboard'),
              ),
              _NavItem(
                icon: Icons.emoji_events_outlined,
                selectedIcon: Icons.emoji_events,
                label: 'Challenges',
                isSelected: currentIndex == 1,
                onTap: () => context.go('/challenge-setup'),
              ),
              _NavItem(
                icon: Icons.workspace_premium_outlined,
                selectedIcon: Icons.workspace_premium,
                label: 'Rewards',
                isSelected: currentIndex == 2,
                onTap: () => context.go('/rewards'),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: 'Stats',
                isSelected: currentIndex == 3,
                onTap: () => context.go('/analytics'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spaceSmall,
          vertical: AppTheme.spaceXSmall,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? AppTheme.primaryTeal : AppTheme.textGray,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? AppTheme.primaryTeal : AppTheme.textGray,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            SizedBox(height: AppTheme.spaceSmall),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayTasksSection extends StatelessWidget {
  final TaskProvider taskProvider;
  
  const _TodayTasksSection({required this.taskProvider});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayTasks = taskProvider.todayTasks;
    final overdueTasks = taskProvider.overdueTasks;
    final smartSuggestions = taskProvider.getSmartTaskSuggestions(limit: 3);
    
    if (todayTasks.isEmpty && overdueTasks.isEmpty && smartSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Today\'s Focus',
                style: theme.textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/tasks'),
                child: const Text('View All'),
              ),
            ],
          ),
          
          SizedBox(height: AppTheme.spaceMedium),
          
          // Quick Add Task Button
          InkWell(
            onTap: () => _showQuickAddTask(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Container(
              padding: EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.primary.withAlpha(76),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_task,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    'Add a task for today',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: AppTheme.spaceMedium),
          
          // Overdue tasks (priority)
          if (overdueTasks.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(25),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: Colors.red.withAlpha(76),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                      SizedBox(width: AppTheme.spaceSmall),
                      Text(
                        'Overdue Tasks (${overdueTasks.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spaceSmall),
                  ...overdueTasks.take(2).map((task) => _TaskItemWidget(
                    task: task,
                    taskProvider: taskProvider,
                    showOverdue: true,
                  )),
                  if (overdueTasks.length > 2)
                    Padding(
                      padding: EdgeInsets.only(top: AppTheme.spaceSmall),
                      child: Text(
                        '+${overdueTasks.length - 2} more overdue tasks',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.withAlpha(204),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: AppTheme.spaceMedium),
          ],
          
          // Today's tasks
          if (todayTasks.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.today, color: AppTheme.primary, size: 20),
                      SizedBox(width: AppTheme.spaceSmall),
                      Text(
                        'Due Today (${todayTasks.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spaceSmall),
                  ...todayTasks.take(3).map((task) => _TaskItemWidget(
                    task: task,
                    taskProvider: taskProvider,
                  )),
                ],
              ),
            ),
            SizedBox(height: AppTheme.spaceMedium),
          ],
          
          // Smart suggestions
          if (smartSuggestions.isNotEmpty && todayTasks.length < 3) ...[
            Container(
              padding: EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withAlpha(25),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.primaryTeal.withAlpha(76),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppTheme.primaryTeal, size: 20),
                      SizedBox(width: AppTheme.spaceSmall),
                      Text(
                        'Suggested Tasks',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spaceSmall),
                  ...smartSuggestions.take(3 - todayTasks.length).map((task) => _TaskItemWidget(
                    task: task,
                    taskProvider: taskProvider,
                    isSuggestion: true,
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _showQuickAddTask(BuildContext context) {
    // Simple task creation for now - you can enhance this later
    context.go('/tasks');
  }
}

// Simple task card for dashboard preview
class _TaskItemWidget extends StatelessWidget {
  final Task task;
  final TaskProvider taskProvider;
  final bool showOverdue;
  final bool isSuggestion;
  
  const _TaskItemWidget({
    required this.task,
    required this.taskProvider,
    this.showOverdue = false,
    this.isSuggestion = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spaceSmall),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: task.isCompleted,
            onChanged: (_) => taskProvider.toggleTaskCompletion(task.id),
            shape: const CircleBorder(),
            activeColor: AppTheme.primary,
          ),
          
          // Task content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(task.priorityEmoji),
                    SizedBox(width: AppTheme.spaceXSmall),
                    Expanded(
                      child: Text(
                        task.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: task.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                          color: task.isCompleted 
                              ? AppTheme.textGray 
                              : (showOverdue ? Colors.red : null),
                        ),
                      ),
                    ),
                    Text(task.tagEmoji),
                  ],
                ),
                
                if (task.estimatedMinutes != null || task.dueDate != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (task.estimatedMinutes != null) ...[
                        Icon(Icons.timer, size: 12, color: AppTheme.textGray),
                        Text(
                          ' ${task.estimatedMinutes}m',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                      if (task.dueDate != null && task.estimatedMinutes != null)
                        Text(' • ', style: TextStyle(color: AppTheme.textGray)),
                      if (showOverdue)
                        Text(
                          'Overdue',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else if (task.isDueToday)
                        Text(
                          'Due today',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // XP reward
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spaceSmall,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              '+${task.xpReward}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetractableFocusButton extends StatefulWidget {
  @override
  State<_RetractableFocusButton> createState() => _RetractableFocusButtonState();
}

class _RetractableFocusButtonState extends State<_RetractableFocusButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.8, 0), // Mostly hidden to the right
      end: const Offset(0, 0), // Fully visible
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Auto-expand on startup, then collapse after 4 seconds
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _expand();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() {
      _isExpanded = true;
    });
    _controller.forward();
    
    // Auto-collapse after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isExpanded) {
        _collapse();
      }
    });
  }

  void _collapse() {
    setState(() {
      _isExpanded = false;
    });
    _controller.reverse();
  }

  void _toggle() {
    if (_isExpanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: () {
          if (_isExpanded) {
            context.go('/focus-timer');
          } else {
            _toggle();
          }
        },
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF00D96F),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D96F).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Start Focus Session',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}