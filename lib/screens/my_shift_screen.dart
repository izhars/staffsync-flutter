import 'package:flutter/material.dart';
import '../models/shift.dart';
import '../services/shift_service.dart';

// Reuse the same design tokens as SettingsPage
class ShiftDesign {
  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFEAECEF);
  static const Color primary = Color(0xFF0F766E);
  static const Color primarySoft = Color(0xFFF0FDFA);

  static const double radiusMd = 18;
  static const double radiusLg = 24;

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];
}

class MyShiftScreen extends StatefulWidget {
  const MyShiftScreen({super.key});

  @override
  State<MyShiftScreen> createState() => _MyShiftScreenState();
}

class _MyShiftScreenState extends State<MyShiftScreen> {
  final ShiftService _service = ShiftService();

  bool _loading = true;
  String? _error;
  MyShiftResponse? _data;

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
      final result = await _service.getMyShift();
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShiftDesign.bg,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: ShiftDesign.primary),
      )
          : RefreshIndicator(
        color: ShiftDesign.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ShiftDesign.bg,
      surfaceTintColor: ShiftDesign.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: ShiftDesign.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: ShiftDesign.textPrimary,
          ),
        ),
      ),
      title: const Text(
        'Shift & Working Hours',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: ShiftDesign.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            onPressed: _loading ? null : _load,
            style: IconButton.styleFrom(
              backgroundColor: ShiftDesign.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.refresh_rounded,
              size: 20,
              color: ShiftDesign.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [_errorCard(_error!)],
      );
    }
    final data = _data;
    if (data == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: const [
          _EmptyState(),
        ],
      );
    }

    final s = data.shift;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _headerCard(s),
        const SizedBox(height: 24),

        _sectionHeader('Timing'),
        _card(
          child: Column(
            children: [
              _infoTile(
                icon: Icons.login_outlined,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                label: 'Start time',
                value: s.startTime,
              ),
              _divider(),
              _infoTile(
                icon: Icons.logout_outlined,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
                label: 'End time',
                value: s.endTime,
              ),
              _divider(),
              _infoTile(
                icon: Icons.timelapse_outlined,
                iconBg: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF059669),
                label: 'Duration',
                value: '${s.durationHours} hrs',
              ),
              _divider(),
              _infoTile(
                icon: Icons.free_breakfast_outlined,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFEA580C),
                label: 'Break',
                value: '${s.breakDuration} min',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _sectionHeader('Rules'),
        _card(
          child: Column(
            children: [
              _infoTile(
                icon: Icons.hourglass_empty_outlined,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                label: 'Grace period',
                value: '${s.gracePeriod} min',
              ),
              _divider(),
              _infoTile(
                icon: Icons.timer_outlined,
                iconBg: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF9333EA),
                label: 'Half-day threshold',
                value: '${s.halfDayThreshold} min',
              ),
              _divider(),
              _infoTile(
                icon: Icons.exit_to_app_outlined,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                label: 'Early leave grace',
                value: '${s.earlyLeaveGrace} min',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _sectionHeader('Schedule'),
        _card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chipsRow(
                  label: 'Working days',
                  values: data.workingDays,
                  color: const Color(0xFF059669),
                  bg: const Color(0xFFECFDF5),
                ),
                const SizedBox(height: 14),
                _chipsRow(
                  label: 'Weekend days',
                  values: data.weekendDays,
                  color: const Color(0xFFDC2626),
                  bg: const Color(0xFFFEE2E2),
                ),
              ],
            ),
          ),
        ),
        if (data.assignedAt != null) ...[
          const SizedBox(height: 24),
          _sectionHeader('Assignment'),
          _card(
            child: _infoTile(
              icon: Icons.event_available_outlined,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF4F46E5),
              label: 'Assigned on',
              value: _formatDate(data.assignedAt!),
            ),
          ),
        ],
        const SizedBox(height: 32),
        Center(
          child: Text(
            'StaffSync · Shift Info',
            style: TextStyle(
              fontSize: 12,
              color: ShiftDesign.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Header card (gradient, matches primary tone) ───
  Widget _headerCard(Shift shift) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ShiftDesign.radiusLg),
        boxShadow: [
          BoxShadow(
            color: ShiftDesign.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shift.code,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (shift.isNightShift)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF312E81),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NIGHT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          if (shift.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              shift.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.92),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  shift.displayTiming,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build helpers (mirroring SettingsPage) ───
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: ShiftDesign.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ShiftDesign.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: ShiftDesign.surface,
        borderRadius: BorderRadius.circular(ShiftDesign.radiusLg),
        boxShadow: ShiftDesign.softShadow,
        border: Border.all(color: ShiftDesign.border),
      ),
      child: child,
    );
  }

  Widget _divider() => const Divider(
    height: 1,
    color: ShiftDesign.border,
    indent: 68,
  );

  Widget _infoTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: ShiftDesign.textPrimary,
                letterSpacing: -0.1,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: ShiftDesign.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipsRow({
    required String label,
    required List<String> values,
    required Color color,
    required Color bg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: ShiftDesign.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (v) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Text(
                v[0].toUpperCase() + v.substring(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          )
              .toList(),
        ),
      ],
    );
  }

  Widget _errorCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ShiftDesign.surface,
        borderRadius: BorderRadius.circular(ShiftDesign.radiusLg),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: ShiftDesign.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Failed to load shift',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ShiftDesign.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: ShiftDesign.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: ShiftDesign.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ShiftDesign.surface,
        borderRadius: BorderRadius.circular(ShiftDesign.radiusLg),
        boxShadow: ShiftDesign.softShadow,
        border: Border.all(color: ShiftDesign.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: ShiftDesign.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.event_busy_outlined,
              size: 36,
              color: ShiftDesign.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No shift assigned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ShiftDesign.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'You do not have a shift assigned yet. '
                'Please contact your HR or administrator.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: ShiftDesign.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}