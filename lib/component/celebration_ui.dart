import 'package:flutter/material.dart';
import 'package:staffsync/screens/celebration_screen.dart';
import '../models/celebration.dart';
import '../services/celebration_api.dart';

// ===================== DESIGN TOKENS =====================

class CelebrationDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // Neutral palette
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFEAECEF);
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Celebration colors
  static const Color birthday = Color(0xFFEC4899); // pink-500
  static const Color birthdaySoft = Color(0xFFFDF2F8);
  static const Color birthdayBorder = Color(0xFFFBCFE8);

  static const Color anniversary = Color(0xFFF97316); // orange-500
  static const Color anniversarySoft = Color(0xFFFFF7ED);
  static const Color anniversaryBorder = Color(0xFFFED7AA);

  static const Color workAnniversary = Color(0xFF6366F1); // indigo-500
  static const Color workSoft = Color(0xFFEEF2FF);
  static const Color workBorder = Color(0xFFC7D2FE);

  static const Color today = Color(0xFF8B5CF6); // violet-500
  static const Color todaySoft = Color(0xFFF5F3FF);
  static const Color todayBorder = Color(0xFFDDD6FE);

  static const Color upcoming = Color(0xFF0F766E); // teal-700
  static const Color upcomingSoft = Color(0xFFF0FDFA);
  static const Color upcomingBorder = Color(0xFF99F6E4);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 10),
      spreadRadius: -8,
    ),
  ];
}

// ===================== EVENT KIND =====================

enum _EventKind { birthday, anniversary, workAnniversary }

extension _EventKindX on _EventKind {
  Color get color => switch (this) {
    _EventKind.birthday => CelebrationDesign.birthday,
    _EventKind.anniversary => CelebrationDesign.anniversary,
    _EventKind.workAnniversary => CelebrationDesign.workAnniversary,
  };

  Color get softColor => switch (this) {
    _EventKind.birthday => CelebrationDesign.birthdaySoft,
    _EventKind.anniversary => CelebrationDesign.anniversarySoft,
    _EventKind.workAnniversary => CelebrationDesign.workSoft,
  };

  Color get borderColor => switch (this) {
    _EventKind.birthday => CelebrationDesign.birthdayBorder,
    _EventKind.anniversary => CelebrationDesign.anniversaryBorder,
    _EventKind.workAnniversary => CelebrationDesign.workBorder,
  };

  IconData get icon => switch (this) {
    _EventKind.birthday => Icons.cake_rounded,
    _EventKind.anniversary => Icons.favorite_rounded,
    _EventKind.workAnniversary => Icons.work_rounded,
  };

  String get label => switch (this) {
    _EventKind.birthday => '🎂 Birthday',
    _EventKind.anniversary => '💍 Anniversary',
    _EventKind.workAnniversary => '💼 Work Anniversary',
  };
}

// ===================== ROW WRAPPERS =====================

class _TodayRow {
  final Employee employee;
  final _EventKind kind;
  const _TodayRow(this.employee, this.kind);
}

class _UpcomingRow {
  final UpcomingEvent event;
  final _EventKind kind;
  const _UpcomingRow(this.event, this.kind);
}

// ===================== WIDGET =====================

class CelebrationWidget extends StatefulWidget {
  final bool showHeader;
  final bool showViewAllButton;
  final VoidCallback? onViewAllPressed;

  const CelebrationWidget({
    super.key,
    this.showHeader = true,
    this.showViewAllButton = true,
    this.onViewAllPressed,
  });

  @override
  State<CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<CelebrationWidget> {
  final CelebrationService _service = CelebrationService();

  bool _isLoading = true;
  String? _error;
  List<_TodayRow> _todayRows = const [];
  List<_UpcomingRow> _upcomingRows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch both endpoints in parallel.
      final results = await Future.wait<Object>([
        _service.getTodayCelebrations(),
        _service.getUpcomingCelebrations(),
      ]);

      final today = (results[0] as CelebrationResponse).data.today;
      final upcoming = (results[1] as UpcomingResponse).data.upcoming;

      final todayRows = <_TodayRow>[
        if (today != null) ...[
          ...today.birthdays.data.map((e) => _TodayRow(e, _EventKind.birthday)),
          ...today.workAnniversaries.data
              .map((e) => _TodayRow(e, _EventKind.workAnniversary)),
          ...today.marriageAnniversaries.data
              .map((e) => _TodayRow(e, _EventKind.anniversary)),
        ],
      ];

      final upcomingRows = <_UpcomingRow>[
        if (upcoming != null) ...[
          ...upcoming.birthdays
              .map((e) => _UpcomingRow(e, _EventKind.birthday)),
          ...upcoming.marriageAnniversaries
              .map((e) => _UpcomingRow(e, _EventKind.anniversary)),
          ...upcoming.workAnniversaries
              .map((e) => _UpcomingRow(e, _EventKind.workAnniversary)),
        ],
      ]..sort((a, b) => a.event.daysUntil.compareTo(b.event.daysUntil));

      if (!mounted) return;
      setState(() {
        _todayRows = todayRows;
        _upcomingRows = upcomingRows.take(5).toList(growable: false);
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Celebration load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CelebrationDesign.surface,
        borderRadius: BorderRadius.circular(CelebrationDesign.radiusLg),
        border: Border.all(color: CelebrationDesign.border, width: 1),
        boxShadow: CelebrationDesign.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CelebrationDesign.radiusLg),
        child: Column(
          children: [
            _buildAccentBar(),
            Padding(
              padding: const EdgeInsets.all(CelebrationDesign.md + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showHeader) _buildHeader(),   // isme already bottom: md hai
                  _buildDivider(),
                  const SizedBox(height: CelebrationDesign.md),  // divider ke baad ka gap
                  _buildBody(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: CelebrationDesign.border,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) return _buildErrorView();
    return _buildCelebrationContent();
  }

  // ===================== ACCENT BAR =====================

  Widget _buildAccentBar() {
    return Container(
      height: 4,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CelebrationDesign.birthday,
            CelebrationDesign.anniversary,
            CelebrationDesign.workAnniversary,
            CelebrationDesign.today,
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: CelebrationDesign.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CelebrationDesign.birthdaySoft,
              borderRadius:
              BorderRadius.circular(CelebrationDesign.radiusSm + 2),
              border: Border.all(
                color: CelebrationDesign.birthdayBorder,
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: CelebrationDesign.birthday,
              size: 22,
            ),
          ),
          const SizedBox(width: CelebrationDesign.md - 2),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Celebrations',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: CelebrationDesign.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 11,
                      color: CelebrationDesign.textMuted,
                    ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Birthdays & Anniversaries',
                        style: TextStyle(
                          fontSize: 12,
                          color: CelebrationDesign.textSecondary,
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
          const SizedBox(width: CelebrationDesign.sm),
          if (widget.showViewAllButton) _buildViewAllButton(),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(CelebrationDesign.radiusSm),
      child: InkWell(
        onTap: widget.onViewAllPressed ??
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CelebrationScreen(),
                ),
              );
            },
        borderRadius: BorderRadius.circular(CelebrationDesign.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CelebrationDesign.sm + 4,
            vertical: CelebrationDesign.xs + 2,
          ),
          decoration: BoxDecoration(
            color: CelebrationDesign.workSoft,
            borderRadius: BorderRadius.circular(CelebrationDesign.radiusSm),
            border: Border.all(
              color: CelebrationDesign.workBorder,
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CelebrationDesign.workAnniversary,
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: CelebrationDesign.workAnniversary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== ERROR VIEW =====================

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(CelebrationDesign.lg),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(CelebrationDesign.md),
              decoration: BoxDecoration(
                color: CelebrationDesign.surfaceMuted,
                borderRadius:
                BorderRadius.circular(CelebrationDesign.radiusMd),
                border: Border.all(color: CelebrationDesign.border, width: 1),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: CelebrationDesign.textMuted,
              ),
            ),
            const SizedBox(height: CelebrationDesign.md),
            const Text(
              'Unable to load celebrations',
              style: TextStyle(
                color: CelebrationDesign.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: CelebrationDesign.md),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(CelebrationDesign.radiusSm),
              child: InkWell(
                onTap: _load,
                borderRadius: BorderRadius.circular(CelebrationDesign.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CelebrationDesign.lg,
                    vertical: CelebrationDesign.sm + 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        CelebrationDesign.workAnniversary,
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius:
                    BorderRadius.circular(CelebrationDesign.radiusSm),
                    boxShadow: [
                      BoxShadow(
                        color: CelebrationDesign.workAnniversary
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== MAIN CONTENT =====================

  Widget _buildCelebrationContent() {
    final hasToday = _todayRows.isNotEmpty;
    final hasUpcoming = _upcomingRows.isNotEmpty;

    if (!hasToday && !hasUpcoming) return _buildEmptyState();

    return Column(
      children: [
        if (hasToday) _buildTodaySection(),
        if (hasUpcoming) _buildUpcomingSection(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(CelebrationDesign.xl),
      child: Center(
        child: Column(
          children: [
            Image.asset(
              'assets/lantern.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  '🎉',
                  style: TextStyle(fontSize: 40),
                );
              },
            ),
            const SizedBox(height: CelebrationDesign.md),
            const Text(
              'No celebrations this week',
              style: TextStyle(
                fontSize: 15,
                color: CelebrationDesign.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: CelebrationDesign.xs),
            const Text(
              'Check back later for upcoming events',
              style: TextStyle(
                fontSize: 12,
                color: CelebrationDesign.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== SECTION HEADER =====================

  Widget _buildSectionHeader({
    required String label,
    required IconData icon,
    required Color color,
    required Color softColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CelebrationDesign.sm + 4,
        vertical: CelebrationDesign.xs + 2,
      ),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TODAY SECTION =====================

  Widget _buildTodaySection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: CelebrationDesign.md + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            label: 'TODAY',
            icon: Icons.celebration_rounded,
            color: CelebrationDesign.today,
            softColor: CelebrationDesign.todaySoft,
            borderColor: CelebrationDesign.todayBorder,
          ),
          const SizedBox(height: CelebrationDesign.sm + 4),
          ..._todayRows.map(
                (row) => _buildTodayCard(row.employee, row.kind),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCard(Employee employee, _EventKind kind) {
    final color = kind.color;
    final softColor = kind.softColor;
    final borderColor = kind.borderColor;
    final icon = kind.icon;

    return Container(
      margin: const EdgeInsets.only(bottom: CelebrationDesign.sm + 4),
      decoration: BoxDecoration(
        color: CelebrationDesign.surface,
        borderRadius: BorderRadius.circular(CelebrationDesign.radiusMd),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: CelebrationDesign.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CelebrationDesign.radiusMd),
        child: Column(
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.5)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(CelebrationDesign.md),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        CelebrationDesign.radiusSm + 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        employee.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: CelebrationDesign.md - 2),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: CelebrationDesign.textPrimary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CelebrationDesign.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: softColor,
                            borderRadius: BorderRadius.circular(6),
                            border:
                            Border.all(color: borderColor, width: 1),
                          ),
                          child: Text(
                            kind.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: color,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.apartment_rounded,
                              size: 12,
                              color: CelebrationDesign.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                employee.department,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CelebrationDesign.textSecondary,
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
                  const SizedBox(width: CelebrationDesign.sm),

                  // Icon badge
                  Container(
                    padding: const EdgeInsets.all(CelebrationDesign.sm + 2),
                    decoration: BoxDecoration(
                      color: softColor,
                      borderRadius:
                      BorderRadius.circular(CelebrationDesign.radiusSm),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== UPCOMING SECTION =====================

  Widget _buildUpcomingSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: CelebrationDesign.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            label: 'UPCOMING',
            icon: Icons.event_rounded,
            color: CelebrationDesign.upcoming,
            softColor: CelebrationDesign.upcomingSoft,
            borderColor: CelebrationDesign.upcomingBorder,
          ),
          const SizedBox(height: CelebrationDesign.sm + 4),
          ..._upcomingRows.map(
                (row) => _buildUpcomingCard(row.event, row.kind),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(UpcomingEvent event, _EventKind kind) {
    final color = kind.color;
    final softColor = kind.softColor;
    final borderColor = kind.borderColor;
    final icon = kind.icon;

    final isToday = event.daysUntil == 0;
    final daysText = switch (event.daysUntil) {
      0 => 'Today',
      1 => 'Tomorrow',
      final d when d < 0 => '${-d}d ago',
      final d => '${d}d',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: CelebrationDesign.sm + 2),
      decoration: BoxDecoration(
        color: CelebrationDesign.surface,
        borderRadius: BorderRadius.circular(CelebrationDesign.radiusMd),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: CelebrationDesign.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(CelebrationDesign.sm + 4),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(CelebrationDesign.radiusSm),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Center(
                child: Text(
                  event.initials,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: CelebrationDesign.sm + 4),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.fullName,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: CelebrationDesign.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Type chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: softColor,
                          borderRadius: BorderRadius.circular(5),
                          border:
                          Border.all(color: borderColor, width: 1),
                        ),
                        child: Text(
                          kind.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Department
                      Flexible(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.apartment_rounded,
                              size: 10,
                              color: CelebrationDesign.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                event.department,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: CelebrationDesign.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: CelebrationDesign.sm),

            // Icon + days badge
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CelebrationDesign.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: isToday
                        ? const LinearGradient(
                      colors: [
                        CelebrationDesign.birthday,
                        CelebrationDesign.anniversary,
                      ],
                    )
                        : LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Text(
                    daysText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}