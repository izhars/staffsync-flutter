// lib/screens/daily_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/task_item.dart';
import '../services/task_service.dart';
import 'calendar_task_view.dart';

// ===================== SHARED DESIGN TOKENS =====================
class TaskDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const Color primary = Color(0xFFD97706);
  static const Color primaryDark = Color(0xFFB45309);
  static const Color primarySoft = Color(0xFFFFFBEB);
  static const Color primaryLight = Color(0xFFFDE68A);

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color info = Color(0xFF4F46E5);
  static const Color infoSoft = Color(0xFFEEF2FF);
  static const Color infoBorder = Color(0xFFC7D2FE);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 14,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 22,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
  ];
}

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({Key? key}) : super(key: key);

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  final TaskService _taskService = TaskService();

  List<TaskItem> _tasks = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isSavingDraft = false;
  String? _existingTaskId;
  TaskStatus _currentStatus = TaskStatus.draft;
  int _totalTime = 0;
  bool _hasChanges = false;
  bool _showValidationErrors = false;

  static const int _targetMinutes = 480; // 8h

  @override
  void initState() {
    super.initState();
    _notesController.addListener(_checkForChanges);
    _loadTodayTasks();
  }

  @override
  void dispose() {
    _notesController.removeListener(_checkForChanges);
    _notesController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // State helpers
  // ─────────────────────────────────────────────────────────
  void _checkForChanges() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  void _markAsChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  void _recalculate() {
    _totalTime = TaskService.calculateTotalTime(_tasks);
  }

  // ─────────────────────────────────────────────────────────
  // Data loading
  // ─────────────────────────────────────────────────────────
  Future<void> _loadTodayTasks() async {
    setState(() {
      _isLoading = true;
      _hasChanges = false;
      _showValidationErrors = false;
    });

    try {
      final response = await _taskService.getTodayTask();
      if (response.data != null) {
        _tasks = response.data!.tasks;
        _notesController.text = response.data!.notes ?? '';
        _existingTaskId = response.data!.id;
        _currentStatus = response.data!.status;
        _recalculate();
      } else {
        _tasks = [];
        _hasChanges = true;
      }
    } catch (_) {
      _showSnackBar('Failed to load today\'s tasks', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // Task CRUD (local)
  // ─────────────────────────────────────────────────────────
  Future<void> _openTaskBottomSheet({TaskItem? task, int? index}) async {
    final result = await showModalBottomSheet<TaskItem?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskBottomSheet(
        task: task,
        index: index ?? _tasks.length,
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _tasks[index] = result;
        } else {
          _tasks.add(result);
        }
        _recalculate();
        _markAsChanged();
      });
    }
  }

  Future<void> _removeTask(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TaskDesign.surface,
        surfaceTintColor: TaskDesign.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TaskDesign.radiusXl)),
        title: const Text(
          'Delete task?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: TaskDesign.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        content: const Text(
          'This task will be removed from today\'s list.',
          style: TextStyle(
            color: TaskDesign.textSecondary,
            fontSize: 13.5,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: TaskDesign.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: TaskDesign.dangerSoft,
              foregroundColor: TaskDesign.danger,
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(TaskDesign.radiusSm)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && index < _tasks.length) {
      setState(() {
        _tasks.removeAt(index);
        _recalculate();
        _markAsChanged();
      });
    }
  }

  // ─────────────────────────────────────────────────────────
  // Validation + submit actions
  // ─────────────────────────────────────────────────────────
  bool _validateTasks() {
    if (_tasks.isEmpty) {
      _showSnackBar('Please add at least one task', isError: true);
      return false;
    }
    for (int i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      if (t.title.trim().isEmpty || t.timeSpent <= 0) {
        _showSnackBar('Task ${i + 1} needs a title and time', isError: true);
        return false;
      }
    }
    return true;
  }

  Future<void> _saveAsDraft() async {
    if (!_validateTasks()) {
      setState(() => _showValidationErrors = true);
      return;
    }
    if (!_hasChanges) {
      _showSnackBar('No changes to save', isInfo: true);
      return;
    }

    setState(() => _isSavingDraft = true);
    try {
      final response = await _taskService.saveAsDraft(
        tasks: _tasks,
        notes: _notesController.text.trim(),
      );
      setState(() {
        _existingTaskId = response.data?.id;
        _currentStatus = TaskStatus.draft;
        _hasChanges = false;
        _showValidationErrors = false;
      });
      _showSnackBar('Draft saved successfully');
    } catch (_) {
      _showSnackBar('Failed to save draft', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingDraft = false);
    }
  }

  Future<void> _submitTasks() async {
    if (!_validateTasks()) {
      setState(() => _showValidationErrors = true);
      return;
    }
    if (!_hasChanges && _currentStatus == TaskStatus.submitted) {
      _showSnackBar('No changes to submit', isInfo: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _taskService.submitDailyTasks(
        tasks: _tasks,
        notes: _notesController.text.trim(),
      );
      setState(() {
        _existingTaskId = response.data?.id;
        _currentStatus = TaskStatus.submitted;
        _hasChanges = false;
        _showValidationErrors = false;
      });
      _showSnackBar('Tasks submitted successfully!');
    } catch (_) {
      _showSnackBar('Failed to submit tasks', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // Snackbar
  // ─────────────────────────────────────────────────────────
  void _showSnackBar(String message,
      {bool isError = false, bool isInfo = false}) {
    if (!mounted) return;
    final bg = isError
        ? TaskDesign.danger
        : isInfo
        ? TaskDesign.info
        : TaskDesign.success;
    final icon = isError
        ? Icons.error_outline_rounded
        : isInfo
        ? Icons.info_outline_rounded
        : Icons.check_circle_rounded;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(TaskDesign.md),
        content: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: TaskDesign.bg,
        body: _isLoading ? _buildSkeleton() : _buildBody(),
        floatingActionButton: (!_isLoading && _tasks.isNotEmpty)
            ? _buildFab()
            : null,
        bottomNavigationBar:
        (!_isLoading && _tasks.isNotEmpty) ? _buildActionBar() : null,
      ),
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              color: TaskDesign.primary,
              onRefresh: _loadTodayTasks,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(
                  TaskDesign.md,
                  TaskDesign.md,
                  TaskDesign.md,
                  TaskDesign.lg,
                ),
                children: [
                  _buildTimeSummary(),
                  const SizedBox(height: TaskDesign.md),
                  _buildSectionLabel(
                    'TODAY\'S TASKS',
                    _tasks.isEmpty
                        ? 'Add your first task to get started'
                        : '${_tasks.length} ${_tasks.length == 1 ? "task" : "tasks"} logged',
                  ),
                  const SizedBox(height: TaskDesign.sm + 4),
                  if (_tasks.isEmpty)
                    _buildEmptyState()
                  else
                    ...List.generate(
                      _tasks.length,
                          (i) => Padding(
                        padding: const EdgeInsets.only(
                            bottom: TaskDesign.sm + 2),
                        child: _buildTaskCard(_tasks[i], i),
                      ),
                    ),
                  const SizedBox(height: TaskDesign.lg),
                  _buildSectionLabel(
                    'NOTES',
                    'Blockers, wins, or context for your manager',
                  ),
                  const SizedBox(height: TaskDesign.sm + 4),
                  _buildNotesCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HEADER =====================
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TaskDesign.primary, TaskDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(TaskDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: TaskDesign.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TaskDesign.md,
            TaskDesign.sm,
            TaskDesign.md,
            TaskDesign.md,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(TaskDesign.radiusSm),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(TaskDesign.radiusSm),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: TaskDesign.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Daily Tasks',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (_hasChanges) ...[
                              const SizedBox(width: TaskDesign.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                  BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'UNSAVED',
                                  style: TextStyle(
                                    color: TaskDesign.primaryDark,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('EEEE').format(DateTime.now())} · ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusPill(),
                  const SizedBox(width: TaskDesign.sm),
                  Material(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(TaskDesign.radiusSm),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(TaskDesign.radiusSm),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const DailyTaskCalendarPage(),
                        ),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill() {
    Color soft, border, fg;
    IconData icon;
    String label;

    switch (_currentStatus) {
      case TaskStatus.draft:
        soft = TaskDesign.warningSoft;
        border = TaskDesign.warningBorder;
        fg = TaskDesign.warning;
        icon = Icons.edit_outlined;
        label = 'Draft';
        break;
      case TaskStatus.submitted:
        soft = TaskDesign.successSoft;
        border = TaskDesign.successBorder;
        fg = TaskDesign.success;
        icon = Icons.send_rounded;
        label = 'Submitted';
        break;
      case TaskStatus.approved:
        soft = TaskDesign.infoSoft;
        border = TaskDesign.infoBorder;
        fg = TaskDesign.info;
        icon = Icons.verified_rounded;
        label = 'Approved';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== SECTION LABEL =====================
  Widget _buildSectionLabel(String label, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: TaskDesign.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: TaskDesign.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: TaskDesign.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: TaskDesign.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===================== TIME SUMMARY =====================
  Widget _buildTimeSummary() {
    final progress = (_totalTime / _targetMinutes).clamp(0.0, 1.0);
    final Color progressColor = progress >= 1.0
        ? TaskDesign.success
        : progress >= 0.75
        ? const Color(0xFF65A30D)
        : progress >= 0.5
        ? TaskDesign.primary
        : progress >= 0.25
        ? const Color(0xFFEA580C)
        : TaskDesign.danger;

    final remaining = (_targetMinutes - _totalTime).clamp(0, _targetMinutes);

    return Container(
      padding: const EdgeInsets.all(TaskDesign.md + 2),
      decoration: BoxDecoration(
        color: TaskDesign.surface,
        borderRadius: BorderRadius.circular(TaskDesign.radiusLg),
        border: Border.all(color: TaskDesign.border, width: 1),
        boxShadow: TaskDesign.softShadow,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Time Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: TaskDesign.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEE, MMM d').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: TaskDesign.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: TaskDesign.md, vertical: TaskDesign.sm),
                decoration: BoxDecoration(
                  color: TaskDesign.primarySoft,
                  borderRadius:
                  BorderRadius.circular(TaskDesign.radiusMd),
                  border: Border.all(
                    color: TaskDesign.primaryLight,
                    width: 1,
                  ),
                ),
                child: Text(
                  TaskService.formatMinutes(_totalTime),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TaskDesign.primaryDark,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TaskDesign.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: TaskDesign.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                '${(_totalTime / 60).toStringAsFixed(1)}h / 8h',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: TaskDesign.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: TaskDesign.sm),
          // Progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: TaskDesign.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: TaskDesign.border, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            progressColor,
                            progressColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: TaskDesign.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% complete',
                style: const TextStyle(
                  fontSize: 11,
                  color: TaskDesign.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(remaining / 60).toStringAsFixed(1)}h remaining',
                style: const TextStyle(
                  fontSize: 11,
                  color: TaskDesign.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== TASK CARD =====================
  Widget _buildTaskCard(TaskItem task, int index) {
    final categoryColor = _categoryColor(task.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openTaskBottomSheet(task: task, index: index),
        borderRadius: BorderRadius.circular(TaskDesign.radiusLg),
        splashColor: TaskDesign.primary.withOpacity(0.05),
        highlightColor: TaskDesign.primary.withOpacity(0.03),
        child: Container(
          padding: const EdgeInsets.all(TaskDesign.md),
          decoration: BoxDecoration(
            color: TaskDesign.surface,
            borderRadius: BorderRadius.circular(TaskDesign.radiusLg),
            border: Border.all(color: TaskDesign.border, width: 1),
            boxShadow: TaskDesign.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: categoryColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: TaskDesign.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title.isEmpty ? 'Untitled Task' : task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: TaskDesign.textPrimary,
                            letterSpacing: -0.2,
                            height: 1.3,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: TaskDesign.textSecondary,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: TaskDesign.sm),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: TaskDesign.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: TaskDesign.sm + 2),
              // Footer row
              Row(
                children: [
                  _buildCategoryPill(task.category, categoryColor),
                  const SizedBox(width: TaskDesign.sm),
                  _buildMetaChip(
                    Icons.timer_outlined,
                    _formatTime(task.timeSpent),
                    emphasized: true,
                  ),
                  if (task.project.isNotEmpty) ...[
                    const SizedBox(width: TaskDesign.sm),
                    Flexible(
                      child: _buildMetaChip(
                        Icons.work_outline_rounded,
                        task.project,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(TaskCategory category, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Text(
        _formatCategory(category).toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text,
      {bool emphasized = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: emphasized
              ? TaskDesign.primary
              : TaskDesign.textMuted,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            color: emphasized
                ? TaskDesign.primaryDark
                : TaskDesign.textSecondary,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ===================== EMPTY STATE =====================
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(TaskDesign.xl),
      decoration: BoxDecoration(
        color: TaskDesign.surface,
        borderRadius: BorderRadius.circular(TaskDesign.radiusLg),
        border: Border.all(color: TaskDesign.border, width: 1),
        boxShadow: TaskDesign.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TaskDesign.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: TaskDesign.primaryLight,
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 32,
              color: TaskDesign.primary,
            ),
          ),
          const SizedBox(height: TaskDesign.md),
          const Text(
            'No tasks added yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: TaskDesign.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap the + button to add your first task\nand start tracking your day.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: TaskDesign.textMuted,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: TaskDesign.md),
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => _openTaskBottomSheet(),
              style: ElevatedButton.styleFrom(
                backgroundColor: TaskDesign.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: TaskDesign.lg),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(TaskDesign.radiusMd),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add First Task'),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== NOTES =====================
  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(TaskDesign.md),
      decoration: BoxDecoration(
        color: TaskDesign.surface,
        borderRadius: BorderRadius.circular(TaskDesign.radiusLg),
        border: Border.all(color: TaskDesign.border, width: 1),
        boxShadow: TaskDesign.softShadow,
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 4,
        minLines: 3,
        style: const TextStyle(
          fontSize: 13,
          color: TaskDesign.textPrimary,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          hintText: 'Add notes, blockers, or accomplishments for today...',
          hintStyle: TextStyle(
            color: TaskDesign.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  // ===================== SKELETON =====================
  Widget _buildSkeleton() {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: Color(0xFFE8EAEE),
        highlightColor: Color(0xFFF6F7FB),
        duration: Duration(milliseconds: 1200),
      ),
      child: Column(
        children: [
          // Header skeleton
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(TaskDesign.radiusXl),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TaskDesign.md,
                  TaskDesign.sm,
                  TaskDesign.md,
                  TaskDesign.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            TaskDesign.radiusSm),
                      ),
                    ),
                    const SizedBox(width: TaskDesign.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 140,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 180,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(TaskDesign.md),
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(TaskDesign.radiusLg),
                  ),
                ),
                const SizedBox(height: TaskDesign.md),
                ...List.generate(
                  3,
                      (_) => Padding(
                    padding: const EdgeInsets.only(
                        bottom: TaskDesign.sm + 2),
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            TaskDesign.radiusLg),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== FAB + ACTION BAR =====================
  Widget _buildFab() {
    return FloatingActionButton(
      heroTag: 'add_task',
      onPressed: () => _openTaskBottomSheet(),
      backgroundColor: TaskDesign.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TaskDesign.radiusMd),
      ),
      child: const Icon(Icons.add_rounded, size: 24),
    );
  }

  Widget _buildActionBar() {
    final canSave = !_isSubmitting && !_isSavingDraft && _hasChanges;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        TaskDesign.md,
        TaskDesign.sm + 2,
        TaskDesign.md,
        TaskDesign.sm + 2,
      ),
      decoration: BoxDecoration(
        color: TaskDesign.surface,
        border: Border(
          top: BorderSide(color: TaskDesign.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: canSave ? _saveAsDraft : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TaskDesign.warning,
                    side: BorderSide(
                      color: canSave
                          ? TaskDesign.warningBorder
                          : TaskDesign.border,
                      width: 1.5,
                    ),
                    backgroundColor: canSave
                        ? TaskDesign.warningSoft
                        : TaskDesign.surfaceMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(TaskDesign.radiusMd),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                  icon: _isSavingDraft
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TaskDesign.warning,
                    ),
                  )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(
                    _isSavingDraft ? 'Saving...' : 'Save Draft',
                  ),
                ),
              ),
            ),
            const SizedBox(width: TaskDesign.sm + 2),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: canSave ? _submitTasks : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TaskDesign.success,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    TaskDesign.success.withOpacity(0.4),
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(TaskDesign.radiusMd),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HELPERS =====================
  Color _categoryColor(TaskCategory c) {
    // All shades derived from the shared palette for visual harmony
    switch (c) {
      case TaskCategory.development:
        return const Color(0xFF4F46E5);
      case TaskCategory.meeting:
        return const Color(0xFF059669);
      case TaskCategory.testing:
        return const Color(0xFFDC2626);
      case TaskCategory.documentation:
        return const Color(0xFFD97706);
      case TaskCategory.research:
        return const Color(0xFF7C3AED);
      case TaskCategory.support:
        return const Color(0xFF0D9488);
      case TaskCategory.other:
        return const Color(0xFF6B7280);
    }
  }

  String _formatCategory(TaskCategory c) {
    switch (c) {
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

  String _formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    return '${m}m';
  }
}

// ═════════════════════════════════════════════════════════════
// TASK BOTTOM SHEET — Feedback-style form
// ═════════════════════════════════════════════════════════════
class TaskBottomSheet extends StatefulWidget {
  final TaskItem? task;
  final int index;

  const TaskBottomSheet({
    Key? key,
    this.task,
    required this.index,
  }) : super(key: key);

  @override
  State<TaskBottomSheet> createState() => _TaskBottomSheetState();
}

class _TaskBottomSheetState extends State<TaskBottomSheet> {
  late TaskItem _task;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController =
  TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _task = widget.task ??
        TaskItem(
          title: '',
          description: '',
          project: '',
          timeSpent: 0,
          category: TaskCategory.development,
        );

    _titleController.text = _task.title;
    _descriptionController.text = _task.description;
    _projectController.text = _task.project;
    _timeController.text = _task.timeSpent == 0 ? '' : _task.timeSpent.toString();
    _timeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _projectController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      _showError('Task title is required');
      return false;
    }
    final time = int.tryParse(_timeController.text) ?? 0;
    if (time <= 0) {
      _showError('Time spent must be greater than 0');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: TaskDesign.danger,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(TaskDesign.md),
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _saveTask() {
    if (_validateForm()) {
      final updated = TaskItem(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        project: _projectController.text.trim(),
        timeSpent: int.tryParse(_timeController.text) ?? 0,
        category: _task.category,
      );
      Navigator.pop(context, updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Container(
      decoration: const BoxDecoration(
        color: TaskDesign.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TaskDesign.radiusXl),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(
                  top: TaskDesign.sm + 4, bottom: TaskDesign.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: TaskDesign.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TaskDesign.lg,
                TaskDesign.sm,
                TaskDesign.md,
                TaskDesign.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TaskDesign.primarySoft,
                      borderRadius: BorderRadius.circular(
                          TaskDesign.radiusSm),
                      border: Border.all(
                        color: TaskDesign.primaryLight,
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: TaskDesign.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: TaskDesign.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Task' : 'Add New Task',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: TaskDesign.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing
                              ? 'Update the details for this task'
                              : 'Log what you worked on today',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: TaskDesign.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: TaskDesign.surfaceMuted,
                    borderRadius: BorderRadius.circular(
                        TaskDesign.radiusSm),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                          TaskDesign.radiusSm),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.close_rounded,
                          color: TaskDesign.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  TaskDesign.lg,
                  TaskDesign.sm,
                  TaskDesign.lg,
                  TaskDesign.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('DETAILS', 'What did you work on?'),
                    const SizedBox(height: TaskDesign.sm + 4),
                    _buildFormField(
                      label: 'Task Title',
                      hint: 'e.g. Fixed login bug',
                      controller: _titleController,
                      icon: Icons.title_rounded,
                      required: true,
                    ),
                    const SizedBox(height: TaskDesign.sm + 4),
                    _buildFormField(
                      label: 'Description',
                      hint: 'Add details or accomplishments...',
                      controller: _descriptionController,
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: TaskDesign.lg),
                    _buildSectionLabel('CONTEXT', 'Project and category'),
                    const SizedBox(height: TaskDesign.sm + 4),
                    _buildFormField(
                      label: 'Project',
                      hint: 'Project or client name',
                      controller: _projectController,
                      icon: Icons.work_outline_rounded,
                    ),
                    const SizedBox(height: TaskDesign.sm + 4),
                    _buildCategoryPicker(),
                    const SizedBox(height: TaskDesign.lg),
                    _buildSectionLabel('TIME', 'How long did it take?'),
                    const SizedBox(height: TaskDesign.sm + 4),
                    _buildTimeRow(),
                    const SizedBox(height: TaskDesign.md),
                  ],
                ),
              ),
            ),
            // Save button
            Container(
              padding: const EdgeInsets.fromLTRB(
                TaskDesign.lg,
                TaskDesign.sm + 2,
                TaskDesign.lg,
                TaskDesign.sm + 2,
              ),
              decoration: BoxDecoration(
                color: TaskDesign.surface,
                border: Border(
                  top: BorderSide(color: TaskDesign.border, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TaskDesign.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(TaskDesign.radiusMd),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                    child: Text(isEditing ? 'Update Task' : 'Add Task'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: TaskDesign.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: TaskDesign.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: TaskDesign.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: TaskDesign.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: TaskDesign.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: TaskDesign.textSecondary,
                letterSpacing: 0.1,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 3),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 12,
                  color: TaskDesign.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: TaskDesign.sm),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 13.5,
            color: TaskDesign.textPrimary,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: TaskDesign.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TaskDesign.md,
              vertical: TaskDesign.sm + 4,
            ),
            filled: true,
            fillColor: TaskDesign.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TaskDesign.radiusMd),
              borderSide:
              const BorderSide(color: TaskDesign.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TaskDesign.radiusMd),
              borderSide:
              const BorderSide(color: TaskDesign.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TaskDesign.radiusMd),
              borderSide: const BorderSide(
                color: TaskDesign.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.category_outlined,
                size: 14, color: TaskDesign.textMuted),
            SizedBox(width: 6),
            Text(
              'Category',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: TaskDesign.textSecondary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: TaskDesign.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: TaskDesign.md),
          decoration: BoxDecoration(
            color: TaskDesign.surfaceMuted,
            borderRadius: BorderRadius.circular(TaskDesign.radiusMd),
            border: Border.all(color: TaskDesign.border, width: 1),
          ),
          child: DropdownButtonFormField<TaskCategory>(
            value: _task.category,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: TaskDesign.textSecondary,
            ),
            dropdownColor: TaskDesign.surface,
            borderRadius: BorderRadius.circular(TaskDesign.radiusMd),
            items: TaskCategory.values.map((c) {
              return DropdownMenuItem<TaskCategory>(
                value: c,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _categoryColor(c),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatCategory(c),
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: TaskDesign.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _task = _task.copyWith(category: v));
            },
            style: const TextStyle(
              fontSize: 13.5,
              color: TaskDesign.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow() {
    final minutes = int.tryParse(_timeController.text) ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 14, color: TaskDesign.textMuted),
                  SizedBox(width: 6),
                  Text(
                    'Time Spent (minutes)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: TaskDesign.textSecondary,
                      letterSpacing: 0.1,
                    ),
                  ),
                  SizedBox(width: 3),
                  Text(
                    '*',
                    style: TextStyle(
                      fontSize: 12,
                      color: TaskDesign.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TaskDesign.sm),
              TextFormField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 13.5,
                  color: TaskDesign.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 90',
                  hintStyle: const TextStyle(
                    color: TaskDesign.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TaskDesign.md,
                    vertical: TaskDesign.sm + 4,
                  ),
                  filled: true,
                  fillColor: TaskDesign.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(TaskDesign.radiusMd),
                    borderSide: const BorderSide(
                        color: TaskDesign.border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(TaskDesign.radiusMd),
                    borderSide: const BorderSide(
                        color: TaskDesign.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(TaskDesign.radiusMd),
                    borderSide: const BorderSide(
                      color: TaskDesign.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: TaskDesign.sm + 2),
        // Live time preview
        Container(
          width: 110,
          padding: const EdgeInsets.symmetric(
              horizontal: TaskDesign.md, vertical: TaskDesign.sm + 4),
          decoration: BoxDecoration(
            color: TaskDesign.primarySoft,
            borderRadius: BorderRadius.circular(TaskDesign.radiusMd),
            border: Border.all(
              color: TaskDesign.primaryLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: TaskDesign.primaryDark,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                TaskService.formatMinutes(minutes),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: TaskDesign.primaryDark,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _categoryColor(TaskCategory c) {
    switch (c) {
      case TaskCategory.development:
        return const Color(0xFF4F46E5);
      case TaskCategory.meeting:
        return const Color(0xFF059669);
      case TaskCategory.testing:
        return const Color(0xFFDC2626);
      case TaskCategory.documentation:
        return const Color(0xFFD97706);
      case TaskCategory.research:
        return const Color(0xFF7C3AED);
      case TaskCategory.support:
        return const Color(0xFF0D9488);
      case TaskCategory.other:
        return const Color(0xFF6B7280);
    }
  }

  String _formatCategory(TaskCategory c) {
    switch (c) {
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
}