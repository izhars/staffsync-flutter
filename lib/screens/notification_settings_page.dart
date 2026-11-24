import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/notification_preference.dart';
import '../services/notification_preference_service.dart';
import '../services/auth_service.dart';

// ════════════════════════════════════════════════════════════════════
// LOCAL DESIGN SYSTEM (mirrors DashboardDesign)
// ════════════════════════════════════════════════════════════════════
class _D {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 28;

  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFEAECEF);
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color primarySoft = Color(0xFFF0FDFA);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 10),
      spreadRadius: -6,
    ),
  ];
}

// ════════════════════════════════════════════════════════════════════
// PAGE
// ════════════════════════════════════════════════════════════════════
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _service = NotificationPreferenceService();
  final _auth = AuthService();

  NotificationPreference? _pref;
  bool _loading = true;
  String? _error;
  bool _saving = false;
  Future<void>? _saveChain;

  String? _currentDeviceId;
  Map<String, dynamic>? _currentDeviceInfo;
  String? _currentFcmToken;

  static const _categoryInfo = <String, _CategoryMeta>{
    'attendance': _CategoryMeta('Attendance', CupertinoIcons.doc_checkmark, Color(0xFF1E88E5)),
    'leave': _CategoryMeta('Leave', CupertinoIcons.calendar_today, Color(0xFFFB8C00)),
    'payroll': _CategoryMeta('Payroll', CupertinoIcons.money_dollar, Color(0xFF8E24AA)),
    'announcements': _CategoryMeta('Announcements', CupertinoIcons.speaker_2, Color(0xFFAB47BC)),
    'tasks': _CategoryMeta('Tasks', CupertinoIcons.check_mark_circled, Color(0xFF00897B)),
    'expenses': _CategoryMeta('Expenses', CupertinoIcons.creditcard, Color(0xFFE53935)),
    'assets': _CategoryMeta('Assets', CupertinoIcons.device_laptop, Color(0xFF3949AB)),
    'celebrations': _CategoryMeta('Celebrations', CupertinoIcons.gift, Color(0xFFD81B60)),
    'security': _CategoryMeta('Security', CupertinoIcons.lock_shield, Color(0xFFFF7043)),
    'messages': _CategoryMeta('Messages', CupertinoIcons.chat_bubble, Color(0xFF039BE5)),
    'calls': _CategoryMeta('Calls', CupertinoIcons.phone, Color(0xFF43A047)),
    'employeeInteractions': _CategoryMeta(
        'Employee Interactions', CupertinoIcons.person_2, Color(0xFF6D4C41)),
    'scheduleUpdates': _CategoryMeta(
        'Schedule Updates', CupertinoIcons.clock, Color(0xFFFFB300)),
    'onboarding': _CategoryMeta('Onboarding', CupertinoIcons.person_add, Color(0xFF00ACC1)),
    'tickets': _CategoryMeta('Tickets', CupertinoIcons.ticket, Color(0xFF5C6BC0)),
  };

  static const _timezones = <String>[
    'Asia/Kolkata',
    'Asia/Dubai',
    'Asia/Singapore',
    'Asia/Tokyo',
    'Europe/London',
    'Europe/Berlin',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'Australia/Sydney',
    'UTC',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ─────────────────────── LOAD ───────────────────────
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _service.getPreferences(),
        _auth.getDeviceId(),
        _auth.getDeviceInfo(),
        _auth.getStoredFcmToken(),
      ]);
      if (!mounted) return;
      setState(() {
        _pref = results[0] as NotificationPreference;
        _currentDeviceId = results[1] as String;
        _currentDeviceInfo = results[2] as Map<String, dynamic>;
        _currentFcmToken = results[3] as String?;
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

  // ─────────────────────── SAVE ───────────────────────
  Future<void> _save() async {
    final pref = _pref;
    if (pref == null) return;

    final chain = _saveChain ?? Future<void>.value();
    final next = chain.then((_) async {
      if (!mounted) return;
      setState(() => _saving = true);
      try {
        final current = _pref;
        if (current == null) return;
        final updated = await _service.updatePreferences(
          pushEnabled: current.pushEnabled,
          categories: current.categories,
          quietHours: current.quietHours,
        );
        if (!mounted) return;
        setState(() => _pref = updated);
      } catch (e) {
        if (!mounted) return;
        _showSnack('Failed to save: $e', isError: true);
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
    _saveChain = next;
    await next;
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13.5,
          ),
        ),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade500,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_D.radiusSm),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────── PICKERS ───────────────────────
  Future<void> _pickTime({required bool isStart}) async {
    final qh = _pref!.quietHours;
    final current = isStart ? qh.start : qh.end;
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final formatted = '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';

    setState(() {
      _pref = _pref!.copyWith(
        quietHours: qh.copyWith(
          start: isStart ? formatted : qh.start,
          end: isStart ? qh.end : formatted,
        ),
      );
    });
    _save();
  }

  Future<void> _pickTimezone() async {
    final current = _pref!.quietHours.timezone;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _D.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(_D.radiusXl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: _D.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Quiet-hours timezone',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: _D.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              ..._timezones.map((tz) {
                final selectedHere = tz == current;
                return ListTile(
                  leading: Icon(
                    selectedHere
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selectedHere ? _D.primary : _D.textMuted,
                  ),
                  title: Text(
                    tz,
                    style: TextStyle(
                      fontWeight:
                      selectedHere ? FontWeight.w700 : FontWeight.w500,
                      color: _D.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, tz),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted || selected == current) return;

    setState(() {
      _pref = _pref!.copyWith(
        quietHours: _pref!.quietHours.copyWith(timezone: selected),
      );
    });
    _save();
  }

  // ════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _D.bg,
      appBar: AppBar(
        backgroundColor: _D.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _D.textPrimary,
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
            color: _D.textPrimary,
          ),
        ),
        actions: [
          if (_pref != null && _saving)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _D.primary,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? _buildLoading()
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  // ─────────────────────── LOADING ───────────────────────
  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.only(top: _D.sm, bottom: 32),
      children: [
        _buildSkeletonCard(rows: 1),
        _buildSkeletonCard(rows: 4),
        _buildSkeletonCard(rows: 3),
        _buildSkeletonCard(rows: 2),
      ],
    );
  }

  Widget _buildSkeletonCard({required int rows}) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: _D.md,
        vertical: _D.sm,
      ),
      padding: const EdgeInsets.all(_D.lg),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.radiusLg),
        boxShadow: _D.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 16,
            width: 120,
            decoration: BoxDecoration(
              color: _D.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            rows,
                (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _D.border,
                      borderRadius: BorderRadius.circular(_D.radiusSm),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: _D.border,
                        borderRadius: BorderRadius.circular(4),
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

  // ─────────────────────── ERROR ───────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_D.lg),
        child: Container(
          padding: const EdgeInsets.all(_D.xl),
          decoration: BoxDecoration(
            color: _D.surface,
            borderRadius: BorderRadius.circular(_D.radiusLg),
            boxShadow: _D.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(_D.radiusMd),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: Colors.red.shade500,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _D.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _D.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Retry',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _D.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_D.radiusSm),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────── CONTENT ───────────────────────
  Widget _buildContent() {
    final pref = _pref!;
    final enabled = pref.pushEnabled;

    return RefreshIndicator(
      color: _D.primary,
      backgroundColor: _D.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(top: _D.sm, bottom: 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // ── Master toggle ──
          _buildCard(
            children: [
              _buildSectionHeader(
                title: 'Push Notifications',
                subtitle: 'Master switch for all push notifications',
              ),
              _buildSwitchRow(
                icon: CupertinoIcons.bell_fill,
                iconColor: _D.primary,
                title: 'Enable push notifications',
                value: pref.pushEnabled,
                onChanged: (v) {
                  setState(() => _pref = pref.copyWith(pushEnabled: v));
                  _save();
                },
              ),
              const SizedBox(height: _D.sm),
            ],
          ),

          // ── Categories ──
          _buildCard(
            children: [
              _buildSectionHeader(
                title: 'Categories',
                subtitle: 'Choose which notifications you receive',
              ),
              ..._categoryInfo.entries.map((e) {
                final key = e.key;
                final meta = e.value;
                final value = pref.categories[key] ?? true;
                return _buildSwitchRow(
                  icon: meta.icon,
                  iconColor: meta.color,
                  title: meta.label,
                  value: value,
                  onChanged: enabled
                      ? (v) {
                    final newCats =
                    Map<String, bool>.from(pref.categories);
                    newCats[key] = v;
                    setState(() =>
                    _pref = pref.copyWith(categories: newCats));
                    _save();
                  }
                      : null,
                );
              }),
              const SizedBox(height: _D.sm),
            ],
          ),

          // ── Quiet Hours ──
          _buildCard(
            children: [
              _buildSectionHeader(
                title: 'Quiet Hours',
                subtitle: 'Silence non-urgent notifications',
              ),
              _buildSwitchRow(
                icon: CupertinoIcons.moon_fill,
                iconColor: const Color(0xFF5E35B1),
                title: 'Enable quiet hours',
                subtitle: pref.quietHours.enabled
                    ? '${pref.quietHours.start} – ${pref.quietHours.end} (${pref.quietHours.timezone})'
                    : null,
                value: pref.quietHours.enabled,
                onChanged: enabled
                    ? (v) {
                  setState(() {
                    _pref = _pref!.copyWith(
                      quietHours:
                      pref.quietHours.copyWith(enabled: v),
                    );
                  });
                  _save();
                }
                    : null,
              ),
              if (pref.quietHours.enabled) ...[
                const SizedBox(height: _D.sm),
                _buildDivider(),
                _buildTapRow(
                  icon: Icons.play_arrow_rounded,
                  iconColor: Colors.green.shade600,
                  title: 'Start time',
                  trailing: pref.quietHours.start,
                  onTap: () => _pickTime(isStart: true),
                ),
                _buildDivider(),
                _buildTapRow(
                  icon: Icons.stop_rounded,
                  iconColor: Colors.red.shade500,
                  title: 'End time',
                  trailing: pref.quietHours.end,
                  onTap: () => _pickTime(isStart: false),
                ),
                _buildDivider(),
                _buildTapRow(
                  icon: Icons.public_rounded,
                  iconColor: _D.primary,
                  title: 'Timezone',
                  subtitle: pref.quietHours.timezone,
                  showChevron: true,
                  onTap: _pickTimezone,
                ),
              ],
              const SizedBox(height: _D.sm),
            ],
          ),

          // ── Devices ──
          _buildCard(
            children: [
              _buildSectionHeader(
                title: 'Registered Devices',
                subtitle: 'Devices receiving push notifications',
              ),
              ..._buildDeviceTiles(pref),
              const SizedBox(height: _D.sm),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────── CARD ───────────────────────
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: _D.md,
        vertical: _D.sm,
      ),
      decoration: BoxDecoration(
        color: _D.surface,
        borderRadius: BorderRadius.circular(_D.radiusLg),
        boxShadow: _D.softShadow,
        border: Border.all(color: _D.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_D.lg, _D.lg, _D.lg, _D.sm + 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: _D.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: _D.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _D.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _D.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(
    height: 0.5,
    margin: const EdgeInsets.symmetric(horizontal: _D.lg),
    color: _D.border,
  );

  // ─────────────────────── SWITCH ROW ───────────────────────
  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    final enabled = onChanged != null;
    final color = enabled ? iconColor : _D.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _D.lg,
        vertical: _D.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(_D.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: enabled ? _D.textPrimary : _D.textMuted,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _D.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: _D.primary,
          ),
        ],
      ),
    );
  }

  // ─────────────────────── TAP ROW ───────────────────────
  Widget _buildTapRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? trailing,
    bool showChevron = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_D.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _D.lg,
          vertical: _D.md + 2,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(_D.radiusSm),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: _D.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _D.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _D.primarySoft,
                  borderRadius: BorderRadius.circular(_D.radiusSm),
                ),
                child: Text(
                  trailing,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _D.primary,
                  ),
                ),
              ),
            if (showChevron)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _D.textMuted,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── DEVICES ───────────────────────
  List<Widget> _buildDeviceTiles(NotificationPreference pref) {
    final tiles = <Widget>[];
    if (_currentDeviceInfo != null) {
      final platform =
          (_currentDeviceInfo!['platform'] as String?)?.toLowerCase() ??
              'unknown';
      final model = _currentDeviceInfo!['model'] as String?;
      final osVersion = _currentDeviceInfo!['osVersion'] as String?;
      final appVersion = _currentDeviceInfo!['appVersion'] as String?;

      tiles.add(_buildDeviceTile(
        platform: platform,
        deviceId: _currentDeviceId,
        model: model,
        osVersion: osVersion,
        appVersion: appVersion,
        token: _currentFcmToken,
        isCurrent: true,
      ));
    }

    if (tiles.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(_D.lg, 0, _D.lg, _D.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _D.border,
                  borderRadius: BorderRadius.circular(_D.radiusSm),
                ),
                child: const Icon(
                  Icons.devices_other_rounded,
                  color: _D.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No devices registered',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _D.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'This device will register automatically',
                      style: TextStyle(
                        fontSize: 12,
                        color: _D.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ];
    }
    return tiles;
  }

  Widget _buildDeviceTile({
    required String platform,
    required String? deviceId,
    String? model,
    String? osVersion,
    String? appVersion,
    String? token,
    required bool isCurrent,
  }) {
    final subtitleParts = <String>[
      model ?? deviceId ?? 'Unknown device',
      if (osVersion != null && osVersion.isNotEmpty) 'OS $osVersion',
      if (appVersion != null && appVersion.isNotEmpty) 'app $appVersion',
      if (token != null && token.isNotEmpty) 'token ${_shortToken(token)}',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: _D.md + 4,
        vertical: _D.xs + 2,
      ),
      padding: const EdgeInsets.all(_D.md + 2),
      decoration: BoxDecoration(
        color: _D.primarySoft.withOpacity(0.4),
        borderRadius: BorderRadius.circular(_D.radiusMd),
        border: Border.all(
          color: _D.primary.withOpacity(0.15),
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _D.primaryLight,
              borderRadius: BorderRadius.circular(_D.radiusSm),
            ),
            child: Icon(
              _platformIcon(platform),
              color: _D.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      platform.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _D.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _D.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'This device',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitleParts.join(' · '),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _D.textSecondary,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _platformIcon(String p) {
    switch (p.toLowerCase()) {
      case 'android':
        return Icons.android_rounded;
      case 'ios':
        return Icons.phone_iphone_rounded;
      case 'web':
        return Icons.language_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  String _shortToken(String t) =>
      t.length <= 14 ? t : '${t.substring(0, 6)}…${t.substring(t.length - 4)}';
}

class _CategoryMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _CategoryMeta(this.label, this.icon, this.color);
}