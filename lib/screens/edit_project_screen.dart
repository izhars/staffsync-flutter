import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staffsync/screens/projects_screen.dart'; // for ProjectDesign
import '../models/project_model.dart';
import '../services/project_service.dart';

class EditProjectScreen extends StatefulWidget {
  final Project project;

  const EditProjectScreen({Key? key, required this.project}) : super(key: key);

  @override
  _EditProjectScreenState createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectService = ProjectService();
  final FocusNode _tagFocusNode = FocusNode();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _budgetController;
  late TextEditingController _tagController;

  late List<String> _selectedTags;
  String _selectedStatus = 'active';
  bool _isSubmitting = false;
  DateTime? _startDate;
  DateTime? _endDate;
  late double _budgetAllocated;
  final List<String> _statusOptions = [
    'planning',
    'active',
    'in-progress',
    'on-hold',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.project.name);
    _codeController = TextEditingController(text: widget.project.code);
    _descriptionController = TextEditingController(text: widget.project.description);
    _startDateController = TextEditingController(
        text: DateFormat('dd-MM-yyyy').format(widget.project.startDate));
    _endDateController = TextEditingController(
        text: DateFormat('dd-MM-yyyy').format(widget.project.endDate));
    _budgetController = TextEditingController(
        text: widget.project.budgetAllocated.toStringAsFixed(0));
    _tagController = TextEditingController();
    _selectedTags = List.from(widget.project.tags);
    _selectedStatus = widget.project.status;
    _startDate = widget.project.startDate;
    _endDate = widget.project.endDate;
    _budgetAllocated = widget.project.budgetAllocated;

    if (!_statusOptions.contains(_selectedStatus)) {
      _statusOptions.add(_selectedStatus);
    }
  }

  @override
  void dispose() {
    _tagFocusNode.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _budgetController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProjectDesign.bg,
      appBar: AppBar(
        title: const Text('Edit Project', style: ProjectDesign.screenTitle),
        elevation: 0,
        backgroundColor: ProjectDesign.surface,
        foregroundColor: ProjectDesign.textPrimary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ProjectDesign.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSubmitting)
            Padding(
              padding: const EdgeInsets.only(right: ProjectDesign.md),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(ProjectDesign.primary),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ProjectDesign.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: ProjectDesign.lg),

              // Project Name
              _buildLabel('Project Name *'),
              _buildTextField(
                controller: _nameController,
                hintText: 'Enter project name',
                prefixIcon: Icons.business_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter project name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: ProjectDesign.md),

              // Project Code
              _buildLabel('Project Code *'),
              _buildTextField(
                controller: _codeController,
                hintText: 'e.g., HRMS-MOB-2024',
                prefixIcon: Icons.code_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter project code';
                  }
                  if (!RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(value)) {
                    return 'Only letters, numbers, hyphens, and underscores allowed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: ProjectDesign.md),

              // Status Dropdown
              _buildLabel('Status'),
              _buildStatusDropdown(),
              const SizedBox(height: ProjectDesign.md),

              // Dates Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Start Date'),
                        _buildDateField(
                          controller: _startDateController,
                          hintText: 'Select start date',
                          onTap: () => _selectDate(context, true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ProjectDesign.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('End Date'),
                        _buildDateField(
                          controller: _endDateController,
                          hintText: 'Select end date',
                          onTap: () => _selectDate(context, false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ProjectDesign.md),

              // Budget
              _buildLabel('Budget (${widget.project.currency})'),
              _buildTextField(
                controller: _budgetController,
                hintText: 'Enter budget amount',
                prefixIcon: Icons.attach_money_rounded,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                suffixText: 'INR',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter budget amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  final budget = double.parse(value);
                  if (budget < 0) {
                    return 'Budget cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: ProjectDesign.md),

              // Description
              _buildLabel('Description'),
              _buildTextArea(
                controller: _descriptionController,
                hintText: 'Enter project description...',
              ),
              const SizedBox(height: ProjectDesign.md),

              // Tags Section
              _buildLabel('Tags'),
              _buildTagsSection(),
              const SizedBox(height: ProjectDesign.xl),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== HEADER =====================
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: ProjectDesign.lg),
      padding: const EdgeInsets.all(ProjectDesign.md + 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ProjectDesign.primary, ProjectDesign.primaryDark],
        ),
        borderRadius: BorderRadius.circular(ProjectDesign.radiusLg),
        boxShadow: [
          BoxShadow(
            color: ProjectDesign.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ProjectDesign.sm + 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: ProjectDesign.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.project.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: ProjectDesign.xs),
                Text(
                  'Update project details',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== LABEL =====================
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ProjectDesign.sm),
      child: Text(text, style: ProjectDesign.fieldLabel),
    );
  }

  // ===================== TEXT FIELD =====================
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    String? suffixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Function(String?)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      style: ProjectDesign.fieldValue,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: ProjectDesign.hint,
        filled: true,
        fillColor: ProjectDesign.surfaceMuted,
        prefixIcon: Icon(prefixIcon, color: ProjectDesign.textSecondary, size: 20),
        suffixText: suffixText,
        suffixStyle: ProjectDesign.fieldValue.copyWith(color: ProjectDesign.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide: const BorderSide(color: ProjectDesign.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide: const BorderSide(color: ProjectDesign.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide: const BorderSide(color: ProjectDesign.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide: const BorderSide(color: ProjectDesign.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ProjectDesign.md,
          vertical: ProjectDesign.md,
        ),
      ),
    );
  }

  // ===================== DATE FIELD =====================
  Widget _buildDateField({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          style: ProjectDesign.fieldValue,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: ProjectDesign.hint,
            filled: true,
            fillColor: ProjectDesign.surfaceMuted,
            prefixIcon: const Icon(Icons.calendar_today_rounded,
                color: ProjectDesign.textSecondary, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              borderSide: const BorderSide(color: ProjectDesign.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              borderSide: const BorderSide(color: ProjectDesign.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              borderSide: const BorderSide(color: ProjectDesign.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ProjectDesign.md,
              vertical: ProjectDesign.md,
            ),
          ),
        ),
      ),
    );
  }

  // ===================== TEXT AREA =====================
  Widget _buildTextArea({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      style: ProjectDesign.fieldValue,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: ProjectDesign.hint,
        filled: true,
        fillColor: ProjectDesign.surfaceMuted,
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide: const BorderSide(color: ProjectDesign.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide: const BorderSide(color: ProjectDesign.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide: const BorderSide(color: ProjectDesign.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(ProjectDesign.md),
      ),
    );
  }

  // ===================== STATUS DROPDOWN =====================
  Widget _buildStatusDropdown() {
    final Set<String> statusSet = Set.from(_statusOptions);
    statusSet.add(_selectedStatus);
    final List<String> allStatusOptions = statusSet.toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ProjectDesign.sm + 4),
      decoration: BoxDecoration(
        color: ProjectDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
        border: Border.all(color: ProjectDesign.border),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedStatus,
        style: ProjectDesign.fieldValue,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: ProjectDesign.sm),
        ),
        items: allStatusOptions.map((status) {
          final (color, bgColor, borderColor, icon, label) =
          _getStatusStyle(status);
          return DropdownMenuItem<String>(
            value: status,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: ProjectDesign.sm + 4),
                Text(
                  _formatStatusText(status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) setState(() => _selectedStatus = value);
        },
        dropdownColor: ProjectDesign.surface,
        icon: const Icon(Icons.arrow_drop_down_rounded, color: ProjectDesign.textSecondary),
        borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
        elevation: 2,
      ),
    );
  }

  // ===================== TAGS SECTION =====================
  Widget _buildTagsSection() {
    return Container(
      padding: const EdgeInsets.all(ProjectDesign.md),
      decoration: BoxDecoration(
        color: ProjectDesign.surface,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
        border: Border.all(color: ProjectDesign.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags Input with Add Button
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tagController,
                  focusNode: _tagFocusNode,
                  style: ProjectDesign.fieldValue,
                  decoration: InputDecoration(
                    hintText: 'Enter tag and press Enter or click +',
                    hintStyle: ProjectDesign.hint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: ProjectDesign.sm),
                    suffixIcon: _tagController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.add_circle_rounded,
                          color: ProjectDesign.primary, size: 20),
                      onPressed: _addTagFromController,
                    )
                        : null,
                  ),
                  onFieldSubmitted: (value) => _addTagFromController(),
                ),
              ),
              const SizedBox(width: ProjectDesign.sm),
              Container(
                decoration: BoxDecoration(
                  color: ProjectDesign.primarySoft,
                  borderRadius: BorderRadius.circular(ProjectDesign.radiusSm - 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, color: ProjectDesign.primary, size: 20),
                  onPressed: _addTagFromController,
                  tooltip: 'Add Tag',
                ),
              ),
            ],
          ),

          // Tags List
          if (_selectedTags.isNotEmpty) ...[
            const SizedBox(height: ProjectDesign.sm + 4),
            Wrap(
              spacing: ProjectDesign.sm,
              runSpacing: ProjectDesign.sm,
              children: _selectedTags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ProjectDesign.sm + 2, vertical: 5),
                  decoration: BoxDecoration(
                    color: ProjectDesign.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => _removeTag(tag),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // Tag Suggestions
          if (_selectedTags.isEmpty) ...[
            const SizedBox(height: ProjectDesign.sm),
            Text(
              'Suggestions: flutter, mobile, web, backend, design',
              style: ProjectDesign.hint.copyWith(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // Clear All Button
          if (_selectedTags.isNotEmpty) ...[
            const SizedBox(height: ProjectDesign.sm + 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearAllTags,
                style: TextButton.styleFrom(
                  foregroundColor: ProjectDesign.danger,
                  padding: const EdgeInsets.symmetric(
                      horizontal: ProjectDesign.sm + 4, vertical: ProjectDesign.xs),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delete_outline_rounded, size: 16),
                    const SizedBox(width: ProjectDesign.xs),
                    Text('Clear All',
                        style: ProjectDesign.buttonText
                            .copyWith(color: ProjectDesign.danger)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===================== ACTION BUTTONS =====================
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              ),
              side: const BorderSide(color: ProjectDesign.border),
              padding: const EdgeInsets.symmetric(vertical: ProjectDesign.md),
            ),
            child: Text('CANCEL',
                style: ProjectDesign.buttonText.copyWith(color: ProjectDesign.textSecondary)),
          ),
        ),
        const SizedBox(width: ProjectDesign.md),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: ProjectDesign.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              ),
              padding: const EdgeInsets.symmetric(vertical: ProjectDesign.md),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_rounded, size: 18),
                const SizedBox(width: ProjectDesign.sm),
                Text('SAVE CHANGES',
                    style: ProjectDesign.buttonText.copyWith(color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===================== STATUS STYLE (matches ProjectsScreen) =====================
  (Color, Color, Color, IconData, String) _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'planning':
        return (
        ProjectDesign.primary,
        ProjectDesign.primarySoft,
        ProjectDesign.primaryLight,
        Icons.edit_note_rounded,
        'PLANNING'
        );
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

  // Tag Management Methods
  void _addTagFromController() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty) {
      if (!_selectedTags.contains(tag)) {
        setState(() {
          _selectedTags.add(tag);
          _tagController.clear();
        });
        _tagFocusNode.requestFocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tag "$tag" already exists',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            duration: const Duration(seconds: 2),
            backgroundColor: ProjectDesign.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
            ),
            margin: const EdgeInsets.all(ProjectDesign.md),
          ),
        );
        _tagController.clear();
      }
    }
  }

  void _removeTag(String tag) {
    setState(() => _selectedTags.remove(tag));
  }

  void _clearAllTags() {
    setState(() => _selectedTags.clear());
    _tagController.clear();
    _tagFocusNode.requestFocus();
  }

  String _formatStatusText(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ProjectDesign.primary,
              onPrimary: Colors.white,
              surface: ProjectDesign.surface,
              onSurface: ProjectDesign.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      if (isStartDate) {
        setState(() {
          _startDate = picked;
          _startDateController.text = formattedDate;
        });
      } else {
        setState(() {
          _endDate = picked;
          _endDateController.text = formattedDate;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTags.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maximum 10 tags allowed',
              style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: ProjectDesign.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          ),
          margin: const EdgeInsets.all(ProjectDesign.md),
        ),
      );
      return;
    }

    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('End date must be after start date',
              style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: ProjectDesign.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          ),
          margin: const EdgeInsets.all(ProjectDesign.md),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': _selectedStatus,
        'startDate': _startDate?.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
        'budget': {'allocated': double.parse(_budgetController.text)},
        'tags': _selectedTags,
      };

      final result = await _projectService.updateProject(widget.project.id, updates);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: ProjectDesign.sm + 4),
                Text('Project updated successfully',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: ProjectDesign.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
            ),
            margin: const EdgeInsets.all(ProjectDesign.md),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showErrorDialog(result['message'] ?? 'Failed to update project');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
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
              child: const Icon(Icons.error_rounded,
                  color: ProjectDesign.danger, size: 22),
            ),
            const SizedBox(width: ProjectDesign.sm + 4),
            const Text('Update Failed', style: ProjectDesign.cardTitle),
          ],
        ),
        content: Text(message, style: ProjectDesign.cardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: ProjectDesign.buttonText
                    .copyWith(color: ProjectDesign.primary)),
          ),
        ],
      ),
    );
  }
}