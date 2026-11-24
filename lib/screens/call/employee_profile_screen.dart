import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/employee_interaction_service.dart';

// ===================== DESIGN TOKENS =====================
class InteractionDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;

  static const Color primary = Color(0xFF4F46E5);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color primaryLight = Color(0xFFC7D2FE);

  static const Color surface = Colors.white;
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFF5F3FF);
  static const Color purpleBorder = Color(0xFFDDD6FE);

  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralSoft = Color(0xFFF3F4F6);
  static const Color neutralBorder = Color(0xFFE5E7EB);

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

class EmployeeProfileScreen extends StatefulWidget {
  final String employeeId;

  const EmployeeProfileScreen({
    Key? key,
    required this.employeeId,
  }) : super(key: key);

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final List<EmployeeInteraction> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _initialLoading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  // ===================== DATA =====================

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });
    try {
      final res = await EmployeeInteractionService.fetchHistory(page: 1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.interactions);
        _page = res.currentPage;
        _hasMore = res.hasMore;
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _initialLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final res = await EmployeeInteractionService.fetchHistory(page: 1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res.interactions);
        _page = res.currentPage;
        _hasMore = res.hasMore;
        _error = null;
      });
    } catch (_) {}
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _initialLoading) return;
    setState(() => _loadingMore = true);
    try {
      final res =
      await EmployeeInteractionService.fetchHistory(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.interactions);
        _page = res.currentPage;
        _hasMore = res.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  bool _isCall(EmployeeInteraction i) =>
      i.type == 'started_call' ||
          i.type == 'missed_call' ||
          i.callType != null;

  List<EmployeeInteraction> get _activity =>
      _items.where((i) => i.type != 'viewed_profile').toList();

  List<EmployeeInteraction> get _calls => _items.where(_isCall).toList();

  // ===================== HELPERS =====================

  IconData _getIcon(String type) {
    switch (type) {
      case 'started_call':
        return Icons.phone_in_talk_rounded;
      case 'missed_call':
        return Icons.phone_missed_rounded;
      case 'messaged':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.timeline_rounded;
    }
  }

  (Color, Color, Color) _getPalette(String type) {
    switch (type) {
      case 'missed_call':
        return (
        InteractionDesign.danger,
        InteractionDesign.dangerSoft,
        InteractionDesign.dangerBorder,
        );
      case 'started_call':
        return (
        InteractionDesign.success,
        InteractionDesign.successSoft,
        InteractionDesign.successBorder,
        );
      case 'messaged':
        return (
        InteractionDesign.purple,
        InteractionDesign.purpleSoft,
        InteractionDesign.purpleBorder,
        );
      default:
        return (
        InteractionDesign.neutral,
        InteractionDesign.neutralSoft,
        InteractionDesign.neutralBorder,
        );
    }
  }

  String _formatTimestamp(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd, yyyy').format(t);
  }

  String _formatFull(DateTime t) =>
      DateFormat('MMM dd, yyyy • hh:mm a').format(t.toLocal());

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _getInteractionTitle(EmployeeInteraction i) {
    if (i.readableType.isNotEmpty) return i.readableType;
    switch (i.type) {
      case 'started_call':
        return 'Started Call';
      case 'missed_call':
        return 'Missed Call';
      case 'messaged':
        return 'Sent Message';
      default:
        return i.type.replaceAll('_', ' ').toUpperCase();
    }
  }

  bool _isMissed(EmployeeInteraction i) =>
      i.type == 'missed_call' || i.callStatus == 'missed';

  String _statusLabel(EmployeeInteraction i) {
    if (_isMissed(i)) return i.isIncoming ? 'Missed' : 'No answer';
    switch (i.callStatus) {
      case 'started':
        return 'Ringing';
      case 'accepted':
        return 'Ongoing';
      case 'ended':
        return 'Completed';
      default:
        return i.callStatus == null
            ? 'Call'
            : i.callStatus![0].toUpperCase() + i.callStatus!.substring(1);
    }
  }

  (Color, Color, Color) _statusPalette(EmployeeInteraction i) {
    if (_isMissed(i)) {
      return (
      InteractionDesign.danger,
      InteractionDesign.dangerSoft,
      InteractionDesign.dangerBorder
      );
    }
    switch (i.callStatus) {
      case 'ended':
        return (
        InteractionDesign.success,
        InteractionDesign.successSoft,
        InteractionDesign.successBorder
        );
      case 'accepted':
      case 'started':
        return (
        InteractionDesign.info,
        InteractionDesign.infoSoft,
        InteractionDesign.infoBorder
        );
      default:
        return (
        InteractionDesign.neutral,
        InteractionDesign.neutralSoft,
        InteractionDesign.neutralBorder
        );
    }
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    final activity = _activity;
    final calls = _calls;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: InteractionDesign.bg,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: InteractionDesign.bg,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 4,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Interaction History',
                style: TextStyle(
                  color: InteractionDesign.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Activity & call logs',
                style: TextStyle(
                  color: InteractionDesign.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          leadingWidth: 56,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(InteractionDesign.radiusSm),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: InteractionDesign.surface,
                    borderRadius:
                    BorderRadius.circular(InteractionDesign.radiusSm),
                    border:
                    Border.all(color: InteractionDesign.border, width: 1),
                    boxShadow: InteractionDesign.softShadow,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: InteractionDesign.textPrimary,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: _buildTabBar(activity.length, calls.length),
          ),
        ),
        body: _initialLoading
            ? _buildLoadingState()
            : _error != null
            ? _buildErrorState(_error!)
            : TabBarView(
          children: [
            _buildList(
              items: activity,
              header: _buildHeader(
                icon: Icons.timeline_rounded,
                title: 'Recent Activity',
                count: activity.length,
              ),
              emptyTitle: 'No activity yet',
              emptySubtitle: 'Your interaction history will appear here',
              builder: _buildInteractionCard,
            ),
            _buildList(
              items: calls,
              header: _buildHeader(
                icon: Icons.call_rounded,
                title: 'Recent Calls',
                count: calls.length,
              ),
              emptyTitle: 'No call logs yet',
              emptySubtitle: 'Your recent calls will appear here',
              builder: _buildCallCard,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(int activityCount, int callCount) {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(
        InteractionDesign.md,
        0,
        InteractionDesign.md,
        InteractionDesign.sm,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: InteractionDesign.neutralSoft,
        borderRadius: BorderRadius.circular(InteractionDesign.radiusMd),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(InteractionDesign.radiusSm),
        indicator: BoxDecoration(
          color: InteractionDesign.surface,
          borderRadius: BorderRadius.circular(InteractionDesign.radiusSm),
          boxShadow: InteractionDesign.softShadow,
        ),
        labelColor: InteractionDesign.primary,
        unselectedLabelColor: InteractionDesign.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          Tab(text: 'Activity ($activityCount)'),
          Tab(text: 'Call Logs ($callCount)'),
        ],
      ),
    );
  }

  // ===================== LIST =====================

  Widget _buildList({
    required List<EmployeeInteraction> items,
    required Widget header,
    required String emptyTitle,
    required String emptySubtitle,
    required Widget Function(EmployeeInteraction) builder,
  }) {
    // Filtered tab may be empty/short while more pages exist — keep fetching.
    if (items.length < 6 && _hasMore && !_loadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
    }

    if (items.isEmpty && !_hasMore) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: InteractionDesign.primary,
        child: _buildEmptyState(emptyTitle, emptySubtitle),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: InteractionDesign.primary,
      backgroundColor: InteractionDesign.surface,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
            _loadMore();
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            InteractionDesign.md,
            InteractionDesign.sm,
            InteractionDesign.md,
            InteractionDesign.xl,
          ),
          itemCount: items.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) return header;
            if (index == items.length + 1) {
              return _loadingMore
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          InteractionDesign.primary),
                    ),
                  ),
                ),
              )
                  : const SizedBox.shrink();
            }
            return builder(items[index - 1]);
          },
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: InteractionDesign.md),
      padding: const EdgeInsets.all(InteractionDesign.md),
      decoration: BoxDecoration(
        color: InteractionDesign.surface,
        borderRadius: BorderRadius.circular(InteractionDesign.radiusLg),
        border: Border.all(color: InteractionDesign.border, width: 1),
        boxShadow: InteractionDesign.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: InteractionDesign.primarySoft,
              borderRadius: BorderRadius.circular(InteractionDesign.radiusSm),
              border:
              Border.all(color: InteractionDesign.primaryLight, width: 1),
            ),
            child: Icon(icon, color: InteractionDesign.primary, size: 20),
          ),
          const SizedBox(width: InteractionDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: InteractionDesign.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count${_hasMore ? '+' : ''} ${count == 1 ? 'entry' : 'entries'}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: InteractionDesign.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== SHARED WIDGETS =====================

  Widget _avatar(String name, String url, {double size = 44}) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: InteractionDesign.primarySoft,
      child: Text(
        initial,
        style: TextStyle(
          color: InteractionDesign.primary,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(InteractionDesign.radiusSm),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? fallback
            : Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback,
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required Color color,
    required Color soft,
    required Color border,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border.withOpacity(0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _directionChip(EmployeeInteraction i) {
    final color =
    i.isIncoming ? InteractionDesign.success : InteractionDesign.info;
    final soft =
    i.isIncoming ? InteractionDesign.successSoft : InteractionDesign.infoSoft;
    final border = i.isIncoming
        ? InteractionDesign.successBorder
        : InteractionDesign.infoBorder;
    return _chip(
      label: i.isIncoming ? 'IN' : 'OUT',
      icon: i.isIncoming
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded,
      color: color,
      soft: soft,
      border: border,
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: InteractionDesign.surface,
    borderRadius: BorderRadius.circular(InteractionDesign.radiusLg),
    border: Border.all(color: InteractionDesign.border, width: 1),
    boxShadow: InteractionDesign.softShadow,
  );

  // ===================== ACTIVITY CARD =====================

  Widget _buildInteractionCard(EmployeeInteraction i) {
    final (accent, soft, border) = _getPalette(i.type);

    String? subtitle;
    if (_isCall(i)) {
      final parts = <String>[];
      if (i.callType != null) {
        parts.add(i.callType![0].toUpperCase() + i.callType!.substring(1));
      }
      if (i.durationSeconds != null && i.durationSeconds! > 0) {
        parts.add(_formatDuration(i.durationSeconds!));
      }
      if (parts.isNotEmpty) subtitle = parts.join(' • ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: InteractionDesign.sm + 4),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(InteractionDesign.md),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _avatar(i.counterpartName, i.counterpartProfilePicture),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: soft,
                      shape: BoxShape.circle,
                      border: Border.all(color: InteractionDesign.surface, width: 2),
                    ),
                    child: Icon(_getIcon(i.type), color: accent, size: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(width: InteractionDesign.sm + 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getInteractionTitle(i),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: InteractionDesign.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          i.counterpartName.isEmpty
                              ? 'Unknown'
                              : i.counterpartName,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: InteractionDesign.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: _Dot(),
                      ),
                      Text(
                        _formatTimestamp(i.timestamp),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: InteractionDesign.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: InteractionDesign.sm),
            _directionChip(i),
          ],
        ),
      ),
    );
  }

  // ===================== CALL LOG CARD =====================

  Widget _buildCallCard(EmployeeInteraction i) {
    final missed = _isMissed(i);
    final (accent, soft, border) =
    missed ? _getPalette('missed_call') : _getPalette('started_call');
    final (sAccent, sSoft, sBorder) = _statusPalette(i);
    final isVideo = i.callType == 'video';
    final hasDuration = i.durationSeconds != null && i.durationSeconds! > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: InteractionDesign.sm + 4),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(InteractionDesign.md),
        child: Column(
          children: [
            Row(
              children: [
                _avatar(i.counterpartName, i.counterpartProfilePicture),
                const SizedBox(width: InteractionDesign.sm + 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i.counterpartName.isEmpty ? 'Unknown' : i.counterpartName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: missed
                              ? InteractionDesign.danger
                              : InteractionDesign.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            i.isIncoming
                                ? (missed
                                ? Icons.call_missed_rounded
                                : Icons.call_received_rounded)
                                : Icons.call_made_rounded,
                            size: 14,
                            color: accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            i.isIncoming ? 'Incoming' : 'Outgoing',
                            style: const TextStyle(
                              fontSize: 12,
                              color: InteractionDesign.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: _Dot(),
                          ),
                          Text(
                            _formatTimestamp(i.timestamp),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: InteractionDesign.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: InteractionDesign.sm),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius:
                    BorderRadius.circular(InteractionDesign.radiusSm),
                    border: Border.all(color: border, width: 1),
                  ),
                  child: Icon(
                    isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                    color: accent,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: InteractionDesign.sm + 4),
            Container(height: 1, color: InteractionDesign.border),
            const SizedBox(height: InteractionDesign.sm + 4),
            Row(
              children: [
                _chip(
                  label: _statusLabel(i).toUpperCase(),
                  color: sAccent,
                  soft: sSoft,
                  border: sBorder,
                ),
                const SizedBox(width: 6),
                _chip(
                  label: (i.callType ?? 'audio').toUpperCase(),
                  icon: isVideo ? Icons.videocam_rounded : Icons.mic_rounded,
                  color: InteractionDesign.neutral,
                  soft: InteractionDesign.neutralSoft,
                  border: InteractionDesign.neutralBorder,
                ),
                const Spacer(),
                if (hasDuration) ...[
                  const Icon(Icons.timer_outlined,
                      size: 13, color: InteractionDesign.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(i.durationSeconds!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: InteractionDesign.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: InteractionDesign.sm),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: InteractionDesign.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    i.endedAt != null
                        ? '${_formatFull(i.timestamp)}  →  ${DateFormat('hh:mm a').format(i.endedAt!.toLocal())}'
                        : _formatFull(i.timestamp),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: InteractionDesign.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== STATES =====================

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(InteractionDesign.xl),
        margin: const EdgeInsets.symmetric(horizontal: InteractionDesign.lg),
        decoration: BoxDecoration(
          color: InteractionDesign.surface,
          borderRadius: BorderRadius.circular(InteractionDesign.radiusLg),
          border: Border.all(color: InteractionDesign.border, width: 1),
          boxShadow: InteractionDesign.cardShadow,
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                AlwaysStoppedAnimation<Color>(InteractionDesign.primary),
              ),
            ),
            SizedBox(height: InteractionDesign.md),
            Text(
              'Loading interactions...',
              style: TextStyle(
                color: InteractionDesign.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(InteractionDesign.xl),
        margin: const EdgeInsets.symmetric(horizontal: InteractionDesign.lg),
        decoration: BoxDecoration(
          color: InteractionDesign.surface,
          borderRadius: BorderRadius.circular(InteractionDesign.radiusLg),
          border: Border.all(color: InteractionDesign.border, width: 1),
          boxShadow: InteractionDesign.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: InteractionDesign.dangerSoft,
                shape: BoxShape.circle,
                border: Border.all(color: InteractionDesign.dangerBorder),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: InteractionDesign.danger,
              ),
            ),
            const SizedBox(height: InteractionDesign.md),
            const Text(
              'Unable to load interactions',
              style: TextStyle(
                color: InteractionDesign.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: InteractionDesign.xs + 2),
            Text(
              error,
              style: const TextStyle(
                color: InteractionDesign.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: InteractionDesign.md),
            TextButton.icon(
              onPressed: _loadInitial,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: InteractionDesign.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(InteractionDesign.md),
      children: [
        Container(
          padding: const EdgeInsets.all(InteractionDesign.xl),
          decoration: _cardDecoration,
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: InteractionDesign.neutralSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  size: 36,
                  color: InteractionDesign.textMuted,
                ),
              ),
              const SizedBox(height: InteractionDesign.md),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: InteractionDesign.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: InteractionDesign.xs + 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: InteractionDesign.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: InteractionDesign.textMuted,
        shape: BoxShape.circle,
      ),
    );
  }
}