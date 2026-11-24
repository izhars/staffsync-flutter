import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import '../services/onboarding_service.dart';
import 'onboarding_detail_screen.dart';

class OnboardingDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 8;
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

  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 10),
      spreadRadius: -6,
    ),
  ];
}


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _service = OnboardingService();
  OnboardingModel? _data;
  bool _loading = true;
  String? _error;

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
      final data = await _service.getMyOnboarding();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingDesign.bg,
      appBar: AppBar(
        backgroundColor: OnboardingDesign.surface,
        elevation: 0,
        surfaceTintColor: OnboardingDesign.surface,
        title: const Text(
          'My Onboarding',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: OnboardingDesign.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded,
                color: OnboardingDesign.textSecondary),
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: OnboardingDesign.border, width: 1),
        ),
      ),
      body: RefreshIndicator(
        color: OnboardingDesign.primary,
        backgroundColor: OnboardingDesign.surface,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: OnboardingDesign.primary),
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(OnboardingDesign.lg),
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(OnboardingDesign.lg),
            decoration: BoxDecoration(
              color: OnboardingDesign.dangerSoft,
              borderRadius: BorderRadius.circular(OnboardingDesign.radiusMd),
              border: Border.all(color: OnboardingDesign.danger.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 44, color: OnboardingDesign.danger),
                const SizedBox(height: 12),
                Text(
                  'Failed to load onboarding.\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: OnboardingDesign.danger,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OnboardingDesign.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(OnboardingDesign.radiusSm),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                  child: const Text('Retry',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (_data == null) {
      return ListView(
        padding: const EdgeInsets.all(OnboardingDesign.lg),
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(OnboardingDesign.lg),
            decoration: BoxDecoration(
              color: OnboardingDesign.surface,
              borderRadius: BorderRadius.circular(OnboardingDesign.radiusMd),
              border: Border.all(color: OnboardingDesign.border),
              boxShadow: OnboardingDesign.softShadow,
            ),
            child: Column(
              children: const [
                Icon(Icons.hourglass_empty_rounded,
                    size: 52, color: OnboardingDesign.textMuted),
                SizedBox(height: 14),
                Text(
                  'Your onboarding has not started yet.\nPlease contact HR.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: OnboardingDesign.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return _buildHero(_data!);
  }

  Widget _buildHero(OnboardingModel o) {
    final start = o.startDate;
    final target = o.targetCompletionDate;

    final (statusBg, statusFg) = switch (o.status) {
      'pending' => (OnboardingDesign.warningSoft, OnboardingDesign.warning),
      'in-progress' => (OnboardingDesign.infoSoft, OnboardingDesign.info),
      'completed' => (OnboardingDesign.successSoft, OnboardingDesign.success),
      'cancelled' => (OnboardingDesign.dangerSoft, OnboardingDesign.danger),
      _ => (const Color(0xFFF3F4F6), OnboardingDesign.textSecondary),
    };

    final docItems = o.documentChecklist;
    final taskItems = o.taskChecklist;

    return ListView(
      padding: const EdgeInsets.all(OnboardingDesign.md + 4),
      children: [
        // ── Hero card ──
        Container(
          padding: const EdgeInsets.all(OnboardingDesign.lg),
          decoration: BoxDecoration(
            color: OnboardingDesign.surface,
            borderRadius: BorderRadius.circular(OnboardingDesign.radiusLg),
            border: Border.all(color: OnboardingDesign.border),
            boxShadow: OnboardingDesign.mediumShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.employee?.fullName ?? 'Your Onboarding',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: OnboardingDesign.textPrimary,
                            letterSpacing: -0.3,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          o.employee?.employeeId ?? '',
                          style: const TextStyle(
                            color: OnboardingDesign.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: OnboardingDesign.sm),
                  _StatusPill(
                    label: o.status,
                    bg: statusBg,
                    fg: statusFg,
                  ),
                ],
              ),
              const SizedBox(height: OnboardingDesign.lg),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (o.progress / 100).clamp(0, 1),
                        minHeight: 10,
                        backgroundColor: OnboardingDesign.border,
                        valueColor: const AlwaysStoppedAnimation(
                          OnboardingDesign.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${o.progress}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: OnboardingDesign.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OnboardingDesign.md + 4),
              if (start != null)
                _MetaLine(label: 'Started', value: _fmt(start)),
              if (target != null)
                _MetaLine(label: 'Target', value: _fmt(target)),
            ],
          ),
        ),
        const SizedBox(height: OnboardingDesign.md + 4),

        // ── Quick stats ──
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Tasks',
                value:
                '${taskItems.where((c) => c.completed).length}/${taskItems.length}',
                color: OnboardingDesign.info,
                soft: OnboardingDesign.infoSoft,
                icon: Icons.checklist_rounded,
              ),
            ),
            const SizedBox(width: OnboardingDesign.sm + 4),
            Expanded(
              child: _StatCard(
                label: 'Documents',
                value:
                '${docItems.where((c) => c.completed).length}/${docItems.length}',
                color: OnboardingDesign.success,
                soft: OnboardingDesign.successSoft,
                icon: Icons.folder_copy_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: OnboardingDesign.lg),

        // ── CTA ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: OnboardingDesign.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(OnboardingDesign.radiusSm),
              ),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OnboardingDetailScreen(onboardingId: o.id),
                ),
              );
              _load();
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text(
              'Open onboarding',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ===================== SUB-WIDGETS =====================

class _StatusPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _StatusPill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;
  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              color: OnboardingDesign.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: OnboardingDesign.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color soft;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(OnboardingDesign.md + 6),
      decoration: BoxDecoration(
        color: OnboardingDesign.surface,
        borderRadius: BorderRadius.circular(OnboardingDesign.radiusMd),
        border: Border.all(color: OnboardingDesign.border),
        boxShadow: OnboardingDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              color: OnboardingDesign.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}