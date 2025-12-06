import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../providers/app_blocking_provider.dart';
import '../models/blocked_app_model.dart';

class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _enableTimeSchedule = false; // Will be loaded from provider in initializeSettings
  
  // Search and filtering
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _installedApps = [];
  List<Map<String, dynamic>> _filteredApps = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  
  late Map<String, bool> _selectedApps;

  @override
  void initState() {
    super.initState();
    _selectedApps = {};
    _loadInstalledApps();
    _initializeSettings();
    
    // Listen to search changes
    _searchController.addListener(_filterApps);
  }
  
  Future<void> _loadInstalledApps() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final blockingProvider = Provider.of<AppBlockingProvider>(context, listen: false);
      final installedApps = await blockingProvider.getInstalledApps();
      
      setState(() {
        _installedApps = installedApps.map((app) => {
          'name': app['appName']?.toString() ?? 'Unknown App',
          'package': app['packageName']?.toString() ?? '',
          'category': _categorizeApp(app['packageName']?.toString() ?? ''),
          'isSystemApp': app['isSystemApp'] ?? false,
        }).where((app) => 
          app['package']!.isNotEmpty && 
          !app['package']!.startsWith('com.android.') &&
          !(app['isSystemApp'] as bool)
        ).toList();
        
        // Sort by app name
        _installedApps.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
        
        _filteredApps = List.from(_installedApps);
        _isLoading = false;
      });
      
      // Initialize selected apps based on existing blocked apps
      for (var app in _installedApps) {
        _selectedApps[app['package']] = false;
      }
      
      // Mark currently blocked apps as selected
      for (var blockedApp in blockingProvider.blockedApps) {
        if (_selectedApps.containsKey(blockedApp.packageName)) {
          _selectedApps[blockedApp.packageName] = blockedApp.isBlocked;
        }
      }
      
    } catch (e) {
      debugPrint('Error loading installed apps: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  String _categorizeApp(String packageName) {
    if (packageName.contains('facebook') || 
        packageName.contains('instagram') || 
        packageName.contains('twitter') || 
        packageName.contains('tiktok') || 
        packageName.contains('snapchat') ||
        packageName.contains('reddit') ||
        packageName.contains('pinterest')) {
      return 'Social Media';
    }
    if (packageName.contains('whatsapp') || 
        packageName.contains('telegram') || 
        packageName.contains('discord') ||
        packageName.contains('messenger')) {
      return 'Messaging';
    }
    if (packageName.contains('youtube') || 
        packageName.contains('netflix') || 
        packageName.contains('spotify') ||
        packageName.contains('music')) {
      return 'Entertainment';
    }
    if (packageName.contains('game') || 
        packageName.contains('play')) {
      return 'Games';
    }
    return 'Other';
  }
  
  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApps = _installedApps.where((app) {
        final matchesSearch = query.isEmpty || 
          app['name'].toString().toLowerCase().contains(query) ||
          app['package'].toString().toLowerCase().contains(query);
        
        final matchesCategory = _selectedCategory == 'All' || 
          app['category'] == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }
  
  void _initializeSettings() {
    // Load existing time schedule settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final blockingProvider = Provider.of<AppBlockingProvider>(context, listen: false);
      
      setState(() {
        // Always load the current enableTimeSchedule state
        _enableTimeSchedule = blockingProvider.enableTimeSchedule;
        
        // Load time schedule settings if they exist
        if (blockingProvider.blockingStartTime != null && 
            blockingProvider.blockingEndTime != null) {
          _startTime = blockingProvider.blockingStartTime!;
          _endTime = blockingProvider.blockingEndTime!;
        }
      });
    });
  }
  
  void _showAddCustomAppDialog() async {
    final packageController = TextEditingController();
    final nameController = TextEditingController();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: packageController,
              decoration: const InputDecoration(
                labelText: 'Package Name*',
                hintText: 'e.g. com.example.app',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'App Name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Package name is required. You can find it in the app\'s Play Store URL or using app info apps.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final packageName = packageController.text.trim();
              final displayName = nameController.text.trim();
              
              if (packageName.isNotEmpty) {
                Navigator.pop(context, {
                  'package': packageName,
                  'name': displayName.isNotEmpty ? displayName : packageName,
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      await _addCustomApp(result['package']!, result['name']!);
    }
  }
  
  Future<void> _addCustomApp(String packageName, String displayName) async {
    try {
      final blockingProvider = Provider.of<AppBlockingProvider>(context, listen: false);
      await blockingProvider.addCustomApp(packageName, displayName);
      
      // Add to installed apps for this session
      if (mounted) {
        setState(() {
          _installedApps.add({
            'name': displayName,
            'package': packageName,
            'category': 'Custom',
            'isSystemApp': false,
          });
          _selectedApps[packageName] = true;  // Auto-select the newly added app
          _filterApps(); // Refresh filtered list
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $displayName to blocked apps'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
        );
      }
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppTheme.surfaceDark,
              hourMinuteTextColor: AppTheme.textWhite,
              dialHandColor: AppTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveSettings() {
    final blockingProvider = Provider.of<AppBlockingProvider>(context, listen: false);
    
    // Update blocked status for each app instead of clearing all
    for (var app in _installedApps) {
      final isSelected = _selectedApps[app['package']] == true;
      final existingApp = blockingProvider.blockedApps.firstWhere(
        (blocked) => blocked.packageName == app['package'],
        orElse: () => BlockedApp(packageName: '', appName: ''),
      );
      
      if (isSelected) {
        if (existingApp.packageName.isEmpty) {
          // Add new blocked app
          blockingProvider.addBlockedApp(app['package'], app['name']);
        } else if (!existingApp.isBlocked) {
          // Enable blocking for existing app
          blockingProvider.toggleAppBlocking(app['package']);
        }
      } else {
        if (existingApp.packageName.isNotEmpty && existingApp.isBlocked) {
          // Disable blocking but don't remove the app
          blockingProvider.toggleAppBlocking(app['package']);
        }
      }
    }
    
    // Set or disable time schedule
    if (_enableTimeSchedule) {
      blockingProvider.setBlockingSchedule(_startTime, _endTime);
    } else {
      blockingProvider.disableTimeSchedule();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_enableTimeSchedule 
          ? 'Blocking schedule set: ${_startTime.format(context)} - ${_endTime.format(context)}'
          : 'Apps will be blocked 24/7 (no time schedule)'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    if (Navigator.canPop(context)) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedCount = _selectedApps.values.where((selected) => selected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Blocking Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: selectedCount > 0 ? _saveSettings : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: selectedCount > 0 ? AppTheme.primary : AppTheme.textGray,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Permissions warning banner
              Consumer<AppBlockingProvider>(
                builder: (context, blockingProvider, child) {
                  if (!blockingProvider.hasRequiredPermissions) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(AppTheme.spaceMedium),
                      padding: const EdgeInsets.all(AppTheme.spaceMedium),
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: Colors.orange.withAlpha((0.3 * 255).round())),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Permissions Required',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'App blocking won\'t work without Usage Stats permission.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/permissions'),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Fix', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Header with selected count
              Container(
                width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Apps to Block',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Row(
                    children: [
                      Icon(
                        Icons.apps_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$selectedCount apps selected',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Time Schedule Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(AppTheme.spaceMedium),
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: _enableTimeSchedule 
                    ? AppTheme.primary.withAlpha((0.3 * 255).round())
                    : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Time Schedule',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Switch(
                        value: _enableTimeSchedule,
                        onChanged: (value) {
                          setState(() {
                            _enableTimeSchedule = value;
                          });
                          
                          // Immediately save the toggle state to provider
                          final blockingProvider = Provider.of<AppBlockingProvider>(context, listen: false);
                          if (value) {
                            blockingProvider.setBlockingSchedule(_startTime, _endTime);
                          } else {
                            blockingProvider.disableTimeSchedule();
                          }
                        },
                        activeThumbColor: AppTheme.primary,
                      ),
                    ],
                  ),
                  if (_enableTimeSchedule) ...[
                    const SizedBox(height: AppTheme.spaceMedium),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceMedium),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Set Blocking Hours',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Apps will only be blocked during these hours. Outside this time, you can use them freely.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeButton(
                            label: 'Start Time',
                            time: _startTime,
                            onTap: () => _selectTime(true),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spaceMedium),
                        Icon(
                          Icons.arrow_forward,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spaceMedium),
                        Expanded(
                          child: _TimeButton(
                            label: 'End Time',
                            time: _endTime,
                            onTap: () => _selectTime(false),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Search Bar
            Container(
              margin: const EdgeInsets.all(AppTheme.spaceMedium),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search apps...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ),

            // Category Filter
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  'All',
                  'Social Media',
                  'Messaging',
                  'Entertainment',
                  'Games',
                  'Other',
                ].map((category) {
                  final isSelected = _selectedCategory == category;
                  return Container(
                    margin: const EdgeInsets.only(right: AppTheme.spaceSmall),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _filterApps();
                        });
                      },
                      selectedColor: AppTheme.primary.withValues(alpha: 0.3),
                      checkmarkColor: AppTheme.primary,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppTheme.spaceMedium),

            // Loading State
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLarge),
                child: const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppTheme.spaceMedium),
                    Text('Loading installed apps...'),
                  ],
                ),
              )
            // Apps List
            else if (_filteredApps.isEmpty && !_isLoading)
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLarge),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: AppTheme.textGray,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    Text(
                      _searchController.text.isNotEmpty
                          ? 'No apps found matching "${_searchController.text}"'
                          : 'No apps found in this category',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
                itemCount: _filteredApps.length,
                itemBuilder: (context, index) {
                  final app = _filteredApps[index];
                  final packageName = app['package']!;
                  final appName = app['name']!;
                  final category = app['category']!;
                  final isSelected = _selectedApps[packageName] ?? false;

                  return _AppListItem(
                    appName: appName,
                    packageName: packageName,
                    category: category,
                    isSelected: isSelected,
                    isDark: isDark,
                    onToggle: (value) {
                      setState(() {
                        _selectedApps[packageName] = value;
                      });
                    },
                  );
                },
              ),

            // Add Custom App Section
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(AppTheme.spaceMedium),
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Custom App',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  Text(
                    'Know the package name of an app you want to block? Add it here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  ElevatedButton.icon(
                    onPressed: _showAddCustomAppDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Custom App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Info
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(AppTheme.spaceMedium),
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
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: Text(
                      'Select apps from your device to block. Use search and categories to find apps quickly.',
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
    );
  }
}

class _AppListItem extends StatelessWidget {
  final String appName;
  final String packageName;
  final String category;
  final bool isSelected;
  final bool isDark;
  final Function(bool) onToggle;

  const _AppListItem({
    required this.appName,
    required this.packageName,
    required this.category,
    required this.isSelected,
    required this.isDark,
    required this.onToggle,
  });

  IconData _getAppIcon() {
    // Map popular apps to Material Icons
    if (packageName.contains('instagram')) return Icons.camera_alt;
    if (packageName.contains('tiktok')) return Icons.music_note;
    if (packageName.contains('twitter')) return Icons.tag;
    if (packageName.contains('facebook')) return Icons.facebook;
    if (packageName.contains('snapchat')) return Icons.photo_camera;
    if (packageName.contains('reddit')) return Icons.forum;
    if (packageName.contains('pinterest')) return Icons.push_pin;
    if (packageName.contains('linkedin')) return Icons.work;
    if (packageName.contains('youtube')) return Icons.play_circle;
    return Icons.apps;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isSelected
              ? AppTheme.primary
              : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          // App Icon
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withAlpha((0.2 * 255).round())
                  : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              _getAppIcon(),
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              size: 24,
            ),
          ),

          const SizedBox(width: AppTheme.spaceMedium),

          // App Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),

          // Toggle Switch
          Switch(
            value: isSelected,
            onChanged: onToggle,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  final bool isDark;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  color: AppTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    time.format(context),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to change',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textGray.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
