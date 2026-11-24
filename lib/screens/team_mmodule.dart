import 'package:flutter/material.dart';
import '../services/project_service.dart';

// ===================== SHARED DESIGN TOKENS =====================
// In production, move this to lib/theme/project_design.dart and import.
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

// ===================== PROJECT DROPDOWN =====================

class ProjectDropdown extends StatefulWidget {
  final Function(String?) onProjectSelected;
  final String? initialValue;

  const ProjectDropdown({
    Key? key,
    required this.onProjectSelected,
    this.initialValue,
  }) : super(key: key);

  @override
  State<ProjectDropdown> createState() => _ProjectDropdownState();
}

class _ProjectDropdownState extends State<ProjectDropdown> {
  final ProjectService _projectService = ProjectService();
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = false;
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.initialValue;
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final response = await _projectService.getProjectsForDropdown();

    if (!mounted) return;

    if (response['success'] == true) {
      final projectsList =
      List<Map<String, dynamic>>.from(response['data'] ?? []);
      setState(() {
        _projects = projectsList;
        if (_selectedProjectId == null && projectsList.isNotEmpty) {
          _selectedProjectId = projectsList[0]['value'].toString();
          Future.microtask(
                () => widget.onProjectSelected(_selectedProjectId),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Failed to load projects',
            style: const TextStyle(fontWeight: FontWeight.w600),
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
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ProjectDesign.surface,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
        border: Border.all(color: ProjectDesign.border, width: 1),
        boxShadow: ProjectDesign.softShadow,
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedProjectId,
        isExpanded: true,
        dropdownColor: ProjectDesign.surface,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: ProjectDesign.primary,
          size: 20,
        ),
        decoration: InputDecoration(
          labelText: 'PROJECT',
          labelStyle: const TextStyle(
            color: ProjectDesign.textMuted,
            fontWeight: FontWeight.w800,
            fontSize: 10.5,
            letterSpacing: 0.8,
          ),
          floatingLabelStyle: const TextStyle(
            color: ProjectDesign.primary,
            fontWeight: FontWeight.w800,
            fontSize: 10.5,
            letterSpacing: 0.8,
          ),
          hintText: 'Choose a project',
          hintStyle: const TextStyle(
            color: ProjectDesign.textMuted,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.folder_special_outlined,
            color: ProjectDesign.primary,
            size: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ProjectDesign.sm,
            vertical: ProjectDesign.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          isDense: true,
        ),
        items: _projects.map((project) {
          final isSelected =
              project['value'].toString() == _selectedProjectId;
          return DropdownMenuItem<String>(
            value: project['value'].toString(),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected
                      ? ProjectDesign.primary
                      : ProjectDesign.textMuted,
                ),
                const SizedBox(width: ProjectDesign.sm + 2),
                Expanded(
                  child: Text(
                    project['label'],
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: ProjectDesign.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: _isLoading
            ? null
            : (String? newValue) {
          setState(() => _selectedProjectId = newValue);
          widget.onProjectSelected(newValue);
        },
        validator: (value) =>
        value == null ? 'Please select a project' : null,
      ),
    );
  }
}

// ===================== TEAM MEMBERS PAGE =====================

class TeamMembersPage extends StatefulWidget {
  const TeamMembersPage({Key? key}) : super(key: key);

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage>
    with SingleTickerProviderStateMixin {
  final ProjectService _projectService = ProjectService();
  List<dynamic> _teamMembers = [];
  bool _isLoading = false;
  String? _selectedProjectId;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamMembers(String projectId) async {
    setState(() => _isLoading = true);
    _animationController.reset();

    final response = await _projectService.getProjectTeam(projectId);
    if (!mounted) return;

    if (response['success'] == true) {
      setState(() => _teamMembers = response['data'] ?? []);
      _animationController.forward();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Failed to load team members',
            style: const TextStyle(fontWeight: FontWeight.w600),
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
    if (mounted) setState(() => _isLoading = false);
  }

  // Role styles: (fg, bg, border)
  (Color, Color, Color) _getRoleStyle(String roleCode) {
    switch (roleCode.toUpperCase()) {
      case 'PROJECT_MANAGER':
        return (
        ProjectDesign.primary,
        ProjectDesign.primarySoft,
        ProjectDesign.primaryLight,
        );
      case 'TECH_LEAD':
        return (
        ProjectDesign.info,
        ProjectDesign.infoSoft,
        ProjectDesign.infoBorder,
        );
      case 'DEVELOPER':
        return (
        ProjectDesign.success,
        ProjectDesign.successSoft,
        ProjectDesign.successBorder,
        );
      case 'DESIGNER':
        return (
        ProjectDesign.warning,
        ProjectDesign.warningSoft,
        ProjectDesign.warningBorder,
        );
      default:
        return (
        ProjectDesign.neutral,
        ProjectDesign.neutralSoft,
        ProjectDesign.neutralBorder,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProjectDesign.bg,
      body: Column(
        children: [
          _buildHeaderCard(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ProjectDesign.md,
        ProjectDesign.md,
        ProjectDesign.md,
        ProjectDesign.md,
      ),
      decoration: BoxDecoration(
        color: ProjectDesign.surface,
        border: const Border(
          bottom: BorderSide(color: ProjectDesign.border, width: 1),
        ),
        boxShadow: ProjectDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ProjectDesign.primarySoft,
                  borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                  border: Border.all(
                    color: ProjectDesign.primaryLight,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: ProjectDesign.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: ProjectDesign.sm + 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ProjectDesign.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage your project team',
                      style: TextStyle(
                        fontSize: 12,
                        color: ProjectDesign.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ProjectDesign.md),
          ProjectDropdown(
            onProjectSelected: (projectId) {
              setState(() => _selectedProjectId = projectId);
              if (projectId != null) {
                _loadTeamMembers(projectId);
              } else {
                setState(() => _teamMembers = []);
              }
            },
            initialValue: _selectedProjectId,
          ),
        ],
      ),
    );
  }

  // ===================== BODY =====================

  Widget _buildBody() {
    if (_selectedProjectId == null) {
      return _buildEmptyState(
        icon: Icons.folder_open_rounded,
        title: 'No Project Selected',
        subtitle: 'Select a project above to view its team members.',
      );
    }
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor:
            AlwaysStoppedAnimation<Color>(ProjectDesign.primary),
          ),
        ),
      );
    }
    if (_teamMembers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_off_outlined,
        title: 'No Team Members',
        subtitle: 'This project has no team members yet.',
      );
    }

    return Column(
      children: [
        _buildCountHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              ProjectDesign.md,
              0,
              ProjectDesign.md,
              ProjectDesign.xl,
            ),
            itemCount: _teamMembers.length,
            itemBuilder: (context, index) {
              final member = _teamMembers[index];
              return FadeTransition(
                opacity: _animationController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        (index / _teamMembers.length).clamp(0.0, 0.6),
                        1.0,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
                  child: _buildTeamMemberCard(member),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCountHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ProjectDesign.md,
        ProjectDesign.md,
        ProjectDesign.md,
        ProjectDesign.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: ProjectDesign.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: ProjectDesign.sm),
          Text(
            'TEAM',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: ProjectDesign.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: ProjectDesign.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: ProjectDesign.primarySoft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: ProjectDesign.primaryLight,
                width: 1,
              ),
            ),
            child: Text(
              '${_teamMembers.length}',
              style: const TextStyle(
                fontSize: 10,
                color: ProjectDesign.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== MEMBER CARD =====================

  Widget _buildTeamMemberCard(Map<String, dynamic> member) {
    final employee = member['employee'];
    final role = member['role'];
    final allocation = (member['allocation'] ?? 0) as num;
    final responsibilities =
        (member['responsibilities'] as List<dynamic>?) ?? [];

    final (roleColor, roleBg, roleBorder) = _getRoleStyle(role['code']);
    final initial = (employee['firstName'] as String).isNotEmpty
        ? employee['firstName'][0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: ProjectDesign.sm + 4),
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
          onTap: () {
            // TODO: Show member details
          },
          child: Padding(
            padding: const EdgeInsets.all(ProjectDesign.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== TOP: AVATAR + NAME + ROLE =====
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [roleColor, roleColor.withOpacity(0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                        BorderRadius.circular(ProjectDesign.radiusSm + 2),
                        boxShadow: [
                          BoxShadow(
                            color: roleColor.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
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
                            employee['fullName'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: ProjectDesign.textPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: ProjectDesign.sm,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: roleBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: roleBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  (role['name'] ?? '').toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: roleColor,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.mail_outline_rounded,
                                size: 12,
                                color: ProjectDesign.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  employee['email'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ProjectDesign.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      borderRadius:
                      BorderRadius.circular(ProjectDesign.radiusSm),
                      child: InkWell(
                        borderRadius:
                        BorderRadius.circular(ProjectDesign.radiusSm),
                        onTap: () => _showMemberOptions(member),
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            color: ProjectDesign.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: ProjectDesign.md),
                Container(height: 1, color: ProjectDesign.border),
                const SizedBox(height: ProjectDesign.md),

                // ===== STATS ROW =====
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.pie_chart_outline_rounded,
                        label: 'Allocation',
                        value: '${allocation.toStringAsFixed(0)}%',
                        isWarning: allocation >= 80,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: ProjectDesign.border,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.assignment_outlined,
                        label: 'Responsibilities',
                        value: '${responsibilities.length}',
                        isWarning: false,
                      ),
                    ),
                  ],
                ),

                // ===== RESPONSIBILITIES =====
                if (responsibilities.isNotEmpty) ...[
                  const SizedBox(height: ProjectDesign.md),
                  Container(height: 1, color: ProjectDesign.border),
                  const SizedBox(height: ProjectDesign.sm + 4),
                  const Text(
                    'RECENT RESPONSIBILITIES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ProjectDesign.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: ProjectDesign.sm),
                  ...responsibilities.take(2).map((resp) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getPriorityColor(resp['priority']),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: ProjectDesign.sm),
                          Expanded(
                            child: Text(
                              resp['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: ProjectDesign.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: ProjectDesign.sm),
                          Text(
                            '${resp['progress']}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ProjectDesign.textSecondary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isWarning,
  }) {
    final color = isWarning ? ProjectDesign.warning : ProjectDesign.primary;
    final bg = isWarning
        ? ProjectDesign.warningSoft
        : ProjectDesign.primarySoft;
    final border = isWarning
        ? ProjectDesign.warningBorder
        : ProjectDesign.primaryLight;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(ProjectDesign.radiusSm - 2),
            border: Border.all(color: border, width: 1),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: ProjectDesign.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9.5,
                color: ProjectDesign.textMuted,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: ProjectDesign.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return ProjectDesign.danger;
      case 'medium':
        return ProjectDesign.warning;
      case 'low':
        return ProjectDesign.success;
      default:
        return ProjectDesign.textMuted;
    }
  }

  // ===================== EMPTY STATE =====================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProjectDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: ProjectDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 42,
                color: ProjectDesign.primary,
              ),
            ),
            const SizedBox(height: ProjectDesign.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ProjectDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: ProjectDesign.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: ProjectDesign.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== MEMBER OPTIONS =====================

  void _showMemberOptions(Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: ProjectDesign.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ProjectDesign.radiusXl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: ProjectDesign.sm + 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ProjectDesign.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: ProjectDesign.md),

              // Member preview
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ProjectDesign.lg,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ProjectDesign.primarySoft,
                        borderRadius:
                        BorderRadius.circular(ProjectDesign.radiusSm),
                        border: Border.all(
                          color: ProjectDesign.primaryLight,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (member['employee']['firstName'] as String)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ProjectDesign.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: ProjectDesign.sm + 4),
                    Expanded(
                      child: Text(
                        member['employee']['fullName'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ProjectDesign.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ProjectDesign.sm + 4),
              const Divider(height: 1, color: ProjectDesign.border),

              // Edit
              _buildOptionTile(
                icon: Icons.edit_outlined,
                iconColor: ProjectDesign.info,
                iconBg: ProjectDesign.infoSoft,
                title: 'Edit Member',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit functionality pending'),
                    ),
                  );
                },
              ),

              // Remove
              _buildOptionTile(
                icon: Icons.person_remove_outlined,
                iconColor: ProjectDesign.danger,
                iconBg: ProjectDesign.dangerSoft,
                title: 'Remove Member',
                titleColor: ProjectDesign.danger,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Remove functionality pending'),
                    ),
                  );
                },
              ),

              const SizedBox(height: ProjectDesign.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ProjectDesign.lg,
            vertical: ProjectDesign.sm + 4,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius:
                  BorderRadius.circular(ProjectDesign.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: ProjectDesign.sm + 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? ProjectDesign.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}