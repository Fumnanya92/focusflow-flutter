import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../core/services/tutorial_service.dart';
import '../../focus/providers/focus_timer_provider.dart';
import '../../blocking/providers/app_blocking_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../widgets/gamification_stats_card.dart';

class DashboardShowcaseWrapper extends StatefulWidget {
  final Widget child;

  const DashboardShowcaseWrapper({
    super.key,
    required this.child,
  });

  @override
  State<DashboardShowcaseWrapper> createState() => _DashboardShowcaseWrapperState();
}

class _DashboardShowcaseWrapperState extends State<DashboardShowcaseWrapper> {
  final GlobalKey _focusCardKey = GlobalKey();
  final GlobalKey _blockingCardKey = GlobalKey();
  final GlobalKey _tasksCardKey = GlobalKey();
  final GlobalKey _statsCardKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _quickActionsKey = GlobalKey();
  
  // Track completed showcase explorations
  final Set<String> _exploredCards = <String>{};
  String? _currentlyExploring;

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 [SHOWCASE] DashboardShowcaseWrapper initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExploredCards();
      _loadCurrentExploring();
      _checkAndStartTutorial();
      _checkForReturnFromExploration();
    });
  }

  void _checkForReturnFromExploration() {
    // Check if user is returning from exploration
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_currentlyExploring != null && mounted) {
        debugPrint('🎯 [EXPLORATION] User returned from exploring: $_currentlyExploring');
        _markAsExplored(_currentlyExploring!);
        _currentlyExploring = null; // Clear current exploration
        _saveCurrentExploring();
        
        // Check if all main cards have been explored
        await _checkExplorationComplete();
      }
    });
  }

  void _checkAndStartTutorial() async {
    // Wait for the widget to be built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tutorialCompleted = await TutorialService.isDashboardTutorialCompleted();
      // Only show tutorial for truly new users (not on every app start)
      if (!tutorialCompleted && mounted) {
        // Add a small delay to let the dashboard load first
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _startDashboardTutorial();
        }
      }
    });
  }

  void _startDashboardTutorial() {
    ShowCaseWidget.of(context).startShowCase([
      _focusCardKey,
      _blockingCardKey,
      _tasksCardKey,
      _statsCardKey,
      _quickActionsKey,
      _settingsKey,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: TutorialService.isDashboardTutorialCompleted(),
      builder: (context, snapshot) {
        debugPrint('🎯 [SHOWCASE] Tutorial completion check - hasData: ${snapshot.hasData}, data: ${snapshot.data}');
        
        // If tutorial is completed, show plain main dashboard
        if (snapshot.hasData && snapshot.data == true) {
          debugPrint('🎯 [SHOWCASE] Tutorial completed - showing plain MainDashboardScreen');
          return widget.child;
        }
        
        debugPrint('🎯 [SHOWCASE] Tutorial not completed - showing with showcase wrapper');
        // If tutorial not completed, show with showcase wrapper
        return ShowCaseWidget(
          onStart: (index, key) {
            debugPrint('Showcase started at index $index with key $key');
          },
          onComplete: (index, key) {
            if (index == 5) { // Last showcase item
              TutorialService.markDashboardTutorialCompleted();
              _showDashboardTutorialComplete();
            }
          },
          onFinish: () {
            // This is called when user finishes or skips the entire showcase
            TutorialService.markDashboardTutorialCompleted();
            // The wrapper will now hide the showcase and show main dashboard
            if (mounted) {
              setState(() {}); // Trigger rebuild to hide showcase
            }
          },
          blurValue: 1,
          builder: (context) => _buildDashboardWithShowcase(),
        );
      },
    );
  }

  Widget _buildDashboardWithShowcase() {
    return Consumer4<FocusTimerProvider, AppBlockingProvider, AuthProvider, TaskProvider>(
      builder: (context, timerProvider, blockingProvider, authProvider, taskProvider, child) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with showcase
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
                        const SizedBox(width: AppTheme.spaceSmall),
                        Showcase(
                          key: _settingsKey,
                          title: 'Settings & Profile',
                          description: 'Access app settings, profile, and logout from here. You can also restart tutorials anytime!',
                          targetShapeBorder: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings,
                              size: 28,
                              color: AppTheme.textGrayLight,
                            ),
                            onPressed: () {
                              context.go('/settings');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Focus Session Card with showcase
                  Showcase(
                    key: _focusCardKey,
                    title: 'Focus Timer',
                    description: 'Start focus sessions here! Choose between Pomodoro (25 min) or Deep Focus (60 min). Tap to try it!',
                    targetBorderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
                      child: _buildFocusSessionCard(context, timerProvider),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceMedium),

                  // App Blocking Card with showcase
                  Showcase(
                    key: _blockingCardKey,
                    title: 'App Blocking Control',
                    description: 'Monitor which apps are blocked and control your blocking sessions. This is where you stay focused!',
                    targetBorderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
                      child: _buildAppBlockingCard(context, blockingProvider),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceMedium),

                  // Tasks Card with showcase
                  Showcase(
                    key: _tasksCardKey,
                    title: 'Daily Tasks',
                    description: 'Plan your day and track your progress. Complete tasks to earn XP and maintain your productivity streak!',
                    targetBorderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
                      child: _buildTasksCard(context, taskProvider),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceMedium),

                  // Gamification Stats with showcase
                  Showcase(
                    key: _statsCardKey,
                    title: 'Your Progress',
                    description: 'Track your XP, level, and streaks. The more you focus and complete tasks, the higher you level up!',
                    targetBorderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
                      child: GamificationStatsCard(),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceMedium),

                  // Quick Actions with showcase
                  Showcase(
                    key: _quickActionsKey,
                    title: 'Quick Actions',
                    description: 'Access all major features quickly from here. Analytics, Challenges, and more!',
                    targetBorderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
                      child: _buildQuickActionsCard(context),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceMedium * 2),
                ],
              ),
            ),
          ),
          floatingActionButton: _buildTutorialFAB(),
        );
      },
    );
  }

  Widget _buildTutorialFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        _showTutorialMenu();
      },
      backgroundColor: AppTheme.primary,
      icon: const Icon(Icons.help_outline, color: Colors.white),
      label: const Text('Help', style: TextStyle(color: Colors.white)),
    );
  }

  void _showTutorialMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tutorial Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ListTile(
              leading: const Icon(Icons.play_circle, color: AppTheme.primary),
              title: const Text('Restart Dashboard Tour', style: TextStyle(color: AppTheme.textWhite)),
              subtitle: const Text('Replay the dashboard highlights', style: TextStyle(color: AppTheme.textGray)),
              onTap: () {
                Navigator.pop(context);
                _startDashboardTutorial();
              },
            ),
            ListTile(
              leading: const Icon(Icons.school, color: AppTheme.accent),
              title: const Text('Full Interactive Tutorial', style: TextStyle(color: AppTheme.textWhite)),
              subtitle: const Text('Complete tutorial with all features', style: TextStyle(color: AppTheme.textGray)),
              onTap: () {
                Navigator.pop(context);
                context.go('/interactive-tutorial');
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppTheme.primary),
              title: const Text('Complete Dashboard Tutorial', style: TextStyle(color: AppTheme.textWhite)),
              subtitle: const Text('Mark dashboard tutorial as completed', style: TextStyle(color: AppTheme.textGray)),
              onTap: () {
                Navigator.pop(context);
                _completeDashboardTutorial();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: AppTheme.success),
              title: const Text('Reset All Tutorials', style: TextStyle(color: AppTheme.textWhite)),
              subtitle: const Text('Start fresh as a new user', style: TextStyle(color: AppTheme.textGray)),
              onTap: () {
                Navigator.pop(context);
                _resetTutorials();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _completeDashboardTutorial() async {
    await TutorialService.markDashboardTutorialCompleted();
    if (mounted) {
      setState(() {}); // Trigger rebuild to switch to plain dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard tutorial completed! No more highlights.'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _resetTutorials() async {
    await TutorialService.resetAllTutorials();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All tutorials reset! Restart the app to see tutorials again.'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _showDashboardTutorialComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppTheme.success,
              size: 28,
            ),
            SizedBox(width: AppTheme.spaceSmall),
            Text(
              'Dashboard Tour Complete!',
              style: TextStyle(color: AppTheme.success),
            ),
          ],
        ),
        content: const Text(
          'Great! You now know how to navigate the main dashboard. The highlights will no longer appear. You can restart tours anytime from Settings.',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Just rebuild to show main dashboard without showcase
              if (mounted) {
                setState(() {}); // Trigger rebuild
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Using FocusFlow!'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildFocusSessionCard(BuildContext context, FocusTimerProvider timerProvider) {
    final theme = Theme.of(context);
    final isExplored = _exploredCards.contains('focus');
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 28),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  timerProvider.isRunning ? 'Focus Session Active' : 'Ready to Focus',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isExplored) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Explored!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          if (timerProvider.isRunning) ...[
            Text(
              '${timerProvider.remainingMinutes}:${timerProvider.remainingSeconds.toString().padLeft(2, '0')}',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            LinearProgressIndicator(
              value: timerProvider.progress,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ] else ...[
            Text(
              'Start your focus session now',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ElevatedButton(
              onPressed: () {
                // Store that user is exploring focus
                _setCurrentExploring('focus');
                context.go('/focus-timer');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E3A8A),
              ),
              child: const Text('Start Focus Session'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBlockingCard(BuildContext context, AppBlockingProvider blockingProvider) {
    final theme = Theme.of(context);
    final isExplored = _exploredCards.contains('blocking');
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: blockingProvider.isMonitoring 
            ? [Colors.red.shade800, Colors.red.shade600]
            : [Colors.grey.shade800, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                blockingProvider.isMonitoring ? Icons.block : Icons.security,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  blockingProvider.isMonitoring ? 'Blocking Active' : 'Ready to Block',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isExplored) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Explored!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            blockingProvider.isMonitoring
              ? '${blockingProvider.blockedApps.length} apps blocked • ${blockingProvider.blocksToday} blocks today'
              : 'Set up app blocking to stay focused',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          ElevatedButton(
            onPressed: () {
              // Store that user is exploring blocking
              _setCurrentExploring('blocking');
              context.go('/app-selection');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: blockingProvider.isMonitoring ? Colors.red : Colors.grey.shade800,
            ),
            child: Text(blockingProvider.isMonitoring ? 'Manage Blocking' : 'Set Up Blocking'),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard(BuildContext context, TaskProvider taskProvider) {
    final theme = Theme.of(context);
    final completedToday = taskProvider.getCompletedTasksToday();
    final totalToday = taskProvider.getTodayTasks().length;
    final isExplored = _exploredCards.contains('tasks');
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt, color: Colors.white, size: 28),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  'Daily Tasks',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isExplored) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Explored!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            totalToday > 0 
              ? '$completedToday/$totalToday completed today'
              : 'No tasks planned for today',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          ElevatedButton(
            onPressed: () {
              // Store that user is exploring tasks
              _setCurrentExploring('tasks');
              context.go('/tasks');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF059669),
            ),
            child: Text(totalToday > 0 ? 'View Tasks' : 'Plan Your Day'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionButton(
                icon: Icons.analytics,
                label: 'Analytics',
                onTap: () => context.go('/analytics'),
              ),
              _buildQuickActionButton(
                icon: Icons.emoji_events,
                label: 'Rewards',
                onTap: () => context.go('/rewards'),
              ),
              _buildQuickActionButton(
                icon: Icons.phone_android,
                label: 'Phone Down',
                onTap: () => context.go('/phone-down-setup'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textGrayLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _setCurrentExploring(String cardType) {
    debugPrint('🎯 [EXPLORATION] User starting to explore: $cardType');
    _currentlyExploring = cardType;
    _saveCurrentExploring();
  }

  void _saveCurrentExploring() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentlyExploring != null) {
      await prefs.setString('current_exploring', _currentlyExploring!);
    } else {
      await prefs.remove('current_exploring');
    }
  }

  void _loadCurrentExploring() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString('current_exploring');
    if (current != null) {
      _currentlyExploring = current;
      debugPrint('🎯 [EXPLORATION] Restored current exploration: $_currentlyExploring');
    }
  }

  void _markAsExplored(String cardType) {
    debugPrint('🎯 [EXPLORATION] Adding $cardType to explored cards');
    setState(() {
      _exploredCards.add(cardType);
    });
    debugPrint('🎯 [EXPLORATION] Explored cards now: $_exploredCards');
    _saveExploredCards();
  }

  void _saveExploredCards() async {
    debugPrint('🎯 [EXPLORATION] Saving explored cards: $_exploredCards');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dashboard_explored_cards', _exploredCards.toList());
  }
  
  void _loadExploredCards() async {
    debugPrint('🎯 [EXPLORATION] Loading explored cards from storage');
    final prefs = await SharedPreferences.getInstance();
    final savedCards = prefs.getStringList('dashboard_explored_cards') ?? [];
    debugPrint('🎯 [EXPLORATION] Loaded cards: $savedCards');
    setState(() {
      _exploredCards.addAll(savedCards);
    });
    debugPrint('🎯 [EXPLORATION] Current explored cards after loading: $_exploredCards');
    // Check completion after loading
    _checkExplorationComplete();
  }
  
  Future<void> _checkExplorationComplete() async {
    final requiredExplorations = {'focus', 'blocking', 'tasks'};
    debugPrint('🎯 [EXPLORATION] Checking completion - required: $requiredExplorations, current: $_exploredCards');
    if (requiredExplorations.every((card) => _exploredCards.contains(card))) {
      debugPrint('🎯 [EXPLORATION] All features explored! Completing tutorial...');
      // User has explored all main features, complete the tutorial
      await Future.delayed(const Duration(milliseconds: 1000));
      await TutorialService.markDashboardTutorialCompleted();
      if (mounted) {
        _showExplorationComplete();
      }
    }
  }

  void _showExplorationComplete() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 All features explored! Returning to main dashboard...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to main dashboard after showing the message
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/main-dashboard');
        }
      });
    }
  }
}