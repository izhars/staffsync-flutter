import 'package:flutter/material.dart';
import '../services/task_api.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final TaskApi taskApi;
  final Function(Map<String, dynamic>) onTaskUpdated;
  final String currentUserId;

  const TaskDetailsScreen({
    Key? key,
    required this.taskId,
    required this.taskApi,
    required this.onTaskUpdated,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late Map<String, dynamic> _task;
  bool _isLoading = true;
  bool _isRefreshing = false;
  final TextEditingController _commentController = TextEditingController();
  bool _isAddingComment = false;
  bool _isCompletingTask = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _task = {};
    _loadTask();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final taskData = await widget.taskApi.getTask(widget.taskId);
      final processedTask = _processTaskData(taskData);

      if (mounted) {
        setState(() {
          _task = processedTask;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load task: $e', isError: true);
      }
    }
  }

  Future<void> _refreshTask() async {
    if (!mounted) return;

    setState(() => _isRefreshing = true);
    try {
      final taskData = await widget.taskApi.getTask(widget.taskId);
      final processedTask = _processTaskData(taskData);

      if (mounted) {
        setState(() {
          _task = processedTask;
          _isRefreshing = false;
        });
        widget.onTaskUpdated(processedTask);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        _showSnackBar('Failed to refresh task: $e', isError: true);
      }
    }
  }

  Map<String, dynamic> _processTaskData(Map<String, dynamic> taskData) {
    final processedTask = Map<String, dynamic>.from(taskData);

    if (processedTask['assignee'] is String) {
      processedTask['assignee'] = {
        '_id': processedTask['assignee'],
        'firstName': 'User',
        'lastName': '',
        'fullName': 'User'
      };
    }

    if (processedTask['assigner'] is String) {
      processedTask['assigner'] = {
        '_id': processedTask['assigner'],
        'firstName': 'User',
        'lastName': '',
        'fullName': 'User'
      };
    }

    if (!processedTask.containsKey('comments')) {
      processedTask['comments'] = [];
    } else if (processedTask['comments'] is! List) {
      processedTask['comments'] = [];
    }

    final comments = List<Map<String, dynamic>>.from(processedTask['comments']);
    final processedComments = <Map<String, dynamic>>[];

    for (var comment in comments) {
      final processedComment = Map<String, dynamic>.from(comment);

      if (comment['author'] is Map) {
        final author = Map<String, dynamic>.from(comment['author']);
        if (author['_id'] == widget.currentUserId) {
          author['firstName'] = 'You';
          author['fullName'] = 'You';
        }
        processedComment['author'] = author;
      } else if (comment['author'] is String) {
        final authorId = comment['author'] as String;
        final author = <String, dynamic>{
          '_id': authorId,
          'firstName': 'User',
          'lastName': '',
          'fullName': 'User',
        };
        if (authorId == widget.currentUserId) {
          author['firstName'] = 'You';
          author['fullName'] = 'You';
        }
        processedComment['author'] = author;
      }

      processedComments.add(processedComment);
    }

    // Sort comments by createdAt (oldest first for chat-like experience)
    processedComments.sort((a, b) {
      final dateA = DateTime.parse(a['createdAt'] ?? DateTime.now().toString());
      final dateB = DateTime.parse(b['createdAt'] ?? DateTime.now().toString());
      return dateA.compareTo(dateB); // Ascending order (oldest first)
    });

    processedTask['comments'] = processedComments;
    return processedTask;
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() => _isAddingComment = true);
    try {
      await widget.taskApi.addComment(_task['_id'], text);
      await _refreshTask();
      _commentController.clear();

      if (mounted) {
        _showSnackBar('Comment added successfully!', isError: false);
      }

      // Scroll to bottom to show new comment
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error adding comment: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingComment = false);
      }
    }
  }

  Future<void> _markComplete() async {
    setState(() => _isCompletingTask = true);
    try {
      final updatedTask = await widget.taskApi.completeTask(_task['_id']);
      final processedTask = _processTaskData(updatedTask);

      if (mounted) {
        setState(() {
          _task = processedTask;
        });
        widget.onTaskUpdated(processedTask);
        _showSnackBar('Task marked as complete!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isCompletingTask = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not set';

    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final taskDate = DateTime(date.year, date.month, date.day);

      if (taskDate == today) {
        return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (taskDate == yesterday) {
        return 'Yesterday, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'important':
        return Colors.orange;
      case 'meeting':
        return Colors.purple;
      case 'development':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? Colors.blueGrey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.blueGrey[700]),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.blueGrey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> comment) {
    String authorName = 'Unknown';
    bool isCurrentUser = false;
    String authorId = '';

    if (comment['author'] is Map) {
      final author = comment['author'] as Map<String, dynamic>;
      authorId = author['_id'] ?? '';
      authorName = author['fullName'] ??
          '${author['firstName'] ?? ''} ${author['lastName'] ?? ''}'.trim();
      isCurrentUser = author['firstName'] == 'You' ||
          author['fullName'] == 'You' ||
          authorId == widget.currentUserId;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
        isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 16,
              child: Text(
                authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.blue[600] : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  Text(
                    comment['text'] ?? '',
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(comment['createdAt']),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue[700],
              radius: 16,
              child: Text(
                authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Task Details'),
          centerTitle: true,
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_task.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Task Details'),
          centerTitle: true,
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                'Task not found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadTask,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isOverdue = _task['dueDate'] != null &&
        DateTime.parse(_task['dueDate']).isBefore(DateTime.now()) &&
        _task['status'] != 'completed';

    final categoryColor = _getCategoryColor(_task['category']);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Task Details'),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_task['status'] != 'completed')
            IconButton(
              icon: _isCompletingTask
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.check_circle_outline),
              onPressed: _isCompletingTask ? null : _markComplete,
              tooltip: 'Mark Complete',
            ),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshTask,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Task Header Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _task['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _task['category'] ?? 'general',
                            style: TextStyle(
                              fontSize: 12,
                              color: categoryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _task['status'] == 'completed'
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (_task['status'] ?? 'open').toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_task['description'] != null &&
                    _task['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _task['description'].toString(),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: 'Due Date',
                      value: _task['dueDate'] != null
                          ? _formatDate(_task['dueDate'])
                          : 'Not set',
                      color: isOverdue ? Colors.red : null,
                    ),
                    _buildInfoChip(
                      icon: Icons.person_add,
                      label: 'Assigned By',
                      value: _task['assigner'] != null
                          ? '${_task['assigner']['firstName'] ?? ''} ${_task['assigner']['lastName'] ?? ''}'
                          .trim()
                          : 'Unknown',
                    ),
                    _buildInfoChip(
                      icon: Icons.person,
                      label: 'Assigned To',
                      value: _task['assignee'] != null
                          ? '${_task['assignee']['firstName'] ?? ''} ${_task['assignee']['lastName'] ?? ''}'
                          .trim()
                          : 'Unknown',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chat Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.forum, color: Colors.blue[700], size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Discussion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(_task['comments'] as List).length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Expanded(
                    child: (_task['comments'] as List).isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.grey[300],
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start the conversation',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: (_task['comments'] as List).length,
                      itemBuilder: (context, index) {
                        return _buildChatBubble(
                            _task['comments'][index]);
                      },
                    ),
                  ),
                  // Input Area
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextField(
                                controller: _commentController,
                                focusNode: _commentFocusNode,
                                maxLines: 4,
                                minLines: 1,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (mounted) setState(() {});
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: _commentController.text.trim().isEmpty
                                  ? Colors.grey[300]
                                  : Colors.blue[700],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _isAddingComment ||
                                  _commentController.text.trim().isEmpty
                                  ? null
                                  : _addComment,
                              icon: _isAddingComment
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(Icons.send, size: 20),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}