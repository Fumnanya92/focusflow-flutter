import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/hybrid_database_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/focus/providers/focus_timer_provider.dart';
import 'features/tasks/providers/task_provider.dart';
import 'features/challenges/providers/challenge_provider.dart';
import 'features/blocking/providers/app_blocking_provider.dart';
import 'features/blocking/widgets/blocking_listener.dart';
import 'features/rewards/providers/rewards_provider.dart';
import 'features/gamification/providers/gamification_provider.dart';
import 'features/tasks/services/task_overlay_service.dart';

// Global navigator key for accessing navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global reference to AppBlockingProvider for task reminder functionality
AppBlockingProvider? _globalAppBlockingProvider;




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive first
    debugPrint('🔧 Initializing LocalStorageService...');
    await LocalStorageService.initialize();
    debugPrint('✅ LocalStorageService initialized');
    
    // Load environment variables
    debugPrint('🔧 Loading environment variables...');
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Environment variables loaded');
    
    // Initialize Supabase BEFORE HybridDatabaseService
    debugPrint('🔧 Initializing Supabase...');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: false, // Set to true only in development
    );
    debugPrint('✅ Supabase initialized');
    
    // Initialize Hybrid Database Service AFTER Supabase
    debugPrint('🔧 Initializing HybridDatabaseService...');
    await HybridDatabaseService.initializeService();
    debugPrint('✅ HybridDatabaseService initialized');
    
    // Setup task reminder navigation channel
    _setupTaskReminderChannel();
    
  } catch (e) {
    debugPrint('Initialization error: $e');
    // Continue with app launch even if some services fail
  }
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const FocusFlowApp());
}

/// Setup method channel for task reminder navigation
void _setupTaskReminderChannel() {
  debugPrint('🔧 Setting up task reminder method channel');
  
  // Initialize the new Flutter-based overlay service
  NavigatorService.setNavigatorKey(navigatorKey);
  TaskOverlayService.initialize();
  const MethodChannel('com.example.focusflow/overlay').setMethodCallHandler((call) async {
    debugPrint('📞 Method channel call received: ${call.method}');
    switch (call.method) {
      case 'taskReminderAction':
        final action = call.arguments['action'] as String?;
        debugPrint('📱 Task reminder action received: $action');
        
        switch (action) {
          case 'open_tasks':
            // Navigate to task planning screen - handle it directly here
            debugPrint('📝 ===== NAVIGATION REQUEST =====');
            debugPrint('📝 Navigating to task planning from task reminder');
            _navigateToTasks();
            debugPrint('📝 ===== END NAVIGATION REQUEST =====');
            break;
            
          case 'ask_me_later':
            // Handle snooze - call AppBlockingProvider method
            debugPrint('⏰ ===== SNOOZE REQUEST =====');
            debugPrint('⏰ User chose to snooze task reminder for 10 minutes');
            _handleTaskReminderSnooze();
            debugPrint('⏰ ===== END SNOOZE REQUEST =====');
            break;
            
          case 'remind_at_end':
            // Handle remind at end of focus time
            debugPrint('🎯 User chose to be reminded at end of focus time');
            _handleRemindAtEnd();
            break;
            
          default:
            debugPrint('❓ Unknown task reminder action: $action');
        }
        break;
        
      case 'navigate_to_tasks':
        // Fallback navigation method
        debugPrint('📝 Fallback navigation to tasks received');
        _navigateToTasks();
        break;
    }
  });
}

/// Navigate to task planning screen
void _navigateToTasks() {
  // Add delay to ensure app is brought to foreground first
  Future.delayed(const Duration(milliseconds: 500), () {
    try {
      // Navigate to existing My Tasks page
      appRouter.go('/tasks');
      debugPrint('✅ Navigation to My Tasks page completed');
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      // Fallback to dashboard if tasks navigation fails
      try {
        appRouter.go('/dashboard');
        debugPrint('✅ Fallback navigation to dashboard completed');
      } catch (fallbackError) {
        debugPrint('❌ Fallback navigation failed: $fallbackError');
      }
    }
  });
}

/// Handle task reminder snooze (ask me in 10 minutes)
void _handleTaskReminderSnooze() {
  debugPrint('⏰ ===== SNOOZE FUNCTIONALITY =====');
  debugPrint('⏰ User chose to snooze task reminder for 10 minutes');
  
  if (_globalAppBlockingProvider != null) {
    debugPrint('⏰ Calling snoozeTaskReminder on AppBlockingProvider');
    _globalAppBlockingProvider!.snoozeTaskReminder();
    debugPrint('⏰ ✅ Snooze request completed - reminder will show again in 10 minutes');
  } else {
    debugPrint('⏰ ❌ Error: AppBlockingProvider not available for snooze');
  }
  
  debugPrint('⏰ ===== END SNOOZE FUNCTIONALITY =====');
}

/// Handle remind at end of focus time
void _handleRemindAtEnd() {
  // Set flag to remind user at end of focus session
  debugPrint('✅ User will be reminded at end of focus time');
}

/// Setup navigation method channel


class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // Show exit confirmation dialog
        final shouldExit = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('🚪 Exit FocusFlow?'),
            content: const Text(
              'Are you sure you want to close FocusFlow?\n\n'
              'This will stop all monitoring and protection.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit App', 
                  style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => RewardsProvider()),
          ChangeNotifierProxyProvider<RewardsProvider, GamificationProvider>(
            create: (context) => GamificationProvider(
              Provider.of<RewardsProvider>(context, listen: false),
            ),
            update: (context, rewards, previous) => previous ?? GamificationProvider(rewards),
          ),
          ChangeNotifierProvider(create: (_) {
            final provider = AppBlockingProvider();
            _globalAppBlockingProvider = provider; // Store global reference
            return provider;
          }),
          ChangeNotifierProxyProvider2<GamificationProvider, AppBlockingProvider, FocusTimerProvider>(
            create: (context) {
              final timer = FocusTimerProvider();
              final gamification = Provider.of<GamificationProvider>(context, listen: false);
              final appBlocking = Provider.of<AppBlockingProvider>(context, listen: false);
              timer.setGamificationProvider(gamification);
              timer.setAppBlockingProvider(appBlocking);
              return timer;
            },
            update: (context, gamification, appBlocking, previous) {
              if (previous != null) {
                previous.setGamificationProvider(gamification);
                previous.setAppBlockingProvider(appBlocking);
                return previous;
              }
              final timer = FocusTimerProvider();
              timer.setGamificationProvider(gamification);
              timer.setAppBlockingProvider(appBlocking);
              return timer;
            },
          ),
          ChangeNotifierProvider(create: (_) => TaskProvider()),
          ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        ],
        child: MaterialApp.router(
          title: 'FocusFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: appRouter,
          key: navigatorKey,
          builder: (context, child) => BlockingListener(
            child: child ?? Container(),
          ),
        ),
      ),
    );
  }
}
