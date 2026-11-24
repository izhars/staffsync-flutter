// screens/project_roles_screen.dart
import 'package:flutter/material.dart';
import '../component/add_role_dialog.dart';
import '../component/role_detail_sheet.dart';
import '../services/auth_service.dart';
import '../services/project_service.dart';
import '../models/role_model.dart';
import 'projects_screen.dart';

class ProjectRolesScreen extends StatefulWidget {
  const ProjectRolesScreen({Key? key}) : super(key: key);

  @override
  _ProjectRolesScreenState createState() => _ProjectRolesScreenState();
}

class _ProjectRolesScreenState extends State<ProjectRolesScreen> {
  final ProjectService _projectService = ProjectService();
  final AuthService _authService = AuthService();
  List<ProjectRole> _roles = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  String? _userRole;
  ProjectRole? _roleToDelete;
  bool _showDeleteDialog = false;
  bool _isProcessing = false;

  bool get isManager {
    if (_userRole == null) return false;
    final r = _userRole!.trim().toLowerCase();
    return ['manager', 'superadmin', 'hr_admin', 'admin', 'hr'].contains(r);
  }

  List<ProjectRole> get _filteredRoles {
    if (_searchController.text.isEmpty) return _roles;
    final query = _searchController.text.toLowerCase();
    return _roles.where((r) {
      return r.name.toLowerCase().contains(query) ||
          r.code.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUserRole();
    await _loadRoles();
  }

  Future<void> _loadUserRole() async {
    final role = await _authService.getUserRole();
    if (!mounted) return;
    setState(() => _userRole = role);
  }

  Future<void> _loadRoles() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await _projectService.getProjectRoles();
      if (result['success']) {
        final rolesData = result['data'] as List;
        setState(() {
          _roles = rolesData.map((r) => ProjectRole.fromJson(r)).toList();
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
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load roles';
        _isLoading = false;
      });
    }
  }

  Future<void> _editRole(ProjectRole role) async {
    if (!isManager) {
      _showSnack('Only managers can edit roles');
      return;
    }

    final result = await showDialog(
      context: context,
      builder: (_) => AddRoleDialog(initialRole: role),
    );

    if (result == true) {
      _showSnack('Role updated successfully');
      await _loadRoles();
    }
  }

  void _confirmDeleteRole(ProjectRole role) {
    if (!isManager) {
      _showSnack('Only managers can delete roles');
      return;
    }

    setState(() {
      _roleToDelete = role;
      _showDeleteDialog = true;
    });
  }

  Future<void> _executeDeleteRole() async {
    if (_roleToDelete == null) return;

    setState(() => _isProcessing = true);

    try {
      final response =
      await _projectService.deleteProjectRole(_roleToDelete!.id);

      if (response['success']) {
        _showSnack('Role deleted successfully');
        await _loadRoles();
      } else {
        _showSnack(response['message'] ?? 'Failed to delete role');
      }
    } catch (e) {
      _showSnack('Error deleting role');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _showDeleteDialog = false;
          _roleToDelete = null;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(ProjectDesign.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProjectDesign.bg,
      body: Stack(
        children: [
          _buildBody(),
          if (_showDeleteDialog) _buildDeleteConfirmationDialog(),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
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
        backgroundColor: ProjectDesign.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        onPressed: () => _showAddRoleDialog(context),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'New Role',
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

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ProjectDesign.md,
            ProjectDesign.md,
            ProjectDesign.md,
            ProjectDesign.sm,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: ProjectDesign.surface,
              borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
              border: Border.all(color: ProjectDesign.border, width: 1),
              boxShadow: ProjectDesign.softShadow,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ProjectDesign.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search roles...',
                hintStyle: const TextStyle(
                  color: ProjectDesign.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: ProjectDesign.textMuted,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ProjectDesign.textMuted,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                    setState(() {});
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(vertical: ProjectDesign.md - 2),
              ),
            ),
          ),
        ),

        // Body
        Expanded(
          child: _roles.isEmpty
              ? _buildEmptyState()
              : _filteredRoles.isEmpty
              ? _buildNoResultsState()
              : RefreshIndicator(
            onRefresh: _loadRoles,
            color: ProjectDesign.primary,
            backgroundColor: ProjectDesign.surface,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                ProjectDesign.md,
                ProjectDesign.sm,
                ProjectDesign.md,
                ProjectDesign.xl + ProjectDesign.md,
              ),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: ProjectDesign.sm + 4,
                mainAxisSpacing: ProjectDesign.sm + 4,
                childAspectRatio: 0.75,
              ),
              itemCount: _filteredRoles.length,
              itemBuilder: (_, i) =>
                  _buildRoleCard(_filteredRoles[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(ProjectRole role) {
    final levelColor = _getRoleColor(role.level);

    return Container(
      decoration: BoxDecoration(
        color: ProjectDesign.surface,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
        border: Border.all(color: ProjectDesign.border, width: 1),
        boxShadow: ProjectDesign.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
          onTap: () => _showRoleDetails(context, role),
          child: Padding(
            padding: const EdgeInsets.all(ProjectDesign.sm + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER =====
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.12),
                        borderRadius:
                        BorderRadius.circular(ProjectDesign.radiusSm),
                        border: Border.all(
                          color: levelColor.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        role.code.length >= 2
                            ? role.code.substring(0, 2).toUpperCase()
                            : role.code.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: levelColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isManager && !role.isSystemRole)
                      _buildMenuButton(role),
                  ],
                ),
                const SizedBox(height: ProjectDesign.sm + 2),

                // ===== NAME =====
                Text(
                  role.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ProjectDesign.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role.code,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: ProjectDesign.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),

                const SizedBox(height: ProjectDesign.sm),

                // ===== LEVEL & REPORTS TO BADGE =====
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ProjectDesign.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: levelColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 11, color: levelColor),
                          const SizedBox(width: 4),
                          Text(
                            'LEVEL ${role.level}',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: levelColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '→ ${role.reportsTo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: ProjectDesign.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: ProjectDesign.sm),

                // ===== DESCRIPTION =====
                Expanded(
                  child: Text(
                    role.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: ProjectDesign.textSecondary,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: ProjectDesign.sm),

                // ===== FOOTER =====
                Row(
                  children: [
                    Icon(
                      Icons.lock_open_rounded,
                      size: 12,
                      color: ProjectDesign.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${role.permissions.length}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: ProjectDesign.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _buildActivePill(role.isActive),
                  ],
                ),

                // ===== SYSTEM TAG =====
                if (role.isSystemRole) ...[
                  const SizedBox(height: ProjectDesign.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ProjectDesign.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: ProjectDesign.infoSoft,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: ProjectDesign.infoBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.shield_rounded,
                          size: 10,
                          color: ProjectDesign.info,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'SYSTEM',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: ProjectDesign.info,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(ProjectRole role) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: ProjectDesign.textMuted,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: (value) {
        if (value == 'edit') {
          _editRole(role);
        } else if (value == 'delete') {
          _confirmDeleteRole(role);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: ProjectDesign.sm),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 16, color: ProjectDesign.danger),
              SizedBox(width: ProjectDesign.sm),
              Text(
                'Delete',
                style: TextStyle(color: ProjectDesign.danger),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivePill(bool isActive) {
    final color =
    isActive ? ProjectDesign.success : ProjectDesign.textMuted;
    final bg = isActive
        ? ProjectDesign.successSoft
        : ProjectDesign.surfaceMuted;
    final border = isActive
        ? ProjectDesign.successBorder
        : ProjectDesign.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteConfirmationDialog() {
    return Dialog(
      backgroundColor: ProjectDesign.surface,
      surfaceTintColor: ProjectDesign.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ProjectDesign.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ProjectDesign.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ProjectDesign.dangerSoft,
                    borderRadius:
                    BorderRadius.circular(ProjectDesign.radiusSm),
                    border: Border.all(
                      color: ProjectDesign.dangerBorder,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: ProjectDesign.danger,
                    size: 22,
                  ),
                ),
                const SizedBox(width: ProjectDesign.sm + 2),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Role?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ProjectDesign.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'This action cannot be undone',
                        style: TextStyle(
                          fontSize: 11.5,
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

            Container(
              padding: const EdgeInsets.all(ProjectDesign.sm + 4),
              decoration: BoxDecoration(
                color: ProjectDesign.surfaceMuted,
                borderRadius:
                BorderRadius.circular(ProjectDesign.radiusSm),
                border: Border.all(
                  color: ProjectDesign.border,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _roleToDelete?.name ?? '',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ProjectDesign.textPrimary,
                    ),
                  ),
                  if (_roleToDelete != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _roleToDelete!.code,
                      style: const TextStyle(
                        fontSize: 11,
                        color: ProjectDesign.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: ProjectDesign.lg),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showDeleteDialog = false;
                        _roleToDelete = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: ProjectDesign.md - 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ProjectDesign.radiusSm,
                        ),
                      ),
                      side: const BorderSide(
                        color: ProjectDesign.border,
                        width: 1,
                      ),
                      foregroundColor: ProjectDesign.textPrimary,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: ProjectDesign.sm + 4),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _executeDeleteRole,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProjectDesign.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: ProjectDesign.md - 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ProjectDesign.radiusSm,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
            'Loading roles...',
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
              'Failed to load roles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ProjectDesign.textPrimary,
                letterSpacing: -0.2,
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
              onPressed: _loadRoles,
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
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: ProjectDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                size: 42,
                color: ProjectDesign.primary,
              ),
            ),
            const SizedBox(height: ProjectDesign.lg),
            const Text(
              'No Roles Yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ProjectDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: ProjectDesign.sm),
            const Text(
              'Create your first project role to define responsibilities and permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: ProjectDesign.textMuted,
                height: 1.5,
              ),
            ),
            if (isManager) ...[
              const SizedBox(height: ProjectDesign.lg),
              ElevatedButton.icon(
                onPressed: () => _showAddRoleDialog(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Create Role'),
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

  Widget _buildNoResultsState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(ProjectDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: ProjectDesign.textMuted,
            ),
            SizedBox(height: ProjectDesign.md),
            Text(
              'No matching roles',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ProjectDesign.textPrimary,
              ),
            ),
            SizedBox(height: ProjectDesign.xs + 2),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 13,
                color: ProjectDesign.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(int level) {
    if (level >= 8) return ProjectDesign.primary;
    if (level >= 6) return ProjectDesign.info;
    if (level >= 4) return ProjectDesign.success;
    return ProjectDesign.warning;
  }

  void _showRoleDetails(BuildContext context, ProjectRole role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoleDetailSheet(role: role),
    );
  }

  void _showAddRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddRoleDialog(),
    ).then((value) {
      if (value == true) _loadRoles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}