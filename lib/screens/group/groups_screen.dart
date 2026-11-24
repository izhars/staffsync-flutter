import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/chat_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/user.dart';
import '../../app/add_members_bottom_sheet_content.dart';
import '../../models/Group.dart';
import '../chat_home_screen.dart';
import '../create_group_screen.dart';
import 'group_chat_screen.dart';

class GroupsScreen extends StatefulWidget {
  final ChatService chatService;

  const GroupsScreen({Key? key, required this.chatService}) : super(key: key);

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  late Future<List<Group>> _groupsFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _groupsFuture = _loadGroups();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        _currentUser = User.fromJson(userData);
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  Future<List<Group>> _loadGroups() async {
    try {
      final groups = await widget.chatService.getJoinedGroups();

      if (_currentUser == null) {
        final userData = await _authService.getUserData();
        if (userData != null) {
          _currentUser = User.fromJson(userData);
        }
      }

      final currentUserId = _currentUser?.id;
      if (currentUserId != null) {
        for (var group in groups) {
          group.currentUserId = currentUserId;
        }
      }

      return groups;
    } catch (e) {
      print('❌ Error loading groups: $e');
      return [];
    }
  }

  void _refreshGroups() {
    setState(() {
      _groupsFuture = _loadGroups();
    });
  }

  Future<void> _deleteGroup(Group group) async {
    if (!group.isOwner) {
      _showSnack('Only group owners can delete the group', isError: true);
      return;
    }

    final shouldDelete = await _showConfirmDialog(
      title: 'Delete Group',
      message:
      'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (shouldDelete != true) return;

    try {
      _showLoadingDialog();
      final response = await widget.chatService.deleteGroup(group.id);
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        if (response['success'] == true) {
          _showSnack(response['message'] ?? 'Group deleted successfully');
          _refreshGroups();
        } else {
          _showSnack(response['message'] ?? 'Failed to delete group',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showSnack('Error deleting group', isError: true);
      }
    }
  }

  Future<void> _leaveGroup(Group group) async {
    final shouldLeave = await _showConfirmDialog(
      title: 'Leave Group',
      message: 'Are you sure you want to leave "${group.name}"?',
      confirmText: 'Leave',
      isDestructive: true,
    );

    if (shouldLeave != true) return;

    try {
      _showLoadingDialog();
      final response = await widget.chatService.leaveGroup(group.id);
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        if (response['success'] == true) {
          _showSnack(response['message'] ?? 'Left group successfully');
          _refreshGroups();
        } else {
          _showSnack(response['message'] ?? 'Failed to leave group',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showSnack('Error leaving group', isError: true);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? ChatDesign.danger : ChatDesign.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(ChatDesign.md),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(ChatDesign.lg),
          decoration: BoxDecoration(
            color: ChatDesign.surface,
            borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
          ),
          child: const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor:
              AlwaysStoppedAnimation<Color>(ChatDesign.primary),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChatDesign.surface,
        surfaceTintColor: ChatDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChatDesign.radiusLg),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ChatDesign.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: ChatDesign.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding:
        const EdgeInsets.symmetric(horizontal: ChatDesign.md, vertical: ChatDesign.sm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: ChatDesign.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
              ),
            ),
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor:
              isDestructive ? ChatDesign.danger : ChatDesign.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
              ),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupContextMenu(Group group, BuildContext context) {
    final isOwner = group.isOwner;
    final isAdmin = group.isAdmin;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: ChatDesign.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ChatDesign.radiusXl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: ChatDesign.sm + 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ChatDesign.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: ChatDesign.md),

              // Group info header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatDesign.lg,
                  vertical: ChatDesign.sm,
                ),
                child: Row(
                  children: [
                    _buildGroupAvatar(group, size: 40),
                    const SizedBox(width: ChatDesign.sm + 4),
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ChatDesign.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: ChatDesign.sm),
              const Divider(height: 1, color: ChatDesign.border),

              _buildMenuTile(
                icon: Icons.info_outline_rounded,
                iconColor: ChatDesign.info,
                iconBg: ChatDesign.infoSoft,
                title: 'Group Info',
                onTap: () {
                  Navigator.pop(context);
                  _showGroupInfo(group);
                },
              ),

              if (isAdmin)
                _buildMenuTile(
                  icon: Icons.edit_outlined,
                  iconColor: ChatDesign.warning,
                  iconBg: ChatDesign.warningSoft,
                  title: 'Edit Group',
                  onTap: () {
                    Navigator.pop(context);
                    _editGroup(group);
                  },
                ),

              if (isAdmin)
                _buildMenuTile(
                  icon: Icons.person_add_alt_rounded,
                  iconColor: ChatDesign.online,
                  iconBg: ChatDesign.onlineSoft,
                  title: 'Add Members',
                  onTap: () {
                    Navigator.pop(context);
                    _showAddMembersBottomSheet(group);
                  },
                ),

              if (isOwner)
                _buildMenuTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: ChatDesign.danger,
                  iconBg: ChatDesign.dangerSoft,
                  title: 'Delete Group',
                  titleColor: ChatDesign.danger,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteGroup(group);
                  },
                ),

              if (!isOwner)
                _buildMenuTile(
                  icon: Icons.logout_rounded,
                  iconColor: ChatDesign.danger,
                  iconBg: ChatDesign.dangerSoft,
                  title: 'Leave Group',
                  titleColor: ChatDesign.danger,
                  onTap: () {
                    Navigator.pop(context);
                    _leaveGroup(group);
                  },
                ),

              const SizedBox(height: ChatDesign.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
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
            horizontal: ChatDesign.lg,
            vertical: ChatDesign.sm + 4,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: ChatDesign.sm + 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? ChatDesign.textPrimary,
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

  void _showGroupInfo(Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChatDesign.surface,
        surfaceTintColor: ChatDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChatDesign.radiusLg),
        ),
        titlePadding: const EdgeInsets.fromLTRB(
          ChatDesign.lg,
          ChatDesign.lg,
          ChatDesign.lg,
          ChatDesign.sm,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          ChatDesign.lg,
          0,
          ChatDesign.lg,
          ChatDesign.sm,
        ),
        title: Row(
          children: [
            _buildGroupAvatar(group, size: 44),
            const SizedBox(width: ChatDesign.sm + 4),
            Expanded(
              child: Text(
                group.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ChatDesign.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group.description.isNotEmpty) ...[
                const Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ChatDesign.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  group.description,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: ChatDesign.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: ChatDesign.md),
              ],

              _buildInfoTile(
                Icons.people_outline_rounded,
                '${group.memberCount} members',
              ),
              _buildInfoTile(
                group.isPublic
                    ? Icons.public_rounded
                    : Icons.lock_outline_rounded,
                group.isPublic ? 'Public' : 'Private',
              ),
              _buildInfoTile(
                Icons.admin_panel_settings_outlined,
                'Admins: ${group.admins.length}',
              ),
              _buildInfoTile(
                Icons.person_outline_rounded,
                'Created by ${group.creatorName}',
              ),
              _buildInfoTile(
                Icons.calendar_today_rounded,
                DateFormat.yMMMd().format(group.createdAt),
              ),

              const SizedBox(height: ChatDesign.md),
              const Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: ChatDesign.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              _buildSettingRow('Media Allowed', group.settings.allowMedia),
              _buildSettingRow(
                  'Reactions Allowed', group.settings.allowReactions),
              _buildSettingRow(
                  'Editing Allowed', group.settings.allowEditing),
              _buildSettingRow(
                  'Approval Required', group.settings.approvalRequired),
              _buildSettingRow(
                  'Max Participants', group.settings.maxParticipants),
            ],
          ),
        ),
        actionsPadding:
        const EdgeInsets.symmetric(horizontal: ChatDesign.md, vertical: ChatDesign.sm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: ChatDesign.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: ChatDesign.textSecondary),
          const SizedBox(width: ChatDesign.sm + 2),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: ChatDesign.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: ChatDesign.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (value is bool)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value
                    ? ChatDesign.onlineSoft
                    : ChatDesign.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                value ? Icons.check_rounded : Icons.close_rounded,
                color:
                value ? ChatDesign.online : ChatDesign.danger,
                size: 12,
              ),
            )
          else
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: ChatDesign.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  void _editGroup(Group group) {
    _showSnack('Edit group functionality coming soon');
  }

  Future<void> _showAddMembersBottomSheet(Group group) async {
    if (!group.isAdmin && !group.isOwner) return;

    final selectedUserIds = <String>{};

    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ChatDesign.radiusXl),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setSheetState) => AddMembersBottomSheetContent(
            groupId: group.id,
            chatService: widget.chatService,
            scrollController: scrollController,
            selectedUserIds: selectedUserIds,
            onSelectionChanged: () => setSheetState(() {}),
            onAddMembers: (selectedIds) async {
              Navigator.pop(context);
              await _confirmAndAddMembers(group.id, selectedIds);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndAddMembers(
      String groupId, Set<String> selectedUserIds) async {
    _showLoadingDialog();

    try {
      final success = await widget.chatService.addParticipantsToGroup(
        groupId: groupId,
        participantIds: selectedUserIds.toList(),
      );

      if (mounted) Navigator.pop(context);

      if (success) {
        _showSnack(
          'Added ${selectedUserIds.length} member${selectedUserIds.length > 1 ? 's' : ''}',
        );
        _refreshGroups();
      } else {
        _showSnack('Failed to add members', isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnack('Error: $e', isError: true);
    }
  }

  Widget _buildGroupAvatar(Group group, {double size = 40}) {
    final avatarUrl = group.avatar.url.isNotEmpty ? group.avatar.url : '';

    if (avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackAvatar(group, size),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: ChatDesign.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(ChatDesign.primary),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildFallbackAvatar(group, size);
  }

  Widget _buildFallbackAvatar(Group group, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGroupGradient(group.name),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          group.name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatDesign.bg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search
            Container(
              padding: const EdgeInsets.fromLTRB(
                ChatDesign.md,
                ChatDesign.md,
                ChatDesign.md,
                ChatDesign.sm,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: ChatDesign.surface,
                  borderRadius:
                  BorderRadius.circular(ChatDesign.radiusMd),
                  border:
                  Border.all(color: ChatDesign.border, width: 1),
                  boxShadow: ChatDesign.softShadow,
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: ChatDesign.md),
                      child: Icon(
                        Icons.search_rounded,
                        color: ChatDesign.textMuted,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: ChatDesign.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search groups...',
                          hintStyle: TextStyle(
                            color: ChatDesign.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                          EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: ChatDesign.textMuted,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),

            // List
            Expanded(
              child: FutureBuilder<List<Group>>(
                future: _groupsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildLoadingState();
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }

                  final groups = snapshot.data ?? [];
                  if (groups.isEmpty) {
                    return _buildEmptyState();
                  }

                  final filteredGroups =
                  _searchController.text.isEmpty
                      ? groups
                      : groups.where((group) {
                    final query =
                    _searchController.text.toLowerCase();
                    return group.name
                        .toLowerCase()
                        .contains(query) ||
                        group.description
                            .toLowerCase()
                            .contains(query) ||
                        group.participants.any((p) =>
                        p.fullName
                            .toLowerCase()
                            .contains(query) ||
                            p.email
                                .toLowerCase()
                                .contains(query));
                  }).toList();

                  if (filteredGroups.isEmpty) {
                    return _buildNoResultsState();
                  }

                  return _buildGroupsList(filteredGroups);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCreateGroupFab(),
    );
  }

  Widget _buildCreateGroupFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
        boxShadow: [
          BoxShadow(
            color: ChatDesign.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          if (_currentUser != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateGroupScreen(
                  chatService: widget.chatService,
                  currentUser: _currentUser!,
                ),
              ),
            ).then((_) => _refreshGroups());
          } else {
            _showSnack('Please wait while we load your user data',
                isError: true);
          }
        },
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'New Group',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            letterSpacing: -0.1,
          ),
        ),
        backgroundColor: ChatDesign.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
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
              AlwaysStoppedAnimation<Color>(ChatDesign.primary),
            ),
          ),
          SizedBox(height: ChatDesign.md),
          Text(
            'Loading your groups...',
            style: TextStyle(
              color: ChatDesign.textSecondary,
              fontSize: 13,
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
        padding: const EdgeInsets.all(ChatDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(ChatDesign.lg),
              decoration: const BoxDecoration(
                color: ChatDesign.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: ChatDesign.danger,
              ),
            ),
            const SizedBox(height: ChatDesign.md),
            const Text(
              'Failed to load groups',
              style: TextStyle(
                color: ChatDesign.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: ChatDesign.sm),
            const Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ChatDesign.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: ChatDesign.lg),
            ElevatedButton.icon(
              onPressed: _refreshGroups,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChatDesign.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatDesign.lg,
                  vertical: ChatDesign.sm + 4,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(ChatDesign.radiusSm),
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
        padding: const EdgeInsets.all(ChatDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: ChatDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_2_outlined,
                size: 42,
                color: ChatDesign.primary,
              ),
            ),
            const SizedBox(height: ChatDesign.lg),
            const Text(
              'No groups yet',
              style: TextStyle(
                color: ChatDesign.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: ChatDesign.sm),
            const Text(
              'Create your first group and start collaborating with your team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ChatDesign.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(ChatDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: ChatDesign.textMuted,
            ),
            SizedBox(height: ChatDesign.md),
            Text(
              'No matching groups',
              style: TextStyle(
                color: ChatDesign.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: ChatDesign.xs + 2),
            Text(
              'Try a different search',
              style: TextStyle(
                color: ChatDesign.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsList(List<Group> groups) {
    groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return RefreshIndicator(
      onRefresh: () async => _refreshGroups(),
      color: ChatDesign.primary,
      backgroundColor: ChatDesign.surface,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: ChatDesign.sm),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          return _buildGroupCard(groups[index]);
        },
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    final isAdmin = group.isAdmin;
    final isOwner = group.isOwner;

    return GestureDetector(
      onLongPress: () => _showGroupContextMenu(group, context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: ChatDesign.md),
        decoration: BoxDecoration(
          color: ChatDesign.surface,
          borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
          border: Border.all(color: ChatDesign.border, width: 1),
          boxShadow: ChatDesign.softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openGroupChat(group),
            borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(ChatDesign.sm + 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Stack(
                    children: [
                      _buildGroupAvatar(group, size: 52),
                      if (isOwner || isAdmin)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: ChatDesign.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ChatDesign.border,
                                width: 1,
                              ),
                              boxShadow: ChatDesign.softShadow,
                            ),
                            child: Icon(
                              isOwner
                                  ? Icons.workspace_premium_rounded
                                  : Icons.star_rounded,
                              size: 11,
                              color: isOwner
                                  ? ChatDesign.warning
                                  : ChatDesign.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: ChatDesign.sm + 4),

                  // Info
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: ChatDesign.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: ChatDesign.sm),
                            Icon(
                              group.isPublic
                                  ? Icons.public_rounded
                                  : Icons.lock_outline_rounded,
                              size: 13,
                              color: ChatDesign.textMuted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Description
                        Text(
                          group.description.isNotEmpty
                              ? group.description
                              : 'No description',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: group.description.isNotEmpty
                                ? ChatDesign.textSecondary
                                : ChatDesign.textMuted,
                            fontStyle: group.description.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: ChatDesign.sm),

                        // Footer
                        Row(
                          children: [
                            _buildMetaChip(
                              Icons.people_alt_outlined,
                              '${group.memberCount}',
                            ),
                            const SizedBox(width: ChatDesign.sm + 2),
                            _buildMetaChip(
                              Icons.schedule_rounded,
                              _formatDate(group.updatedAt),
                            ),
                            const Spacer(),
                            if (isOwner || isAdmin)
                              _buildRoleBadge(isOwner),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: ChatDesign.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: ChatDesign.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(bool isOwner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isOwner ? ChatDesign.dangerSoft : ChatDesign.primarySoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isOwner
              ? ChatDesign.danger.withOpacity(0.2)
              : ChatDesign.primaryLight,
          width: 1,
        ),
      ),
      child: Text(
        isOwner ? 'OWNER' : 'ADMIN',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: isOwner ? ChatDesign.danger : ChatDesign.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  List<Color> _getGroupGradient(String groupName) {
    final gradients = [
      [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)], // Blue
      [const Color(0xFF10B981), const Color(0xFF047857)], // Emerald
      [const Color(0xFFEF4444), const Color(0xFFB91C1C)], // Red
      [const Color(0xFFF59E0B), const Color(0xFFB45309)], // Amber
      [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)], // Violet
      [const Color(0xFF06B6D4), const Color(0xFF0E7490)], // Cyan
      [const Color(0xFFF97316), const Color(0xFFC2410C)], // Orange
      [const Color(0xFFEC4899), const Color(0xFFBE185D)], // Pink
    ];
    return gradients[groupName.hashCode.abs() % gradients.length];
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }

  void _openGroupChat(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(group: group),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}