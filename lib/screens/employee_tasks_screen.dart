import 'package:flutter/material.dart';
import 'package:staffsync/screens/task_details_screen.dart';
import '../services/task_api.dart';

class EmployeeTasksScreen extends StatefulWidget {
  const EmployeeTasksScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeTasksScreen> createState() => _EmployeeTasksScreenState();
}

class _EmployeeTasksScreenState extends State<EmployeeTasksScreen> {
  late TaskApi taskApi;
  List<dynamic> tasks = [];
  bool isLoading = true;
  String? error;
  int currentPage = 1;
  int totalPages = 1;
  bool hasMore = true;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    taskApi = TaskApi();
    fetchTasks();
  }

  Future<void> fetchTasks({bool loadMore = false}) async {
    if (loadMore) {
      if (!hasMore || isLoadingMore) return;
      setState(() => isLoadingMore = true);
      currentPage++;
    } else {
      setState(() {
        isLoading = true;
        error = null;
        tasks = [];
        currentPage = 1;
        hasMore = true;
      });
    }

    try {
      final response = await taskApi.getMyTasks(page: currentPage);
      final List<dynamic> fetchedTasks = response['data'] ?? [];
      final pagination = response['pagination'] ?? {};

      if (loadMore) {
        setState(() {
          tasks.addAll(fetchedTasks);
        });
      } else {
        setState(() {
          tasks = fetchedTasks;
        });
      }

      // Calculate total pages
      final total = pagination['total'] ?? 0;
      final limit = pagination['limit'] ?? 20;
      totalPages = (total / limit).ceil();
      hasMore = currentPage < totalPages;

    } catch (e) {
      setState(() {
        error = e.toString();
      });
      if (loadMore) {
        currentPage--; // Revert page if error
      }
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> markComplete(String id) async {
    try {
      final updatedTask = await taskApi.completeTask(id);
      setState(() {
        tasks = tasks.map((t) => t['_id'] == id ? updatedTask : t).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task marked as complete!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // In EmployeeTasksScreen, replace the showTaskDetails method:

  Future<void> showTaskDetails(Map<String, dynamic> task) async {
    // You need to pass the currentUserId when navigating
    String currentUserId = await taskApi.getCurrentUserId();

    // Navigate to TaskDetailsScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(
          taskId: task['_id'], // ✅ Pass the task ID here
          taskApi: TaskApi(),
          onTaskUpdated: (updatedTask) {
            // Handle the updated task
            print('Task updated: $updatedTask');
          },
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
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

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => fetchTasks(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
          if (!isLoading && error == null && tasks.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      count: tasks.where((t) => t['status'] == 'completed').length,
                      total: tasks.length,
                      label: 'Completed',
                      color: Colors.green,
                    ),
                    _buildStatItem(
                      count: tasks.where((t) =>
                      t['dueDate'] != null &&
                          DateTime.parse(t['dueDate']).isBefore(DateTime.now()) &&
                          t['status'] != 'completed'
                      ).length,
                      total: tasks.length,
                      label: 'Overdue',
                      color: Colors.red,
                    ),
                    _buildStatItem(
                      count: tasks.where((t) => t['status'] == 'open').length,
                      total: tasks.length,
                      label: 'Pending',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),

          // Tasks List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => fetchTasks(),
              color: Colors.blue[700],
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                        color: Colors.red[400],
                        size: 64,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Failed to load tasks',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: fetchTasks,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : tasks.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt,
                        color: Colors.grey[400],
                        size: 80,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No tasks assigned',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You\'re all caught up!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: fetchTasks,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollEndNotification &&
                      scrollNotification.metrics.pixels ==
                          scrollNotification.metrics.maxScrollExtent &&
                      hasMore &&
                      !isLoadingMore) {
                    fetchTasks(loadMore: true);
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: tasks.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == tasks.length) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.blue[700],
                          ),
                        ),
                      );
                    }

                    final task = tasks[index];
                    final isOverdue = task['dueDate'] != null &&
                        DateTime.parse(task['dueDate']).isBefore(DateTime.now()) &&
                        task['status'] != 'completed';
                    final hasComments = task['comments']?.isNotEmpty ?? false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () => showTaskDetails(task),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task['title'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueGrey,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (task['status'] == 'completed')
                                      Icon(Icons.check_circle,
                                        color: Colors.green[400],
                                        size: 24,
                                      )
                                    else if (isOverdue)
                                      Icon(Icons.warning_amber,
                                        color: Colors.red[400],
                                        size: 24,
                                      )
                                    else
                                      Icon(Icons.pending,
                                        color: Colors.orange[400],
                                        size: 24,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                if (task['description'] != null &&
                                    task['description'].isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      task['description'],
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildTaskTag(
                                      icon: Icons.category_outlined,
                                      text: task['category'],
                                      color: Colors.blue,
                                    ),
                                    if (task['dueDate'] != null)
                                      _buildTaskTag(
                                        icon: Icons.calendar_today_outlined,
                                        text: _formatDate(task['dueDate']),
                                        color: isOverdue ? Colors.red : Colors.green,
                                      ),
                                    if (hasComments)
                                      _buildTaskTag(
                                        icon: Icons.chat_bubble_outline,
                                        text: '${task['comments'].length} comments',
                                        color: Colors.purple,
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.blue.withOpacity(0.1),
                                      radius: 16,
                                      child: Text(
                                        task['assigner']['firstName'][0],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Assigned by ${task['assigner']['firstName']} ${task['assigner']['lastName']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: task['status'] != 'completed'
                                          ? () => markComplete(task['_id'])
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: task['status'] == 'completed'
                                            ? Colors.grey[300]
                                            : isOverdue
                                            ? Colors.red
                                            : Colors.green,
                                        foregroundColor: task['status'] == 'completed'
                                            ? Colors.grey[600]
                                            : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: Text(
                                        task['status'] == 'completed'
                                            ? 'Completed'
                                            : isOverdue
                                            ? 'Overdue'
                                            : 'Complete',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required int count,
    required int total,
    required String label,
    required Color color,
  }) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Column(
      children: [
        Text(
          '$count/$total',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 40 * (percentage / 100),
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskTag({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}