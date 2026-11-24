import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/chat_service.dart';
import '../../services/employee_service.dart';
import '../../models/user.dart';

// ===================== DESIGN TOKENS (from dashboard) =====================
const double _xs = 4;
const double _sm = 8;
const double _lg = 24;
const double _xl = 32;

const double _radiusSm = 12;
const double _radiusMd = 18;
const double _radiusLg = 24;

const Color _bg = Color(0xFFF6F7FB);
const Color _surface = Colors.white;
const Color _textPrimary = Color(0xFF1A1D26);
const Color _textSecondary = Color(0xFF6B7280);
const Color _textMuted = Color(0xFF9CA3AF);
const Color _border = Color(0xFFEAECEF);
const Color _primary = Color(0xFF0F766E);
const Color _primaryLight = Color(0xFFCCFBF1);
const Color _primarySoft = Color(0xFFF0FDFA);
const Color _error = Color(0xFFEF4444);

final List<BoxShadow> _softShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 16,
    offset: const Offset(0, 6),
    spreadRadius: -4,
  ),
];

final List<BoxShadow> _mediumShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 24,
    offset: const Offset(0, 10),
    spreadRadius: -6,
  ),
];
// =========================================================================

class CreateGroupScreen extends StatefulWidget {
  final ChatService chatService;
  final User currentUser;

  const CreateGroupScreen({
    Key? key,
    required this.chatService,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController =
  TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<User> _allUsers = [];
  List<String> _selectedUserIds = [];
  List<User> _filteredUsers = [];
  bool _isCreating = false;
  bool _isLoadingUsers = true;
  bool _isUploadingImage = false;
  File? _groupImageFile;
  String? _groupAvatarUrl;
  String? _groupAvatarPublicId;
  final ImagePicker _picker = ImagePicker();

  // Group settings
  bool _isPublic = false;
  bool _approvalRequired = false;
  bool _allowMedia = true;
  bool _allowReactions = true;
  bool _allowEditing = true;
  int _maxParticipants = 100;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoadingUsers = true);

      final employees =
      await _employeeService.getEmployeeListWithStatus(isActive: true);
      final users = employees.map((emp) => User.fromJson(emp)).toList();
      final filteredUsers =
      users.where((user) => user.id != widget.currentUser.id).toList();

      setState(() {
        _allUsers = filteredUsers;
        _filteredUsers = filteredUsers;
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('❌ Error loading users: $e');
      _showError('Failed to load users');
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _pickGroupImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          _showError('Image size should be less than 5MB');
          return;
        }

        setState(() {
          _groupImageFile = file;
          _groupAvatarUrl = null;
          _groupAvatarPublicId = null;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _searchUsers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = _allUsers);
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        return user.fullName.toLowerCase().contains(q) ||
            user.email.toLowerCase().contains(q) ||
            user.employeeId.toLowerCase().contains(q) ||
            (user.department?.name ?? '').toLowerCase().contains(q);
      }).toList();
    });
  }

  void _toggleUserSelection(User user) {
    setState(() {
      if (_selectedUserIds.contains(user.id)) {
        _selectedUserIds.remove(user.id);
      } else {
        _selectedUserIds.add(user.id);
      }
    });
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      _showError('Please enter a group name');
      return;
    }

    if (_selectedUserIds.isEmpty) {
      _showError('Please select at least one member');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final group = await widget.chatService.createGroup(
        name: _groupNameController.text.trim(),
        description: _groupDescriptionController.text.trim(),
        isPublic: _isPublic,
        approvalRequired: _approvalRequired,
        allowMedia: _allowMedia,
        allowReactions: _allowReactions,
        allowEditing: _allowEditing,
        maxParticipants: _maxParticipants,
        participantIds: _selectedUserIds,
        avatar: _groupImageFile,
      );

      if (group != null) {
        _showSuccess('Group created successfully!');
        Navigator.pop(context, group);
      } else {
        _showError('Failed to create group');
      }
    } catch (e) {
      print('❌ Error creating group: $e');
      _showError('Failed to create group: ${e.toString()}');
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13.5,
          ),
        ),
        backgroundColor: _error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13.5,
          ),
        ),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================
  Widget _buildImagePreview() {
    return Center(
      child: GestureDetector(
        onTap: _isUploadingImage || _isCreating ? null : _pickGroupImage,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primarySoft,
                image: _groupImageFile != null
                    ? DecorationImage(
                  image: FileImage(_groupImageFile!),
                  fit: BoxFit.cover,
                )
                    : _groupAvatarUrl != null
                    ? DecorationImage(
                  image: NetworkImage(_groupAvatarUrl!),
                  fit: BoxFit.cover,
                )
                    : null,
                border: Border.all(color: _primaryLight, width: 2),
                boxShadow: _softShadow,
              ),
              child: _groupImageFile == null && _groupAvatarUrl == null
                  ? const Icon(Icons.group_add, size: 50, color: _primary)
                  : null,
            ),
            if (_isUploadingImage)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: _softShadow,
                ),
                child: Icon(
                  _isUploadingImage ? Icons.cloud_upload : Icons.camera_alt,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SETTINGS
  // ============================================================
  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_radiusLg),
        boxShadow: _softShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: _lg),
          childrenPadding: EdgeInsets.zero,
          title: const Text(
            'Group Settings',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(_radiusSm),
            ),
            child: const Icon(Icons.settings_outlined,
                color: _primary, size: 20),
          ),
          children: [
            _buildSettingSwitch(
              title: 'Public Group',
              subtitle: 'Anyone can join without invitation',
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            _buildSettingSwitch(
              title: 'Approval Required',
              subtitle: 'Admin approval needed to join',
              value: _approvalRequired,
              onChanged: (v) => setState(() => _approvalRequired = v),
            ),
            _buildSettingSwitch(
              title: 'Allow Media',
              subtitle: 'Members can share photos and files',
              value: _allowMedia,
              onChanged: (v) => setState(() => _allowMedia = v),
            ),
            _buildSettingSwitch(
              title: 'Allow Reactions',
              subtitle: 'Members can react to messages',
              value: _allowReactions,
              onChanged: (v) => setState(() => _allowReactions = v),
            ),
            _buildSettingSwitch(
              title: 'Allow Editing',
              subtitle: 'Members can edit their messages',
              value: _allowEditing,
              onChanged: (v) => setState(() => _allowEditing = v),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(_lg, _sm, _lg, _lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Max Participants',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: _sm),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _maxParticipants.toDouble(),
                          min: 2,
                          max: 500,
                          divisions: 49,
                          label: _maxParticipants.toString(),
                          activeColor: _primary,
                          onChanged: (value) {
                            setState(() {
                              _maxParticipants = value.round();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _primarySoft,
                          borderRadius: BorderRadius.circular(_radiusSm),
                          border: Border.all(color: _primaryLight),
                        ),
                        child: Center(
                          child: Text(
                            _maxParticipants.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: _textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: _primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: _lg),
    );
  }

  // ============================================================
  // SELECTED MEMBERS
  // ============================================================
  Widget _buildSelectedMembersSection() {
    final selectedUsers =
    _allUsers.where((user) => _selectedUserIds.contains(user.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Members (${selectedUsers.length})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            if (selectedUsers.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() => _selectedUserIds.clear());
                },
                icon: const Icon(Icons.clear_all, size: 16, color: _error),
                label: const Text(
                  'Clear All',
                  style: TextStyle(
                    color: _error,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (selectedUsers.isNotEmpty)
          SizedBox(
            height: 74,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedUsers.length,
              itemBuilder: (context, index) {
                final user = selectedUsers[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: _primaryLight,
                            backgroundImage: user.profilePicture.isNotEmpty
                                ? NetworkImage(user.profilePicture)
                                : null,
                            child: user.profilePicture.isEmpty
                                ? Text(
                              user.initials,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _primary,
                              ),
                            )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => _toggleUserSelection(user),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 54,
                        child: Text(
                          user.firstName,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ============================================================
  // MEMBERS LIST
  // ============================================================
  Widget _buildMembersList() {
    if (_isLoadingUsers) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(_radiusLg),
          boxShadow: _softShadow,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primary),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(_radiusLg),
          boxShadow: _softShadow,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off,
                    size: 40, color: _primary),
              ),
              const SizedBox(height: 12),
              const Text(
                'No users found',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: _sm),
          child: Text(
            'Available Members (${_filteredUsers.length})',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(_radiusLg),
            boxShadow: _softShadow,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredUsers.length,
            separatorBuilder: (context, index) =>
            const Divider(height: 1, indent: 72, color: _border),
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];
              final isSelected = _selectedUserIds.contains(user.id);

              return ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: _primaryLight,
                  backgroundImage: user.profilePicture.isNotEmpty
                      ? NetworkImage(user.profilePicture)
                      : null,
                  child: user.profilePicture.isEmpty
                      ? Text(
                    user.initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  )
                      : null,
                ),
                title: Text(
                  user.fullName,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? _primary : _textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (user.department != null)
                      Text(
                        user.department!.name,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                trailing: Checkbox(
                  value: isSelected,
                  onChanged:
                  _isCreating ? null : (_) => _toggleUserSelection(user),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: _primary,
                ),
                onTap:
                _isCreating ? null : () => _toggleUserSelection(user),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Create New Group',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: _surface,
        surfaceTintColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textPrimary),
          onPressed: _isCreating ? null : () => Navigator.pop(context),
        ),
        actions: [
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_primary),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Avatar
                _buildImagePreview(),
                const SizedBox(height: _sm),
                const Center(
                  child: Text(
                    'Tap to set group photo (optional)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: _lg),

                // Group Name
                _buildTextField(
                  controller: _groupNameController,
                  label: 'Group Name *',
                  hint: 'Enter group name',
                  icon: Icons.group_outlined,
                  maxLength: 50,
                  enabled: !_isCreating,
                ),
                const SizedBox(height: 16),

                // Group Description
                _buildTextField(
                  controller: _groupDescriptionController,
                  label: 'Description (Optional)',
                  hint: 'Enter group description',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                  maxLength: 200,
                  enabled: !_isCreating,
                ),
                const SizedBox(height: _lg),

                // Settings
                _buildSettingsSection(),
                const SizedBox(height: _lg),

                // Selected Members
                if (_selectedUserIds.isNotEmpty) ...[
                  _buildSelectedMembersSection(),
                  const SizedBox(height: _lg),
                ],

                // Search
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(_radiusMd),
                    border: Border.all(color: _border, width: 1.5),
                    boxShadow: _softShadow,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchUsers,
                    enabled: !_isCreating,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search members...',
                      hintStyle: const TextStyle(
                        color: _textMuted,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon:
                      const Icon(Icons.search, color: _textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty &&
                          !_isCreating
                          ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: _textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Members List
                _buildMembersList(),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Create Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                border: const Border(top: BorderSide(color: _border)),
                boxShadow: _mediumShadow,
              ),
              child: ElevatedButton.icon(
                onPressed:
                _isCreating || _isUploadingImage ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _primary.withOpacity(0.5),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_radiusMd),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 24),
                ),
                icon: _isCreating
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.group_add, size: 22),
                label: Text(
                  _isCreating
                      ? 'Creating Group...'
                      : _isUploadingImage
                      ? 'Uploading Image...'
                      : 'Create Group',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: _sm),
        Container(
          decoration: BoxDecoration(
            color: enabled ? _surface : _bg,
            borderRadius: BorderRadius.circular(_radiusMd),
            border: Border.all(color: _border, width: 1.5),
            boxShadow: _softShadow,
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            enabled: enabled,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: _textMuted,
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: _textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}