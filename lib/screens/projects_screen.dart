// screens/projects_screen.dart
import 'package:flutter/material.dart';
import 'package:staffsync/screens/project_detail_screen.dart';
import 'package:staffsync/screens/project_chat_screen.dart';
import 'package:staffsync/services/auth_service.dart';
import '../services/project_service.dart';
import '../models/project_model.dart';
import 'add_project_screen.dart';

// ===================== PROJECT DESIGN TOKENS =====================
class ProjectDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF6D28D9);
  static const Color primarySoft = Color(0xFFF5F3FF);
  static const Color primaryLight = Color(0xFFDDD6FE);

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

  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralSoft = Color(0xFFF3F4F6);
  static const Color neutralBorder = Color(0xFFE5E7EB);

  // ===== Typography =====
  static const TextStyle screenTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.4,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: textSecondary,
    letterSpacing: 0.8,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.4,
    height: 1.3,
  );

  static const TextStyle cardBody = TextStyle(
    fontSize: 13,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.1,
  );

  static const TextStyle fieldValue = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle hint = TextStyle(
    color: textMuted,
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonText = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 13.5,
    letterSpacing: -0.1,
  );

  static const TextStyle microLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.6,
  );

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

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  _ProjectsScreenState createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final AuthService _authService = AuthService();
  final ProjectService _projectService = ProjectService();
  List<Project> _projects = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _userRole;

  String _selectedFilter = 'all';
  String _searchQuery = '';

  bool get isManager {
    if (_userRole == null) return false;
    final r = _userRole!.trim().toLowerCase();
    return ['manager', 'superadmin', 'hr_admin', 'admin', 'hr'].contains(r);
  }

  List<Project> get _filteredProjects {
    return _projects.where((p) {
      if (_selectedFilter != 'all') {
        final st = p.status.toLowerCase();
        if (_selectedFilter == 'active') {
          if (st != 'active' && st != 'in-progress') return false;
        } else if (st != _selectedFilter) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = p.name.toLowerCase().contains(q);
        final matchCode = p.code.toLowerCase().contains(q);
        if (!matchName && !matchCode) return false;
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUserRole();
    await _loadProjects();
  }

  Future<void> _loadUserRole() async {
    final role = await _authService.getUserRole();
    if (!mounted) return;
    setState(() => _userRole = role);
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await _projectService.getAllProjects();
      if (!mounted) return;

      if (result['success']) {
        final projectsData = result['data']['projects'] as List;
        setState(() {
          _projects = projectsData.map((p) => Project.fromJson(p)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load projects';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProjectDesign.bg,
      body: _buildBody(),
      floatingActionButton: isManager ? _buildFab() : null,
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddProjectScreen()),
          ).then((_) => _loadProjects());
        },
        backgroundColor: ProjectDesign.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'New Project',
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

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_hasError) return _buildErrorState();

    final projects = _filteredProjects;

    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProjects,
            color: ProjectDesign.primary,
            backgroundColor: ProjectDesign.surface,
            child: projects.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      ProjectDesign.md,
                      ProjectDesign.sm,
                      ProjectDesign.md,
                      80,
                    ),
                    itemCount: projects.length,
                    itemBuilder: (context, index) =>
                        _buildProjectCard(projects[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'active', 'label': 'Active'},
      {'key': 'planning', 'label': 'Planning'},
      {'key': 'completed', 'label': 'Completed'},
      {'key': 'on-hold', 'label': 'On Hold'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: ProjectDesign.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ProjectDesign.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 20, color: ProjectDesign.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Search projects by name or code...',
                      hintStyle: TextStyle(fontSize: 13, color: ProjectDesign.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _searchQuery = ''),
                    child: const Icon(Icons.close_rounded, size: 18, color: ProjectDesign.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = filters[i];
                final isSelected = _selectedFilter == f['key'];
                return ChoiceChip(
                  label: Text(
                    f['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : ProjectDesign.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: ProjectDesign.primary,
                  backgroundColor: ProjectDesign.bg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? ProjectDesign.primary : ProjectDesign.border,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onSelected: (_) {
                    setState(() => _selectedFilter = f['key']!);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor:
              AlwaysStoppedAnimation<Color>(ProjectDesign.primary),
            ),
          ),
          SizedBox(height: ProjectDesign.md),
          Text(
            'Loading projects...',
            style: TextStyle(
              fontSize: 13,
              color: ProjectDesign.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProjectDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(ProjectDesign.lg),
              decoration: const BoxDecoration(
                color: ProjectDesign.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: ProjectDesign.danger,
              ),
            ),
            const SizedBox(height: ProjectDesign.md),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ProjectDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: ProjectDesign.sm),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: ProjectDesign.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: ProjectDesign.lg),
            ElevatedButton.icon(
              onPressed: _loadProjects,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ProjectDesign.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: ProjectDesign.lg,
                  vertical: ProjectDesign.sm + 4,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(ProjectDesign.radiusSm),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProjectDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: ProjectDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: ProjectDesign.primary,
              ),
            ),
            const SizedBox(height: ProjectDesign.lg),
            const Text(
              'No Projects Yet',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: ProjectDesign.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: ProjectDesign.sm),
            Text(
              isManager
                  ? 'Start by creating your first project to track budgets and team progress.'
                  : 'No projects assigned yet. Check back soon.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: ProjectDesign.textMuted,
                height: 1.5,
              ),
            ),
            if (isManager) ...[
              const SizedBox(height: ProjectDesign.lg),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddProjectScreen()),
                ).then((_) => _loadProjects()),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Create First Project'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProjectDesign.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ProjectDesign.lg,
                    vertical: ProjectDesign.sm + 6,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(ProjectDesign.radiusSm),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final daysRemaining = project.endDate.difference(DateTime.now()).inDays;
    final progress = project.budgetAllocated > 0
        ? (project.budgetSpent / project.budgetAllocated).clamp(0.0, 1.0)
        : 0.0;
    final isOverBudget = progress > 0.8;

    return Container(
      margin: const EdgeInsets.only(bottom: ProjectDesign.md),
      decoration: BoxDecoration(
        color: ProjectDesign.surface,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusLg),
        border: Border.all(color: ProjectDesign.border, width: 1),
        boxShadow: ProjectDesign.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusLg),
          onTap: () => _openProject(project),
          child: Padding(
            padding: const EdgeInsets.all(ProjectDesign.md + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER =====
                Row(
                  children: [
                    _buildStatusBadge(project.status),
                    const SizedBox(width: 6),
                    _buildPriorityBadge(project.priority),
                    const Spacer(),
                    _buildCodeChip(project.code),
                  ],
                ),
                const SizedBox(height: ProjectDesign.md),

                // ===== TITLE =====
                Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ProjectDesign.textPrimary,
                    letterSpacing: -0.4,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    project.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ProjectDesign.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: ProjectDesign.md),

                // ===== COMPLETION PROGRESS BAR =====
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: ProjectDesign.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Completion Progress',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ProjectDesign.textSecondary,
                            ),
                          ),
                          Text(
                            '${project.progress}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: ProjectDesign.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (project.progress / 100).clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            project.progress == 100 ? ProjectDesign.success : ProjectDesign.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ProjectDesign.sm + 4),

                // ===== TIMELINE =====
                _buildTimelineRow(project, daysRemaining),
                const SizedBox(height: ProjectDesign.sm + 4),

                // ===== BUDGET =====
                _buildBudgetBlock(project, progress, isOverBudget),
                const SizedBox(height: ProjectDesign.md),

                // ===== FOOTER =====
                Row(
                  children: [
                    Expanded(child: _buildTagsWrap(project.tags)),
                    const SizedBox(width: ProjectDesign.sm),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProjectChatScreen(project: project)),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ProjectDesign.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: ProjectDesign.primaryLight),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 14, color: ProjectDesign.primary),
                            SizedBox(width: 4),
                            Text(
                              'Chat',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: ProjectDesign.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: ProjectDesign.sm),
                    _buildManagerAvatar(project.manager.fullName),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (color, bgColor, borderColor, icon, label) =
    _getStatusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ProjectDesign.sm + 2,
        vertical: ProjectDesign.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bg = ProjectDesign.neutralSoft;
    Color text = ProjectDesign.neutral;
    final p = priority.toLowerCase();
    if (p == 'urgent') {
      bg = ProjectDesign.dangerSoft;
      text = ProjectDesign.danger;
    } else if (p == 'high') {
      bg = ProjectDesign.warningSoft;
      text = ProjectDesign.warning;
    } else if (p == 'medium') {
      bg = ProjectDesign.infoSoft;
      text = ProjectDesign.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ProjectDesign.sm + 2,
        vertical: ProjectDesign.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: text,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (Color, Color, Color, IconData, String) _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return (
        ProjectDesign.success,
        ProjectDesign.successSoft,
        ProjectDesign.successBorder,
        Icons.check_circle_rounded,
        'COMPLETED'
        );
      case 'in-progress':
      case 'active':
        return (
        ProjectDesign.info,
        ProjectDesign.infoSoft,
        ProjectDesign.infoBorder,
        Icons.play_circle_rounded,
        'ACTIVE'
        );
      case 'on-hold':
        return (
        ProjectDesign.warning,
        ProjectDesign.warningSoft,
        ProjectDesign.warningBorder,
        Icons.pause_circle_rounded,
        'ON HOLD'
        );
      case 'cancelled':
        return (
        ProjectDesign.danger,
        ProjectDesign.dangerSoft,
        ProjectDesign.dangerBorder,
        Icons.cancel_rounded,
        'CANCELLED'
        );
      default:
        return (
        ProjectDesign.neutral,
        ProjectDesign.neutralSoft,
        ProjectDesign.neutralBorder,
        Icons.circle_rounded,
        status.toUpperCase()
        );
    }
  }

  Widget _buildCodeChip(String code) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ProjectDesign.sm + 2,
        vertical: ProjectDesign.xs + 1,
      ),
      decoration: BoxDecoration(
        color: ProjectDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusSm - 2),
        border: Border.all(color: ProjectDesign.border, width: 1),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color: ProjectDesign.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTimelineRow(Project project, int daysRemaining) {
    final (color, bgColor, borderColor, icon, label) =
    _getTimelineStyle(daysRemaining);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ProjectDesign.sm + 4,
        vertical: ProjectDesign.sm + 2,
      ),
      decoration: BoxDecoration(
        color: ProjectDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
        border: Border.all(color: ProjectDesign.border, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: ProjectDesign.primary,
          ),
          const SizedBox(width: ProjectDesign.sm),
          Expanded(
            child: Text(
              '${_formatDate(project.startDate)} — ${_formatDate(project.endDate)}',
              style: const TextStyle(
                fontSize: 12,
                color: ProjectDesign.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: ProjectDesign.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ProjectDesign.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color, IconData, String) _getTimelineStyle(int days) {
    if (days < 0) {
      return (
      ProjectDesign.danger,
      ProjectDesign.dangerSoft,
      ProjectDesign.dangerBorder,
      Icons.warning_amber_rounded,
      'Overdue'
      );
    }
    if (days < 30) {
      return (
      ProjectDesign.warning,
      ProjectDesign.warningSoft,
      ProjectDesign.warningBorder,
      Icons.timer_rounded,
      '$days days'
      );
    }
    return (
    ProjectDesign.success,
    ProjectDesign.successSoft,
    ProjectDesign.successBorder,
    Icons.timer_outlined,
    '$days days'
    );
  }

  Widget _buildBudgetBlock(Project project, double progress, bool isOver) {
    final color = isOver ? ProjectDesign.danger : ProjectDesign.primary;
    final soft = isOver
        ? ProjectDesign.dangerSoft
        : ProjectDesign.primarySoft;
    final border = isOver
        ? ProjectDesign.dangerBorder
        : ProjectDesign.primaryLight;

    return Container(
      padding: const EdgeInsets.all(ProjectDesign.sm + 4),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                'BUDGET USAGE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                '${project.budgetUtilization.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: ProjectDesign.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: ProjectDesign.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${project.currency} ${_formatCurrency(project.budgetSpent)} spent',
                style: const TextStyle(
                  fontSize: 11,
                  color: ProjectDesign.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'of ${project.currency} ${_formatCurrency(project.budgetAllocated)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: ProjectDesign.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsWrap(List<String> tags) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ProjectDesign.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: ProjectDesign.primarySoft,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: ProjectDesign.primaryLight,
              width: 1,
            ),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              fontSize: 10.5,
              color: ProjectDesign.primaryDark,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildManagerAvatar(String fullName) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ProjectDesign.primary, ProjectDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ProjectDesign.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _openProject(Project project) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(ProjectDesign.lg),
          decoration: BoxDecoration(
            color: ProjectDesign.surface,
            borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
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
      ),
    );

    try {
      bool isMember = await _projectService.isUserInProject(project.id);
      if (!mounted) return;
      Navigator.pop(context);

      if (isMember) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(project: project),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'You are not a member of this project',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: ProjectDesign.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
            ),
            margin: const EdgeInsets.all(ProjectDesign.md),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}