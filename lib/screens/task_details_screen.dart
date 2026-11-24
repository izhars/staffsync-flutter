import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/task_api.dart';

// Same design tokens
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

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

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
}

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final TaskApi taskApi;
  final Function(Map<String, dynamic>) onTaskUpdated;
  final String currentUserId;

  const TaskDetailsScreen({
    Key? key,
    required this.taskId,
    required this.taskApi,
    required this.onTaskUpdated,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  Map<String, dynamic> _task = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isAddingComment = false;
  bool _isCompletingTask = false;

  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();

  static const Map<String, Map<String, dynamic>> _categoryMeta = {
    'onboarding': {
      'label': 'Onboarding',
      'fg': Color(0xFF4F46E5),
      'soft': Color(0xFFEEF2FF),
      'border': Color(0xFFC7D2FE),
    },
    'offboarding': {
      'label': 'Offboarding',
      'fg': Color(0xFFB45309),
      'soft': Color(0xFFFFFBEB),
      'border': Color(0xFFFDE68A),
    },
    'training': {
      'label': 'Training',
      'fg': Color(0xFF0D9488),
      'soft': Color(0xFFF0FDFA),
      'border': Color(0xFF99F6E4),
    },
    'performance': {
      'label': 'Performance',
      'fg': Color(0xFF7C3AED),
      'soft': Color(0xFFF5F3FF),
      'border': Color(0xFFDDD6FE),
    },
    'compliance': {
      'label': 'Compliance',
      'fg': Color(0xFFDC2626),
      'soft': Color(0xFFFEF2F2),
      'border': Color(0xFFFECACA),
    },
    'general': {
      'label': 'General',
      'fg': Color(0xFF6B7280),
      'soft': Color(0xFFF3F4F6),
      'border': Color(0xFFE5E7EB),
    },
  };

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final taskData = await widget.taskApi.getTask(widget.taskId);
      final processed = _processTaskData(taskData);

      if (!mounted) return;
      setState(() {
        _task = processed;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Failed to load task: $e', isError: true);
    }
  }

  Future<void> _refreshTask() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);

    try {
      final taskData = await widget.taskApi.getTask(widget.taskId);
      final processed = _processTaskData(taskData);

      if (!mounted) return;
      setState(() {
        _task = processed;
        _isRefreshing = false;
      });
      widget.onTaskUpdated(processed);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      _showSnackBar('Failed to refresh task: $e', isError: true);
    }
  }

  Map<String, dynamic> _processTaskData(Map<String, dynamic> taskData) {
    final processed = Map<String, dynamic>.from(taskData);
    processed['assignee'] = _normalizeUser(processed['assignee']);
    processed['assigner'] = _normalizeUser(processed['assigner']);

    final rawComments = processed['comments'];
    final comments = rawComments is List
        ? rawComments
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        : <Map<String, dynamic>>[];

    final normalized = comments.map((c) {
      final out = Map<String, dynamic>.from(c);
      out['author'] = _normalizeUser(c['author']);
      return out;
    }).toList();

    normalized.sort((a, b) {
      final da = DateTime.tryParse(a['createdAt']?.toString() ?? '');
      final db = DateTime.tryParse(b['createdAt']?.toString() ?? '');
      if (da == null && db == null) return 0;
      if (da == null) return -1;
      if (db == null) return 1;
      return da.compareTo(db);
    });

    processed['comments'] = normalized;
    return processed;
  }

  Map<String, dynamic> _normalizeUser(dynamic raw) {
    if (raw is Map) {
      final user = Map<String, dynamic>.from(raw);
      if (user['_id']?.toString() == widget.currentUserId) {
        user['firstName'] = 'You';
        user['fullName'] = 'You';
      }
      return user;
    }
    if (raw is String) {
      final user = <String, dynamic>{
        '_id': raw,
        'firstName': 'User',
        'lastName': '',
        'fullName': 'User',
      };
      if (raw == widget.currentUserId) {
        user['firstName'] = 'You';
        user['fullName'] = 'You';
      }
      return user;
    }
    return <String, dynamic>{
      '_id': '',
      'firstName': 'Unknown',
      'lastName': '',
      'fullName': 'Unknown',
    };
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isAddingComment = true);

    try {
      final updatedTask = await widget.taskApi.addComment(_task['_id'], text);
      final processed = _processTaskData(updatedTask);

      if (!mounted) return;
      setState(() => _task = processed);
      widget.onTaskUpdated(processed);
      _commentController.clear();
      _showSnackBar('Comment added successfully!', isError: false);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error adding comment: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isAddingComment = false);
    }
  }

  Future<void> _markComplete() async {
    setState(() => _isCompletingTask = true);
    try {
      final updatedTask = await widget.taskApi.completeTask(_task['_id']);
      final processed = _processTaskData(updatedTask);

      if (!mounted) return;
      setState(() => _task = processed);
      widget.onTaskUpdated(processed);
      _showSnackBar('Task marked as complete!', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isCompletingTask = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor:
        isError ? TaskDesign.danger : TaskDesign.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(TaskDesign.md),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not set';
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final taskDate = DateTime(date.year, date.month, date.day);

      if (taskDate == today) {
        return 'Today, ${DateFormat('h:mm a').format(date)}';
      } else if (taskDate == yesterday) {
        return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (_) {
      return 'Invalid date';
    }
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return '';
    }
  }

  String _displayName(dynamic user) {
    if (user is Map) {
      final first = (user['firstName'] ?? '').toString();
      final last = (user['lastName'] ?? '').toString();
      final name = '$first $last'.trim();
      return name.isEmpty ? 'Unknown' : name;
    }
    return 'Unknown';
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: TaskDesign.bg,
        body: Center(
          child: CircularProgressIndicator.adaptive(
            valueColor:
            AlwaysStoppedAnimation<Color>(TaskDesign.primary),
          ),
        ),
      );
    }

    if (_task.isEmpty) {
      return Scaffold(
        backgroundColor: TaskDesign.bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: TaskDesign.dangerSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: TaskDesign.danger,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: TaskDesign.lg),
                      const Text(
                        'Task not found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: TaskDesign.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: TaskDesign.lg),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _loadTask,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TaskDesign.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                TaskDesign.radiusMd,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: TaskDesign.lg,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dueDate = _task['dueDate'] != null
        ? DateTime.tryParse(_task['dueDate'].toString())
        : null;
    final isOverdue = dueDate != null &&
        dueDate.isBefore(DateTime.now()) &&
        _task['status'] != 'completed';
    final comments = (_task['comments'] as List?) ?? const [];
    final isCompleted = _task['status'] == 'completed';

    final categoryKey =
    (_task['category']?.toString() ?? 'general').toLowerCase();
    final catMeta = _categoryMeta[categoryKey] ?? _categoryMeta['general']!;
    final catFg = catMeta['fg'] as Color;
    final catSoft = catMeta['soft'] as Color;
    final catBorder = catMeta['border'] as Color;
    final catLabel = catMeta['label'] as String;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: TaskDesign.bg,
        body: Column(
          children: [
            _buildHeader(isCompleted: isCompleted),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task info card
                    Padding(
                      padding: const EdgeInsets.all(TaskDesign.md),
                      child: _buildTaskInfoCard(
                        isOverdue: isOverdue,
                        catFg: catFg,
                        catSoft: catSoft,
                        catBorder: catBorder,
                        catLabel: catLabel,
                        isCompleted: isCompleted,
                      ),
                    ),

                    // Discussion header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TaskDesign.md,
                      ),
                      child: _buildDiscussionHeader(comments.length),
                    ),

                    const SizedBox(height: TaskDesign.sm + 4),

                    // Comments
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: TaskDesign.md,
                      ),
                      decoration: BoxDecoration(
                        color: TaskDesign.surface,
                        borderRadius:
                        BorderRadius.circular(TaskDesign.radiusLg),
                        border:
                        Border.all(color: TaskDesign.border, width: 1),
                        boxShadow: TaskDesign.softShadow,
                      ),
                      child: comments.isEmpty
                          ? _buildEmptyComments()
                          : Column(
                        children: [
                          const SizedBox(height: TaskDesign.sm),
                          ...comments.asMap().entries.map((e) {
                            final c = e.value;
                            if (c is! Map) {
                              return const SizedBox.shrink();
                            }
                            return _buildChatBubble(
                              Map<String, dynamic>.from(c),
                            );
                          }),
                          const SizedBox(height: TaskDesign.sm),
                        ],
                      ),
                    ),

                    const SizedBox(height: TaskDesign.md),

                    // Comment input
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TaskDesign.md,
                      ),
                      child: _buildCommentInput(),
                    ),

                    const SizedBox(height: TaskDesign.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader({bool isCompleted = false}) {
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
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'View and discuss the task',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompleted)
                Material(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
                  child: InkWell(
                    borderRadius:
                    BorderRadius.circular(TaskDesign.radiusSm),
                    onTap: _isCompletingTask ? null : _markComplete,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: _isCompletingTask
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: TaskDesign.sm),
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
                  onTap: _isRefreshing ? null : _refreshTask,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: _isRefreshing
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== TASK INFO CARD =====================

  Widget _buildTaskInfoCard({
    required bool isOverdue,
    required Color catFg,
    required Color catSoft,
    required Color catBorder,
    required String catLabel,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(TaskDesign.md + 2),
      decoration: BoxDecoration(
        color: TaskDesign.surface,
        borderRadius: BorderRadius.circular(TaskDesign.radiusLg),
        border: Border.all(color: TaskDesign.border, width: 1),
        boxShadow: TaskDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + category pills
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TaskDesign.sm + 2,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? TaskDesign.successSoft
                      : (isOverdue
                      ? TaskDesign.dangerSoft
                      : TaskDesign.warningSoft),
                  borderRadius:
                  BorderRadius.circular(TaskDesign.radiusSm),
                  border: Border.all(
                    color: isCompleted
                        ? TaskDesign.successBorder
                        : (isOverdue
                        ? TaskDesign.dangerBorder
                        : TaskDesign.warningBorder),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : (isOverdue
                          ? Icons.warning_rounded
                          : Icons.access_time_rounded),
                      color: isCompleted
                          ? TaskDesign.success
                          : (isOverdue
                          ? TaskDesign.danger
                          : TaskDesign.warning),
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isCompleted
                          ? 'Completed'
                          : (isOverdue ? 'Overdue' : 'Pending'),
                      style: TextStyle(
                        color: isCompleted
                            ? TaskDesign.success
                            : (isOverdue
                            ? TaskDesign.danger
                            : TaskDesign.warning),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TaskDesign.sm + 2,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: catSoft,
                  borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
                  border: Border.all(color: catBorder, width: 1),
                ),
                child: Text(
                  catLabel,
                  style: TextStyle(
                    color: catFg,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: TaskDesign.md),

          // Title
          Text(
            _task['title']?.toString() ?? 'No Title',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: TaskDesign.textPrimary,
              letterSpacing: -0.5,
              height: 1.25,
            ),
          ),

          // Description
          if ((_task['description'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: TaskDesign.sm),
            Text(
              _task['description'].toString(),
              style: const TextStyle(
                fontSize: 13.5,
                color: TaskDesign.textSecondary,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: TaskDesign.md),

          // Divider
          Container(height: 1, color: TaskDesign.border),

          const SizedBox(height: TaskDesign.md),

          // Info chips row
          Wrap(
            spacing: TaskDesign.sm,
            runSpacing: TaskDesign.sm,
            children: [
              _buildInfoChip(
                icon: Icons.calendar_today_rounded,
                label: 'DUE DATE',
                value: _task['dueDate'] != null
                    ? _formatDate(_task['dueDate'].toString())
                    : 'Not set',
                fg: isOverdue ? TaskDesign.danger : TaskDesign.info,
                soft: isOverdue
                    ? TaskDesign.dangerSoft
                    : TaskDesign.infoSoft,
                border: isOverdue
                    ? TaskDesign.dangerBorder
                    : TaskDesign.infoBorder,
              ),
              _buildInfoChip(
                icon: Icons.person_add_rounded,
                label: 'ASSIGNED BY',
                value: _displayName(_task['assigner']),
                fg: TaskDesign.primary,
                soft: TaskDesign.primarySoft,
                border: TaskDesign.primaryLight,
              ),
              _buildInfoChip(
                icon: Icons.person_rounded,
                label: 'ASSIGNED TO',
                value: _displayName(_task['assignee']),
                fg: TaskDesign.success,
                soft: TaskDesign.successSoft,
                border: TaskDesign.successBorder,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color fg,
    required Color soft,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TaskDesign.sm + 4,
        vertical: TaskDesign.sm,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: fg.withOpacity(0.75),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== DISCUSSION =====================

  Widget _buildDiscussionHeader(int commentCount) {
    return Row(
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
        const Text(
          'DISCUSSION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: TaskDesign.textPrimary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: TaskDesign.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: TaskDesign.infoSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TaskDesign.infoBorder, width: 1),
          ),
          child: Text(
            '$commentCount',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: TaskDesign.info,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyComments() {
    return Padding(
      padding: const EdgeInsets.all(TaskDesign.xl),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: TaskDesign.surfaceMuted,
              shape: BoxShape.circle,
              border: Border.all(color: TaskDesign.border, width: 1),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: TaskDesign.textMuted,
              size: 26,
            ),
          ),
          const SizedBox(height: TaskDesign.md),
          const Text(
            'No comments yet',
            style: TextStyle(
              fontSize: 14,
              color: TaskDesign.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start the conversation',
            style: TextStyle(
              fontSize: 12,
              color: TaskDesign.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> comment) {
    final author = comment['author'] is Map
        ? Map<String, dynamic>.from(comment['author'])
        : <String, dynamic>{};
    final authorId = author['_id']?.toString() ?? '';
    final authorName = (author['fullName'] ??
        '${author['firstName'] ?? ''} ${author['lastName'] ?? ''}')
        .toString()
        .trim();
    final isMe = authorId == widget.currentUserId;
    final initials =
    authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TaskDesign.md,
        vertical: TaskDesign.sm - 2,
      ),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: TaskDesign.surfaceMuted,
                shape: BoxShape.circle,
                border: Border.all(color: TaskDesign.border, width: 1),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: TaskDesign.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: TaskDesign.sm),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TaskDesign.md - 2,
                vertical: TaskDesign.sm + 2,
              ),
              decoration: BoxDecoration(
                color: isMe ? TaskDesign.primary : TaskDesign.surfaceMuted,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(TaskDesign.radiusMd),
                  topRight: const Radius.circular(TaskDesign.radiusMd),
                  bottomLeft: Radius.circular(
                    isMe ? TaskDesign.radiusMd : 4,
                  ),
                  bottomRight: Radius.circular(
                    isMe ? 4 : TaskDesign.radiusMd,
                  ),
                ),
                border: isMe
                    ? null
                    : Border.all(color: TaskDesign.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && authorName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          color: TaskDesign.textPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  Text(
                    comment['text']?.toString() ?? '',
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : TaskDesign.textPrimary,
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(comment['createdAt']?.toString()),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withOpacity(0.75)
                          : TaskDesign.textMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: TaskDesign.sm),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: TaskDesign.primaryDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: TaskDesign.primaryLight,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===================== COMMENT INPUT =====================

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: TaskDesign.surface,
        borderRadius: BorderRadius.circular(TaskDesign.radiusLg),
        border: Border.all(color: TaskDesign.border, width: 1),
        boxShadow: TaskDesign.softShadow,
      ),
      padding: const EdgeInsets.all(TaskDesign.sm + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: TaskDesign.surfaceMuted,
                borderRadius: BorderRadius.circular(TaskDesign.radiusMd),
                border: Border.all(color: TaskDesign.border, width: 1),
              ),
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                maxLines: 4,
                minLines: 1,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: TaskDesign.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: TaskDesign.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: TaskDesign.md - 2,
                    vertical: TaskDesign.sm + 4,
                  ),
                ),
                onChanged: (_) {
                  if (mounted) setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: TaskDesign.sm),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _commentController.text.trim().isEmpty
                  ? TaskDesign.surfaceMuted
                  : TaskDesign.primary,
              borderRadius: BorderRadius.circular(TaskDesign.radiusMd),
              border: Border.all(
                color: _commentController.text.trim().isEmpty
                    ? TaskDesign.border
                    : TaskDesign.primary,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(TaskDesign.radiusMd),
                onTap: _isAddingComment ||
                    _commentController.text.trim().isEmpty
                    ? null
                    : _addComment,
                child: Center(
                  child: _isAddingComment
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: _commentController.text.trim().isEmpty
                        ? TaskDesign.textMuted
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}