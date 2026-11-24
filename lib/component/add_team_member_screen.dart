import 'package:flutter/material.dart';
import '../models/celebration.dart';
import '../services/project_service.dart';
import '../services/employee_service.dart';

class AddTeamMemberScreen extends StatefulWidget {
  final String projectId;

  const AddTeamMemberScreen({Key? key, required this.projectId}) : super(key: key);

  @override
  _AddTeamMemberScreenState createState() => _AddTeamMemberScreenState();
}

class _AddTeamMemberScreenState extends State<AddTeamMemberScreen> {
  final ProjectService _projectService = ProjectService();
  final EmployeeService _employeeService = EmployeeService();

  List<Employee> _employees = [];
  List<Map<String, dynamic>> _roles = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  Employee? _selectedEmployee;
  String? _selectedRoleId;
  final TextEditingController _allocationController = TextEditingController(text: '80');

  final List<Map<String, dynamic>> _responsibilities = [];
  final TextEditingController _responsibilityTitleController = TextEditingController();
  final TextEditingController _responsibilityDescController = TextEditingController();
  String _selectedCategory = 'technical';
  String _selectedPriority = 'medium';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final employeeData = await _employeeService.getAllEmployees();
      final rolesResult = await _projectService.getProjectRoles();

      setState(() {
        _employees = employeeData
            .map((e) => Employee.fromJson(e))
            .toList();

        if (rolesResult['success'] == true) {
          _roles = (rolesResult['data'] as List)
              .map((r) => {
            'id': (r['_id'] ?? r['id']).toString(),
            'name': r['name'],
            'code': r['code'],
          })
              .toList();
        }

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading initial data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _addResponsibility() {
    final title = _responsibilityTitleController.text.trim();
    final description = _responsibilityDescController.text.trim();

    if (title.isNotEmpty && description.isNotEmpty) {
      setState(() {
        _responsibilities.add({
          'title': title,
          'description': description,
          'category': _selectedCategory,
          'priority': _selectedPriority,
        });
        _responsibilityTitleController.clear();
        _responsibilityDescController.clear();
      });
    }
  }

  void _removeResponsibility(int index) {
    setState(() {
      _responsibilities.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an employee'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final allocation = int.tryParse(_allocationController.text);
    if (allocation == null || allocation < 0 || allocation > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Allocation must be between 0-100'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _projectService.addTeamMember(
        projectId: widget.projectId,
        employeeId: _selectedEmployee!.id,
        roleId: _selectedRoleId!,
        allocation: allocation,
        responsibilities: _responsibilities,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team member added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error adding team member'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Team Member'),
        backgroundColor: theme.primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withOpacity(0.8),
                    theme.primaryColorDark ?? theme.primaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_add, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Team Member',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Assign employee to project with role & responsibilities',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Select Employee
            _buildSection(
              title: 'Select Employee',
              child: _buildEmployeeSelector(),
            ),
            const SizedBox(height: 24),

            // Select Role
            _buildSection(
              title: 'Select Role',
              child: _buildRoleSelector(),
            ),
            const SizedBox(height: 24),

            // Allocation
            _buildSection(
              title: 'Allocation (%)',
              child: TextField(
                controller: _allocationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter allocation percentage (0-100)',
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                  ),
                  prefixIcon: Icon(Icons.percent, color: theme.colorScheme.onSurfaceVariant),
                  suffixText: '%',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Responsibilities
            _buildResponsibilitiesSection(),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Adding...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'ADD TEAM MEMBER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildEmployeeSelector() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _showEmployeeBottomSheet(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Text(
                (_selectedEmployee?.fullName ?? 'E').substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedEmployee?.fullName ?? 'Select employee',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _selectedEmployee == null ? FontWeight.w400 : FontWeight.w700,
                      color: _selectedEmployee == null
                          ? theme.hintColor
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_selectedEmployee != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _selectedEmployee!.department ?? 'No department',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final theme = Theme.of(context);
    final selected = _roles.firstWhere(
          (r) => r['id'] == _selectedRoleId,
      orElse: () => <String, dynamic>{},
    );

    final hasSelection = selected.isNotEmpty;

    return InkWell(
      onTap: () => _showRoleBottomSheet(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.badge_rounded,
                color: theme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSelection ? selected['name'] ?? '' : 'Select role',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: hasSelection ? FontWeight.w700 : FontWeight.w400,
                      color: hasSelection
                          ? theme.colorScheme.onSurface
                          : theme.hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasSelection && selected['code'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          selected['code'],
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showEmployeeBottomSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String query = '';
        List<Employee> filtered = List.from(_employees);

        return StatefulBuilder(
          builder: (context, setModalState) {
            void filter(String value) {
              query = value.toLowerCase();
              filtered = _employees.where((e) {
                final name = e.fullName.toLowerCase();
                final dept = (e.department ?? '').toLowerCase();
                return name.contains(query) || dept.contains(query);
              }).toList();
              setModalState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Select Employee',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: filter,
                    decoration: InputDecoration(
                      hintText: 'Search by name or department',
                      prefixIcon: Icon(Icons.search_rounded, color: theme.hintColor),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 360,
                    child: filtered.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: theme.hintColor),
                          const SizedBox(height: 12),
                          Text(
                            'No employee found',
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: theme.dividerColor,
                      ),
                      itemBuilder: (context, index) {
                        final employee = filtered[index];
                        final isSelected = _selectedEmployee?.id == employee.id;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: theme.primaryColor.withOpacity(0.1),
                            child: Text(
                              employee.fullName.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          title: Text(
                            employee.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            employee.department ?? 'No department',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                            Icons.check_circle_rounded,
                            color: theme.primaryColor,
                            size: 28,
                          )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedEmployee = employee;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRoleBottomSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Select Role',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 320,
                child: _roles.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 48, color: theme.hintColor),
                      const SizedBox(height: 12),
                      Text(
                        'No roles available',
                        style: TextStyle(
                          color: theme.hintColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.dividerColor,
                  ),
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = role['id'] == _selectedRoleId;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Text(
                          (role['code'] ?? '').toString().trim().isNotEmpty
                              ? role['code'].toString().substring(0, 2).toUpperCase()
                              : role['name'].toString().substring(0, 2).toUpperCase(),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Text(
                        role['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: role['code'] != null
                          ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role['code'],
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                          : null,
                      trailing: isSelected
                          ? Icon(
                        Icons.check_circle_rounded,
                        color: theme.primaryColor,
                        size: 28,
                      )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedRoleId = role['id'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponsibilitiesSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Responsibilities',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.primaryColor,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.add_circle_rounded, color: theme.primaryColor),
              onPressed: _showAddResponsibilityDialog,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Responsibilities List
        if (_responsibilities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.task_alt_rounded, size: 48, color: theme.hintColor),
                const SizedBox(height: 12),
                Text(
                  'No responsibilities added',
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Tap + to add responsibilities for this team member',
                  style: TextStyle(
                    color: theme.hintColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _responsibilities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final responsibility = _responsibilities[index];
              return _buildResponsibilityCard(responsibility, index);
            },
          ),
      ],
    );
  }

  Widget _buildResponsibilityCard(Map<String, dynamic> responsibility, int index) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getPriorityColor(responsibility['priority']).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_rounded,
              size: 20,
              color: _getPriorityColor(responsibility['priority']),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  responsibility['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  responsibility['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        responsibility['category'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(responsibility['priority']).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        responsibility['priority'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getPriorityColor(responsibility['priority']),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_rounded, color: theme.colorScheme.error),
            onPressed: () => _removeResponsibility(index),
          ),
        ],
      ),
    );
  }

  void _showAddResponsibilityDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.add_task_rounded, color: theme.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Responsibility',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Title
              TextField(
                controller: _responsibilityTitleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g., Develop user authentication',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              TextField(
                controller: _responsibilityDescController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Detailed description of the responsibility...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Category and Priority
              Row(
                children: [
                  Expanded(
                    flex: 3, // 👈 more space
                    child: _buildCategorySelector(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2, // 👈 less space
                    child: _buildPrioritySelector(),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _addResponsibility();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white, // 👈 drip added
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

  Widget _buildCategorySelector() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              items: const [
                DropdownMenuItem(value: 'technical', child: Text('Technical')),
                DropdownMenuItem(value: 'management', child: Text('Management')),
                DropdownMenuItem(value: 'quality', child: Text('Quality')),
                DropdownMenuItem(value: 'communication', child: Text('Communication')),
                DropdownMenuItem(value: 'documentation', child: Text('Documentation')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPriority = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    final theme = Theme.of(context);
    switch (priority) {
      case 'high':
      case 'critical':
        return theme.colorScheme.error;
      case 'medium':
        return theme.colorScheme.tertiary;
      case 'low':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.outline;
    }
  }
}
