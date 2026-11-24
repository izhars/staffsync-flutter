import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';

class AddMembersBottomSheetContent extends StatefulWidget {
  final String groupId;
  final ChatService chatService;
  final ScrollController scrollController;
  final Set<String> selectedUserIds;
  final VoidCallback onSelectionChanged;
  final Function(Set<String>) onAddMembers;

  const AddMembersBottomSheetContent({
    Key? key,
    required this.groupId,
    required this.chatService,
    required this.scrollController,
    required this.selectedUserIds,
    required this.onSelectionChanged,
    required this.onAddMembers,
  }) : super(key: key);

  @override
  State<AddMembersBottomSheetContent> createState() => _AddMembersBottomSheetContentState();
}

class _AddMembersBottomSheetContentState extends State<AddMembersBottomSheetContent> {
  late Future<Map<String, dynamic>> _usersFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchGroupUsers();
  }

  Future<Map<String, dynamic>> _fetchGroupUsers() async {
    try {
      // Call your API: http://localhost:5000/api/chat/conversations/group/{groupId}/users
      final response = await widget.chatService.getGroupUsers(widget.groupId);
      return response; // Expect {'success': true, 'data': {...}}
    } catch (e) {
      print('Error fetching group users: $e');
      return {'success': false, 'data': {'nonAddedUsers': []}};
    }
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = _fetchGroupUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text(
                  'Add Members',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.selectedUserIds.length} selected',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Search Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search non-members...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Counts Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Added: X', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                Text('Available: Y', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Users List
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.data!['success']) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Failed to load users'),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _refreshUsers, child: Text('Retry')),
                      ],
                    ),
                  );
                }

                final data = snapshot.data!['data'] as Map<String, dynamic>;
                List<dynamic> nonAddedUsers = data['nonAddedUsers'] ?? [];
                final filteredUsers = _searchController.text.isEmpty
                    ? nonAddedUsers
                    : nonAddedUsers.where((user) =>
                user['fullName'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
                    user['email'].toString().toLowerCase().contains(_searchController.text.toLowerCase())).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text('No available users'));
                }

                return ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final userId = user['id'].toString();
                    final isSelected = widget.selectedUserIds.contains(userId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getUserColor(user['fullName']),
                          backgroundImage: user['profilePicture'].isNotEmpty
                              ? NetworkImage(user['profilePicture'])
                              : null,
                          child: user['profilePicture'].isEmpty
                              ? Text(user['fullName'][0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text(user['fullName']),
                        subtitle: Text(user['email']),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                widget.selectedUserIds.add(userId);
                              } else {
                                widget.selectedUserIds.remove(userId);
                              }
                              widget.onSelectionChanged();
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              widget.selectedUserIds.remove(userId);
                            } else {
                              widget.selectedUserIds.add(userId);
                            }
                            widget.onSelectionChanged();
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Action Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.selectedUserIds.isEmpty
                    ? null
                    : () => widget.onAddMembers({...widget.selectedUserIds}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(widget.selectedUserIds.isEmpty ? 'Select Users' : 'Add ${widget.selectedUserIds.length} Member${widget.selectedUserIds.length > 1 ? 's' : ''}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getUserColor(String name) {
    final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.teal, Colors.red];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
