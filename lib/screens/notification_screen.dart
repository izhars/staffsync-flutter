import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/AppNotification.dart';
import '../services/NotificationService.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<AppNotification>> _future;
  final LocalNotificationService _notificationService = LocalNotificationService();

  bool _refreshing = false;
  int _unreadCount = 0;
  String _filter = 'all'; // all, unread, read

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();
  }

  void _loadNotifications() {
    setState(() {
      _future = _notificationService.fetchMyNotifications();
      _refreshing = false;
    });
  }

  Future<void> _loadUnreadCount() async {
    final count = await _notificationService.getUnreadCount();
    if (mounted) {
      setState(() => _unreadCount = count);
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() => _refreshing = true);

    await Future.wait([
      _notificationService.fetchMyNotifications(),
      _notificationService.getUnreadCount(),
    ]);

    if (!mounted) return;

    _loadNotifications();
    await _loadUnreadCount();
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.read) return;
    try {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        notification.read = true; // if fields are final, recreate list instead
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      });
    } catch (e) {
      _showSnackBar('Failed to mark as read', isError: true);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _refreshNotifications();
      _showSnackBar('All notifications marked as read');
    } catch (e) {
      _showSnackBar('Failed to mark all as read', isError: true);
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _notificationService.deleteNotification(id);
      await _refreshNotifications();
      _showSnackBar('Notification deleted');
    } catch (e) {
      _showSnackBar('Failed to delete notification', isError: true);
    }
  }

  Future<void> _deleteAllNotifications() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear notification center'),
        content: const Text('This will permanently remove all notifications.'),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.08),
              foregroundColor: Colors.red.shade600,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _notificationService.deleteAllNotifications();
        await _refreshNotifications();
        _showSnackBar('All notifications deleted');
      } catch (e) {
        _showSnackBar('Failed to delete all notifications', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor:
        (isError ? Colors.red.shade500 : Colors.green.shade500).withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'info':
        return Icons.info_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'error':
        return Icons.error_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type, BuildContext context) {
    switch (type) {
      case 'info':
        return Colors.blue.shade500;
      case 'warning':
        return Colors.orange.shade500;
      case 'success':
        return Colors.green.shade500;
      case 'error':
        return Colors.red.shade500;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  List<AppNotification> _applyFilter(List<AppNotification> list) {
    switch (_filter) {
      case 'unread':
        return list.where((n) => !n.read).toList();
      case 'read':
        return list.where((n) => n.read).toList();
      default:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          children: [
            const Text(
              'Notification Center',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              AnimatedScale(
                scale: _unreadCount > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _markAllAsRead,
                style: TextButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                ),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text(
                  'Mark all',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'delete_all') {
                _deleteAllNotifications();
              } else if (value == 'refresh') {
                _refreshNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      'Delete all',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // subtle top gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.05),
                    surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          FutureBuilder<List<AppNotification>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !_refreshing) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _ErrorState(
                  onRetry: _refreshNotifications,
                  error: snapshot.error.toString(),
                );
              }

              final notifications = _applyFilter(snapshot.data ?? []);

              if (notifications.isEmpty) {
                return _EmptyState(onRefresh: _refreshNotifications);
              }

              return RefreshIndicator(
                onRefresh: _refreshNotifications,
                edgeOffset: kToolbarHeight + 24,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(height: kToolbarHeight + 16),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _FilterChips(
                          filter: _filter,
                          onChanged: (value) {
                            setState(() => _filter = value);
                          },
                        ),
                      ),
                    ),
                    SliverList.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        final iconColor = _getIconColor(n.type, context);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          child: Dismissible(
                            key: Key(n.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade400,
                                    Colors.red.shade600,
                                  ],
                                ),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18)),
                                  title: const Text('Delete notification?'),
                                  content: const Text(
                                      'You will not be able to undo this action.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Keep'),
                                    ),
                                    FilledButton.tonal(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                        Colors.red.withOpacity(0.08),
                                        foregroundColor: Colors.red.shade600,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) =>
                                _deleteNotification(n.id),
                            child: _NotificationTile(
                              notification: n,
                              iconColor: iconColor,
                              formatDate: _formatDate,
                              onTap: () async {
                                await _markAsRead(n);

                                if (n.meta.containsKey('leaveId')) {
                                  final leaveId = n.meta['leaveId'];
                                  debugPrint('Navigate to leave: $leaveId');
                                }
                                if (n.meta.containsKey('applicantId')) {
                                  final applicantId = n.meta['applicantId'];
                                  debugPrint('Navigate to applicant: $applicantId');
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final Color iconColor;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.iconColor,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.read;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface.withOpacity(isUnread ? 0.9 : 0.85),
                theme.colorScheme.surfaceVariant.withOpacity(
                  isUnread ? 0.25 : 0.12,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: (isUnread
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant)
                  .withOpacity(isUnread ? 0.32 : 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isUnread ? 0.12 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              splashColor: theme.colorScheme.primary.withOpacity(0.05),
              highlightColor: Colors.transparent,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            iconColor.withOpacity(0.18),
                            iconColor.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _iconForType(notification.type),
                          color: iconColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight:
                                    isUnread ? FontWeight.w700 : FontWeight.w500,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.75),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatDate(notification.createdAt),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const Spacer(),
                              if (notification.meta['status'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    (notification.meta['status'] as String)
                                        .toUpperCase(),
                                    style:
                                    theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: theme.colorScheme.primary,
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
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'info':
        return Icons.info_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'error':
        return Icons.error_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}

class _FilterChips extends StatelessWidget {
  final String filter;
  final ValueChanged<String> onChanged;

  const _FilterChips({
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget chip(String value, String label) {
      final selected = filter == value;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        pressElevation: 0,
        selectedColor: theme.colorScheme.primary.withOpacity(0.12),
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        onSelected: (_) => onChanged(value),
      );
    }

    return Row(
      children: [
        chip('all', 'All'),
        const SizedBox(width: 8),
        chip('unread', 'Unread'),
        const SizedBox(width: 8),
        chip('read', 'Read'),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      edgeOffset: kToolbarHeight + 24,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.06),
                        theme.colorScheme.primary.withOpacity(0.02),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_off_rounded,
                    size: 40,
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'You’re all caught up',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'New notifications will appear here as they arrive.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  final String error;

  const _ErrorState({
    required this.onRetry,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.06),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.shade500,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
