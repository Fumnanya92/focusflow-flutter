import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _blockNotifications = true;
  bool _focusReminders = true;
  bool _achievementNotifications = true;
  String _selectedTheme = 'light';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _blockNotifications = prefs.getBool('block_notifications') ?? true;
      _focusReminders = prefs.getBool('focus_reminders') ?? true;
      _achievementNotifications = prefs.getBool('achievement_notifications') ?? true;
      _selectedTheme = prefs.getString('selected_theme') ?? 'light';
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: ListView(
        children: [
          // Profile Section
          if (authProvider.currentUser != null)
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text(authProvider.currentUser?.userMetadata?['name'] ?? 'User'),
              subtitle: Text(authProvider.currentUser?.email ?? 'No email'),
            ),

          const Divider(),

          // Settings Items
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showNotificationSettings(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Apps'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.go('/app-selection');
            },
          ),

          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showThemeDialog(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Tutorials & Help'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showTutorialOptions(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAboutDialog(context);
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.error),
            ),
            onTap: () {
              authProvider.logout();
            },
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('App Block Notifications'),
              subtitle: const Text('Get notified when apps are blocked'),
              value: _blockNotifications,
              onChanged: (value) {
                setState(() {
                  _blockNotifications = value;
                });
                _savePreference('block_notifications', value);
              },
            ),
            SwitchListTile(
              title: const Text('Focus Reminders'),
              subtitle: const Text('Reminders to start focus sessions'),
              value: _focusReminders,
              onChanged: (value) {
                setState(() {
                  _focusReminders = value;
                });
                _savePreference('focus_reminders', value);
              },
            ),
            SwitchListTile(
              title: const Text('Achievement Notifications'),
              subtitle: const Text('Celebrate your focus achievements'),
              value: _achievementNotifications,
              onChanged: (value) {
                setState(() {
                  _achievementNotifications = value;
                });
                _savePreference('achievement_notifications', value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                _selectedTheme == 'light' ? Icons.check_circle : Icons.circle_outlined,
                color: _selectedTheme == 'light' ? Colors.blue : null,
              ),
              title: const Text('Light Theme'),
              onTap: () {
                setState(() {
                  _selectedTheme = 'light';
                });
                _savePreference('selected_theme', 'light');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme preference saved')),
                );
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(
                _selectedTheme == 'dark' ? Icons.check_circle : Icons.circle_outlined,
                color: _selectedTheme == 'dark' ? Colors.blue : null,
              ),
              title: const Text('Dark Theme'),
              onTap: () {
                setState(() {
                  _selectedTheme = 'dark';
                });
                _savePreference('selected_theme', 'dark');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme preference saved')),
                );
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(
                _selectedTheme == 'system' ? Icons.check_circle : Icons.circle_outlined,
                color: _selectedTheme == 'system' ? Colors.blue : null,
              ),
              title: const Text('System Default'),
              onTap: () {
                setState(() {
                  _selectedTheme = 'system';
                });
                _savePreference('selected_theme', 'system');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Theme preference saved')),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTutorialOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: AppTheme.primary),
                const SizedBox(width: AppTheme.spaceSmall),
                const Text(
                  'Tutorials & Help',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            ListTile(
              leading: const Icon(Icons.play_circle, color: AppTheme.primary),
              title: const Text('Interactive Tutorial'),
              subtitle: const Text('Complete walkthrough with live demos'),
              onTap: () {
                Navigator.pop(context);
                context.go('/interactive-tutorial');
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.dashboard, color: AppTheme.accent),
              title: const Text('Dashboard Tour'),
              subtitle: const Text('Quick highlights of main features'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to dashboard and trigger showcase
                context.go('/dashboard');
                // The showcase will automatically start if not completed
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.refresh, color: AppTheme.success),
              title: const Text('Reset All Tutorials'),
              subtitle: const Text('Start fresh as a new user'),
              onTap: () {
                Navigator.pop(context);
                _resetTutorials();
              },
            ),

            ListTile(
              leading: const Icon(Icons.help, color: AppTheme.textSecondary),
              title: const Text('App Features'),
              subtitle: const Text('Learn about all FocusFlow features'),
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _resetTutorials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tutorial_completed');
      await prefs.remove('dashboard_tutorial_completed');
      await prefs.remove('app_blocking_tutorial_completed');
      await prefs.remove('focus_timer_tutorial_completed');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tutorials reset! You can now see tutorials again.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error resetting tutorials'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('FocusFlow Features'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem('🚫 App Blocking', 'Block distracting apps during focus sessions'),
              _buildHelpItem('⏰ Focus Timer', 'Pomodoro and Deep Focus modes with progress tracking'),
              _buildHelpItem('✅ Task Management', 'Daily task planning and completion tracking'),
              _buildHelpItem('📊 Analytics', 'Detailed productivity insights and progress reports'),
              _buildHelpItem('🎮 Gamification', 'Earn XP, unlock badges, and track streaks'),
              _buildHelpItem('🏆 Rewards', 'Celebrate achievements and milestones'),
              _buildHelpItem('📱 Phone Down', 'Challenge yourself to put your phone down'),
              _buildHelpItem('⚙️ Settings', 'Customize notifications, themes, and preferences'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'FocusFlow',
      applicationVersion: '1.0.0+1', // Must match pubspec.yaml version
      applicationIcon: const Icon(
        Icons.center_focus_strong,
        size: 64,
        color: AppTheme.primary,
      ),
      children: [
        const Text(
          'FocusFlow helps you stay focused by blocking distracting apps during your work sessions. Build better habits and achieve your goals with our gamified focus system.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('• Block distracting apps during focus time'),
        const Text('• Earn points and achievements'),
        const Text('• Track your progress with analytics'),
        const Text('• Customize blocking schedules'),
        const Text('• Grace periods for urgent tasks'),
        const SizedBox(height: 16),
        const Text(
          'Stay focused, stay productive!',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
