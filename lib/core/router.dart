import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_helpers.dart';
import '../features/onboarding/screens/welcome_screen.dart';
import '../features/onboarding/screens/permissions_screen.dart';
import '../features/onboarding/screens/personalization_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';

import '../features/dashboard/screens/main_dashboard_screen.dart';
import '../features/focus/screens/focus_timer_screen.dart';
import '../features/tasks/screens/tasks_screen.dart';
import '../features/tasks/screens/daily_task_prompt_screen.dart';
import '../features/challenges/screens/phone_down_setup_screen.dart';
import '../features/challenges/screens/phone_down_active_screen.dart';
import '../features/analytics/screens/analytics_screen.dart';
import '../features/rewards/screens/rewards_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/blocking/screens/app_selection_screen.dart';



final GoRouter appRouter = GoRouter(
  initialLocation: '/welcome',
  errorBuilder: (context, state) {
    // Handle navigation errors gracefully
    return const MainDashboardScreen();
  },
  redirect: (context, state) async {
    // Check authentication and onboarding status
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      // Get current auth state from Supabase directly
      final hasStoredAuth = supabase.auth.currentUser != null;
      
      debugPrint('🔄 [ROUTER] Current location: ${state.matchedLocation}');
      debugPrint('🔄 [ROUTER] Has auth: $hasStoredAuth');
      debugPrint('🔄 [ROUTER] Onboarding completed: $onboardingCompleted');
      
      // Auth-required routes (main app functionality)
      final authRequiredRoutes = [
        '/dashboard', '/focus-timer', '/tasks', '/analytics', 
        '/rewards', '/challenge-setup', '/challenge-active',
        '/app-selection', '/settings', '/daily-task-prompt'
      ];
      
      final isAuthRequired = authRequiredRoutes.any((route) => 
          state.matchedLocation.startsWith(route));
      
      // Public routes that don't require auth
      final publicRoutes = [
        '/welcome', '/permissions', '/personalization', 
        '/login', '/signup', '/forgot-password'
      ];
      
      final isPublicRoute = publicRoutes.contains(state.matchedLocation) ||
          state.matchedLocation.startsWith('/blocking-overlay/');
      
      // 1. If trying to access auth-required route without authentication
      if (isAuthRequired && !hasStoredAuth) {
        debugPrint('🔄 [ROUTER] Auth required but not authenticated, redirecting to login');
        return '/login';
      }
      
      // 2. If authenticated but onboarding not completed, allow onboarding
      if (hasStoredAuth && !onboardingCompleted && !isPublicRoute) {
        debugPrint('🔄 [ROUTER] Authenticated but onboarding not completed, redirecting to personalization');
        return '/personalization'; // Skip to final onboarding step
      }
      
      // 3. If onboarding completed and trying to access onboarding pages, redirect to dashboard
      if (onboardingCompleted && hasStoredAuth &&
          (state.matchedLocation == '/welcome' || 
           state.matchedLocation == '/permissions' || 
           state.matchedLocation == '/personalization')) {
        debugPrint('🔄 [ROUTER] Onboarding completed and authenticated, redirecting to dashboard');
        return '/dashboard';
      }
      
      // 4. Check critical permissions for authenticated users
      if (hasStoredAuth && onboardingCompleted) {
        // Check if essential permissions are granted
        final hasUsageStats = prefs.getBool('usage_stats_granted') ?? false;
        final hasOverlay = prefs.getBool('overlay_granted') ?? false;
        
        // If trying to access main app without essential permissions, redirect to permissions
        if (isAuthRequired && (!hasUsageStats || !hasOverlay)) {
          debugPrint('🔄 [ROUTER] Missing critical permissions, redirecting to /permissions');
          return '/permissions';
        }
      }
      
      // 5. If no auth and not on public route, redirect to login
      if (!hasStoredAuth && !isPublicRoute) {
        return '/login';
      }
      
    } catch (e) {
      // If there's an error, redirect to login for safety
      debugPrint('🔄 [ROUTER] Error in redirect logic: $e');
      if (state.matchedLocation != '/login' && state.matchedLocation != '/welcome') {
        return '/login';
      }
    }
    
    debugPrint('🔄 [ROUTER] No redirect needed, staying on ${state.matchedLocation}');
    return null;
  },
  routes: [
    // Onboarding Flow
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/permissions',
      name: 'permissions',
      builder: (context, state) => const PermissionsScreen(),
    ),
    GoRoute(
      path: '/personalization',
      name: 'personalization',
      builder: (context, state) => const PersonalizationScreen(),
    ),
    
    // Authentication
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    
    // Blocking overlay route


    
    // Main Dashboard
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const MainDashboardScreen(),
    ),
    
    // Focus Timer
    GoRoute(
      path: '/focus-timer',
      name: 'focus-timer',
      builder: (context, state) => const FocusTimerScreen(),
    ),
    
    // Tasks
    GoRoute(
      path: '/tasks',
      name: 'tasks',
      builder: (context, state) => const TasksScreen(),
    ),
    GoRoute(
      path: '/daily-task-prompt',
      name: 'daily-task-prompt',
      builder: (context, state) => const DailyTaskPromptScreen(),
    ),
    
    // Phone-Down Challenge
    GoRoute(
      path: '/challenge-setup',
      name: 'challenge-setup',
      builder: (context, state) => const PhoneDownSetupScreen(),
    ),
    GoRoute(
      path: '/challenge-active',
      name: 'challenge-active',
      builder: (context, state) => const PhoneDownActiveScreen(),
    ),
    
    // Analytics
    GoRoute(
      path: '/analytics',
      name: 'analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    
    // Rewards
    GoRoute(
      path: '/rewards',
      name: 'rewards',
      builder: (context, state) => const RewardsScreen(),
    ),
    
    // Streak Detail (redirect to dashboard for now)
    GoRoute(
      path: '/streak-detail',
      name: 'streak-detail', 
      redirect: (context, state) => '/dashboard',
    ),
    
    // App Blocking
    GoRoute(
      path: '/app-selection',
      name: 'app-selection',
      builder: (context, state) => const AppSelectionScreen(),
    ),

    
    // Settings
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),

  ],
);
