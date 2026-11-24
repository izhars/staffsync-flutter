import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/employee_service.dart';
import '../../models/user.dart';
import 'chat_connection_screen.dart';
import 'chat_home_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late ChatService _chatService;
  final AuthService _authService = AuthService();
  final EmployeeService _employeeService = EmployeeService();
  User? _currentUser;
  late Future<List<User>> _contactsFuture;
  List<User> _allContacts = [];
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'All'},
    {'id': 'online', 'label': 'Online'},
    {'id': 'hr', 'label': 'HR'},
    {'id': 'manager', 'label': 'Managers'},
    {'id': 'it', 'label': 'IT'},
    {'id': 'sales', 'label': 'Sales'},
  ];

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _contactsFuture = Future.value([]);
    _loadUserDataAndContacts();
  }

  Future<void> _loadUserDataAndContacts() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        _currentUser = User.fromJson(userData);
      }

      setState(() {
        _contactsFuture = _getContacts();
      });
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _contactsFuture = Future.value([]);
      });
    }
  }

  Future<List<User>> _getContacts() async {
    try {
      final allEmployees =
      await _employeeService.getEmployeeListWithStatus(isActive: true);
      final allUsers = allEmployees.map((emp) => User.fromJson(emp)).toList();
      final filteredUsers =
      allUsers.where((user) => user.id != _currentUser?.id).toList();
      _allContacts = filteredUsers;
      return filteredUsers;
    } catch (e) {
      print('❌ Error loading contacts: $e');
      return [];
    }
  }

  List<User> _filterContacts(List<User> contacts) {
    if (_selectedFilter == 'all') return contacts;

    if (_selectedFilter == 'online') {
      return contacts.where((user) => user.isOnline).toList();
    }
    if (_selectedFilter == 'hr') {
      return contacts
          .where((u) => u.department?.code?.toLowerCase() == 'hr')
          .toList();
    }
    if (_selectedFilter == 'manager') {
      return contacts
          .where((u) => u.role.toLowerCase() == 'manager')
          .toList();
    }
    if (_selectedFilter == 'it') {
      return contacts
          .where((u) => u.department?.code?.toLowerCase() == 'it')
          .toList();
    }
    if (_selectedFilter == 'sales') {
      return contacts
          .where((u) => u.department?.code?.toLowerCase() == 'sales')
          .toList();
    }
    return contacts;
  }

  List<User> _searchContacts(List<User> contacts, String query) {
    if (query.isEmpty) return contacts;

    final lowercaseQuery = query.toLowerCase();
    return contacts.where((user) {
      return user.fullName.toLowerCase().contains(lowercaseQuery) ||
          user.email.toLowerCase().contains(lowercaseQuery) ||
          user.employeeId.toLowerCase().contains(lowercaseQuery) ||
          (user.department?.name ?? '')
              .toLowerCase()
              .contains(lowercaseQuery) ||
          user.role.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ===== SEARCH + FILTERS =====
        Container(
          padding: const EdgeInsets.fromLTRB(
            ChatDesign.md,
            ChatDesign.md,
            ChatDesign.md,
            ChatDesign.sm,
          ),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: ChatDesign.sm + 4),
              _buildFilterChips(),
            ],
          ),
        ),

        // ===== CONTACTS LIST =====
        Expanded(
          child: FutureBuilder<List<User>>(
            future: _contactsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }
              if (snapshot.hasError) {
                return _buildErrorState();
              }

              final contacts = snapshot.data ?? [];
              if (contacts.isEmpty) {
                return _buildEmptyState();
              }

              List<User> filteredContacts = _filterContacts(contacts);
              filteredContacts = _searchContacts(
                filteredContacts,
                _searchController.text,
              );

              filteredContacts.sort((a, b) {
                if (a.isOnline != b.isOnline) {
                  return a.isOnline ? -1 : 1;
                }
                return a.fullName.compareTo(b.fullName);
              });

              if (filteredContacts.isEmpty) {
                return _buildNoResultsState();
              }

              return _buildContactsList(filteredContacts);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: ChatDesign.surface,
        borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
        border: Border.all(color: ChatDesign.border, width: 1),
        boxShadow: ChatDesign.softShadow,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ChatDesign.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search contacts...',
          hintStyle: const TextStyle(
            color: ChatDesign.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ChatDesign.textMuted,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: ChatDesign.textMuted,
              size: 18,
            ),
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter['id'];

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: ChatDesign.md - 2,
                vertical: ChatDesign.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? ChatDesign.primary
                    : ChatDesign.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? ChatDesign.primary
                      : ChatDesign.border,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: ChatDesign.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                    spreadRadius: -2,
                  ),
                ]
                    : null,
              ),
              child: Text(
                filter['label'],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : ChatDesign.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          );
        },
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
            'Loading contacts...',
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
              'Failed to load contacts',
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
              onPressed: () =>
                  setState(() => _contactsFuture = _getContacts()),
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
              decoration: BoxDecoration(
                color: ChatDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_alt_outlined,
                size: 42,
                color: ChatDesign.primary,
              ),
            ),
            const SizedBox(height: ChatDesign.lg),
            const Text(
              'No contacts yet',
              style: TextStyle(
                color: ChatDesign.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: ChatDesign.sm),
            const Text(
              'Your team members will appear here once added to the system',
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
              'No matching contacts',
              style: TextStyle(
                color: ChatDesign.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: ChatDesign.xs + 2),
            Text(
              'Try a different search or filter',
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

  Widget _buildContactsList(List<User> contacts) {
    final Map<String, List<User>> groupedContacts = {};

    for (var contact in contacts) {
      final deptName = contact.department?.name ?? 'Other';
      if (!groupedContacts.containsKey(deptName)) {
        groupedContacts[deptName] = [];
      }
      groupedContacts[deptName]!.add(contact);
    }

    final sortedDepartments = groupedContacts.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: ChatDesign.lg),
      itemCount: sortedDepartments.length,
      itemBuilder: (context, deptIndex) {
        final deptName = sortedDepartments[deptIndex];
        final deptContacts = groupedContacts[deptName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDepartmentHeader(deptName, deptContacts.length),
            ...deptContacts.map((user) => _buildContactCard(user)),
          ],
        );
      },
    );
  }

  Widget _buildDepartmentHeader(String deptName, int count) {
    final deptColor = _getDepartmentColor(deptName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ChatDesign.md,
        ChatDesign.lg,
        ChatDesign.md,
        ChatDesign.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: deptColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: ChatDesign.sm),
          Text(
            deptName.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: ChatDesign.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: ChatDesign.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ChatDesign.surfaceMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                color: ChatDesign.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(User user) {
    final lastSeen = _formatLastSeen(user.lastSeen as String?);
    final isOnline = user.isOnline;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ChatDesign.md,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: ChatDesign.surface,
        borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
        border: Border.all(color: ChatDesign.border, width: 1),
        boxShadow: ChatDesign.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startChatWithUser(user),
          borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(ChatDesign.sm + 4),
            child: Row(
              children: [
                // ===== AVATAR =====
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isOnline
                            ? const LinearGradient(
                          colors: [
                            ChatDesign.online,
                            ChatDesign.online,
                          ],
                        )
                            : null,
                        border: isOnline
                            ? null
                            : Border.all(
                          color: ChatDesign.border,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: ChatDesign.primarySoft,
                        child: ClipOval(
                          child: user.profilePicture.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: user.profilePicture,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                    ChatDesign.primary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) =>
                                _avatarFallback(user),
                          )
                              : _avatarFallback(user),
                        ),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: ChatDesign.online,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ChatDesign.surface,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                ChatDesign.online.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: ChatDesign.sm + 4),

                // ===== INFO =====
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + role
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: ChatDesign.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: ChatDesign.sm),
                          _buildRoleBadge(user.role),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Designation
                      Row(
                        children: [
                          const Icon(
                            Icons.work_outline_rounded,
                            size: 12,
                            color: ChatDesign.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              user.designation?.isNotEmpty == true
                                  ? user.designation!
                                  : 'Employee',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ChatDesign.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Online status
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? ChatDesign.online
                                  : ChatDesign.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? 'Online' : 'Last seen $lastSeen',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOnline
                                  ? ChatDesign.online
                                  : ChatDesign.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ===== CHAT BUTTON =====
                const SizedBox(width: ChatDesign.sm),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: ChatDesign.primarySoft,
                    borderRadius:
                    BorderRadius.circular(ChatDesign.radiusSm),
                    border: Border.all(
                      color: ChatDesign.primaryLight,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: ChatDesign.primary,
                    size: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(User user) {
    return Center(
      child: Text(
        user.fullName.isNotEmpty
            ? user.fullName.substring(0, 1).toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: ChatDesign.primary,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final (color, bgColor) = _getRoleColors(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  (Color, Color) _getRoleColors(String role) {
    switch (role.toLowerCase()) {
      case 'hr':
        return (ChatDesign.purple, ChatDesign.purpleSoft);
      case 'manager':
        return (ChatDesign.warning, ChatDesign.warningSoft);
      case 'superadmin':
      case 'admin':
        return (ChatDesign.danger, ChatDesign.dangerSoft);
      case 'employee':
        return (ChatDesign.info, ChatDesign.infoSoft);
      default:
        return (ChatDesign.textSecondary, ChatDesign.surfaceMuted);
    }
  }

  Color _getDepartmentColor(String deptName) {
    switch (deptName.toLowerCase()) {
      case 'information technology':
        return ChatDesign.info;
      case 'human resources':
        return ChatDesign.purple;
      case 'sales':
        return ChatDesign.online;
      case 'research & development':
        return ChatDesign.warning;
      case 'administration':
        return ChatDesign.danger;
      default:
        return ChatDesign.textMuted;
    }
  }

  String _formatLastSeen(String? lastSeen) {
    if (lastSeen == null || lastSeen == 'Never') return 'Never';
    if (lastSeen == 'Now') return 'just now';

    try {
      final dateTime = DateTime.parse(lastSeen);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) return 'just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return DateFormat('MMM d').format(dateTime);
    } catch (e) {
      return lastSeen;
    }
  }

  Future<void> _startChatWithUser(User user) async {
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

    try {
      final conversation = await _chatService.getOrCreateConversation(user.id);
      if (!mounted) return;
      Navigator.pop(context);

      if (conversation != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUser: user,
              conversationId: conversation.id,
              chatService: _chatService,
            ),
          ),
        );
      } else {
        _showErrorSnack('Failed to create conversation');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorSnack('Failed to start chat');
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: ChatDesign.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(ChatDesign.md),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _chatService.dispose();
    super.dispose();
  }
}