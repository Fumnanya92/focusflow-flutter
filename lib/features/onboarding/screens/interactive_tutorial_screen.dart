import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/services/tutorial_service.dart';

class InteractiveTutorialScreen extends StatefulWidget {
  const InteractiveTutorialScreen({super.key});

  @override
  State<InteractiveTutorialScreen> createState() => _InteractiveTutorialScreenState();
}

class _InteractiveTutorialScreenState extends State<InteractiveTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Set<int> _completedSteps = <int>{}; // Track completed demo steps

  @override
  void initState() {
    super.initState();
    
    // Check if returning from a demo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      final stepParam = uri.queryParameters['step'];
      if (stepParam != null) {
        final step = int.tryParse(stepParam);
        if (step != null && step < _tutorialSteps.length) {
          _currentPage = step;
          _completedSteps.add(step); // Mark as completed
          _pageController.animateToPage(
            step,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          setState(() {});
        }
      }
    });
  }

  final List<TutorialStep> _tutorialSteps = [
    TutorialStep(
      icon: Icons.spa,
      title: 'Welcome to FocusFlow!',
      description: 'Ready to boost your productivity? Let\'s take a quick tour of the key features.',
      actionText: 'Start Tour',
      color: AppTheme.primary,
    ),
    TutorialStep(
      icon: Icons.block,
      title: 'Smart App Blocking',
      description: 'Block distracting apps during focus sessions. Tap "Try It" to see the app selection screen.',
      actionText: 'Try It',
      color: Colors.red,
      demoAction: DemoAction.appBlocking,
    ),
    TutorialStep(
      icon: Icons.timer,
      title: 'Focus Timer',
      description: 'Use Pomodoro (25 min) or Deep Focus (60 min) modes. Tap to start a quick demo timer.',
      actionText: 'Try It',
      color: Colors.orange,
      demoAction: DemoAction.focusTimer,
    ),
    TutorialStep(
      icon: Icons.task_alt,
      title: 'Daily Tasks',
      description: 'Plan your day and track completion. Try adding a sample task to see how it works.',
      actionText: 'Try It',
      color: Colors.blue,
      demoAction: DemoAction.tasks,
    ),
    TutorialStep(
      icon: Icons.analytics,
      title: 'Analytics & Insights',
      description: 'Track your productivity with detailed analytics and progress reports.',
      actionText: 'View',
      color: Colors.purple,
      demoAction: DemoAction.analytics,
    ),
    TutorialStep(
      icon: Icons.emoji_events,
      title: 'Gamification',
      description: 'Earn XP, unlock badges, and compete on leaderboards. Stay motivated!',
      actionText: 'View',
      color: Colors.green,
      demoAction: DemoAction.rewards,
    ),
    TutorialStep(
      icon: Icons.celebration,
      title: 'You\'re All Set!',
      description: 'Ready to start your productivity journey? You can always access help from Settings.',
      actionText: 'Get Started',
      color: AppTheme.accent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header with skip button
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Interactive Tutorial',
                    style: theme.textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      _skipTutorial();
                    },
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _tutorialSteps.length,
                backgroundColor: isDark 
                  ? AppTheme.borderDark 
                  : AppTheme.borderLight,
                valueColor: AlwaysStoppedAnimation<Color>(_tutorialSteps[_currentPage].color),
              ),
            ),

            // Tutorial content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _tutorialSteps.length,
                itemBuilder: (context, index) {
                  final step = _tutorialSteps[index];
                  return _buildTutorialPage(step, index);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: AppTheme.spaceSmall),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _tutorialSteps.length - 1) {
                          _completeTutorial();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tutorialSteps[_currentPage].color,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _currentPage == _tutorialSteps.length - 1 
                          ? 'Complete Tutorial' 
                          : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialPage(TutorialStep step, int index) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              size: 60,
              color: step.color,
            ),
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Title
          Text(
            step.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: step.color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spaceMedium),

          // Description
          Text(
            step.description,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Interactive demo button (if available)
          if (step.demoAction != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _completedSteps.contains(index) 
                    ? AppTheme.success.withValues(alpha: 0.5)
                    : step.color.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                color: _completedSteps.contains(index)
                  ? AppTheme.success.withValues(alpha: 0.1)
                  : step.color.withValues(alpha: 0.05),
              ),
              child: Column(
                children: [
                  Icon(
                    _completedSteps.contains(index) ? Icons.check_circle : Icons.touch_app,
                    color: _completedSteps.contains(index) ? AppTheme.success : step.color,
                    size: 32,
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    _completedSteps.contains(index) 
                      ? '✓ Explored!' 
                      : 'Interactive Demo Available',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: step.color,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  ElevatedButton(
                    onPressed: () => _handleDemoAction(step.demoAction!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: step.color,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(step.actionText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
          ],

          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _tutorialSteps.length,
              (dotIndex) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotIndex == index
                      ? step.color
                      : step.color.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDemoAction(DemoAction action) {
    // Mark current step as completed
    setState(() {
      _completedSteps.add(_currentPage);
    });
    
    switch (action) {
      case DemoAction.appBlocking:
        context.go('/app-selection?returnTo=/interactive-tutorial&step=$_currentPage');
        break;
      case DemoAction.focusTimer:
        context.go('/focus-timer?returnTo=/interactive-tutorial&step=$_currentPage');
        break;
      case DemoAction.tasks:
        context.go('/tasks?returnTo=/interactive-tutorial&step=$_currentPage');
        break;
      case DemoAction.analytics:
        context.go('/analytics?returnTo=/interactive-tutorial&step=$_currentPage');
        break;
      case DemoAction.rewards:
        context.go('/rewards?returnTo=/interactive-tutorial&step=$_currentPage');
        break;
    }
  }

  void _skipTutorial() {
    _showSkipConfirmation();
  }

  void _showSkipConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Tutorial?'),
        content: const Text(
          'Are you sure you want to skip the tutorial? You can always access help from the Settings menu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Tutorial'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeTutorial();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _completeTutorial() async {
    await TutorialService.markTutorialCompleted();
    if (mounted) {
      // Check if user has explored all demo features
      final demoStepsCount = _tutorialSteps.where((step) => step.demoAction != null).length;
      final exploredCount = _completedSteps.length;
      
      if (exploredCount >= demoStepsCount && exploredCount > 0) {
        // User explored features, go to main dashboard
        context.go('/dashboard');
      } else {
        // Show completion dialog and then go to dashboard
        TutorialService.showTutorialCompletionDialog(context);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/dashboard');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final String actionText;
  final Color color;
  final DemoAction? demoAction;

  TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionText,
    required this.color,
    this.demoAction,
  });
}

enum DemoAction {
  appBlocking,
  focusTimer,
  tasks,
  analytics,
  rewards,
}