import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/task_provider.dart';
import '../../blocking/providers/app_blocking_provider.dart';

class TaskReminderOverlay extends StatefulWidget {
  final String title;
  final String message;
  final bool hasTasksToday;
  final int taskCount;
  final VoidCallback? onDismiss;

  const TaskReminderOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.hasTasksToday,
    required this.taskCount,
    this.onDismiss,
  });

  @override
  State<TaskReminderOverlay> createState() => _TaskReminderOverlayState();
}

class _TaskReminderOverlayState extends State<TaskReminderOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _animateOut() async {
    await _animationController.reverse();
  }
  
  void _handlePlanTasks() async {
    await _animateOut();
    if (mounted) {
      widget.onDismiss?.call();
      context.go('/tasks');
    }
  }
  
  void _handleSnooze() async {
    await _animateOut();
    if (mounted) {
      widget.onDismiss?.call();
      final appBlockingProvider = Provider.of<AppBlockingProvider>(context, listen: false);
      appBlockingProvider.snoozeTaskReminder();
    }
  }
  
  void _handleViewTasks() async {
    await _animateOut();
    if (mounted) {
      widget.onDismiss?.call();
      context.go('/tasks');
    }
  }
  
  void _handleDismiss() async {
    await _animateOut();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final completedCount = taskProvider.completedTasks.length;
    final totalCount = taskProvider.activeTasks.length + taskProvider.completedTasks.length;
    
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.4),
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF8FAFF),
                          Color(0xFFE8F4FD),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 2,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Close button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: _handleDismiss,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Animated emoji
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1000),
                            tween: Tween<double>(begin: 0.8, end: 1.1),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryTeal.withValues(alpha: 0.1),
                                        AppTheme.primary.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '📋',
                                      style: TextStyle(fontSize: 36),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Title
                          Text(
                            widget.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Message
                          Text(
                            widget.hasTasksToday 
                              ? 'Amazing! You have ${widget.taskCount} task${widget.taskCount > 1 ? 's' : ''} planned today. How are they going?'
                              : widget.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF666666),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Action buttons
                          if (!widget.hasTasksToday) ...[
                            // Plan Tasks Button
                            _ActionButton(
                              icon: Icons.add_task,
                              label: 'Plan My Tasks',
                              description: 'Set up your daily goals',
                              onTap: _handlePlanTasks,
                              isPrimary: true,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Snooze Button
                            _ActionButton(
                              icon: Icons.schedule,
                              label: 'Ask me in 10 minutes',
                              description: 'Remind me later',
                              onTap: _handleSnooze,
                              isPrimary: false,
                            ),
                          ] else ...[
                            // View Tasks Button
                            _ActionButton(
                              icon: Icons.checklist,
                              label: 'View My Tasks',
                              description: 'Check your progress',
                              onTap: _handleViewTasks,
                              isPrimary: true,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Progress indicator
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$completedCount/$totalCount tasks completed today',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.isPrimary
        ? const LinearGradient(
            colors: [AppTheme.primary, Color(0xFF16C454)],
          )
        : LinearGradient(
            colors: [
              AppTheme.primaryTeal.withValues(alpha: 0.1),
              AppTheme.primaryTeal.withValues(alpha: 0.05),
            ],
          );
    
    final iconColor = widget.isPrimary ? Colors.white : AppTheme.primaryTeal;
    final textColor = widget.isPrimary ? Colors.white : const Color(0xFF1A1A1A);
    final borderColor = widget.isPrimary ? null : AppTheme.primaryTeal.withValues(alpha: 0.2);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _scaleController.forward(),
            onTapUp: (_) => _scaleController.reverse(),
            onTapCancel: () => _scaleController.reverse(),
            onTap: widget.onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                border: borderColor != null 
                  ? Border.all(color: borderColor, width: 1.5)
                  : null,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: iconColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}