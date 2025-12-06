import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';

class DailyTaskPromptScreen extends StatefulWidget {
  const DailyTaskPromptScreen({super.key});

  @override
  State<DailyTaskPromptScreen> createState() => _DailyTaskPromptScreenState();
}

class _DailyTaskPromptScreenState extends State<DailyTaskPromptScreen> {
  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleStartDay() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    final tasks = <Task>[];
    for (var controller in _controllers) {
      if (controller.text.trim().isNotEmpty) {
        tasks.add(Task(title: controller.text.trim()));
      }
    }

    if (tasks.isNotEmpty) {
      await taskProvider.setDailyTasks(tasks);
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Spacer
              const Spacer(),

              // Header
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What will you accomplish today?',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      'Focus on what truly matters. List three main goals for today.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.textGreen : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spaceLarge),

              // Task Input Fields
              ..._controllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spaceSmall,
                          left: AppTheme.spaceSmall,
                        ),
                        child: Text(
                          'Task ${index + 1}',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: _getHintText(index),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.surfaceDark
                              : AppTheme.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(
                              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(
                              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(AppTheme.spaceMedium),
                        ),
                        onSubmitted: (_) {
                          // Move to next field or submit
                          if (index < _controllers.length - 1) {
                            FocusScope.of(context).nextFocus();
                          } else {
                            _handleStartDay();
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: AppTheme.spaceLarge),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleStartDay,
                  child: const Text('Start My Focused Day'),
                ),
              ),

              const SizedBox(height: AppTheme.spaceSmall),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    context.go('/dashboard');
                  },
                  child: Text(
                    'I\'ll do this later',
                    style: TextStyle(
                      color: isDark ? AppTheme.textGreen : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spaceMedium),
            ],
          ),
        ),
      ),
    );
  }

  String _getHintText(int index) {
    switch (index) {
      case 0:
        return 'e.g., Finish the project proposal';
      case 1:
        return 'e.g., Go for a 30-minute walk';
      case 2:
        return 'e.g., Read one chapter of my book';
      default:
        return 'Enter your task';
    }
  }
}
