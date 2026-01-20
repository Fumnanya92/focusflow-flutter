import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/tutorial_back_button.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../widgets/task_dialog.dart';


class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    
    return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: const TutorialBackButton(
          defaultRoute: '/dashboard',
        ),
        title: Text(
          'Tasks',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddTaskDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            color: AppTheme.surfaceDark,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: AppTheme.backgroundDark,
                    filled: true,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spaceMedium),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedFilter == 'all',
                        onTap: () => setState(() => _selectedFilter = 'all'),
                        count: taskProvider.allTasks.length,
                      ),
                      _FilterChip(
                        label: 'Today',
                        isSelected: _selectedFilter == 'today',
                        onTap: () => setState(() => _selectedFilter = 'today'),
                        count: taskProvider.todayTasks.length,
                      ),
                      _FilterChip(
                        label: 'Overdue',
                        isSelected: _selectedFilter == 'overdue',
                        onTap: () => setState(() => _selectedFilter = 'overdue'),
                        count: taskProvider.overdueTasks.length,
                        isWarning: true,
                      ),
                      _FilterChip(
                        label: 'Completed',
                        isSelected: _selectedFilter == 'completed',
                        onTap: () => setState(() => _selectedFilter = 'completed'),
                        count: taskProvider.completedTasks.length,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Stats Card
          Container(
            margin: const EdgeInsets.all(AppTheme.spaceMedium),
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.check_circle,
                  label: 'Completed',
                  value: '${taskProvider.completedTasks.length}',
                  color: AppTheme.primary,
                ),
                _StatItem(
                  icon: Icons.pending_actions,
                  label: 'Pending',
                  value: '${taskProvider.pendingTasks.length}',
                  color: AppTheme.primaryTeal,
                ),
                _StatItem(
                  icon: Icons.star,
                  label: 'XP Earned',
                  value: '${taskProvider.totalXPEarned}',
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
          
          // Tasks List
          Expanded(
            child: _buildTasksList(taskProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(TaskProvider taskProvider) {
    List<Task> tasks = _getFilteredTasks(taskProvider);
    
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.task_alt,
              size: 64,
              color: AppTheme.textGray,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'No tasks found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textGray,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Start by adding your first task!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGray,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            ElevatedButton(
              onPressed: () => _showAddTaskDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Task'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(
          task: task,
          taskProvider: taskProvider,
          onTap: () => _showEditTaskDialog(context, task),
        );
      },
    );
  }

  List<Task> _getFilteredTasks(TaskProvider taskProvider) {
    List<Task> tasks;
    
    switch (_selectedFilter) {
      case 'today':
        tasks = taskProvider.todayTasks;
        break;
      case 'overdue':
        tasks = taskProvider.overdueTasks;
        break;
      case 'completed':
        tasks = taskProvider.completedTasks;
        break;
      default:
        tasks = taskProvider.allTasks;
    }
    
    if (_searchQuery.isEmpty) return tasks;
    
    return tasks.where((task) =>
        task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (task.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TaskDialog(),
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(task: task),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int count;
  final bool isWarning;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.count,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? Colors.red : AppTheme.primary;
    
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spaceSmall),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: color.withAlpha(50),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : AppTheme.textGray,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: AppTheme.spaceXSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final TaskProvider taskProvider;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.taskProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
      color: AppTheme.surfaceDark,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: task.isCompleted,
                onChanged: (_) => taskProvider.toggleTaskCompletion(task.id),
                shape: const CircleBorder(),
                activeColor: AppTheme.primary,
              ),
              
              // Task content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(task.priorityEmoji),
                        const SizedBox(width: AppTheme.spaceXSmall),
                        Expanded(
                          child: Text(
                            task.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              decoration: task.isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : null,
                              color: task.isCompleted 
                                  ? AppTheme.textGray 
                                  : (task.isOverdue ? Colors.red : null),
                            ),
                          ),
                        ),
                        Text(task.tagEmoji),
                      ],
                    ),
                    
                    if (task.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        task.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textGray,
                          decoration: task.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    if (task.estimatedMinutes != null || task.dueDate != null) ...[
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Row(
                        children: [
                          if (task.estimatedMinutes != null) ...[
                            const Icon(Icons.timer, size: 16, color: AppTheme.textGray),
                            const SizedBox(width: 4),
                            Text(
                              '${task.estimatedMinutes}m',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                          if (task.dueDate != null && task.estimatedMinutes != null)
                            const Text(' • ', style: TextStyle(color: AppTheme.textGray)),
                          if (task.dueDate != null) ...[
                            const Icon(Icons.schedule, size: 16, color: AppTheme.textGray),
                            const SizedBox(width: 4),
                            Text(
                              _formatDueDate(task.dueDate!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: task.isOverdue ? Colors.red : 
                                       task.isDueToday ? AppTheme.primary : AppTheme.textGray,
                                fontWeight: (task.isOverdue || task.isDueToday) ? FontWeight.w600 : null,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    
                    // Reminders
                    if (task.hasPendingReminders) ...[
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Row(
                        children: [
                          const Icon(Icons.notifications, size: 16, color: AppTheme.primaryTeal),
                          const SizedBox(width: 4),
                          Text(
                            'Has reminders',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // XP reward
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  '+${task.xpReward}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // Options menu
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _showDeleteConfirmation(context, task, taskProvider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete Task', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert, color: AppTheme.textGray),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Task task, TaskProvider taskProvider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await taskProvider.deleteTask(task.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" deleted'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
              },
            ),
          ),
        );
      }
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    if (taskDate.isBefore(today)) {
      final days = today.difference(taskDate).inDays;
      return 'Overdue by $days day${days > 1 ? 's' : ''}';
    } else if (taskDate.isAtSameMomentAs(today)) {
      return 'Due today';
    } else if (taskDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return 'Due tomorrow';
    } else {
      final days = taskDate.difference(today).inDays;
      return 'Due in $days day${days > 1 ? 's' : ''}';
    }
  }
}