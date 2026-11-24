import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_notification.dart';
import '../services/api_exception.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart' hide NotificationType;

// ===================== SHARED DESIGN TOKENS =====================
class NotifDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const Color primary = Color(0xFFD97706);
  static const Color primaryDark = Color(0xFFB45309);
  static const Color primarySoft = Color(0xFFFFFBEB);
  static const Color primaryLight = Color(0xFFFDE68A);

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 14,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 22,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
  ];
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final LocalNotificationService _service = LocalNotificationService();

  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _refreshing = false;
  int _unreadCount = 0;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.fetchMyNotifications(),
        _service.getUnreadCount(),
      ]);
      if (!mounted) return;
      final notifs = results[0] as List<AppNotification>;
      final unread = results[1] as int;
      final localUnread = notifs.where((n) => !n.read).length;
      setState(() {
        _notifications = notifs;
        _unreadCount = unread > 0 ? unread : localUnread;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is ApiException ? e.message : e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _service.getUnreadCount();
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Future<void> _refreshNotifications() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    try {
      final results = await Future.wait([
        _service.fetchMyNotifications(),
        _service.getUnreadCount(),
      ]);
      if (!mounted) return;
      final notifs = results[0] as List<AppNotification>;
      final unread = results[1] as int;
      final localUnread = notifs.where((n) => !n.read).length;
      setState(() {
        _notifications = notifs;
        _unreadCount = unread > 0 ? unread : localUnread;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_notifications.isEmpty) {
        setState(() => _errorMessage = e is ApiException ? e.message : e.toString());
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.read) return;
    setState(() {
      n.read = true;
      _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    });
    try {
      await _service.markAsRead(n.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        n.read = false;
        _unreadCount += 1;
      });
      final msg = e is ApiException ? e.message : 'Failed to mark as read';
      _showSnackBar(msg, isError: true);
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadItems = _notifications.where((n) => !n.read).toList();
    final prevCount = _unreadCount;

    if (unreadItems.isEmpty && prevCount == 0) return;

    // 1. Optimistic update: mark all read and reset unread badge immediately
    setState(() {
      for (final n in _notifications) {
        n.read = true;
      }
      _unreadCount = 0;
    });

    try {
      // 2. Call backend API
      final res = await _service.markAllAsRead();
      final msg = (res['message'] as String?) ?? 'All notifications marked as read';
      _showSnackBar(msg);
      // Background count sync
      _loadUnreadCount();
    } catch (e) {
      if (!mounted) return;
      // Revert in case of real failure
      setState(() {
        for (final n in unreadItems) {
          n.read = false;
        }
        _unreadCount = prevCount;
      });
      final msg = e is ApiException ? e.message : 'Failed to mark all as read';
      _showSnackBar(msg, isError: true);
    }
  }

  Future<void> _deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final removed = _notifications[index];

    setState(() {
      _notifications.removeAt(index);
      if (!removed.read) {
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      }
    });

    try {
      await _service.deleteNotification(id);
      _showSnackBar('Notification deleted');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifications.insert(index, removed);
        if (!removed.read) {
          _unreadCount += 1;
        }
      });
      final msg = e is ApiException ? e.message : 'Failed to delete notification';
      _showSnackBar(msg, isError: true);
    }
  }

  Future<void> _deleteAllNotifications() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NotifDesign.surface,
        surfaceTintColor: NotifDesign.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NotifDesign.radiusXl)),
        title: const Text(
          'Clear notification center',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: NotifDesign.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        content: const Text(
          'This will permanently remove all notifications.',
          style: TextStyle(
            color: NotifDesign.textSecondary,
            fontSize: 13.5,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: NotifDesign.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: NotifDesign.dangerSoft,
              foregroundColor: NotifDesign.danger,
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(NotifDesign.radiusSm)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final backup = List<AppNotification>.from(_notifications);
      final prevCount = _unreadCount;

      setState(() {
        _notifications.clear();
        _unreadCount = 0;
      });

      try {
        await _service.deleteAllNotifications();
        _showSnackBar('All notifications deleted');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _notifications = backup;
          _unreadCount = prevCount;
        });
        final msg = e is ApiException ? e.message : 'Failed to delete all notifications';
        _showSnackBar(msg, isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? NotifDesign.danger : NotifDesign.success,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NotifDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(NotifDesign.md),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  List<AppNotification> _applyFilter(List<AppNotification> list) {
    switch (_filter) {
      case 'unread':
        return list.where((n) => !n.read).toList();
      case 'read':
        return list.where((n) => n.read).toList();
      case 'attendance':
        return list.where((n) => n.type == NotificationType.attendance).toList();
      case 'leave':
        return list.where((n) => n.type == NotificationType.leave || n.type == NotificationType.leaveUpdate).toList();
      case 'payroll':
        return list.where((n) => n.type == NotificationType.payroll).toList();
      case 'tickets':
        return list.where((n) => n.type == NotificationType.ticket).toList();
      case 'tasks':
        return list.where((n) => n.type == NotificationType.task).toList();
      case 'announcements':
        return list.where((n) => n.type == NotificationType.announcement).toList();
      case 'expenses':
        return list.where((n) => n.type == NotificationType.expense).toList();
      case 'messages':
        return list.where((n) => n.type == NotificationType.message || n.type == NotificationType.employeeInteraction).toList();
      default:
        return list;
    }
  }

  Future<void> _onNotificationTap(AppNotification n) async {
    await _markAsRead(n);
    final payload = <String, dynamic>{
      ...n.meta,
      'type': n.rawType,
      'title': n.title,
      'body': n.message,
      if (n.link != null) 'link': n.link,
    };
    NotificationNavigator.navigateFromNotification(payload);
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _applyFilter(_notifications);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: NotifDesign.bg,
        body: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.only(
                top: NotifDesign.md,
                bottom: NotifDesign.sm,
              ),
              child: _FilterChips(
                filter: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            Expanded(
              child: _buildBody(filteredNotifications),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<AppNotification> filteredNotifications) {
    if (_isLoading && !_refreshing) {
      return const Center(
        child: CircularProgressIndicator(
          color: NotifDesign.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage != null && _notifications.isEmpty) {
      return _ErrorState(
        onRetry: _fetchInitialData,
        error: _errorMessage!,
      );
    }

    if (filteredNotifications.isEmpty) {
      return _EmptyState(
        onRefresh: _refreshNotifications,
        filter: _filter,
      );
    }

    return RefreshIndicator(
      color: NotifDesign.primary,
      onRefresh: _refreshNotifications,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          NotifDesign.md,
          NotifDesign.xs,
          NotifDesign.md,
          NotifDesign.lg,
        ),
        itemCount: filteredNotifications.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: NotifDesign.sm + 2),
        itemBuilder: (context, index) {
          final n = filteredNotifications[index];
          return Dismissible(
            key: ValueKey(n.id),
            direction: DismissDirection.endToStart,
            background: _dismissBackground(),
            confirmDismiss: (_) => _confirmDelete(),
            onDismissed: (_) => _deleteNotification(n.id),
            child: _NotificationTile(
              notification: n,
              formatDate: _formatDate,
              onTap: () => _onNotificationTap(n),
            ),
          );
        },
      ),
    );
  }

  // ===================== HEADER =====================
  Widget _buildHeader() {
    final hasUnread = _unreadCount > 0 || _notifications.any((n) => !n.read);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [NotifDesign.primary, NotifDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(NotifDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: NotifDesign.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NotifDesign.md,
            NotifDesign.sm,
            NotifDesign.md,
            NotifDesign.md,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(NotifDesign.radiusSm),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(NotifDesign.radiusSm),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: NotifDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (_unreadCount > 0) ...[
                          const SizedBox(width: NotifDesign.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$_unreadCount',
                              style: const TextStyle(
                                color: NotifDesign.primaryDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Stay updated with your activity',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUnread)
                Material(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius:
                  BorderRadius.circular(NotifDesign.radiusSm),
                  child: InkWell(
                    borderRadius:
                    BorderRadius.circular(NotifDesign.radiusSm),
                    onTap: _markAllAsRead,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.done_all_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: NotifDesign.sm),
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(NotifDesign.radiusSm),
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  color: NotifDesign.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(NotifDesign.radiusMd)),
                  onSelected: (value) {
                    if (value == 'mark_all_read') {
                      _markAllAsRead();
                    } else if (value == 'delete_all') {
                      _deleteAllNotifications();
                    } else if (value == 'refresh') {
                      _refreshNotifications();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          Icon(Icons.done_all_rounded,
                              size: 18, color: NotifDesign.primary),
                          SizedBox(width: 12),
                          Text(
                            'Mark all as read',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: NotifDesign.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 18, color: NotifDesign.textSecondary),
                          SizedBox(width: 12),
                          Text(
                            'Refresh',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: NotifDesign.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: const [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: NotifDesign.danger),
                          SizedBox(width: 12),
                          Text(
                            'Delete all',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: NotifDesign.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dismissBackground() => Container(
    margin: const EdgeInsets.symmetric(vertical: 2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(NotifDesign.radiusLg),
      gradient: LinearGradient(
        colors: [Colors.red.shade400, NotifDesign.danger],
      ),
    ),
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 24),
    child: const Icon(Icons.delete_rounded,
        color: Colors.white, size: 22),
  );

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NotifDesign.surface,
        surfaceTintColor: NotifDesign.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NotifDesign.radiusXl)),
        title: const Text(
          'Delete notification?',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: NotifDesign.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        content: const Text(
          'You will not be able to undo this action.',
          style: TextStyle(
            color: NotifDesign.textSecondary,
            fontSize: 13.5,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Keep',
              style: TextStyle(
                color: NotifDesign.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: NotifDesign.dangerSoft,
              foregroundColor: NotifDesign.danger,
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(NotifDesign.radiusSm)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ─────────────────────────────────────────────────────────────
// Notification tile — polished to match Feedback card language
// ─────────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.read;
    final accent = notification.type.color(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NotifDesign.radiusLg),
        splashColor: accent.withOpacity(0.05),
        highlightColor: accent.withOpacity(0.03),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(NotifDesign.md),
          decoration: BoxDecoration(
            color: isUnread ? NotifDesign.surface : NotifDesign.surfaceMuted,
            borderRadius: BorderRadius.circular(NotifDesign.radiusLg),
            border: Border.all(
              color: isUnread
                  ? accent.withOpacity(0.35)
                  : NotifDesign.border,
              width: isUnread ? 1.5 : 1,
            ),
            boxShadow: isUnread
                ? [
              BoxShadow(
                color: accent.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ]
                : NotifDesign.softShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconTile(accent, isUnread),
              const SizedBox(width: NotifDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _titleRow(isUnread),
                    const SizedBox(height: 5),
                    Text(
                      notification.message.isEmpty
                          ? '—'
                          : notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: NotifDesign.textSecondary,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _footerRow(accent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconTile(Color accent, bool isUnread) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isUnread
            ? accent.withOpacity(0.12)
            : NotifDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(NotifDesign.radiusSm),
        border: Border.all(
          color: isUnread
              ? accent.withOpacity(0.30)
              : NotifDesign.border,
          width: 1,
        ),
      ),
      child: Icon(
        notification.type.icon,
        color: isUnread ? accent : NotifDesign.textMuted,
        size: 20,
      ),
    );
  }

  Widget _titleRow(bool isUnread) {
    return Row(
      children: [
        Expanded(
          child: Text(
            notification.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
              color: isUnread
                  ? NotifDesign.textPrimary
                  : NotifDesign.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (isUnread)
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: NotifDesign.primary,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _footerRow(Color accent) {
    final statusRaw = notification.meta['status'];
    final status = statusRaw?.toString();

    return Row(
      children: [
        const Icon(
          Icons.access_time_rounded,
          size: 12,
          color: NotifDesign.textMuted,
        ),
        const SizedBox(width: 5),
        Text(
          formatDate(notification.createdAt),
          style: const TextStyle(
            fontSize: 11,
            color: NotifDesign.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        const Spacer(),
        if (status != null && status.isNotEmpty)
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: accent.withOpacity(0.20),
                width: 1,
              ),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: accent,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter chips — matching Feedback section style
// ─────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final String filter;
  final ValueChanged<String> onChanged;

  const _FilterChips({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String value, String label, IconData icon) {
      final selected = filter == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? NotifDesign.primarySoft
                : NotifDesign.surface,
            borderRadius:
            BorderRadius.circular(NotifDesign.radiusMd),
            border: Border.all(
              color: selected
                  ? NotifDesign.primaryLight
                  : NotifDesign.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color:
                NotifDesign.primary.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ]
                : NotifDesign.softShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? NotifDesign.primary
                    : NotifDesign.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? NotifDesign.primaryDark
                      : NotifDesign.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: NotifDesign.md),
      child: Row(
        children: [
          chip('all', 'All', Icons.notifications_rounded),
          const SizedBox(width: NotifDesign.sm),
          chip('unread', 'Unread', Icons.mark_email_unread_rounded),
          const SizedBox(width: NotifDesign.sm),
          chip('attendance', 'Attendance', Icons.alarm_on_rounded),
          const SizedBox(width: NotifDesign.sm),
          chip('leave', 'Leaves', Icons.beach_access_rounded),
          const SizedBox(width: NotifDesign.sm),
          chip('payroll', 'Payroll', Icons.account_balance_wallet_rounded),
          const SizedBox(width: NotifDesign.sm),
          chip('tickets', 'Tickets', Icons.confirmation_number_rounded),
          const SizedBox(width: NotifDesign.sm),
          chip('tasks', 'Tasks', Icons.task_alt_rounded),
          const SizedBox(width: NotifDesign.sm),
          chip('announcements', 'Announcements', Icons.campaign_rounded),
          const SizedBox(width: NotifDesign.sm),
          chip('expenses', 'Expenses', Icons.receipt_long_rounded),
          const SizedBox(width: NotifDesign.sm),
          chip('messages', 'Messages', Icons.chat_rounded),
          const SizedBox(width: NotifDesign.sm),
          chip('read', 'Read', Icons.mark_email_read_rounded),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final String filter;
  const _EmptyState({required this.onRefresh, this.filter = 'all'});

  String get _title {
    switch (filter) {
      case 'unread':
        return 'No unread notifications';
      case 'read':
        return 'No read notifications';
      case 'attendance':
        return 'No attendance notifications';
      case 'leave':
        return 'No leave notifications';
      case 'payroll':
        return 'No payroll notifications';
      case 'tickets':
        return 'No ticket notifications';
      case 'tasks':
        return 'No task notifications';
      case 'announcements':
        return 'No announcement notifications';
      case 'expenses':
        return 'No expense notifications';
      case 'messages':
        return 'No message notifications';
      default:
        return "You're all caught up";
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: NotifDesign.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.14),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: NotifDesign.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NotifDesign.primaryLight,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_off_rounded,
                    size: 36,
                    color: NotifDesign.primary,
                  ),
                ),
                const SizedBox(height: NotifDesign.lg),
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: NotifDesign.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'New notifications will appear here\nas they arrive.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: NotifDesign.textMuted,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
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

// ─────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  final String error;

  const _ErrorState({required this.onRetry, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NotifDesign.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: NotifDesign.dangerSoft,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: NotifDesign.danger,
              ),
            ),
            const SizedBox(height: NotifDesign.lg),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: NotifDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: NotifDesign.sm),
            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: NotifDesign.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: NotifDesign.lg),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NotifDesign.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: NotifDesign.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(NotifDesign.radiusMd),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}