// screens/project_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:staffsync/screens/edit_project_screen.dart';
import 'package:staffsync/screens/projects_screen.dart'; // for ProjectDesign
import 'package:staffsync/screens/project_chat_screen.dart';
import '../component/add_team_member_screen.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import 'budget_detail_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({Key? key, required this.project}) : super(key: key);

  @override
  _ProjectDetailScreenState createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();

  late Project _project;
  bool _isLoading = true;
  List<ProjectTaskItem> _tasks = [];
  bool _tasksLoading = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadProjectDetails();
    _loadTasks();
  }

  Future<void> _loadProjectDetails() async {
    try {
      final result = await _projectService.getProject(_project.id);
      if (result['success']) {
        setState(() {
          _project = Project.fromJson(result['data']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _tasksLoading = true);
    try {
      final res = await _projectService.getProjectTasks(_project.id);
      if (res['success'] && mounted) {
        final list = (res['data'] as List? ?? [])
            .map((item) => ProjectTaskItem.fromJson(item is Map<String, dynamic> ? item : {}))
            .toList();
        setState(() {
          _tasks = list;
          _tasksLoading = false;
        });
      } else if (mounted) {
        setState(() => _tasksLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _tasksLoading = false);
    }
  }

  Future<void> _toggleTask(ProjectTaskItem task) async {
    final newStatus = task.status == 'completed' ? 'open' : 'completed';
    try {
      await _projectService.updateProjectTask(_project.id, task.id, {'status': newStatus});
      _loadTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $e')),
      );
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    String? selectedAssignee = _project.teamMembers.isNotEmpty ? _project.teamMembers.first.employee.id : null;
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ProjectDesign.radiusMd)),
          title: const Text('Add Project Task', style: ProjectDesign.cardTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title *',
                    hintText: 'e.g. Implement user authentication',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Assignee *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedAssignee,
                  isExpanded: true,
                  items: _project.teamMembers.map((m) {
                    return DropdownMenuItem<String>(
                      value: m.employee.id,
                      child: Text(m.employee.fullName),
                    );
                  }).toList(),
                  onChanged: (val) => setDlgState(() => selectedAssignee = val),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (val) => setDlgState(() => selectedPriority = val ?? 'medium'),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || selectedAssignee == null) return;
                Navigator.pop(ctx);
                try {
                  await _projectService.createProjectTask(_project.id, {
                    'title': titleController.text.trim(),
                    'assignee': selectedAssignee,
                    'priority': selectedPriority,
                  });
                  _loadTasks();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add task: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: ProjectDesign.primary),
              child: const Text('Add Task', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateProgressDialog() {
    double currentProgress = _project.progress.toDouble();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ProjectDesign.radiusMd)),
          title: const Text('Update Completion Progress', style: ProjectDesign.cardTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${currentProgress.toInt()}%',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ProjectDesign.primary),
              ),
              const SizedBox(height: 12),
              Slider(
                value: currentProgress,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${currentProgress.toInt()}%',
                activeColor: ProjectDesign.primary,
                onChanged: (val) => setDlgState(() => currentProgress = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _projectService.updateProgress(_project.id, currentProgress.toInt());
                  _loadProjectDetails();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update progress: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: ProjectDesign.primary),
              child: const Text('Save Progress', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProjectScreen(project: _project)),
    );
    if (result == true) _loadProjectDetails();
  }

  Future<void> _removeTeamMember(String teamMemberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ProjectDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(ProjectDesign.sm),
              decoration: const BoxDecoration(
                color: ProjectDesign.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded,
                  color: ProjectDesign.danger, size: 22),
            ),
            const SizedBox(width: ProjectDesign.sm + 4),
            const Text('Remove Team Member', style: ProjectDesign.cardTitle),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove this team member from the project?',
          style: ProjectDesign.cardBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: ProjectDesign.buttonText
                    .copyWith(color: ProjectDesign.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ProjectDesign.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: ProjectDesign.md,
                vertical: ProjectDesign.sm + 2,
              ),
            ),
            child: Text('Remove',
                style: ProjectDesign.buttonText.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _projectService.removeTeamMember(
        _project.id,
        teamMemberId,
      );
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: ProjectDesign.sm + 4),
                Text('Team member removed successfully',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: ProjectDesign.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
            ),
            margin: const EdgeInsets.all(ProjectDesign.md),
          ),
        );
        _loadProjectDetails();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ProjectDesign.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(ProjectDesign.lg),
                decoration: const BoxDecoration(
                  color: ProjectDesign.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(ProjectDesign.primary),
                  ),
                ),
              ),
              const SizedBox(height: ProjectDesign.md),
              const Text(
                'Loading project details...',
                style: TextStyle(
                  color: ProjectDesign.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ProjectDesign.bg,
      body: RefreshIndicator(
        onRefresh: _loadProjectDetails,
        color: ProjectDesign.primary,
        backgroundColor: ProjectDesign.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(ProjectDesign.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildChatBanner(),
                  const SizedBox(height: ProjectDesign.md),
                  _buildProgressSection(),
                  const SizedBox(height: ProjectDesign.md),
                  _buildTasksSection(),
                  const SizedBox(height: ProjectDesign.md),
                  _buildQuickStats(),
                  const SizedBox(height: ProjectDesign.md),
                  _buildBudgetSection(),
                  const SizedBox(height: ProjectDesign.md),
                  _buildTimelineSection(),
                  const SizedBox(height: ProjectDesign.md),
                  _buildTeamSection(),
                  const SizedBox(height: ProjectDesign.md),
                  if (_project.tags.isNotEmpty) _buildTagsSection(),
                  if (_project.tags.isNotEmpty)
                    const SizedBox(height: ProjectDesign.md),
                  _buildDetailsSection(),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
        boxShadow: [
          BoxShadow(
            color: ProjectDesign.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _navigateToAddTeamMember,
        backgroundColor: ProjectDesign.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.person_add_rounded, size: 22),
        label: const Text(
          'Add Member',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            letterSpacing: -0.1,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
        ),
      ),
    );
  }

  // ===================== SLIVER APP BAR =====================
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: ProjectDesign.primary,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double top = constraints.biggest.height;
          final double collapsedHeight =
              kToolbarHeight + MediaQuery.of(context).padding.top;
          const double expandedHeight = 220;

          final double t = ((expandedHeight - top) /
              (expandedHeight - collapsedHeight))
              .clamp(0.0, 1.0);

          final EdgeInsets titlePadding = EdgeInsets.lerp(
            const EdgeInsets.only(left: 20, bottom: 16, right: 72),
            const EdgeInsets.only(left: 56, bottom: 16, right: 72),
            t,
          )!;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [ProjectDesign.primary, ProjectDesign.primaryDark],
              ),
            ),
            child: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: titlePadding,
              title: Text(
                _project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              background: Padding(
                padding: const EdgeInsets.fromLTRB(
                    ProjectDesign.md + 4, kToolbarHeight + 6, ProjectDesign.md + 4, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: ProjectDesign.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: ProjectDesign.sm + 4,
                          vertical: ProjectDesign.xs + 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _project.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    if (_project.description.isNotEmpty) ...[
                      const SizedBox(height: ProjectDesign.sm),
                      Text(
                        _project.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
      leading: Container(
        margin: const EdgeInsets.all(ProjectDesign.sm),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(ProjectDesign.sm),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          ),
          child: IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
            tooltip: 'Project Chat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProjectChatScreen(project: _project)),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.all(ProjectDesign.sm),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          ),
          child: IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: _navigateToEditProject,
          ),
        ),
      ],
    );
  }

  // ===================== CHAT BANNER =====================
  Widget _buildChatBanner() {
    return Container(
      padding: const EdgeInsets.all(ProjectDesign.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
        boxShadow: [
          BoxShadow(
            color: ProjectDesign.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Project Team Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Chat with ${_project.teamMembers.length} members & share files',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProjectChatScreen(project: _project)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ProjectDesign.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Open Chat',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== COMPLETION PROGRESS SECTION =====================
  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(ProjectDesign.md),
      decoration: BoxDecoration(
        color: ProjectDesign.surface,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
        border: Border.all(color: ProjectDesign.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up_rounded, size: 20, color: ProjectDesign.primary),
                  SizedBox(width: 8),
                  Text('Project Completion Progress', style: ProjectDesign.fieldLabel),
                ],
              ),
              InkWell(
                onTap: _showUpdateProgressDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ProjectDesign.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ProjectDesign.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_project.progress}% Complete',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ProjectDesign.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _project.progress == 100 ? ProjectDesign.successSoft : ProjectDesign.infoSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _project.progress == 100 ? 'COMPLETED' : (_project.status.toUpperCase()),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _project.progress == 100 ? ProjectDesign.success : ProjectDesign.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_project.progress / 100).clamp(0.0, 1.0),
              backgroundColor: ProjectDesign.bg,
              valueColor: AlwaysStoppedAnimation<Color>(
                _project.progress == 100 ? ProjectDesign.success : ProjectDesign.primary,
              ),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TASKS & MILESTONES SECTION =====================
  Widget _buildTasksSection() {
    return Container(
      padding: const EdgeInsets.all(ProjectDesign.md),
      decoration: BoxDecoration(
        color: ProjectDesign.surface,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
        border: Border.all(color: ProjectDesign.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 20, color: ProjectDesign.primary),
                  const SizedBox(width: 8),
                  Text('Tasks & Milestones (${_tasks.length})', style: ProjectDesign.fieldLabel),
                ],
              ),
              InkWell(
                onTap: _showAddTaskDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ProjectDesign.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: ProjectDesign.primary),
                      SizedBox(width: 2),
                      Text(
                        'Add Task',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ProjectDesign.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tasksLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2, color: ProjectDesign.primary),
              ),
            )
          else if (_tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'No tasks created for this project yet.',
                  style: TextStyle(fontSize: 12.5, color: ProjectDesign.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 14),
              itemBuilder: (context, i) {
                final task = _tasks[i];
                final isDone = task.status == 'completed';

                return Row(
                  children: [
                    Checkbox(
                      value: isDone,
                      activeColor: ProjectDesign.success,
                      onChanged: (_) => _toggleTask(task),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? ProjectDesign.textMuted : ProjectDesign.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Assignee: ${task.assigneeName} • ${task.priority.toUpperCase()}',
                            style: const TextStyle(fontSize: 11, color: ProjectDesign.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ===================== QUICK STATS =====================
  Widget _buildQuickStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: ProjectDesign.md,
      mainAxisSpacing: ProjectDesign.md,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          title: 'Duration',
          value: '${_project.duration}',
          unit: 'days',
          icon: Icons.schedule_rounded,
          gradient: [ProjectDesign.info, const Color(0xFF2563EB)],
        ),
        _buildStatCard(
          title: 'Team Size',
          value: '${_project.teamMembers.length}',
          unit: 'members',
          icon: Icons.people_rounded,
          gradient: [ProjectDesign.success, const Color(0xFF059669)],
        ),
        _buildStatCard(
          title: 'Budget Used',
          value: '${_project.budgetUtilization.toStringAsFixed(0)}',
          unit: '%',
          icon: Icons.pie_chart_rounded,
          gradient: [ProjectDesign.warning, const Color(0xFFD97706)],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => BudgetDetailScreen(project: _project)),
            );
          },
        ),
        _buildStatCard(
          title: 'Status',
          value: _project.status,
          unit: '',
          icon: Icons.flag_rounded,
          gradient: _getStatusGradient(_project.status),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required List<Color> gradient,
    VoidCallback? onTap,
  }) {
    Widget card = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(ProjectDesign.radiusLg),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(ProjectDesign.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(ProjectDesign.sm + 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unit.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 2),
                        child: Text(
                          unit,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: ProjectDesign.xs),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (onTap != null) card = GestureDetector(onTap: onTap, child: card);
    return card;
  }

  // ===================== SHARED CARD WRAPPER =====================
  Widget _buildSectionCard({
    required Widget header,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ProjectDesign.surface,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusLg),
        border: Border.all(color: ProjectDesign.border, width: 1),
        boxShadow: ProjectDesign.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(ProjectDesign.md + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: ProjectDesign.md),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required List<Color> gradient,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(ProjectDesign.sm + 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: ProjectDesign.sm + 4),
        Text(
          title,
          style: ProjectDesign.cardTitle.copyWith(fontSize: 16),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  // ===================== BUDGET =====================
  Widget _buildBudgetSection() {
    final progress = _project.budgetAllocated > 0
        ? (_project.budgetSpent / _project.budgetAllocated).clamp(0.0, 1.0)
        : 0.0;
    final isOver = progress > 0.8;
    final barColors = isOver
        ? [ProjectDesign.danger, const Color(0xFFB91C1C)]
        : [ProjectDesign.success, const Color(0xFF059669)];

    return _buildSectionCard(
      header: _buildSectionHeader(
        icon: Icons.currency_rupee_rounded,
        title: 'Budget Overview',
        gradient: [ProjectDesign.success, const Color(0xFF059669)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: ProjectDesign.border,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                height: 12,
                width: MediaQuery.of(context).size.width * progress * 0.82,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: barColors),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: barColors[0].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ProjectDesign.md + 4),
          Row(
            children: [
              Expanded(
                child: _buildBudgetItem(
                  'Spent',
                  '${_project.currency} ${_project.budgetSpent.toStringAsFixed(0)}',
                  ProjectDesign.danger,
                  Icons.trending_up_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: ProjectDesign.border),
              Expanded(
                child: _buildBudgetItem(
                  'Available',
                  '${_project.currency} ${(_project.budgetAllocated - _project.budgetSpent).toStringAsFixed(0)}',
                  ProjectDesign.success,
                  Icons.account_balance_wallet_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: ProjectDesign.border),
              Expanded(
                child: _buildBudgetItem(
                  'Total',
                  '${_project.currency} ${_project.budgetAllocated.toStringAsFixed(0)}',
                  ProjectDesign.primary,
                  Icons.payments_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: ProjectDesign.sm),
        Text(label, style: ProjectDesign.sectionLabel),
        const SizedBox(height: ProjectDesign.xs),
        Text(
          value,
          textAlign: TextAlign.center,
          style: ProjectDesign.fieldValue.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // ===================== TIMELINE =====================
  Widget _buildTimelineSection() {
    final daysRemaining = _project.endDate.difference(DateTime.now()).inDays;
    final totalDays = _project.endDate.difference(_project.startDate).inDays;
    final daysPassed = DateTime.now().difference(_project.startDate).inDays;
    final progress =
    totalDays > 0 ? (daysPassed / totalDays).clamp(0.0, 1.0) : 0.0;
    final isOverdue = daysRemaining < 0;

    final statusColors = isOverdue
        ? [ProjectDesign.danger, const Color(0xFFB91C1C)]
        : [ProjectDesign.success, const Color(0xFF059669)];

    final barColors = progress > 0.9
        ? [ProjectDesign.warning, const Color(0xFFD97706)]
        : [ProjectDesign.primary, ProjectDesign.primaryDark];

    return _buildSectionCard(
      header: _buildSectionHeader(
        icon: Icons.timeline_rounded,
        title: 'Project Timeline',
        gradient: [ProjectDesign.primaryDark, ProjectDesign.primary],
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: ProjectDesign.sm + 4, vertical: ProjectDesign.xs + 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: statusColors),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 5),
              Text(
                isOverdue ? 'Overdue' : '$daysRemaining days',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: ProjectDesign.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                height: 8,
                width: MediaQuery.of(context).size.width * progress * 0.82,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: barColors),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: ProjectDesign.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDateItem(
                  'Start', _formatDate(_project.startDate), Icons.play_circle_rounded),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: ProjectDesign.md, vertical: ProjectDesign.sm),
                decoration: BoxDecoration(
                  color: ProjectDesign.primarySoft,
                  borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                  border: Border.all(color: ProjectDesign.primaryLight),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ProjectDesign.primary,
                    fontSize: 15,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              _buildDateItem(
                  'End', _formatDate(_project.endDate), Icons.flag_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateItem(String label, String date, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: ProjectDesign.primary, size: 18),
        const SizedBox(height: ProjectDesign.xs),
        Text(label, style: ProjectDesign.sectionLabel),
        const SizedBox(height: ProjectDesign.xs),
        Text(date,
            style: ProjectDesign.fieldValue.copyWith(fontSize: 13)),
      ],
    );
  }

  // ===================== TEAM =====================
  Widget _buildTeamSection() {
    return _buildSectionCard(
      header: _buildSectionHeader(
        icon: Icons.people_rounded,
        title: 'Team Members',
        gradient: [ProjectDesign.info, const Color(0xFF2563EB)],
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: ProjectDesign.sm + 4, vertical: ProjectDesign.xs + 2),
          decoration: BoxDecoration(
            color: ProjectDesign.primarySoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ProjectDesign.primaryLight),
          ),
          child: Text(
            '${_project.teamMembers.length} members',
            style: const TextStyle(
              color: ProjectDesign.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      child: _project.teamMembers.isEmpty
          ? _buildEmptyTeam()
          : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _project.teamMembers.length,
        itemBuilder: (context, index) =>
            _buildTeamMemberCard(_project.teamMembers[index]),
      ),
    );
  }

  Widget _buildEmptyTeam() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ProjectDesign.lg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(ProjectDesign.lg),
            decoration: const BoxDecoration(
              color: ProjectDesign.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_off_rounded,
                size: 44, color: ProjectDesign.primary),
          ),
          const SizedBox(height: ProjectDesign.md),
          const Text('No team members yet', style: ProjectDesign.cardTitle),
          const SizedBox(height: ProjectDesign.xs),
          Text('Add team members to get started',
              style: ProjectDesign.hint.copyWith(fontSize: 12)),
          const SizedBox(height: ProjectDesign.md + 4),
          ElevatedButton.icon(
            onPressed: _navigateToAddTeamMember,
            style: ElevatedButton.styleFrom(
              backgroundColor: ProjectDesign.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: ProjectDesign.lg,
                vertical: ProjectDesign.sm + 4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              ),
            ),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: Text('Add Team Member',
                style: ProjectDesign.buttonText.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(TeamMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: ProjectDesign.sm + 4),
      padding: const EdgeInsets.all(ProjectDesign.md),
      decoration: BoxDecoration(
        color: ProjectDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
        border: Border.all(color: ProjectDesign.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ProjectDesign.primary, ProjectDesign.primaryDark],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ProjectDesign.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 22,
                  child: Text(
                    member.employee.fullName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: ProjectDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.employee.fullName,
                      style: ProjectDesign.fieldValue.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: ProjectDesign.xs + 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: ProjectDesign.sm, vertical: 4),
                          decoration: BoxDecoration(
                            color: ProjectDesign.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ProjectDesign.primaryLight),
                          ),
                          child: Text(
                            member.role.name,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: ProjectDesign.primaryDark,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: ProjectDesign.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: ProjectDesign.sm, vertical: 4),
                          decoration: BoxDecoration(
                            color: ProjectDesign.infoSoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ProjectDesign.infoBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.work_history_rounded,
                                  size: 10, color: ProjectDesign.info),
                              const SizedBox(width: 4),
                              Text(
                                '${member.allocation}%',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: ProjectDesign.info,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: ProjectDesign.surface,
                  borderRadius: BorderRadius.circular(ProjectDesign.radiusSm - 2),
                  border: Border.all(color: ProjectDesign.border),
                ),
                child: PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: ProjectDesign.textSecondary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ProjectDesign.radiusSm)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded,
                              size: 18, color: ProjectDesign.info),
                          const SizedBox(width: ProjectDesign.sm + 4),
                          Text('Edit', style: ProjectDesign.cardBody),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_rounded,
                              size: 18, color: ProjectDesign.danger),
                          const SizedBox(width: ProjectDesign.sm + 4),
                          Text('Remove',
                              style: ProjectDesign.cardBody
                                  .copyWith(color: ProjectDesign.danger)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'remove') _removeTeamMember(member.id);
                  },
                ),
              ),
            ],
          ),
          if (member.responsibilities?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(
                  top: ProjectDesign.md, left: 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.checklist_rounded,
                          size: 13, color: ProjectDesign.textSecondary),
                      const SizedBox(width: 6),
                      Text('Responsibilities',
                          style: ProjectDesign.sectionLabel),
                    ],
                  ),
                  const SizedBox(height: ProjectDesign.sm),
                  ...member.responsibilities!.take(2).map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: ProjectDesign.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: ProjectDesign.successSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 12, color: ProjectDesign.success),
                        ),
                        const SizedBox(width: ProjectDesign.sm),
                        Expanded(
                          child: Text(
                            r.title,
                            style: ProjectDesign.cardBody.copyWith(
                              fontSize: 12,
                              color: ProjectDesign.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (member.responsibilities!.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        '+${member.responsibilities!.length - 2} more responsibilities',
                        style: const TextStyle(
                          fontSize: 11,
                          color: ProjectDesign.primary,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
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

  // ===================== TAGS =====================
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer_rounded,
                size: 18, color: ProjectDesign.primary),
            const SizedBox(width: ProjectDesign.sm),
            Text('Tags', style: ProjectDesign.cardTitle.copyWith(fontSize: 16)),
          ],
        ),
        const SizedBox(height: ProjectDesign.sm + 4),
        Wrap(
          spacing: ProjectDesign.sm,
          runSpacing: ProjectDesign.sm,
          children: _project.tags
              .map((tag) => Container(
            padding: const EdgeInsets.symmetric(
                horizontal: ProjectDesign.sm + 4,
                vertical: ProjectDesign.sm),
            decoration: BoxDecoration(
              color: ProjectDesign.primarySoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ProjectDesign.primaryLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tag,
                  style: const TextStyle(
                    color: ProjectDesign.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: ProjectDesign.primary),
                ),
              ],
            ),
          ))
              .toList(),
        ),
      ],
    );
  }

  // ===================== DETAILS =====================
  Widget _buildDetailsSection() {
    return _buildSectionCard(
      header: _buildSectionHeader(
        icon: Icons.info_rounded,
        title: 'Project Details',
        gradient: [ProjectDesign.warning, const Color(0xFFD97706)],
      ),
      child: Column(
        children: [
          _buildDetailRow(
              'Manager', _project.manager.fullName, Icons.person_rounded),
          _buildDetailRow(
              'Created', _formatDate(_project.createdAt), Icons.calendar_today_rounded),
          _buildDetailRow(
              'Updated', _formatDate(_project.createdAt), Icons.update_rounded),
          _buildDetailRow('Project ID', _project.id, Icons.tag_rounded),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ProjectDesign.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ProjectDesign.sm),
            decoration: BoxDecoration(
              color: ProjectDesign.primarySoft,
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm - 2),
            ),
            child: Icon(icon, size: 16, color: ProjectDesign.primary),
          ),
          const SizedBox(width: ProjectDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ProjectDesign.sectionLabel),
                const SizedBox(height: 2),
                Text(value, style: ProjectDesign.fieldValue.copyWith(fontSize: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HELPERS =====================
  void _navigateToAddTeamMember() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTeamMemberScreen(projectId: _project.id),
      ),
    );
    if (result == true) _loadProjectDetails();
  }

  List<Color> _getStatusGradient(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return [ProjectDesign.success, const Color(0xFF059669)];
      case 'in-progress':
      case 'active':
        return [ProjectDesign.info, const Color(0xFF2563EB)];
      case 'on-hold':
        return [ProjectDesign.warning, const Color(0xFFD97706)];
      case 'cancelled':
        return [ProjectDesign.danger, const Color(0xFFB91C1C)];
      default:
        return [ProjectDesign.neutral, const Color(0xFF4B5563)];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}