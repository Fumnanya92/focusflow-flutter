import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/optimized_hybrid_database_service.dart';
import 'core/services/database_migration_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/focus/providers/focus_timer_provider.dart';
import 'features/tasks/providers/task_provider.dart';
import 'features/challenges/providers/challenge_provider.dart';
import 'features/blocking/providers/app_blocking_provider.dart';
import 'features/blocking/widgets/blocking_listener.dart';
import 'features/rewards/providers/rewards_provider.dart';
import 'features/gamification/providers/gamification_provider.dart';
// Global navigator key for accessing navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();






void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Preserve the splash screen until app is fully loaded
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());
  
  try {
    // Initialize Database Migrations FIRST
    debugPrint('🔧 Running database migrations...');
    await DatabaseMigrationService.initialize();
    debugPrint('✅ Database migrations completed');
    
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
    
    // Initialize Optimized Hybrid Database Service AFTER Supabase
    debugPrint('🔧 Initializing OptimizedHybridDatabaseService...');
    await OptimizedHybridDatabaseService.initializeService();
    debugPrint('✅ OptimizedHybridDatabaseService initialized');
    
    // Task reminders are now handled natively in AppBlockingService.kt;
    
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
void _setupNavigationChannel() {
  const platform = MethodChannel('app.focusflow/navigation');
  
  platform.setMethodCallHandler((call) async {
    if (call.method == 'navigateTo') {
      final route = call.arguments as String;
      if (navigatorKey.currentContext != null) {
        final context = navigatorKey.currentContext!;
        context.go(route);
      }
    }
  });
}

class FocusFlowApp extends StatefulWidget {
  const FocusFlowApp({super.key});

  @override
  State<FocusFlowApp> createState() => _FocusFlowAppState();
}

class _FocusFlowAppState extends State<FocusFlowApp> {
  @override
  void initState() {
    super.initState();
    _setupNavigationChannel();
    // Remove splash screen after the app is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

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
          ChangeNotifierProvider(create: (_) => AppBlockingProvider()),
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
