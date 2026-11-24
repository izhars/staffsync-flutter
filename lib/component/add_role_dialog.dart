import 'package:flutter/material.dart';
import '../models/role_model.dart';
import '../services/project_service.dart';
import 'package:staffsync/screens/projects_screen.dart'; // for ProjectDesign

class AddRoleDialog extends StatefulWidget {
  final ProjectRole? initialRole;

  const AddRoleDialog({Key? key, this.initialRole}) : super(key: key);

  @override
  _AddRoleDialogState createState() => _AddRoleDialogState();
}

class _AddRoleDialogState extends State<AddRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int _selectedLevel = 3;
  String _reportsTo = 'Project Manager';
  bool _canViewReports = true;
  bool _canExportReports = false;
  bool _canSubmitReports = true;
  bool _canApproveTasks = false;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _levelOptions = [
    {'level': 1, 'label': 'Level 1 • Intern / Trainee'},
    {'level': 2, 'label': 'Level 2 • Junior'},
    {'level': 3, 'label': 'Level 3 • Mid-Level (Standard)'},
    {'level': 4, 'label': 'Level 4 • Senior'},
    {'level': 5, 'label': 'Level 5 • Lead / Manager'},
  ];

  final List<String> _reportingOptions = [
    'Project Manager',
    'Technical Lead',
    'Department Head',
    'Product Owner',
    'Client Representative',
    'Direct to Admin',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null) {
      final r = widget.initialRole!;
      _nameController.text = r.name;
      _codeController.text = r.code;
      _descriptionController.text = r.description;
      _selectedLevel = r.level;
      _reportsTo = r.reportsTo.isNotEmpty ? r.reportsTo : 'Project Manager';
      _canViewReports = r.permissions['canViewReports'] ?? true;
      _canExportReports = r.permissions['canExportReports'] ?? false;
      _canSubmitReports = r.permissions['canSubmitReports'] ?? true;
      _canApproveTasks = r.permissions['canApproveTasks'] ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNameChanged(String val) {
    if (widget.initialRole == null && _codeController.text.isEmpty) {
      final words = val.trim().split(RegExp(r'\s+'));
      if (words.length == 1 && words[0].length >= 2) {
        _codeController.text = words[0].substring(0, words[0].length.clamp(2, 4)).toUpperCase();
      } else if (words.length > 1) {
        _codeController.text = words.map((w) => w.isNotEmpty ? w[0] : '').take(4).join().toUpperCase();
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final roleData = {
      'name': _nameController.text.trim(),
      'code': _codeController.text.trim().toUpperCase(),
      'level': _selectedLevel,
      'description': _descriptionController.text.trim(),
      'reportsTo': _reportsTo,
      'permissions': {
        'canViewReports': _canViewReports,
        'canExportReports': _canExportReports,
        'canSubmitReports': _canSubmitReports,
        'canApproveTasks': _canApproveTasks,
        // Sensible defaults
        'canCreateTasks': _canApproveTasks || _selectedLevel >= 4,
        'canAssignTasks': _canApproveTasks || _selectedLevel >= 4,
        'canUploadDocuments': true,
      },
      'defaultResponsibilities': <Map<String, dynamic>>[],
      'isActive': true,
    };

    final projectService = ProjectService();
    try {
      final response = widget.initialRole != null
          ? await projectService.updateProjectRole(widget.initialRole!.id, roleData)
          : await projectService.createProjectRole(roleData);

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (response['success'] == true) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to save role'),
              backgroundColor: ProjectDesign.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: ProjectDesign.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialRole != null;

    return Dialog(
      backgroundColor: ProjectDesign.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ProjectDesign.radiusLg),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(ProjectDesign.lg),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== HEADER =====
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(ProjectDesign.sm + 2),
                        decoration: BoxDecoration(
                          color: ProjectDesign.primarySoft,
                          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                        ),
                        child: const Icon(Icons.badge_rounded, color: ProjectDesign.primary, size: 22),
                      ),
                      const SizedBox(width: ProjectDesign.sm + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Edit Project Role' : 'Create Project Role',
                              style: ProjectDesign.cardTitle.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Set role details, reporting manager & report rights',
                              style: TextStyle(fontSize: 12, color: ProjectDesign.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: ProjectDesign.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // ===== BASIC DETAILS =====
                  const Text('ROLE DETAILS', style: ProjectDesign.sectionLabel),
                  const SizedBox(height: ProjectDesign.sm + 4),

                  // Role Name & Code Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Role Name *', style: ProjectDesign.fieldLabel),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameController,
                              style: ProjectDesign.fieldValue,
                              onChanged: _onNameChanged,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              decoration: InputDecoration(
                                hintText: 'e.g. Frontend Engineer',
                                hintStyle: ProjectDesign.hint,
                                filled: true,
                                fillColor: ProjectDesign.surfaceMuted,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                                  borderSide: const BorderSide(color: ProjectDesign.border),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Code *', style: ProjectDesign.fieldLabel),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _codeController,
                              textCapitalization: TextCapitalization.characters,
                              style: ProjectDesign.fieldValue,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              decoration: InputDecoration(
                                hintText: 'e.g. FE',
                                hintStyle: ProjectDesign.hint,
                                filled: true,
                                fillColor: ProjectDesign.surfaceMuted,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                                  borderSide: const BorderSide(color: ProjectDesign.border),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ProjectDesign.md),

                  // Seniority Level
                  const Text('Seniority Level', style: ProjectDesign.fieldLabel),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _selectedLevel,
                    items: _levelOptions.map((opt) {
                      return DropdownMenuItem<int>(
                        value: opt['level'] as int,
                        child: Text(opt['label'] as String, style: const TextStyle(fontSize: 13.5)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLevel = val);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: ProjectDesign.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                        borderSide: const BorderSide(color: ProjectDesign.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: ProjectDesign.md),

                  // Description
                  const Text('Description', style: ProjectDesign.fieldLabel),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    style: ProjectDesign.fieldValue,
                    decoration: InputDecoration(
                      hintText: 'Brief summary of responsibilities & expectations...',
                      hintStyle: ProjectDesign.hint,
                      filled: true,
                      fillColor: ProjectDesign.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                        borderSide: const BorderSide(color: ProjectDesign.border),
                      ),
                    ),
                  ),

                  const SizedBox(height: ProjectDesign.lg),

                  // ===== REPORTING & AUTHORITIES =====
                  const Text('REPORTING & REPORT ACCESS', style: ProjectDesign.sectionLabel),
                  const SizedBox(height: ProjectDesign.sm + 4),

                  // Reports To Dropdown
                  const Text('Reports To', style: ProjectDesign.fieldLabel),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _reportingOptions.contains(_reportsTo) ? _reportsTo : _reportingOptions.first,
                    items: _reportingOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: ProjectDesign.primary),
                            const SizedBox(width: 8),
                            Text(opt, style: const TextStyle(fontSize: 13.5)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _reportsTo = val);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: ProjectDesign.surfaceMuted,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                        borderSide: const BorderSide(color: ProjectDesign.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: ProjectDesign.md),

                  // Reporting Permissions Switches
                  Container(
                    decoration: BoxDecoration(
                      color: ProjectDesign.surfaceMuted,
                      borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
                      border: Border.all(color: ProjectDesign.border),
                    ),
                    child: Column(
                      children: [
                        _buildReportSwitchTile(
                          title: 'View Project Reports',
                          subtitle: 'Can view progress, milestones & budget reports',
                          value: _canViewReports,
                          onChanged: (val) => setState(() => _canViewReports = val),
                          icon: Icons.analytics_outlined,
                        ),
                        const Divider(height: 1, indent: 48),
                        _buildReportSwitchTile(
                          title: 'Export Reports',
                          subtitle: 'Can download project reports in PDF / CSV format',
                          value: _canExportReports,
                          onChanged: (val) => setState(() => _canExportReports = val),
                          icon: Icons.download_rounded,
                        ),
                        const Divider(height: 1, indent: 48),
                        _buildReportSwitchTile(
                          title: 'Submit Progress Reports',
                          subtitle: 'Submits daily/weekly status and progress updates',
                          value: _canSubmitReports,
                          onChanged: (val) => setState(() => _canSubmitReports = val),
                          icon: Icons.edit_note_rounded,
                        ),
                        const Divider(height: 1, indent: 48),
                        _buildReportSwitchTile(
                          title: 'Approve Tasks & Deliverables',
                          subtitle: 'Can sign off on deliverables submitted by peers',
                          value: _canApproveTasks,
                          onChanged: (val) => setState(() => _canApproveTasks = val),
                          icon: Icons.verified_outlined,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: ProjectDesign.xl),

                  // ===== BUTTONS =====
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                            ),
                            side: const BorderSide(color: ProjectDesign.border),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600, color: ProjectDesign.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ProjectDesign.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : Text(
                            isEdit ? 'Save Role' : 'Create Role',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: value ? ProjectDesign.primary : ProjectDesign.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: value ? ProjectDesign.textPrimary : ProjectDesign.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: ProjectDesign.textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: ProjectDesign.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
