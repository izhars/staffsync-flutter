import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'projects_screen.dart';
import '../services/project_service.dart';

// Reuse ProjectDesign tokens from projects_screen.dart
// (In real code, extract to a shared file)

class AddProjectScreen extends StatefulWidget {
  final Function()? onProjectCreated;

  const AddProjectScreen({Key? key, this.onProjectCreated}) : super(key: key);

  @override
  _AddProjectScreenState createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _budgetController = TextEditingController();
  final _tagController = TextEditingController();

  final List<String> _selectedTags = [];
  bool _isSubmitting = false;
  DateTime? _startDate;
  DateTime? _endDate;
  final FocusNode _tagFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tagController.addListener(_onTagTextChanged);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ProjectDesign.bg,
        appBar: _buildAppBar(),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ProjectDesign.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: ProjectDesign.lg),

                _buildSectionLabel('Basic Information'),
                const SizedBox(height: ProjectDesign.sm + 2),
                _buildFieldCard([
                  _buildLabel('Project Name', required: true),
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Enter project name',
                    prefixIcon: Icons.business_rounded,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please enter project name'
                        : null,
                  ),
                  const SizedBox(height: ProjectDesign.md),
                  _buildLabel('Project Code', required: true),
                  _buildTextField(
                    controller: _codeController,
                    hintText: 'e.g., HRMS-MOB-2024',
                    prefixIcon: Icons.tag_rounded,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter project code';
                      }
                      if (!RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(v)) {
                        return 'Only letters, numbers, hyphens & underscores';
                      }
                      return null;
                    },
                  ),
                ]),

                const SizedBox(height: ProjectDesign.md),
                _buildSectionLabel('Timeline'),
                const SizedBox(height: ProjectDesign.sm + 2),
                _buildFieldCard([
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Start Date', required: true),
                            _buildDateField(
                              controller: _startDateController,
                              hintText: 'Select date',
                              onTap: () => _selectDate(context, true),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: ProjectDesign.sm + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('End Date', required: true),
                            _buildDateField(
                              controller: _endDateController,
                              hintText: 'Select date',
                              onTap: () => _selectDate(context, false),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Required';
                                }
                                if (_startDate != null &&
                                    _endDate != null &&
                                    _endDate!.isBefore(_startDate!)) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]),

                const SizedBox(height: ProjectDesign.md),
                _buildSectionLabel('Budget & Description'),
                const SizedBox(height: ProjectDesign.sm + 2),
                _buildFieldCard([
                  _buildLabel('Budget'),
                  _buildTextField(
                    controller: _budgetController,
                    hintText: 'Enter amount',
                    prefixIcon: Icons.currency_rupee_rounded,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final budget = double.tryParse(v);
                        if (budget == null) return 'Enter a valid number';
                        if (budget < 0) return 'Cannot be negative';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: ProjectDesign.md),
                  _buildLabel('Description'),
                  _buildTextArea(
                    controller: _descriptionController,
                    hintText: 'Describe the project scope, goals, and deliverables...',
                  ),
                ]),

                const SizedBox(height: ProjectDesign.md),
                _buildSectionLabel('Tags'),
                const SizedBox(height: ProjectDesign.sm + 2),
                _buildTagsCard(),

                const SizedBox(height: ProjectDesign.lg),
                _buildSubmitButton(),
                const SizedBox(height: ProjectDesign.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: ProjectDesign.surface,
      surfaceTintColor: ProjectDesign.surface,
      centerTitle: true,
      title: const Text(
        'Create New Project',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: ProjectDesign.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded,
            color: ProjectDesign.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: ProjectDesign.border),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(ProjectDesign.md + 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ProjectDesign.primary, ProjectDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ProjectDesign.radiusLg),
        boxShadow: [
          BoxShadow(
            color: ProjectDesign.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm + 2),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.add_box_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: ProjectDesign.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Project',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Fill in the details below to get started',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
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

  Widget _buildSectionLabel(String label) {
    return Row(
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
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: ProjectDesign.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(ProjectDesign.md),
      decoration: BoxDecoration(
        color: ProjectDesign.surface,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
        border: Border.all(color: ProjectDesign.border, width: 1),
        boxShadow: ProjectDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ProjectDesign.sm),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: ProjectDesign.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 3),
            const Text(
              '*',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: ProjectDesign.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    Function(String?)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ProjectDesign.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: ProjectDesign.textMuted,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: ProjectDesign.surfaceMuted,
        prefixIcon: Icon(prefixIcon, color: ProjectDesign.primary, size: 18),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ProjectDesign.md,
          vertical: ProjectDesign.md - 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide:
          const BorderSide(color: ProjectDesign.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide: const BorderSide(
            color: ProjectDesign.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide:
          const BorderSide(color: ProjectDesign.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide:
          const BorderSide(color: ProjectDesign.danger, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ProjectDesign.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: ProjectDesign.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: ProjectDesign.surfaceMuted,
            prefixIcon: const Icon(
              Icons.calendar_today_rounded,
              color: ProjectDesign.primary,
              size: 16,
            ),
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: ProjectDesign.textMuted,
              size: 18,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ProjectDesign.sm,
              vertical: ProjectDesign.md - 2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              borderSide:
              const BorderSide(color: ProjectDesign.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              borderSide:
              const BorderSide(color: ProjectDesign.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              borderSide:
              const BorderSide(color: ProjectDesign.danger, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
              borderSide:
              const BorderSide(color: ProjectDesign.danger, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ProjectDesign.textPrimary,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: ProjectDesign.textMuted,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: ProjectDesign.surfaceMuted,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.all(ProjectDesign.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide:
          const BorderSide(color: ProjectDesign.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
          borderSide:
          const BorderSide(color: ProjectDesign.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTagsCard() {
    return Container(
      padding: const EdgeInsets.all(ProjectDesign.md),
      decoration: BoxDecoration(
        color: ProjectDesign.surface,
        borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
        border: Border.all(color: ProjectDesign.border, width: 1),
        boxShadow: ProjectDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag input
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tagController,
                  focusNode: _tagFocusNode,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: ProjectDesign.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a tag...',
                    hintStyle: const TextStyle(
                      color: ProjectDesign.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: ProjectDesign.surfaceMuted,
                    prefixIcon: const Icon(
                      Icons.label_outline_rounded,
                      color: ProjectDesign.primary,
                      size: 18,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ProjectDesign.sm,
                      vertical: ProjectDesign.sm + 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                      borderSide: const BorderSide(
                        color: ProjectDesign.border,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                      borderSide: const BorderSide(
                        color: ProjectDesign.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onFieldSubmitted: (_) => _addTagFromController(),
                ),
              ),
              const SizedBox(width: ProjectDesign.sm),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: ProjectDesign.primary,
                  borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
                  boxShadow: [
                    BoxShadow(
                      color: ProjectDesign.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius:
                    BorderRadius.circular(ProjectDesign.radiusSm),
                    onTap: _addTagFromController,
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Tag list
          if (_selectedTags.isNotEmpty) ...[
            const SizedBox(height: ProjectDesign.md),
            Wrap(
              spacing: ProjectDesign.sm,
              runSpacing: ProjectDesign.sm,
              children: _selectedTags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ProjectDesign.sm + 2,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ProjectDesign.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ProjectDesign.primaryLight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ProjectDesign.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeTag(tag),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: ProjectDesign.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: ProjectDesign.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: ProjectDesign.sm),
            Row(
              children: [
                Text(
                  '${_selectedTags.length} tag(s) added',
                  style: const TextStyle(
                    fontSize: 11,
                    color: ProjectDesign.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearAllTags,
                  icon: const Icon(Icons.delete_outline_rounded, size: 14),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: ProjectDesign.danger,
                    padding: const EdgeInsets.symmetric(
                      horizontal: ProjectDesign.sm,
                      vertical: 4,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: ProjectDesign.sm),
            const Text(
              'Add tags to help categorize your project (e.g., flutter, mobile, design)',
              style: TextStyle(
                fontSize: 11.5,
                color: ProjectDesign.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: ProjectDesign.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
          ProjectDesign.primary.withOpacity(0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ProjectDesign.radiusMd),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor:
            AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, size: 20),
            SizedBox(width: ProjectDesign.sm),
            Text(
              'Create Project',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== TAG LOGIC =====================

  void _addTagFromController() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;

    if (_selectedTags.contains(tag)) {
      _showSnack('Tag "$tag" already exists');
      _tagController.clear();
      return;
    }

    if (_selectedTags.length >= 10) {
      _showSnack('Maximum 10 tags allowed');
      return;
    }

    setState(() {
      _selectedTags.add(tag);
      _tagController.clear();
    });
    _tagFocusNode.requestFocus();
  }

  void _onTagTextChanged() => setState(() {});

  void _removeTag(String tag) {
    setState(() => _selectedTags.remove(tag));
  }

  void _clearAllTags() {
    setState(() => _selectedTags.clear());
    _tagController.clear();
    _tagFocusNode.requestFocus();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ProjectDesign.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(ProjectDesign.md),
      ),
    );
  }

  // ===================== DATE PICKER =====================

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ProjectDesign.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
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

  // ===================== SUBMIT =====================

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTags.length > 10) {
      _showSnack('Maximum 10 tags allowed');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final projectData = {
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
        'budget': _budgetController.text.isNotEmpty
            ? double.parse(_budgetController.text)
            : 0.0,
        'tags': _selectedTags,
      };

      final projectService = ProjectService();
      final result = await projectService.addProject(projectData);

      if (result['success'] == true) {
        if (widget.onProjectCreated != null) widget.onProjectCreated!();
        if (mounted) _showSuccessDialog();
      } else {
        if (mounted) _showErrorDialog(result['message'] ?? 'Failed to create project');
      }
    } catch (e) {
      if (mounted) _showErrorDialog('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ===================== DIALOGS =====================

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ProjectDesign.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: ProjectDesign.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: ProjectDesign.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: ProjectDesign.md),
              const Text(
                'Project Created',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ProjectDesign.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: ProjectDesign.sm),
              const Text(
                'Your project has been created successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: ProjectDesign.textSecondary,
                  height: 1.5,
                ),
              ),
              if (_selectedTags.isNotEmpty) ...[
                const SizedBox(height: ProjectDesign.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ProjectDesign.sm + 4,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ProjectDesign.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ProjectDesign.primaryLight,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_selectedTags.length} tag(s) added',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: ProjectDesign.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: ProjectDesign.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _tagFocusNode.unfocus();
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
                      child: const Text('Create Another'),
                    ),
                  ),
                  const SizedBox(width: ProjectDesign.sm + 4),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ProjectDesign.primary,
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
                      child: const Text('View Projects'),
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ProjectDesign.surface,
        surfaceTintColor: ProjectDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ProjectDesign.radiusLg),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: ProjectDesign.danger, size: 22),
            SizedBox(width: ProjectDesign.sm + 2),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ProjectDesign.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13.5,
            color: ProjectDesign.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: ProjectDesign.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tagController.removeListener(_onTagTextChanged);
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
}