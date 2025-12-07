import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to dashboard instead of exiting app
            context.go('/dashboard');
          },
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
            padding: EdgeInsets.all(AppTheme.spaceMedium),
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
                
                SizedBox(height: AppTheme.spaceMedium),
                
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
            margin: EdgeInsets.all(AppTheme.spaceMedium),
            padding: EdgeInsets.all(AppTheme.spaceMedium),
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
            Icon(
              Icons.task_alt,
              size: 64,
              color: AppTheme.textGray,
            ),
            SizedBox(height: AppTheme.spaceMedium),
            Text(
              'No tasks found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textGray,
              ),
            ),
            SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Start by adding your first task!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textGray,
              ),
            ),
            SizedBox(height: AppTheme.spaceLarge),
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
      padding: EdgeInsets.all(AppTheme.spaceMedium),
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
      padding: EdgeInsets.only(right: AppTheme.spaceSmall),
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
        SizedBox(height: AppTheme.spaceXSmall),
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
      margin: EdgeInsets.only(bottom: AppTheme.spaceMedium),
      color: AppTheme.surfaceDark,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spaceMedium),
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
                        SizedBox(width: AppTheme.spaceXSmall),
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
                      SizedBox(height: AppTheme.spaceXSmall),
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
                      SizedBox(height: AppTheme.spaceXSmall),
                      Row(
                        children: [
                          if (task.estimatedMinutes != null) ...[
                            Icon(Icons.timer, size: 16, color: AppTheme.textGray),
                            SizedBox(width: 4),
                            Text(
                              '${task.estimatedMinutes}m',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                          if (task.dueDate != null && task.estimatedMinutes != null)
                            Text(' • ', style: TextStyle(color: AppTheme.textGray)),
                          if (task.dueDate != null) ...[
                            Icon(Icons.schedule, size: 16, color: AppTheme.textGray),
                            SizedBox(width: 4),
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
                      SizedBox(height: AppTheme.spaceXSmall),
                      Row(
                        children: [
                          Icon(Icons.notifications, size: 16, color: AppTheme.primaryTeal),
                          SizedBox(width: 4),
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
                padding: EdgeInsets.symmetric(
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
            ],
          ),
        ),
      ),
    );
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