import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:staffsync/screens/task_details_screen.dart';
import '../services/task_api.dart';

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

  // Primary amber palette (matches FeedbackDesign)
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

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 22,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
  ];
}

class EmployeeTasksScreen extends StatefulWidget {
  const EmployeeTasksScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeTasksScreen> createState() => _EmployeeTasksScreenState();
}

class _EmployeeTasksScreenState extends State<EmployeeTasksScreen> {
  late final TaskApi taskApi;
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;
  String? error;
  int currentPage = 1;
  int totalPages = 1;
  bool hasMore = true;
  bool isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // Category metadata — mirrors the feedback category card style
  static const Map<String, Map<String, dynamic>> _categoryMeta = {
    'onboarding': {
      'label': 'Onboarding',
      'icon': Icons.rocket_launch_rounded,
      'fg': Color(0xFF4F46E5),
      'soft': Color(0xFFEEF2FF),
      'border': Color(0xFFC7D2FE),
    },
    'offboarding': {
      'label': 'Offboarding',
      'icon': Icons.logout_rounded,
      'fg': Color(0xFFB45309),
      'soft': Color(0xFFFFFBEB),
      'border': Color(0xFFFDE68A),
    },
    'training': {
      'label': 'Training',
      'icon': Icons.school_rounded,
      'fg': Color(0xFF0D9488),
      'soft': Color(0xFFF0FDFA),
      'border': Color(0xFF99F6E4),
    },
    'performance': {
      'label': 'Performance',
      'icon': Icons.trending_up_rounded,
      'fg': Color(0xFF7C3AED),
      'soft': Color(0xFFF5F3FF),
      'border': Color(0xFFDDD6FE),
    },
    'compliance': {
      'label': 'Compliance',
      'icon': Icons.gavel_rounded,
      'fg': Color(0xFFDC2626),
      'soft': Color(0xFFFEF2F2),
      'border': Color(0xFFFECACA),
    },
    'general': {
      'label': 'General',
      'icon': Icons.more_horiz_rounded,
      'fg': Color(0xFF6B7280),
      'soft': Color(0xFFF3F4F6),
      'border': Color(0xFFE5E7EB),
    },
  };

  @override
  void initState() {
    super.initState();
    taskApi = TaskApi();
    fetchTasks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        hasMore &&
        !isLoadingMore) {
      fetchTasks(loadMore: true);
    }
  }

  Future<void> fetchTasks({bool loadMore = false}) async {
    if (loadMore) {
      if (!hasMore || isLoadingMore) return;
      setState(() => isLoadingMore = true);
    } else {
      setState(() {
        isLoading = true;
        error = null;
        tasks = [];
        currentPage = 1;
        hasMore = true;
      });
    }

    final requestedPage = loadMore ? currentPage + 1 : 1;

    try {
      final response = await taskApi.getMyTasks(page: requestedPage);
      final fetchedRaw = response['data'];
      final List<Map<String, dynamic>> fetchedTasks = fetchedRaw is List
          ? fetchedRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList()
          : <Map<String, dynamic>>[];

      final pagination = response['pagination'] is Map
          ? Map<String, dynamic>.from(response['pagination'])
          : <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        if (loadMore) {
          tasks.addAll(fetchedTasks);
          currentPage = requestedPage;
        } else {
          tasks = fetchedTasks;
          currentPage = 1;
        }

        final total = (pagination['total'] as num?)?.toInt() ?? tasks.length;
        final limit = (pagination['limit'] as num?)?.toInt() ?? 20;
        totalPages = limit > 0 ? (total / limit).ceil() : 1;
        hasMore = currentPage < totalPages;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  Future<void> markComplete(String id) async {
    try {
      final updatedTask = await taskApi.completeTask(id);
      if (!mounted) return;
      setState(() {
        tasks = tasks
            .map((t) => t['_id'] == id ? updatedTask : t)
            .toList();
      });
      _showSnackBar('Task completed successfully!', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to complete task: $e', isError: true);
    }
  }

  Future<void> showTaskDetails(Map<String, dynamic> task) async {
    try {
      final currentUserId = await taskApi.getCurrentUserId();
      if (!mounted) return;

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailsScreen(
            taskId: task['_id'],
            taskApi: taskApi,
            onTaskUpdated: (updatedTask) {
              if (!mounted) return;
              setState(() {
                final index =
                tasks.indexWhere((t) => t['_id'] == updatedTask['_id']);
                if (index != -1) tasks[index] = updatedTask;
              });
            },
            currentUserId: currentUserId,
          ),
        ),
      );

      if (result == true && mounted) fetchTasks();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to open task: $e', isError: true);
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

  // ===================== DATE HELPERS =====================

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final taskDate = DateTime(date.year, date.month, date.day);

      if (taskDate == today) {
        return 'Today • ${DateFormat('h:mm a').format(date)}';
      } else if (taskDate == yesterday) {
        return 'Yesterday • ${DateFormat('h:mm a').format(date)}';
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (_) {
      return 'Invalid date';
    }
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: TaskDesign.bg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: () => fetchTasks(),
                color: TaskDesign.primary,
                backgroundColor: TaskDesign.surface,
                displacement: 40,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    if (!isLoading && error == null && tasks.isNotEmpty)
                      SliverToBoxAdapter(child: _buildStatsSection()),
                    if (isLoading)
                      const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator.adaptive(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              TaskDesign.primary,
                            ),
                          ),
                        ),
                      )
                    else if (error != null)
                      SliverFillRemaining(child: _buildErrorState())
                    else if (tasks.isEmpty)
                        SliverFillRemaining(child: _buildEmptyState())
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              if (index == tasks.length) {
                                return _buildLoadMoreIndicator();
                              }
                              return _buildTaskCard(tasks[index]);
                            },
                            childCount:
                            tasks.length + (isLoadingMore ? 1 : 0),
                          ),
                        ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: TaskDesign.lg),
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
          child: Row(
            children: [
              // Back button
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
                  onTap: () => Navigator.maybePop(context),
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

              // Title block
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Track your assignments and progress',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Refresh
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
                  onTap: () => fetchTasks(),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
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

  // ===================== STATS SECTION =====================

  Widget _buildStatsSection() {
    final completedCount =
        tasks.where((t) => t['status'] == 'completed').length;
    final overdueCount = tasks.where((t) {
      if (t['status'] == 'completed' || t['dueDate'] == null) return false;
      final d = DateTime.tryParse(t['dueDate'].toString());
      return d != null && d.isBefore(DateTime.now());
    }).length;
    final pendingCount = tasks.where((t) => t['status'] == 'open').length;
    final totalCount = tasks.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        TaskDesign.md,
        TaskDesign.md,
        TaskDesign.md,
        TaskDesign.sm,
      ),
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
          Row(
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
                'TASK OVERVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: TaskDesign.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: TaskDesign.md),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  count: completedCount,
                  label: 'Completed',
                  icon: Icons.check_circle_rounded,
                  fg: TaskDesign.success,
                  soft: TaskDesign.successSoft,
                  border: TaskDesign.successBorder,
                ),
              ),
              const SizedBox(width: TaskDesign.sm + 4),
              Expanded(
                child: _buildStatTile(
                  count: pendingCount,
                  label: 'Pending',
                  icon: Icons.pending_rounded,
                  fg: TaskDesign.warning,
                  soft: TaskDesign.warningSoft,
                  border: TaskDesign.warningBorder,
                ),
              ),
              const SizedBox(width: TaskDesign.sm + 4),
              Expanded(
                child: _buildStatTile(
                  count: overdueCount,
                  label: 'Overdue',
                  icon: Icons.warning_rounded,
                  fg: TaskDesign.danger,
                  soft: TaskDesign.dangerSoft,
                  border: TaskDesign.dangerBorder,
                ),
              ),
            ],
          ),
          if (totalCount > 0) ...[
            const SizedBox(height: TaskDesign.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: completedCount / totalCount,
                backgroundColor: TaskDesign.surfaceMuted,
                color: TaskDesign.success,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: TaskDesign.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(
                    color: TaskDesign.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${((completedCount / totalCount) * 100).round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: TaskDesign.textPrimary,
                    fontSize: 11,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required int count,
    required String label,
    required IconData icon,
    required Color fg,
    required Color soft,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TaskDesign.sm + 2,
        vertical: TaskDesign.sm + 4,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(TaskDesign.radiusMd),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 1),
            ),
            child: Icon(icon, color: fg, size: 16),
          ),
          const SizedBox(height: TaskDesign.sm),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: fg.withOpacity(0.85),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TASK CARD =====================

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final isCompleted = task['status'] == 'completed';
    final dueDate =
    task['dueDate'] != null ? DateTime.tryParse(task['dueDate']) : null;
    final isOverdue =
        dueDate != null && dueDate.isBefore(DateTime.now()) && !isCompleted;
    final comments = (task['comments'] as List?) ?? const [];
    final hasComments = comments.isNotEmpty;

    final categoryKey =
    (task['category']?.toString() ?? 'general').toLowerCase();
    final catMeta = _categoryMeta[categoryKey] ?? _categoryMeta['general']!;
    final catFg = catMeta['fg'] as Color;
    final catSoft = catMeta['soft'] as Color;
    final catBorder = catMeta['border'] as Color;
    final catIcon = catMeta['icon'] as IconData;
    final catLabel = catMeta['label'] as String;

    final assigner = task['assigner'] is Map
        ? Map<String, dynamic>.from(task['assigner'])
        : <String, dynamic>{};
    final assignerFirst = (assigner['firstName'] ?? 'U').toString();
    final assignerLast = (assigner['lastName'] ?? '').toString();
    final assignerName = '$assignerFirst $assignerLast'.trim();
    final assignerInitials =
    assignerFirst.isNotEmpty ? assignerFirst[0].toUpperCase() : '?';

    // Status styling
    final Color statusFg;
    final Color statusSoft;
    final Color statusBorder;
    final IconData statusIcon;
    final String statusText;

    if (isCompleted) {
      statusFg = TaskDesign.success;
      statusSoft = TaskDesign.successSoft;
      statusBorder = TaskDesign.successBorder;
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Completed';
    } else if (isOverdue) {
      statusFg = TaskDesign.danger;
      statusSoft = TaskDesign.dangerSoft;
      statusBorder = TaskDesign.dangerBorder;
      statusIcon = Icons.warning_rounded;
      statusText = 'Overdue';
    } else {
      statusFg = TaskDesign.warning;
      statusSoft = TaskDesign.warningSoft;
      statusBorder = TaskDesign.warningBorder;
      statusIcon = Icons.access_time_rounded;
      statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: TaskDesign.md,
        vertical: TaskDesign.sm - 2,
      ),
      child: Material(
        color: TaskDesign.surface,
        borderRadius: BorderRadius.circular(TaskDesign.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(TaskDesign.radiusLg),
          onTap: () => showTaskDetails(task),
          child: Container(
            padding: const EdgeInsets.all(TaskDesign.md + 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TaskDesign.radiusLg),
              border: Border.all(color: TaskDesign.border, width: 1),
              boxShadow: TaskDesign.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: status pill + category pill
                Row(
                  children: [
                    _statusPill(
                      icon: statusIcon,
                      label: statusText,
                      fg: statusFg,
                      soft: statusSoft,
                      border: statusBorder,
                    ),
                    const Spacer(),
                    _categoryPill(
                      icon: catIcon,
                      label: catLabel,
                      fg: catFg,
                      soft: catSoft,
                      border: catBorder,
                    ),
                  ],
                ),

                const SizedBox(height: TaskDesign.md),

                // Title
                Text(
                  task['title']?.toString() ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: TaskDesign.textPrimary,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if ((task['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: TaskDesign.sm - 2),
                  Text(
                    task['description'].toString(),
                    style: const TextStyle(
                      color: TaskDesign.textSecondary,
                      fontSize: 12.5,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: TaskDesign.md),

                // Meta row: due date + comments
                Row(
                  children: [
                    if (task['dueDate'] != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: isOverdue
                                ? TaskDesign.danger
                                : TaskDesign.textMuted,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _formatDate(task['dueDate']),
                            style: TextStyle(
                              color: isOverdue
                                  ? TaskDesign.danger
                                  : TaskDesign.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    if (hasComments) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TaskDesign.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: TaskDesign.infoSoft,
                          borderRadius:
                          BorderRadius.circular(TaskDesign.radiusSm - 2),
                          border: Border.all(
                            color: TaskDesign.infoBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chat_bubble_rounded,
                              color: TaskDesign.info,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comments.length}',
                              style: const TextStyle(
                                color: TaskDesign.info,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: TaskDesign.md),

                // Divider
                Container(height: 1, color: TaskDesign.border),

                const SizedBox(height: TaskDesign.md),

                // Footer: assigner + action
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: TaskDesign.primarySoft,
                        borderRadius:
                        BorderRadius.circular(TaskDesign.radiusSm),
                        border: Border.all(
                          color: TaskDesign.primaryLight,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          assignerInitials,
                          style: const TextStyle(
                            fontSize: 13,
                            color: TaskDesign.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: TaskDesign.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ASSIGNED BY',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: TaskDesign.textMuted,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            assignerName.isEmpty ? 'Unknown' : assignerName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: TaskDesign.textPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!isCompleted)
                      _completeButton(task['_id'])
                    else
                      _completedChip(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill({
    required IconData icon,
    required String label,
    required Color fg,
    required Color soft,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TaskDesign.sm + 2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryPill({
    required IconData icon,
    required String label,
    required Color fg,
    required Color soft,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TaskDesign.sm + 2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 11),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _completeButton(String id) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: () => markComplete(id),
        style: ElevatedButton.styleFrom(
          backgroundColor: TaskDesign.success,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: TaskDesign.md,
            vertical: 0,
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 14),
            SizedBox(width: 5),
            Text('Complete'),
          ],
        ),
      ),
    );
  }

  Widget _completedChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TaskDesign.md,
        vertical: TaskDesign.sm,
      ),
      decoration: BoxDecoration(
        color: TaskDesign.successSoft,
        borderRadius: BorderRadius.circular(TaskDesign.radiusSm),
        border: Border.all(color: TaskDesign.successBorder, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 14,
            color: TaskDesign.success,
          ),
          SizedBox(width: 5),
          Text(
            'Done',
            style: TextStyle(
              color: TaskDesign.success,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== EMPTY / ERROR / LOADING =====================

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(TaskDesign.xl),
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
            'Unable to Load Tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: TaskDesign.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: TaskDesign.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TaskDesign.lg),
            child: Text(
              error ?? 'Something went wrong. Please try again.',
              style: const TextStyle(
                fontSize: 13,
                color: TaskDesign.textSecondary,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: TaskDesign.lg),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => fetchTasks(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: TaskDesign.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(TaskDesign.radiusMd),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: TaskDesign.lg),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(TaskDesign.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: TaskDesign.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: TaskDesign.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: TaskDesign.lg),
          const Text(
            'No Tasks Assigned',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: TaskDesign.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: TaskDesign.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TaskDesign.lg),
            child: Text(
              "You're all caught up! Enjoy some free time or check back later for new tasks.",
              style: const TextStyle(
                fontSize: 13.5,
                color: TaskDesign.textSecondary,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: TaskDesign.lg),
          OutlinedButton.icon(
            onPressed: () => fetchTasks(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TaskDesign.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: TaskDesign.lg,
                vertical: TaskDesign.sm + 4,
              ),
              side: const BorderSide(
                color: TaskDesign.primary,
                width: 1.5,
              ),
              foregroundColor: TaskDesign.primary,
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.all(TaskDesign.lg),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator.adaptive(
            strokeWidth: 2.5,
            valueColor:
            const AlwaysStoppedAnimation<Color>(TaskDesign.primary),
          ),
        ),
      ),
    );
  }
}