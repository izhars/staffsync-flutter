import 'package:flutter/material.dart';
import '../models/task_item.dart';

class TaskItemCard extends StatefulWidget {
  final TaskItem task;
  final int index;
  final ValueChanged<TaskItem> onChanged;
  final VoidCallback? onRemove;
  final bool showError;

  const TaskItemCard({
    Key? key,
    required this.task,
    required this.index,
    required this.onChanged,
    this.onRemove,
    this.showError = false,
  }) : super(key: key);

  @override
  State<TaskItemCard> createState() => _TaskItemCardState();
}

class _TaskItemCardState extends State<TaskItemCard> {
  late TaskItem _task;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  bool _hasTitleError = false;
  bool _hasTimeError = false;

  // Color scheme matching parent
  final Color _primaryColor = const Color(0xFF4361EE);
  final Color _secondaryColor = const Color(0xFF3A0CA3);
  final Color _accentColor = const Color(0xFF4CC9F0);
  final Color _errorColor = const Color(0xFFF72585);
  final Color _successColor = const Color(0xFF4CAF50);
  final Color _warningColor = const Color(0xFFFF9800);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF212529);
  final Color _textSecondary = const Color(0xFF6C757D);
  final Color _shadowColor = const Color(0x0D000000);

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description;
    _projectController.text = widget.task.project;
    _timeController.text = widget.task.timeSpent.toString();
    _validateFields();
  }

  @override
  void didUpdateWidget(covariant TaskItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showError != oldWidget.showError) {
      _validateFields();
    }
  }

  void _validateFields() {
    setState(() {
      _hasTitleError = widget.showError && _task.title.isEmpty;
      _hasTimeError = widget.showError && _task.timeSpent <= 0;
    });
  }

  void _updateTask() {
    widget.onChanged(_task);
    _validateFields();
  }

  void _updateTitle(String value) {
    setState(() => _task = _task.copyWith(title: value));
    _updateTask();
  }

  void _updateDescription(String value) {
    setState(() => _task = _task.copyWith(description: value));
    _updateTask();
  }

  void _updateProject(String value) {
    setState(() => _task = _task.copyWith(project: value));
    _updateTask();
  }

  void _updateTime(String value) {
    final minutes = int.tryParse(value) ?? 0;
    setState(() => _task = _task.copyWith(timeSpent: minutes));
    _updateTask();
  }

  void _updateCategory(TaskCategory? value) {
    if (value != null) {
      setState(() => _task = _task.copyWith(category: value));
      _updateTask();
    }
  }

  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.development:
        return const Color(0xFF4361EE); // Blue
      case TaskCategory.meeting:
        return const Color(0xFF4CAF50); // Green
      case TaskCategory.testing:
        return const Color(0xFFF44336); // Red
      case TaskCategory.documentation:
        return const Color(0xFFFF9800); // Orange
      case TaskCategory.research:
        return const Color(0xFF9C27B0); // Purple
      case TaskCategory.support:
        return const Color(0xFF009688); // Teal
      case TaskCategory.other:
        return const Color(0xFF795548); // Brown
    }
  }

  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.development:
        return Icons.code;
      case TaskCategory.meeting:
        return Icons.groups;
      case TaskCategory.testing:
        return Icons.bug_report;
      case TaskCategory.documentation:
        return Icons.description;
      case TaskCategory.research:
        return Icons.science;
      case TaskCategory.support:
        return Icons.support_agent;
      case TaskCategory.other:
        return Icons.category;
    }
  }

  String _getCategoryLabel(TaskCategory category) {
    switch (category) {
      case TaskCategory.development:
        return 'Development';
      case TaskCategory.meeting:
        return 'Meeting';
      case TaskCategory.testing:
        return 'Testing';
      case TaskCategory.documentation:
        return 'Documentation';
      case TaskCategory.research:
        return 'Research';
      case TaskCategory.support:
        return 'Support';
      case TaskCategory.other:
        return 'Other';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _projectController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with task number and delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.task_alt_outlined,
                        size: 16,
                        color: _primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Task ${widget.index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onRemove != null)
                  GestureDetector(
                    onTap: widget.onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: _errorColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Task title with error indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.title_outlined, size: 18, color: _textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Task Title',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '*',
                      style: TextStyle(
                        fontSize: 14,
                        color: _errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'What did you work on?',
                    hintStyle: TextStyle(color: _textSecondary.withOpacity(0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _hasTitleError ? _errorColor : _primaryColor.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _hasTitleError ? _errorColor : _primaryColor.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _hasTitleError ? _errorColor : _primaryColor,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: _hasTitleError ? _errorColor.withOpacity(0.05) : _backgroundColor,
                    errorText: _hasTitleError ? 'Task title is required' : null,
                    errorStyle: TextStyle(
                      color: _errorColor,
                      fontSize: 12,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: _textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: _updateTitle,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined, size: 18, color: _textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add details, issues, or accomplishments...',
                    hintStyle: TextStyle(color: _textSecondary.withOpacity(0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: _backgroundColor,
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: _textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: _updateDescription,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Project and Category
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.work_outline, size: 18, color: _textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Project',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _projectController,
                        decoration: InputDecoration(
                          hintText: 'Project or client name',
                          hintStyle: TextStyle(color: _textSecondary.withOpacity(0.7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryColor.withOpacity(0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryColor.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _primaryColor, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: _backgroundColor,
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: _textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: _updateProject,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 18, color: _textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primaryColor.withOpacity(0.2)),
                        ),
                        child: DropdownButtonFormField<TaskCategory>(
                          value: _task.category,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            filled: true,
                            fillColor: _backgroundColor,
                          ),
                          items: TaskCategory.values.map((category) {
                            return DropdownMenuItem<TaskCategory>(
                              value: category,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(category).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(category),
                                      size: 18,
                                      color: _getCategoryColor(category),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _getCategoryLabel(category),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _updateCategory,
                          dropdownColor: _cardColor,
                          icon: Icon(Icons.arrow_drop_down, color: _textSecondary),
                          style: TextStyle(
                            fontSize: 15,
                            color: _textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Time spent
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: _textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Time Spent',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '*',
                      style: TextStyle(
                        fontSize: 14,
                        color: _errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _timeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter minutes (e.g., 120)',
                          hintStyle: TextStyle(color: _textSecondary.withOpacity(0.7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _hasTimeError ? _errorColor : _primaryColor.withOpacity(0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _hasTimeError ? _errorColor : _primaryColor.withOpacity(0.2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _hasTimeError ? _errorColor : _primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: _hasTimeError ? _errorColor.withOpacity(0.05) : _backgroundColor,
                          errorText: _hasTimeError ? 'Time must be greater than 0' : null,
                          errorStyle: TextStyle(
                            color: _errorColor,
                            fontSize: 12,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: _textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        onChanged: _updateTime,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _primaryColor.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _formatTime(_task.timeSpent),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total time',
                              style: TextStyle(
                                fontSize: 11,
                                color: _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Time breakdown
                if (_task.timeSpent > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: _textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          _getTimeBreakdown(_task.timeSpent),
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Category color indicator at bottom
            const SizedBox(height: 20),
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getCategoryColor(_task.category),
                    _getCategoryColor(_task.category).withOpacity(0.6),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0) {
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${mins}m';
  }

  String _getTimeBreakdown(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours > 0 && mins > 0) {
      return '${hours} hour${hours > 1 ? 's' : ''} and ${mins} minute${mins > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '${hours} hour${hours > 1 ? 's' : ''}';
    } else {
      return '${mins} minute${mins > 1 ? 's' : ''}';
    }
  }
}