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

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'FocusFlow',
      applicationVersion: '1.0.0',
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
