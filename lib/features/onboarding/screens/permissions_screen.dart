import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import '../../../core/theme.dart';
import '../../blocking/providers/app_blocking_provider.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  bool _usageStatsGranted = false;
  bool _overlayGranted = false;
  bool _notificationsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Recheck permissions when app returns from settings
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    if (!Platform.isAndroid) return;
    
    try {
      // Check notification permission
      final notificationStatus = await Permission.notification.status;
      
      // Check system alert window (overlay) permission
      final overlayStatus = await Permission.systemAlertWindow.status;
      
      // Check usage stats permission via method channel
      bool usageStatsGranted = false;
      try {
        const platform = MethodChannel('app.focusflow/permissions');
        usageStatsGranted = await platform.invokeMethod('checkUsageStatsPermission') ?? false;
      } catch (e) {
        debugPrint('Could not check usage stats permission: $e');
      }
      
      setState(() {
        _notificationsGranted = notificationStatus.isGranted;
        _overlayGranted = overlayStatus.isGranted;
        _usageStatsGranted = usageStatsGranted;
      });
      
      // Save permission status to SharedPreferences for router checks
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('usage_stats_granted', usageStatsGranted);
      await prefs.setBool('overlay_granted', overlayStatus.isGranted);
      await prefs.setBool('notifications_granted', notificationStatus.isGranted);
      
      // Notify AppBlockingProvider of permission changes
      if (mounted) {
        final blockingProvider = Provider.of<AppBlockingProvider>(context, listen: false);
        blockingProvider.updatePermissionStatus(usageStatsGranted);
      }
      
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
  }

  Future<void> _requestNotifications() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationsGranted = status.isGranted;
    });
    
    if (!status.isGranted) {
      _showPermissionDialog(
        'Notifications',
        'Please enable notifications in Settings to receive focus reminders.',
        () => openAppSettings(),
      );
    }
  }

  Future<void> _requestOverlayPermission() async {
    final status = await Permission.systemAlertWindow.request();
    
    if (status.isGranted) {
      setState(() {
        _overlayGranted = true;
      });
    } else {
      _showPermissionDialog(
        'Display Over Other Apps',
        'Please enable "Display over other apps" permission in Settings to show blocking overlays.',
        () => openAppSettings(),
      );
    }
  }

  Future<void> _requestUsageStatsPermission() async {
    try {
      // Open usage access settings directly
      await _openUsageStatsSettings();
      
      // Show dialog explaining the next steps
      _showPermissionDialog(
        'App Usage Access',
        'Please find FocusFlow in the list and toggle "Permit usage access" ON.',
        () => _openUsageStatsSettings(),
      );
    } catch (e) {
      debugPrint('Error opening usage stats settings: $e');
    }
  }

  Future<void> _openUsageStatsSettings() async {
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('app.focusflow/permissions');
        await platform.invokeMethod('openUsageStatsSettings');
      } catch (e) {
        // Fallback to app settings
        await openAppSettings();
      }
    }
  }

  void _showPermissionDialog(String title, String message, VoidCallback onSettingsPressed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onSettingsPressed();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showAllPermissionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grant Permissions'),
        content: const Text(
          'FocusFlow needs all permissions to work effectively. Please grant each permission by tapping on them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showSkipWarningDialog() {
    final essentialMissing = !_usageStatsGranted || !_overlayGranted;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ App Won\'t Work Properly'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Without essential permissions, FocusFlow cannot:'),
            const SizedBox(height: 12),
            if (!_usageStatsGranted) ...[
              const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('• Detect which apps you\'re using')),
                ],
              ),
              const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('• Block distracting apps')),
                ],
              ),
            ],
            if (!_overlayGranted) ...[
              const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('• Show blocking overlays')),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              essentialMissing 
                ? 'The app blocking feature will NOT work at all.'
                : 'Some features may be limited.',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Grant Permissions'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/personalization');
            },
            child: const Text(
              'Continue Anyway',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allGranted = _usageStatsGranted && _overlayGranted && _notificationsGranted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Enable Permissions',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      'FocusFlow needs these permissions to help you stay focused.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.textGreen : AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceMedium),

                    // Progress indicator
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceMedium),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: allGranted 
                            ? AppTheme.primary.withAlpha((0.5 * 255).round())
                            : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            allGranted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: allGranted ? AppTheme.primary : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: AppTheme.spaceMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  allGranted ? 'All Permissions Granted' : 'Permissions Required',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: allGranted ? AppTheme.primary : null,
                                  ),
                                ),
                                Text(
                                  '${(_notificationsGranted ? 1 : 0) + (_overlayGranted ? 1 : 0) + (_usageStatsGranted ? 1 : 0)}/3 granted',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceLarge),

                    // Permission Cards
                    _PermissionCard(
                      icon: Icons.apps,
                      title: 'App Usage Access',
                      description: 'Monitor which apps you use and for how long.',
                      isGranted: _usageStatsGranted,
                      isDark: isDark,
                      onTap: _requestUsageStatsPermission,
                    ),

                    const SizedBox(height: AppTheme.spaceMedium),

                    _PermissionCard(
                      icon: Icons.visibility,
                      title: 'Display Over Other Apps',
                      description: 'Show interruption screen when you open blocked apps.',
                      isGranted: _overlayGranted,
                      isDark: isDark,
                      onTap: _requestOverlayPermission,
                    ),

                    const SizedBox(height: AppTheme.spaceMedium),

                    _PermissionCard(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      description: 'Receive reminders and motivational nudges.',
                      isGranted: _notificationsGranted,
                      isDark: isDark,
                      onTap: _requestNotifications,
                    ),

                    const SizedBox(height: AppTheme.spaceLarge),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceMedium),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: AppTheme.primary.withAlpha((0.3 * 255).round()),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: AppTheme.spaceMedium),
                          Expanded(
                            child: Text(
                              'Your privacy is important. FocusFlow only uses these permissions locally on your device.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppTheme.textWhite : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: allGranted
                          ? () {
                              context.go('/personalization');
                            }
                          : () {
                              _showAllPermissionsDialog();
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (allGranted) ...[
                            const Icon(Icons.check_circle, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            allGranted ? 'Continue to Setup' : 'Grant All Permissions',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  TextButton(
                    onPressed: () {
                      _showSkipWarningDialog();
                    },
                    child: const Text('Skip for Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isGranted;
  final bool isDark;
  final VoidCallback onTap;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.isDark,
    required this.onTap,
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
          color: isGranted
              ? AppTheme.primary
              : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: isGranted
                  ? AppTheme.primary.withAlpha((0.2 * 255).round())
                  : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              isGranted ? Icons.check : icon,
              color: isGranted ? AppTheme.primary : AppTheme.textSecondary,
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
          const SizedBox(width: AppTheme.spaceSmall),
          if (!isGranted)
            OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
              ),
              child: const Text('Grant'),
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
