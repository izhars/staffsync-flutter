// lib/DevicesPage.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/device_session.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────
// Design tokens (mirror DashboardDesign)
// ─────────────────────────────────────────────────────────────
class _D {
  static const bg = Color(0xFFF6F7FB);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1A1D26);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const border = Color(0xFFEAECEF);
  static const primary = Color(0xFF0F766E);
  static const primarySoft = Color(0xFFF0FDFA);
  static const primaryLight = Color(0xFFCCFBF1);
  static const radiusMd = 18.0;
  static const radiusLg = 24.0;

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];
}

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final AuthService _auth = AuthService();

  List<DeviceSession> _sessions = [];
  bool _loading = true;
  String? _error;
  String? _busySessionId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _auth.getSessions();
      if (!mounted) return;
      setState(() {
        _sessions = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _revoke(DeviceSession s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _D.surface,
        surfaceTintColor: _D.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_D.radiusLg),
        ),
        title: const Text(
          'Sign out this device?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          '${s.displayName} will be logged out immediately and will need to sign in again.',
          style: const TextStyle(color: _D.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busySessionId = s.sessionId);
    try {
      await _auth.revokeSession(s.sessionId);
      if (!mounted) return;
      setState(() => _sessions.removeWhere((e) => e.sessionId == s.sessionId));
      _toast('Device signed out');
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busySessionId = null);
    }
  }

  Future<void> _revokeAllOthers() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _D.surface,
        surfaceTintColor: _D.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_D.radiusLg),
        ),
        title: const Text(
          'Sign out all other devices?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: const Text(
          'All other devices will be logged out immediately. This device stays signed in.',
          style: TextStyle(color: _D.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign out all'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _loading = true);
    try {
      final n = await _auth.revokeAllOtherSessions();
      await _load();
      _toast('$n device(s) signed out');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(e.toString(), error: true);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade400 : _D.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final others = _sessions.where((s) => !s.isCurrent).length;

    return Scaffold(
      backgroundColor: _D.bg,
      appBar: AppBar(
        backgroundColor: _D.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Logged-in Devices',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (others > 0 && !_loading)
            IconButton(
              tooltip: 'Sign out all other devices',
              onPressed: _revokeAllOthers,
              icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: _D.primary,
        backgroundColor: _D.surface,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _D.surface,
              borderRadius: BorderRadius.circular(_D.radiusMd),
              border: Border.all(color: _D.border),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 42, color: Colors.red.shade400),
                const SizedBox(height: 14),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _D.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _load,
                  style: FilledButton.styleFrom(
                    backgroundColor: _D.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Skeletonizer(
      enabled: _loading,
      child: _loading
          ? ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SummaryCardSkeleton(),
          SizedBox(height: 16),
          _SessionTileSkeleton(),
          SizedBox(height: 10),
          _SessionTileSkeleton(),
        ],
      )
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 18),
          _buildSectionLabel(),
          const SizedBox(height: 10),
          ..._sessions.map(
                (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SessionTile(
                session: s,
                busy: _busySessionId == s.sessionId,
                onRevoke: () => _revoke(s),
              ),
            ),
          ),
          if (_sessions.isEmpty) _buildEmptyState(),
          const SizedBox(height: 12),
          _buildFooterNote(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Summary card
  // ─────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final others = _sessions.where((s) => !s.isCurrent).length;
    final total = _sessions.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_D.primary, Color(0xFF14867C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_D.radiusMd),
        boxShadow: _D.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.devices_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 1 ? '1 active session' : '$total active sessions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  others == 0
                      ? 'Only this device is signed in'
                      : '$others other device${others == 1 ? '' : 's'} signed in',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulseDot(),
                SizedBox(width: 6),
                Text(
                  'Live',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel() {
    return const Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        'SESSIONS',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _D.textMuted,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.radiusMd),
        border: Border.all(color: _D.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _D.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.devices_other_rounded,
                color: _D.primary, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'No active sessions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _D.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Signed-in devices will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _D.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 15, color: _D.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'If you see a device you don\'t recognize, sign it out and change your password.',
              style: TextStyle(
                fontSize: 11.5,
                color: _D.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Session tile
// ─────────────────────────────────────────────
class _SessionTile extends StatelessWidget {
  final DeviceSession session;
  final bool busy;
  final VoidCallback onRevoke;

  const _SessionTile({
    required this.session,
    required this.busy,
    required this.onRevoke,
  });

  IconData get _platformIcon {
    switch (session.platform) {
      case 'android':
        return Icons.android_rounded;
      case 'ios':
        return Icons.phone_iphone_rounded;
      case 'web':
        return Icons.language_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastActive = _friendlyTime(session.lastActiveAt);
    final isCurrent = session.isCurrent;
    final ip = session.shortIp;

    return Container(
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.radiusMd),
        border: Border.all(
          color: isCurrent ? _D.primary : _D.border,
          width: isCurrent ? 1.6 : 1,
        ),
        boxShadow: isCurrent ? _D.softShadow : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCurrent ? _D.primarySoft : const Color(0xFFF4F5F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _platformIcon,
              color: isCurrent ? _D.primary : _D.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: _D.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) const _ThisDeviceBadge(),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaChip(
                      icon: Icons.memory_rounded,
                      label: session.platformLabel,
                    ),
                    if (ip != null)
                      _MetaChip(icon: Icons.wifi_rounded, label: ip),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _ActiveDot(active: _isOnline(session.lastActiveAt)),
                    const SizedBox(width: 6),
                    Text(
                      'Active $lastActive',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: _D.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action
          if (!isCurrent)
            busy
                ? const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : IconButton(
              tooltip: 'Sign out',
              visualDensity: VisualDensity.compact,
              onPressed: onRevoke,
              icon: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade400,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  bool _isOnline(DateTime lastActive) {
    return DateTime.now().difference(lastActive).inMinutes < 5;
  }

  String _friendlyTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(t);
  }
}

// ─────────────────────────────────────────────
// Small widgets
// ─────────────────────────────────────────────
class _ThisDeviceBadge extends StatelessWidget {
  const _ThisDeviceBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _D.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'This device',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _D.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _D.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveDot extends StatelessWidget {
  final bool active;
  const _ActiveDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF22C55E) : _D.textMuted,
        shape: BoxShape.circle,
        boxShadow: active
            ? [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_c),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Skeletons
// ─────────────────────────────────────────────
class _SummaryCardSkeleton extends StatelessWidget {
  const _SummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.radiusMd),
        border: Border.all(color: _D.border),
      ),
    );
  }
}

class _SessionTileSkeleton extends StatelessWidget {
  const _SessionTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.radiusMd),
        border: Border.all(color: _D.border),
      ),
    );
  }
}