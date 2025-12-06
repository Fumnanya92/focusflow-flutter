import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../core/supabase_helpers.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  String? _selectedMotivation;
  int _dailyGoalMinutes = 60;

  final List<Map<String, dynamic>> _motivations = [
    {
      'id': 'focus',
      'icon': Icons.psychology,
      'title': 'I want to focus more',
      'description': 'Reduce distractions and improve concentration',
    },
    {
      'id': 'scroll',
      'icon': Icons.phone_android,
      'title': 'I want to stop scrolling',
      'description': 'Break the endless scroll habit',
    },
    {
      'id': 'present',
      'icon': Icons.people,
      'title': 'I want to be more present',
      'description': 'Stay engaged with friends and family',
    },
    {
      'id': 'productive',
      'icon': Icons.trending_up,
      'title': 'I want to be more productive',
      'description': 'Accomplish more in less time',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalize'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/permissions'),
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
                      'What brings you here?',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      'Select your main motivation. This helps us personalize your experience.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.textGreen : AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceLarge),

                    // Motivation Cards
                    ..._motivations.map((motivation) {
                      final isSelected = _selectedMotivation == motivation['id'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
                        child: _MotivationCard(
                          icon: motivation['icon'],
                          title: motivation['title'],
                          description: motivation['description'],
                          isSelected: isSelected,
                          isDark: isDark,
                          onTap: () {
                            setState(() {
                              _selectedMotivation = motivation['id'];
                            });
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: AppTheme.spaceLarge),

                    // Daily Goal Section
                    Text(
                      'Set Your Daily Focus Goal',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      'How many minutes do you want to spend in focused work each day?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.textGreen : AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceLarge),

                    // Goal Display
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceLarge),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: AppTheme.primary.withAlpha((0.3 * 255).round()),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$_dailyGoalMinutes',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            'minutes per day',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isDark ? AppTheme.textWhite : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceLarge),

                    // Slider
                    Slider(
                      value: _dailyGoalMinutes.toDouble(),
                      min: 15,
                      max: 180,
                      divisions: 33,
                      activeColor: AppTheme.primary,
                      label: '$_dailyGoalMinutes min',
                      onChanged: (value) {
                        setState(() {
                          _dailyGoalMinutes = value.toInt();
                        });
                      },
                    ),

                    // Quick Presets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _PresetButton(
                          label: '30 min',
                          value: 30,
                          isSelected: _dailyGoalMinutes == 30,
                          onTap: () {
                            setState(() {
                              _dailyGoalMinutes = 30;
                            });
                          },
                        ),
                        _PresetButton(
                          label: '60 min',
                          value: 60,
                          isSelected: _dailyGoalMinutes == 60,
                          onTap: () {
                            setState(() {
                              _dailyGoalMinutes = 60;
                            });
                          },
                        ),
                        _PresetButton(
                          label: '90 min',
                          value: 90,
                          isSelected: _dailyGoalMinutes == 90,
                          onTap: () {
                            setState(() {
                              _dailyGoalMinutes = 90;
                            });
                          },
                        ),
                        _PresetButton(
                          label: '120 min',
                          value: 120,
                          isSelected: _dailyGoalMinutes == 120,
                          onTap: () {
                            setState(() {
                              _dailyGoalMinutes = 120;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.spaceXLarge),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMotivation != null
                      ? () async {
                          // Check if user is authenticated first
                          final prefs = await SharedPreferences.getInstance();
                          final hasAuth = supabase.auth.currentUser != null;
                          
                          if (!hasAuth) {
                            // Redirect to signup if not authenticated
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please create an account to continue'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              context.go('/signup');
                            }
                            return;
                          }
                          
                          // Save onboarding completion
                          await prefs.setBool('onboarding_completed', true);
                          await prefs.setString('user_motivation', _selectedMotivation!);
                          await prefs.setInt('daily_goal_minutes', _dailyGoalMinutes);
                          
                          if (context.mounted) {
                            context.go('/dashboard');
                          }
                        }
                      : null,
                  child: const Text('Complete Setup'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _MotivationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withAlpha((0.2 * 255).round())
                    : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? AppTheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXSmall),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.backgroundDark : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
