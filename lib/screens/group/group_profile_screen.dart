import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staffsync/services/auth_service.dart';
import '../../models/Group.dart';
import '../../models/user.dart';
import '../../services/chat_service.dart';
import '../../services/employee_service.dart';

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
const Color _warning = Color(0xFFF59E0B);

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

class GroupProfileScreen extends StatefulWidget {
  final String groupId;
  const GroupProfileScreen({super.key, required this.groupId});

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  final ChatService _chatService = ChatService();
  final EmployeeService _employeeService = EmployeeService();
  final AuthService _authService = AuthService();
  Group? _group;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _availableUsers = [];
  List<String> _selectedUserIds = [];
  bool _isLoadingUsers = false;
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadGroup();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoadingUsers = true);

      final employees =
      await _employeeService.getEmployeeListWithStatus(isActive: true);

      final users = employees.map<User>((emp) {
        final fullName = emp['fullName']?.toString() ?? '';
        String firstName = '';
        String lastName = '';

        if (fullName.isNotEmpty) {
          final nameParts = fullName.trim().split(' ');
          firstName = nameParts.isNotEmpty ? nameParts[0] : '';
          lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        } else {
          final email = emp['email']?.toString() ?? '';
          firstName = email.split('@').first;
        }

        final userMap = {
          'id': emp['id']?.toString() ?? emp['_id']?.toString() ?? '',
          'employeeId': emp['employeeId']?.toString() ?? '',
          'firstName': firstName,
          'lastName': lastName,
          'fullName': fullName,
          'email': emp['email']?.toString() ?? '',
        };

        if (userMap['id'] == null || userMap['id']!.isEmpty) {
          userMap['id'] =
          'user_${emp['email'] ?? DateTime.now().millisecondsSinceEpoch}';
        }

        return User.fromJson(userMap);
      }).toList();

      final currentUserId = _authService.getUserId();
      final filteredUsers =
      users.where((user) => user.id != currentUserId).toList();

      setState(() {
        _allUsers = filteredUsers;
        _filteredUsers = filteredUsers;
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('❌ Error loading users: $e');
      if (mounted) _showError('Failed to load users: ${e.toString()}');
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _loadGroup() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final group = await _chatService.getGroupDetail(widget.groupId);
      if (mounted) {
        setState(() {
          _group = group;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  bool get _isCurrentUserAdminOrOwner {
    if (_group == null) return false;
    final participant = _group!.currentUserParticipant;
    if (participant == null || participant.id.isEmpty) return false;
    return participant.role == 'owner' || participant.role == 'admin';
  }

  // ---------- snackbars ----------
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

  void _showInfo(String message) {
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

  // ---------- options sheet ----------
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(_radiusLg),
            topRight: Radius.circular(_radiusLg),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: _sm + 4),
              _buildSheetTile(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Add members',
                onTap: () {
                  Navigator.pop(context);
                  _showAddMembersDialog();
                },
              ),
              _buildSheetTile(
                icon: Icons.share_outlined,
                title: 'Share group',
                onTap: () {
                  Navigator.pop(context);
                  _shareGroup();
                },
              ),
              _buildSheetTile(
                icon: Icons.copy_outlined,
                title: 'Copy group ID',
                onTap: () {
                  Navigator.pop(context);
                  _copyGroupId();
                },
              ),
              if (_isCurrentUserAdminOrOwner) ...[
                const Divider(height: 1, color: _border),
                _buildSheetTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit group info',
                  onTap: () {
                    Navigator.pop(context);
                    _showEditGroupDialog();
                  },
                ),
                _buildSheetTile(
                  icon: _group?.isArchived == true
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  title: _group?.isArchived == true
                      ? 'Unarchive group'
                      : 'Archive group',
                  onTap: () {
                    Navigator.pop(context);
                    _toggleArchiveGroup();
                  },
                ),
                _buildSheetTile(
                  icon: Icons.settings_outlined,
                  title: 'Group settings',
                  onTap: () {
                    Navigator.pop(context);
                    _showGroupSettingsDialog();
                  },
                ),
              ],
              const Divider(height: 1, color: _border),
              if (_group?.isOwner == false)
                _buildSheetTile(
                  icon: Icons.logout,
                  title: 'Leave group',
                  onTap: () => _handleLeaveGroup(context),
                  color: _error,
                ),
              if (_group?.isOwner == true)
                _buildSheetTile(
                  icon: Icons.delete_forever,
                  title: 'Delete group',
                  onTap: () => _handleDeleteGroup(context),
                  color: _error,
                ),
              const SizedBox(height: _sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? _textPrimary;
    return ListTile(
      leading: Icon(icon, color: color ?? _primary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
      onTap: onTap,
    );
  }

  void _copyGroupId() {
    if (_group == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        surfaceTintColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
        ),
        title: const Text(
          'Group ID',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        content: SelectableText(
          _group!.id,
          style: const TextStyle(
            fontSize: 14,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareGroup() {
    if (_group == null) return;
    final shareText = 'Join ${_group!.name} group!\n\n'
        'Group ID: ${_group!.id}\n'
        '${_group!.description.isNotEmpty ? 'Description: ${_group!.description}\n' : ''}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        surfaceTintColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
        ),
        title: const Text(
          'Share Group',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share this group with others:',
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primarySoft,
                borderRadius: BorderRadius.circular(_radiusSm),
                border: Border.all(color: _primaryLight),
              ),
              child: SelectableText(
                shareText,
                style: const TextStyle(
                  fontSize: 13,
                  color: _textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showInfo('Copied to clipboard');
            },
            child: const Text(
              'Copy',
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLeaveGroup(BuildContext context) async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _confirmDialog(
        ctx,
        title: 'Leave Group?',
        content:
        'You will no longer receive messages from this group. This action cannot be undone.',
        confirmText: 'Leave',
        confirmColor: _error,
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isProcessing = true);
    try {
      final result = await _chatService.leaveGroup(widget.groupId);
      if (result['success'] == true && mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        throw Exception(result['message'] ?? 'Failed to leave group');
      }
    } catch (e) {
      _showError(
          'Failed to leave: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDeleteGroup(BuildContext context) async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _confirmDialog(
        ctx,
        title: 'Delete Group?',
        content:
        'This will permanently delete the group and all its messages. This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: _error,
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isProcessing = true);
    try {
      final result = await _chatService.deleteGroup(widget.groupId);
      if (result['success'] == true && mounted) {
        _showSuccess('Group deleted successfully');
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        throw Exception(result['message'] ?? 'Failed to delete group');
      }
    } catch (e) {
      _showError(
          'Failed to delete: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleArchiveGroup() async {
    if (_group == null) return;
    final action = _group!.isArchived ? 'unarchive' : 'archive';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _confirmDialog(
        ctx,
        title: '${action.capitalize()} Group?',
        content: _group!.isArchived
            ? 'This will make the group active again.'
            : 'This will hide the group from your chat list. You can unarchive it later.',
        confirmText: action.capitalize(),
        confirmColor: _primary,
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isProcessing = true);
    try {
      final success = await _chatService.archiveGroup(widget.groupId);
      if (success && mounted) {
        await _loadGroup();
        _showSuccess('Group ${action}d successfully');
      } else {
        throw Exception('Failed to $action group');
      }
    } catch (e) {
      _showError(
          'Failed to $action: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _loadAvailableUsers() async {
    if (_group == null) return;
    setState(() => _isLoadingUsers = true);
    try {
      final result = await _chatService.getGroupUsers(widget.groupId);
      if (result['success'] == true && result['data'] != null) {
        final users = List<Map<String, dynamic>>.from(
            result['data']['nonAddedUsers'] ?? []);
        setState(() {
          _availableUsers = users;
          _selectedUserIds.clear();
        });
      } else {
        throw Exception(result['message'] ?? 'Failed to load users');
      }
    } catch (e) {
      _showError(
          'Failed to load users: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _addMembersToGroup() async {
    if (_selectedUserIds.isEmpty) return;
    setState(() => _isProcessing = true);
    try {
      final success = await _chatService.addParticipantsToGroup(
        groupId: widget.groupId,
        participantIds: _selectedUserIds,
      );
      if (success && mounted) {
        Navigator.pop(context);
        await _loadGroup();
        _showSuccess(
            '${_selectedUserIds.length} member(s) added successfully');
      } else {
        throw Exception('Failed to add members');
      }
    } catch (e) {
      _showError(
          'Failed to add members: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showAddMembersDialog() {
    if (_group == null) return;

    final existingMemberIds = _group!.participants
        .map((participant) => participant.userId)
        .where((id) => id.isNotEmpty)
        .toList();

    final usersNotInGroup =
    _allUsers.where((user) => !existingMemberIds.contains(user.id)).toList();

    _selectedUserIds.clear();

    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        List<User> filteredUsers = usersNotInGroup;

        return StatefulBuilder(
          builder: (context, setState) {
            void updateFilter(String query) {
              searchQuery = query.toLowerCase();
              if (searchQuery.isEmpty) {
                filteredUsers = usersNotInGroup;
              } else {
                filteredUsers = usersNotInGroup.where((user) {
                  final fullName =
                  '${user.firstName} ${user.lastName}'.toLowerCase();
                  final email = user.email.toLowerCase();
                  final employeeId = user.employeeId?.toLowerCase() ?? '';
                  return fullName.contains(searchQuery) ||
                      email.contains(searchQuery) ||
                      employeeId.contains(searchQuery);
                }).toList();
              }
            }

            return AlertDialog(
              backgroundColor: _surface,
              surfaceTintColor: _surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radiusLg),
              ),
              title: const Text(
                'Add Members',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search
                    Container(
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(_radiusSm),
                        border: Border.all(color: _border, width: 1.5),
                      ),
                      child: TextField(
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search users by name, email, or ID...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: _textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon:
                          Icon(Icons.search, color: _textSecondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (value) {
                          setState(() => updateFilter(value));
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stats chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatChip(
                          icon: Icons.group,
                          label: 'In Group: ${existingMemberIds.length}',
                          color: _primary,
                        ),
                        _buildStatChip(
                          icon: Icons.person_add,
                          label: 'Available: ${usersNotInGroup.length}',
                          color: _textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: _sm),

                    // Body
                    if (_isLoadingUsers)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor:
                            AlwaysStoppedAnimation<Color>(_primary),
                            strokeWidth: 3,
                          ),
                        ),
                      )
                    else if (usersNotInGroup.isNotEmpty)
                      Expanded(
                        child: Column(
                          children: [
                            if (_selectedUserIds.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: _primarySoft,
                                  borderRadius:
                                  BorderRadius.circular(_radiusSm),
                                  border: Border.all(color: _primaryLight),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: _primary, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_selectedUserIds.length} selected',
                                      style: const TextStyle(
                                        color: _primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (searchQuery.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Found ${filteredUsers.length} user${filteredUsers.length != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: _textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: filteredUsers.isEmpty
                                  ? Center(
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding:
                                      const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _primarySoft,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.search_off,
                                          size: 40,
                                          color: _primary),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No users found',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Try a different search term',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: _textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  : ListView.builder(
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  final isSelected =
                                  _selectedUserIds.contains(user.id);

                                  return Container(
                                    margin: const EdgeInsets.only(
                                        bottom: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _primarySoft
                                          : _surface,
                                      borderRadius:
                                      BorderRadius.circular(
                                          _radiusSm),
                                      border: Border.all(
                                        color: isSelected
                                            ? _primaryLight
                                            : _border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4),
                                      leading: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: _primaryLight,
                                        child: Text(
                                          user.firstName.isNotEmpty
                                              ? user.firstName[0]
                                              .toUpperCase()
                                              : user.email.isNotEmpty
                                              ? user.email[0]
                                              .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: _primary,
                                            fontWeight:
                                            FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        '${user.firstName} ${user.lastName}'
                                            .trim(),
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.email,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _textSecondary,
                                              fontWeight:
                                              FontWeight.w500,
                                            ),
                                          ),
                                          if (user.employeeId
                                              ?.isNotEmpty ==
                                              true)
                                            Text(
                                              'ID: ${user.employeeId}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: _textMuted,
                                                fontWeight:
                                                FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Checkbox(
                                        value: isSelected,
                                        activeColor: _primary,
                                        shape:
                                        RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(4),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedUserIds
                                                  .add(user.id!);
                                            } else {
                                              _selectedUserIds
                                                  .remove(user.id!);
                                            }
                                          });
                                        },
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedUserIds
                                                .remove(user.id!);
                                          } else {
                                            _selectedUserIds
                                                .add(user.id!);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: _primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.group_off,
                                    size: 48, color: _primary),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No Users Available',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  'All registered users are already members of this group.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 13,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _selectedUserIds.clear();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: _textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                  _selectedUserIds.isEmpty ? null : _addMembersToGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_radiusSm),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white),
                    ),
                  )
                      : Text(
                    'Add ${_selectedUserIds.length} Member${_selectedUserIds.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_radiusSm),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateGroupInfo({
    required String name,
    required String description,
  }) async {
    setState(() => _isProcessing = true);
    try {
      final success = await _chatService.updateGroupSettings(
        groupId: widget.groupId,
        settings: {
          'name': name,
          'description': description,
        },
      );
      if (success && mounted) {
        await _loadGroup();
        _showSuccess('Group updated successfully');
      } else {
        throw Exception('Failed to update group');
      }
    } catch (e) {
      _showError(
          'Failed to update: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showEditGroupDialog() {
    if (_group == null) return;
    final nameController = TextEditingController(text: _group!.name);
    final descController = TextEditingController(text: _group!.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        surfaceTintColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLg),
        ),
        title: const Text(
          'Edit Group',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(
              controller: nameController,
              label: 'Group Name',
            ),
            const SizedBox(height: 16),
            _buildDialogField(
              controller: descController,
              label: 'Description',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                _showError('Group name is required');
                return;
              }
              Navigator.pop(context);
              await _updateGroupInfo(
                name: nameController.text.trim(),
                description: descController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_radiusSm),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
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
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _bg,
            hintStyle: const TextStyle(
              color: _textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_radiusSm),
              borderSide: const BorderSide(color: _border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_radiusSm),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _showGroupSettingsDialog() {
    if (_group == null) return;

    bool isPublic = _group!.settings.isPublic;
    bool approvalRequired = _group!.settings.approvalRequired;
    bool allowMedia = _group!.settings.allowMedia;
    bool allowReactions = _group!.settings.allowReactions;
    bool allowEditing = _group!.settings.allowEditing;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: _surface,
            surfaceTintColor: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radiusLg),
            ),
            title: const Text(
              'Group Settings',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSwitchTile(
                      title: 'Public Group',
                      subtitle: 'Anyone can join',
                      value: isPublic,
                      onChanged: (v) => setState(() => isPublic = v),
                    ),
                    _buildSwitchTile(
                      title: 'Approval Required',
                      subtitle: 'Admin approval for new members',
                      value: approvalRequired,
                      onChanged: (v) => setState(() => approvalRequired = v),
                    ),
                    const Divider(height: 1, color: _border),
                    _buildSwitchTile(
                      title: 'Allow Media',
                      subtitle: 'Allow photos, videos, and files',
                      value: allowMedia,
                      onChanged: (v) => setState(() => allowMedia = v),
                    ),
                    _buildSwitchTile(
                      title: 'Allow Reactions',
                      subtitle: 'Allow emoji reactions to messages',
                      value: allowReactions,
                      onChanged: (v) => setState(() => allowReactions = v),
                    ),
                    _buildSwitchTile(
                      title: 'Allow Editing',
                      subtitle: 'Allow members to edit messages',
                      value: allowEditing,
                      onChanged: (v) => setState(() => allowEditing = v),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Max Participants: ${_group!.settings.maxParticipants}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _updateGroupSettings(
                    settings: {
                      'isPublic': isPublic,
                      'approvalRequired': approvalRequired,
                      'allowMedia': allowMedia,
                      'allowReactions': allowReactions,
                      'allowEditing': allowEditing,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_radiusSm),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
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
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _updateGroupSettings({
    required Map<String, dynamic> settings,
  }) async {
    setState(() => _isProcessing = true);
    try {
      final success = await _chatService.updateGroupSettings(
        groupId: widget.groupId,
        settings: settings,
      );
      if (success && mounted) {
        await _loadGroup();
        _showSuccess('Settings updated successfully');
      } else {
        throw Exception('Failed to update settings');
      }
    } catch (e) {
      _showError(
          'Failed to update: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showParticipantOptions(GroupParticipant participant) {
    final isCurrentUser =
        participant.userId == _group?.currentUserParticipant?.userId;
    final isOwner = participant.role == 'owner';
    final canManage =
        _isCurrentUserAdminOrOwner && !isOwner && !isCurrentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(_radiusLg),
            topRight: Radius.circular(_radiusLg),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: _sm + 4),
              _buildSheetTile(
                icon: Icons.person_outline,
                title: 'View Profile',
                onTap: () => Navigator.pop(context),
              ),
              _buildSheetTile(
                icon: Icons.message_outlined,
                title: 'Send Message',
                onTap: () => Navigator.pop(context),
              ),
              if (canManage) ...[
                const Divider(height: 1, color: _border),
                if (participant.role != 'admin')
                  _buildSheetTile(
                    icon: Icons.admin_panel_settings,
                    title: 'Make Admin',
                    onTap: () {
                      Navigator.pop(context);
                      _updateParticipantRole(participant, 'admin');
                    },
                  ),
                if (participant.role == 'admin')
                  _buildSheetTile(
                    icon: Icons.person_outline,
                    title: 'Remove Admin',
                    onTap: () {
                      Navigator.pop(context);
                      _updateParticipantRole(participant, 'member');
                    },
                  ),
                _buildSheetTile(
                  icon: Icons.remove_circle_outline,
                  title: 'Remove from Group',
                  color: _error,
                  onTap: () {
                    Navigator.pop(context);
                    _removeParticipant(participant);
                  },
                ),
              ],
              const SizedBox(height: _sm),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateParticipantRole(
      GroupParticipant participant, String newRole) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _confirmDialog(
        ctx,
        title: '${newRole.capitalize()} Role',
        content:
        'Are you sure you want to make ${participant.fullName} an ${newRole}?',
        confirmText: 'Make ${newRole}',
        confirmColor: _primary,
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isProcessing = true);
    try {
      _showInfo('Update role functionality needs to be implemented in ChatService');
    } catch (e) {
      _showError(
          'Failed to update role: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _removeParticipant(GroupParticipant participant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _confirmDialog(
        ctx,
        title: 'Remove Member',
        content:
        'Are you sure you want to remove ${participant.fullName} from the group?',
        confirmText: 'Remove',
        confirmColor: _error,
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isProcessing = true);
    try {
      final success = await _chatService.removeParticipant(
        groupId: widget.groupId,
        participantId: participant.id,
      );
      if (success && mounted) {
        await _loadGroup();
        _showSuccess('${participant.fullName} removed from group');
      } else {
        throw Exception('Failed to remove participant');
      }
    } catch (e) {
      _showError(
          'Failed to remove: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _confirmDialog(
      BuildContext ctx, {
        required String title,
        required String content,
        required String confirmText,
        required Color confirmColor,
      }) {
    return AlertDialog(
      backgroundColor: _surface,
      surfaceTintColor: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusLg),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: _textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmText,
            style: TextStyle(
              color: confirmColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Group Profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_primary),
                ),
              ),
            ),
          if (!_isLoading && _group != null)
            IconButton(
              icon: const Icon(Icons.more_vert, color: _textPrimary),
              onPressed: _showMoreOptions,
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
          ? _buildError()
          : _group != null
          ? _buildContent()
          : const Center(
        child: Text(
          'Group not found',
          style: TextStyle(color: _textSecondary),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_primary),
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 40, color: _error),
            ),
            const SizedBox(height: _lg),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: _xl),
            ElevatedButton.icon(
              onPressed: _loadGroup,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: _xl, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_radiusSm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final group = _group!;
    final currentUserParticipant = group.currentUserParticipant;
    final hasAvatar = group.avatar.url.isNotEmpty;

    return RefreshIndicator(
      color: _primary,
      backgroundColor: _surface,
      onRefresh: _loadGroup,
      child: ListView(
        children: [
          // ---------- Header ----------
          Container(
            padding: const EdgeInsets.all(_lg),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(_radiusLg),
                bottomRight: Radius.circular(_radiusLg),
              ),
              boxShadow: _softShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(_radiusMd),
                          child: Container(
                            width: 95,
                            height: 195,
                            decoration: BoxDecoration(
                              boxShadow: _softShadow,
                              color: !hasAvatar ? _primary : null,
                            ),
                            child: hasAvatar
                                ? ClipRRect(
                              borderRadius:
                              BorderRadius.circular(_radiusMd),
                              child: Image.network(
                                group.avatar.url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                                : Center(
                              child: Text(
                                group.name.isNotEmpty
                                    ? group.name[0].toUpperCase()
                                    : 'G',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (currentUserParticipant != null &&
                            currentUserParticipant.id.isNotEmpty)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _getRoleColor(
                                    currentUserParticipant.role),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 3),
                                boxShadow: _softShadow,
                              ),
                              child: Icon(
                                _getRoleIcon(currentUserParticipant.role),
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                                letterSpacing: -0.3,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (group.isArchived)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _warning.withOpacity(0.12),
                                borderRadius:
                                BorderRadius.circular(_xs + 2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.archive_rounded,
                                      size: 12, color: _warning),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Archived',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: _warning,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Stats block
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _primarySoft,
                          borderRadius: BorderRadius.circular(_radiusMd),
                          border: Border.all(color: _primaryLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _buildStat(
                                icon: Icons.people_rounded,
                                count: '${group.participants.length}',
                                label: 'Members',
                              ),
                            ),
                            Container(
                                width: 1, height: 30, color: _primaryLight),
                            Expanded(
                              child: _buildStat(
                                icon: group.isPublic
                                    ? Icons.public_rounded
                                    : Icons.lock_rounded,
                                count:
                                group.isPublic ? 'Public' : 'Private',
                                label: 'Visibility',
                              ),
                            ),
                            if (group.type.isNotEmpty) ...[
                              Container(
                                  width: 1,
                                  height: 30,
                                  color: _primaryLight),
                              Expanded(
                                child: _buildStat(
                                  icon: Icons.category_rounded,
                                  count: group.type,
                                  label: 'Type',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (currentUserParticipant != null &&
                          currentUserParticipant.id.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _getRoleColor(
                                currentUserParticipant.role)
                                .withOpacity(0.08),
                            borderRadius:
                            BorderRadius.circular(_radiusSm),
                            border: Border.all(
                              color: _getRoleColor(
                                  currentUserParticipant.role)
                                  .withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getRoleIcon(
                                    currentUserParticipant.role),
                                size: 16,
                                color: _getRoleColor(
                                    currentUserParticipant.role),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'You are ',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                currentUserParticipant.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _getRoleColor(
                                      currentUserParticipant.role),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (group.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          group.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          _buildStatisticsCard(group),
          _buildInfoCard(group),
          _buildSettingsCard(group),
          _buildParticipantsCard(group),
          if (_isCurrentUserAdminOrOwner || group.isOwner == false)
            _buildDangerZoneCard(group),
          const SizedBox(height: _xl),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: _primary),
        const SizedBox(height: 6),
        Text(
          count,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _textMuted,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Icons.workspace_premium_rounded;
      case 'admin':
        return Icons.shield_rounded;
      case 'moderator':
        return Icons.verified_user_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Widget _buildStatisticsCard(Group group) {
    return _buildCard(
      title: 'Statistics',
      icon: Icons.insert_chart_outlined,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(Icons.message, 'Messages',
                group.messageCount.toString(), _primary),
            _buildStatItem(Icons.notifications, 'Unread',
                group.unreadCount.toString(), _warning),
            _buildStatItem(Icons.group, 'Active',
                group.activeParticipants.length.toString(), _primary),
            _buildStatItem(Icons.admin_panel_settings, 'Admins',
                group.admins.length.toString(), _textSecondary),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_radiusSm),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: _textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Group group) {
    return _buildCard(
      title: 'Group Information',
      icon: Icons.info_outline,
      trailing: _isCurrentUserAdminOrOwner
          ? _buildCardEditButton(onPressed: _showEditGroupDialog)
          : null,
      children: [
        _buildInfoRow(Icons.person, 'Created by', group.creatorName),
        _buildInfoRow(
            Icons.date_range, 'Created', _formatDate(group.createdAt)),
        _buildInfoRow(
            Icons.update, 'Last updated', _formatDate(group.updatedAt)),
        _buildInfoRow(Icons.visibility, 'Visibility',
            group.isPublic ? 'Public' : 'Private'),
        _buildInfoRow(Icons.category, 'Type', group.type.capitalize()),
      ],
    );
  }

  Widget _buildSettingsCard(Group group) {
    final settings = group.settings;
    return _buildCard(
      title: 'Group Settings',
      icon: Icons.settings_outlined,
      trailing: _isCurrentUserAdminOrOwner
          ? _buildCardEditButton(onPressed: _showGroupSettingsDialog)
          : null,
      children: [
        _buildSettingRow(
            'Media sharing', settings.allowMedia, Icons.photo_outlined),
        _buildSettingRow('Reactions', settings.allowReactions,
            Icons.emoji_emotions_outlined),
        _buildSettingRow('Message editing', settings.allowEditing,
            Icons.edit_note_outlined),
        _buildSettingRow('Approval required', settings.approvalRequired,
            Icons.verified_user_outlined),
        _buildInfoRow(Icons.group_add, 'Max participants',
            settings.maxParticipants.toString()),
      ],
    );
  }

  Widget _buildCardEditButton({required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: _primarySoft,
        borderRadius: BorderRadius.circular(_radiusSm),
      ),
      child: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 18, color: _primary),
        onPressed: onPressed,
        tooltip: 'Edit',
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildParticipantsCard(Group group) {
    return _buildCard(
      title: 'Participants (${group.participants.length})',
      icon: Icons.people_outline,
      trailing: _isCurrentUserAdminOrOwner
          ? Container(
        decoration: BoxDecoration(
          color: _primarySoft,
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
        child: IconButton(
          icon: const Icon(Icons.person_add,
              size: 18, color: _primary),
          onPressed: _showAddMembersDialog,
          tooltip: 'Add members',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
        ),
      )
          : null,
      children: [
        const SizedBox(height: 6),
        ...group.participants.map((participant) {
          final isCurrentUser =
              participant.userId == group.currentUserParticipant?.userId;
          return InkWell(
            onTap: () => _showParticipantOptions(participant),
            borderRadius: BorderRadius.circular(_radiusSm),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCurrentUser ? _primarySoft : _surface,
                borderRadius: BorderRadius.circular(_radiusSm),
                border: Border.all(
                  color: isCurrentUser ? _primaryLight : _border,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: participant
                        .user['profilePicture']
                        ?.isNotEmpty ==
                        true
                        ? NetworkImage(
                        participant.user['profilePicture'] as String)
                        : null,
                    backgroundColor: _primaryLight,
                    child: participant.user['profilePicture']?.isEmpty !=
                        false
                        ? Text(
                      participant.user['firstName']
                          ?.isNotEmpty ==
                          true
                          ? participant.user['firstName'][0]
                          .toUpperCase()
                          : participant.user['email']?[0]
                          ?.toUpperCase() ??
                          '?',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCurrentUser
                              ? '${participant.user['firstName']} ${participant.user['lastName']} (You)'
                              : '${participant.user['firstName']} ${participant.user['lastName']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          participant.user['email'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getRoleColor(participant.role)
                                    .withOpacity(0.12),
                                borderRadius:
                                BorderRadius.circular(_xs + 2),
                              ),
                              child: Text(
                                participant.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color:
                                  _getRoleColor(participant.role),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Joined ${_formatRelativeDate(participant.joinedAt)}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: _textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (participant.isActive)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDangerZoneCard(Group group) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(_lg),
      decoration: BoxDecoration(
        color: _error.withOpacity(0.04),
        borderRadius: BorderRadius.circular(_radiusLg),
        border: Border.all(color: _error.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(_xs + 2),
                ),
                child: const Icon(Icons.warning_amber_outlined,
                    color: _error, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _error,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (group.isOwner == false)
            _buildDangerRow(
              icon: Icons.logout,
              title: 'Leave Group',
              subtitle:
              'You will no longer receive messages from this group',
              actionLabel: 'Leave',
              onPressed: () => _handleLeaveGroup(context),
            ),
          if (group.isOwner == true)
            _buildDangerRow(
              icon: Icons.delete_forever,
              title: 'Delete Group',
              subtitle:
              'Permanently delete this group and all messages',
              actionLabel: 'Delete',
              onPressed: () => _handleDeleteGroup(context),
            ),
        ],
      ),
    );
  }

  Widget _buildDangerRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        Icon(icon, color: _error, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _error,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radiusSm),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, bool enabled, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? _primary : _error,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_radiusLg),
        boxShadow: _softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(_lg, _lg, _lg, _sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primarySoft,
                    borderRadius: BorderRadius.circular(_radiusSm),
                  ),
                  child: Icon(icon, color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _lg),
            child: Column(children: children),
          ),
          const SizedBox(height: _sm),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return const Color(0xFFB45309); // amber-700
      case 'admin':
        return _primary;
      default:
        return _textSecondary;
    }
  }

  Color _getUserAvatarColor(String userId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
    ];
    final index = userId.hashCode % colors.length;
    return colors[index];
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}