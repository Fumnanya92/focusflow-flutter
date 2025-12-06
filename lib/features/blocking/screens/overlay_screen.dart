import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_blocking_provider.dart';
import '../../gamification/providers/gamification_provider.dart';

class OverlayScreen extends StatefulWidget {
  final String appName;

  const OverlayScreen({
    super.key,
    required this.appName,
  });

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  Timer? _gracePeriodTimer;
  int _remainingSeconds = 0;
  bool _hasUsedGracePeriod = false;
  int _currentPoints = 0;
  String _currentMessage = '';

  // Different message for each attempt
  final List<String> _blockingMessages = [
    "🎯 Your focus session is active. Every time you resist adds +2 points!",
    "🌟 Stay strong! You're building discipline that creates success.",
    "🔥 This urge will pass. Your future self will thank you for staying focused.",
    "🏆 Champions choose discipline over distraction. You've got this!",
    "⚡ Redirect this energy into your important work instead.",
    "🎨 Your focus is creating something meaningful right now.",
    "🚀 You're training your brain for peak performance.",
    "💎 Resistance creates resilience. Keep building your mental strength.",
    "🌱 Each 'no' to distraction grows your willpower stronger.",
    "🎪 Break free from the scroll trap. Your goals are waiting."
  ];

  @override
  void initState() {
    super.initState();
    _loadPoints();
    _selectRandomMessage();
    _checkGracePeriodStatus();
  }

  void _loadPoints() async {
    // Get current points from provider
    final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);
    setState(() {
      _currentPoints = gamificationProvider.totalPoints;
    });
  }

  void _selectRandomMessage() {
    // Select a different message each time they try to open the app
    final now = DateTime.now().millisecondsSinceEpoch;
    final messageIndex = now % _blockingMessages.length;
    _currentMessage = _blockingMessages[messageIndex];
  }

  void _checkGracePeriodStatus() async {
    final blockingProvider = Provider.of<AppBlockingProvider>(context, listen: false);
    final appPackage = _getAppPackage(widget.appName);
    final isInGracePeriod = blockingProvider.isInGracePeriod(appPackage);
    
    setState(() {
      _hasUsedGracePeriod = isInGracePeriod;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // BLOCK ALL ATTEMPTS TO CLOSE THIS OVERLAY
        // NO MERCY - USER MUST USE THE PROPER BUTTONS
        // Back button does NOTHING - completely disabled
        debugPrint('🚫 BLOCKED back button attempt - NO ESCAPE');
        
        // CRITICAL FIX: Force the blocked app to close if they try to escape
        final appPkg = _getAppPackage(widget.appName);
        if (appPkg != 'unknown.package') {
          final platform = MethodChannel('com.example.focusflow/app_monitor');
          platform.invokeMethod('closeApp', {'packageName': appPkg}).catchError((e) {
            debugPrint('❌ Error force closing on back attempt: $e');
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
        children: [
          // Blurred Background (using solid color instead of image)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                    colors: [
                    const Color(0xFF112117).withAlpha((0.95 * 255).round()),
                    const Color(0xFF1A3224).withAlpha((0.95 * 255).round()),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                  color: Colors.black.withAlpha((0.3 * 255).round()),
                ),
              ),
            ),
          ),

          // Overlay Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                
                // Main Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Emoji
                      const Text(
                        '🚫',
                        style: TextStyle(fontSize: 96),
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        'Time to Refocus',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      // Dynamic message (different each attempt)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Main blocking message
                            Text(
                              _remainingSeconds > 0
                                  ? '⏰ Grace period: ${_remainingSeconds}s remaining'
                                  : _currentMessage,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                color: _remainingSeconds > 0 
                                    ? const Color(0xFF19E66B)
                                    : Colors.white.withAlpha((0.9 * 255).round()),
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Points display
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.1 * 255).round()),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF19E66B).withAlpha((0.3 * 255).round()),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '⭐',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Current Points: $_currentPoints',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: const Color(0xFF19E66B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Points consequence info
                            Text(
                              _remainingSeconds > 0
                                  ? 'Grace period costs -5 points when used'
                                  : 'Closing app now: +2 points • Emergency unlock: -25 points',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white.withAlpha((0.6 * 255).round()),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Action Buttons
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          children: [
                            // Close App Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Reward user for closing app properly
                                  final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);
                                  final blockingProvider = Provider.of<AppBlockingProvider>(context, listen: false);
                                  final router = GoRouter.of(context);
                                  
                                  await gamificationProvider.awardProperAppClosure();
                                  
                                  // CRITICAL FIX: Force close the blocked app and clear overlay state
                                  final appPackage = _getAppPackage(widget.appName);
                                  if (appPackage != 'unknown.package') {
                                    // Force terminate the blocked app
                                    final platform = MethodChannel('com.example.focusflow/app_monitor');
                                    try {
                                      await platform.invokeMethod('closeApp', {'packageName': appPackage});
                                      debugPrint('🔒 FORCE CLOSED blocked app: $appPackage');
                                    } catch (e) {
                                      debugPrint('❌ Error force closing app: $e');
                                    }
                                  }
                                  
                                  // Clear the blocking state
                                  blockingProvider.clearCurrentlyBlockedApp();
                                  
                                  // Extra delay to prevent rapid clicking/bypassing
                                  await Future.delayed(const Duration(milliseconds: 500));
                                  router.go('/dashboard');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF19E66B),
                                  foregroundColor: const Color(0xFF112117),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: Text(
                                  'Close App',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Give me 2 minutes Button (only if not used)
                            if (!_hasUsedGracePeriod)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _remainingSeconds > 0 ? null : _startGracePeriod,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withAlpha((0.2 * 255).round()),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: Text(
                                    _remainingSeconds > 0 
                                        ? 'Grace period active (${_remainingSeconds}s)'
                                        : 'Give me 2 minutes',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                            if (!_hasUsedGracePeriod)
                              const SizedBox(height: 12),

                            // Emergency Unlock Button
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: _showEmergencyUnlock,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white.withAlpha((0.7 * 255).round()),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  'Emergency Unlock',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
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

  Future<void> _startGracePeriod() async {
    // Get all context-dependent values BEFORE any async operations
    final appPackage = _getAppPackage(widget.appName);
    final blockingProvider = Provider.of<AppBlockingProvider>(context, listen: false);
    final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);
    final router = GoRouter.of(context);
    
    // Deduct 5 points for using grace period
    await gamificationProvider.applyGracePeriodPenalty();
    
    blockingProvider.startGracePeriod(appPackage, minutes: 2);
    
    setState(() {
      _remainingSeconds = 120; // 2 minutes
      _hasUsedGracePeriod = true;
      _currentPoints = gamificationProvider.totalPoints; // Update displayed points
    });

    _gracePeriodTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          timer.cancel();
          _gracePeriodTimer = null;
        }
      }
    });

    // CRITICAL FIX: Don't just close overlay - properly start grace period  
    // (blockProvider already obtained at method start)
    final appPkg = _getAppPackage(widget.appName);
    
    // Start grace period in the provider
    if (appPkg != 'unknown.package') {
      blockingProvider.startGracePeriod(appPkg, minutes: 2);
    }
    
    // Clear overlay state and navigate
    blockingProvider.clearCurrentlyBlockedApp();
    router.go('/dashboard');
  }

  String _getAppPackage(String appName) {
    final packageMap = {
      'Instagram': 'com.instagram.android',
      'TikTok': 'com.zhiliaoapp.musically',
      'X (Twitter)': 'com.twitter.android',
      'Facebook': 'com.facebook.katana',
      'Snapchat': 'com.snapchat.android',
      'Reddit': 'com.reddit.frontpage',
      'Pinterest': 'com.pinterest',
      'LinkedIn': 'com.linkedin.android',
      'YouTube': 'com.google.android.youtube',
      'Messenger': 'com.facebook.orca',
    };
    
    return packageMap[appName] ?? 'unknown.package';
  }

  void _showEmergencyUnlock() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF112117),
        title: Text(
          'Emergency Unlock',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will disable blocking for 30 minutes and deduct 25 points from your current score of $_currentPoints points.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withAlpha((0.8 * 255).round()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use only for genuine emergencies (work calls, family issues, etc.)',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.orange.withAlpha((0.9 * 255).round()),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withAlpha((0.7 * 255).round()),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final blockingProvider = Provider.of<AppBlockingProvider>(context, listen: false);
              final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);
              final appPackage = _getAppPackage(widget.appName);
              
              // Deduct 25 points for emergency unlock (as per your system)
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final router = GoRouter.of(context);
              
              await gamificationProvider.applyEmergencyUnlockPenalty();
              
              blockingProvider.startGracePeriod(appPackage, minutes: 30);
              
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Emergency unlock active for 30 minutes. 25 points deducted. New balance: ${gamificationProvider.totalPoints} points'),
                  backgroundColor: Colors.orange,
                ),
              );
              
              router.go('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Unlock (-25 points)',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gracePeriodTimer?.cancel();
    super.dispose();
  }
}
