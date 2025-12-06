import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TaskDialog extends StatefulWidget {
  final Task? task; // null for creating new task
  final bool isEditing;

  const TaskDialog({
    super.key,
    this.task,
    this.isEditing = false,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskTag _selectedTag = TaskTag.personal;
  int? _estimatedMinutes;
  int _xpReward = 10;
  List<TaskReminder> _reminders = [];
  
  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _initializeFromTask(widget.task!);
    }
  }
  
  void _initializeFromTask(Task task) {
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _notesController.text = task.notes ?? '';
    _selectedPriority = task.priority;
    _selectedTag = task.tag;
    _estimatedMinutes = task.estimatedMinutes;
    _xpReward = task.xpReward;
    _reminders = [...task.reminders];
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.isEditing;
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusMedium),
                  topRight: Radius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add_task,
                    color: AppTheme.primary,
                  ),
                  SizedBox(width: AppTheme.spaceSmall),
                  Text(
                    isEditing ? 'Edit Task' : 'Create New Task',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spaceMedium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task Title *',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a task title';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: AppTheme.spaceMedium),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 2,
                      ),
                      
                      SizedBox(height: AppTheme.spaceMedium),
                      
                      // Priority and Tag row
                      Row(
                        children: [
                          // Priority
                          Expanded(
                            child: DropdownButtonFormField<TaskPriority>(
                              initialValue: _selectedPriority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                prefixIcon: Icon(Icons.flag),
                              ),
                              items: TaskPriority.values.map((priority) {
                                return DropdownMenuItem(
                                  value: priority,
                                  child: Text(
                                    '${_getPriorityEmoji(priority)} ${_getPriorityName(priority)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPriority = value!;
                                });
                              },
                            ),
                          ),
                          
                          SizedBox(width: AppTheme.spaceMedium),
                          
                          // Tag
                          Expanded(
                            child: DropdownButtonFormField<TaskTag>(
                              initialValue: _selectedTag,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: TaskTag.values.map((tag) {
                                return DropdownMenuItem(
                                  value: tag,
                                  child: Text(
                                    '${_getTagEmoji(tag)} ${_getTagName(tag)}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedTag = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: AppTheme.spaceMedium),
                      
                      // Estimated time and XP reward
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Estimated Minutes',
                                prefixIcon: Icon(Icons.timer),
                                suffixText: 'min',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _estimatedMinutes = int.tryParse(value);
                              },
                              initialValue: _estimatedMinutes?.toString(),
                            ),
                          ),
                          
                          SizedBox(width: AppTheme.spaceMedium),
                          
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'XP Reward',
                                prefixIcon: Icon(Icons.star),
                                suffixText: 'XP',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _xpReward = int.tryParse(value) ?? 10;
                              },
                              initialValue: _xpReward.toString(),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: AppTheme.spaceMedium),
                      
                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action buttons
            Container(
              padding: EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.withAlpha(76)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 56), // Override infinite width
                    ),
                    child: Text(isEditing ? 'Update Task' : 'Create Task'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;
    
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    if (widget.isEditing && widget.task != null) {
      // Update existing task
      final updatedTask = widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        priority: _selectedPriority,
        tag: _selectedTag,
        estimatedMinutes: _estimatedMinutes,
        xpReward: _xpReward,
        reminders: _reminders,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );
      taskProvider.updateTask(updatedTask);
    } else {
      // Create new task
      final newTask = Task(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        priority: _selectedPriority,
        tag: _selectedTag,
        estimatedMinutes: _estimatedMinutes,
        xpReward: _xpReward,
        reminders: _reminders,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );
      taskProvider.addTask(newTask);
    }
    
    Navigator.of(context).pop();
  }
  
  String _getPriorityEmoji(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return '🔴';
      case TaskPriority.medium:
        return '🟡';
      case TaskPriority.low:
        return '🟢';
    }
  }
  
  String _getPriorityName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }
  
  String _getTagEmoji(TaskTag tag) {
    switch (tag) {
      case TaskTag.work:
        return '💼';
      case TaskTag.personal:
        return '👤';
      case TaskTag.goal:
        return '🎯';
      case TaskTag.health:
        return '💪';
      case TaskTag.learning:
        return '📚';
      case TaskTag.other:
        return '📋';
    }
  }
  
  String _getTagName(TaskTag tag) {
    switch (tag) {
      case TaskTag.work:
        return 'Work';
      case TaskTag.personal:
        return 'Personal';
      case TaskTag.goal:
        return 'Goal';
      case TaskTag.health:
        return 'Health';
      case TaskTag.learning:
        return 'Learning';
      case TaskTag.other:
        return 'Other';
    }
  }
}