// lib/screens/calendar_task_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/task_item.dart';
import '../services/task_service.dart';

// ===================== SHARED DESIGN TOKENS =====================
class CalendarDesign {
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
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color info = Color(0xFF4F46E5);
  static const Color infoSoft = Color(0xFFEEF2FF);
  static const Color infoBorder = Color(0xFFC7D2FE);

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

class DailyTaskCalendarPage extends StatefulWidget {
  const DailyTaskCalendarPage({super.key});

  @override
  State<DailyTaskCalendarPage> createState() => _DailyTaskCalendarPageState();
}

class _DailyTaskCalendarPageState extends State<DailyTaskCalendarPage> {
  final TaskService _taskService = TaskService();

  DateTime _selectedDate = DateTime.now();
  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 15));
  DateTime _rangeEnd = DateTime.now().add(const Duration(days: 15));
  Map<DateTime, List<DailyTaskEntry>> _groupedTasks = {};
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTasksForRange();
  }

  // ─────────────────────────────────────────────────────────
  // Data fetching
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchTasksForRange() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries = await _taskService.getTasksByDateRange(
        from: _rangeStart,
        to: _rangeEnd,
      );

      final grouped = <DateTime, List<DailyTaskEntry>>{};
      for (final entry in entries) {
        final key = _keyFor(entry.date);
        grouped.putIfAbsent(key, () => []).add(entry);
      }

      if (!mounted) return;
      setState(() {
        _groupedTasks = grouped;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  /// Re-fetch only if the selected date falls outside the cached window.
  void _ensureRangeCovers(DateTime date) {
    final buffered = date.isAfter(_rangeStart) && date.isBefore(_rangeEnd);
    if (!buffered) {
      _rangeStart = date.subtract(const Duration(days: 15));
      _rangeEnd = date.add(const Duration(days: 15));
      _fetchTasksForRange();
    }
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────
  DateTime _keyFor(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _hasTasks(DateTime d) => _groupedTasks.containsKey(_keyFor(d));

  List<DailyTaskEntry> get _tasksForSelectedDate =>
      _groupedTasks[_keyFor(_selectedDate)] ?? [];

  void _onDaySelected(DateTime date) {
    setState(() => _selectedDate = date);
    _ensureRangeCovers(date);
  }

  void _shiftWeek(int weeks) {
    final next = _selectedDate.add(Duration(days: weeks * 7));
    setState(() => _selectedDate = next);
    _ensureRangeCovers(next);
  }

  void _shiftDay(int days) {
    final next = _selectedDate.add(Duration(days: days));
    setState(() => _selectedDate = next);
    _ensureRangeCovers(next);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: CalendarDesign.primary,
              onPrimary: Colors.white,
              surface: CalendarDesign.surface,
              onSurface: CalendarDesign.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _ensureRangeCovers(picked);
    }
  }

  // ─────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: CalendarDesign.bg,
        body: _isLoading && _groupedTasks.isEmpty
            ? _buildSkeleton()
            : Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _error != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                color: CalendarDesign.primary,
                onRefresh: _fetchTasksForRange,
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    CalendarDesign.md,
                    CalendarDesign.md,
                    CalendarDesign.md,
                    CalendarDesign.lg,
                  ),
                  children: [
                    _buildDateNavigator(),
                    const SizedBox(height: CalendarDesign.md),
                    _buildSectionLabel(
                      'WEEK',
                      'Tap a day to view its tasks',
                    ),
                    const SizedBox(height:CalendarDesign.sm + 4),
                    _buildWeekStrip(),
                    const SizedBox(height:CalendarDesign.lg),
                    _buildSectionLabel(
                      DateFormat('MMMM yyyy')
                          .format(_selectedDate)
                          .toUpperCase(),
                      'Tap a day for details',
                    ),
                    const SizedBox(height:CalendarDesign.sm + 4),
                    _buildMonthGrid(),
                    const SizedBox(height:CalendarDesign.lg),
                    _buildSectionLabel(
                      'TASKS · ${DateFormat('MMM d').format(_selectedDate).toUpperCase()}',
                      _tasksForSelectedDate.isEmpty
                          ? 'Nothing logged for this day'
                          : '${_tasksForSelectedDate.length} ${_tasksForSelectedDate.length == 1 ? "entry" : "entries"} logged',
                    ),
                    const SizedBox(height:CalendarDesign.sm + 4),
                    if (_tasksForSelectedDate.isEmpty)
                      _buildEmptyState()
                    else
                      ..._tasksForSelectedDate.map(
                            (e) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: CalendarDesign.sm + 2),
                          child: _buildDailyEntryCard(e),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================
  Widget _buildHeader() {
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedDate);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CalendarDesign.primary, CalendarDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(CalendarDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: CalendarDesign.primary.withOpacity(0.25),
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
            CalendarDesign.md,
            CalendarDesign.sm,
            CalendarDesign.md,
            CalendarDesign.md,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(CalendarDesign.radiusSm),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(CalendarDesign.radiusSm),
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
              const SizedBox(width: CalendarDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Task History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(CalendarDesign.radiusSm),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(CalendarDesign.radiusSm),
                  onTap: _pickDate,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== SECTION LABEL =====================
  Widget _buildSectionLabel(String label, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: CalendarDesign.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: CalendarDesign.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: CalendarDesign.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: CalendarDesign.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================== DATE NAVIGATOR =====================
  Widget _buildDateNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CalendarDesign.sm,
        vertical: CalendarDesign.sm,
      ),
      decoration: BoxDecoration(
        color: CalendarDesign.surface,
        borderRadius: BorderRadius.circular(CalendarDesign.radiusLg),
        border: Border.all(color: CalendarDesign.border, width: 1),
        boxShadow: CalendarDesign.softShadow,
      ),
      child: Row(
        children: [
          _buildNavButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => _shiftDay(-1),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Text(
                    DateFormat('EEEE').format(_selectedDate).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: CalendarDesign.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CalendarDesign.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildNavButton(
            icon: Icons.chevron_right_rounded,
            onTap: () => _shiftDay(1),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: CalendarDesign.surfaceMuted,
      borderRadius: BorderRadius.circular(CalendarDesign.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(CalendarDesign.radiusSm),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: CalendarDesign.textSecondary,
          ),
        ),
      ),
    );
  }

  // ===================== WEEK STRIP =====================
  Widget _buildWeekStrip() {
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final days = List.generate(
      7,
          (i) => startOfWeek.add(Duration(days: i)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CalendarDesign.sm,
        vertical: CalendarDesign.sm + 2,
      ),
      decoration: BoxDecoration(
        color: CalendarDesign.surface,
        borderRadius: BorderRadius.circular(CalendarDesign.radiusLg),
        border: Border.all(color: CalendarDesign.border, width: 1),
        boxShadow: CalendarDesign.softShadow,
      ),
      child: Row(
        children: [
          _buildWeekNavArrow(
            icon: Icons.chevron_left_rounded,
            onTap: () => _shiftWeek(-1),
          ),
          Expanded(
            child: Row(
              children: days
                  .map((d) => Expanded(child: _buildWeekDay(d)))
                  .toList(),
            ),
          ),
          _buildWeekNavArrow(
            icon: Icons.chevron_right_rounded,
            onTap: () => _shiftWeek(1),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(CalendarDesign.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(CalendarDesign.radiusSm),
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 60,
          child: Icon(
            icon,
            size: 18,
            color: CalendarDesign.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDay(DateTime date) {
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final hasTasks = _hasTasks(date);

    return GestureDetector(
      onTap: () => _onDaySelected(date),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: CalendarDesign.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? CalendarDesign.primary
              : isToday
              ? CalendarDesign.primarySoft
              : Colors.transparent,
          borderRadius: BorderRadius.circular(CalendarDesign.radiusSm),
          border: Border.all(
            color: isSelected
                ? CalendarDesign.primary
                : isToday
                ? CalendarDesign.primaryLight
                : CalendarDesign.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: CalendarDesign.primary.withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              DateFormat('EEE').format(date).toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: isSelected
                    ? Colors.white.withOpacity(0.85)
                    : CalendarDesign.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: isSelected
                    ? Colors.white
                    : isToday
                    ? CalendarDesign.primaryDark
                    : CalendarDesign.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasTasks
                    ? (isSelected
                    ? Colors.white
                    : CalendarDesign.primary)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== MONTH GRID =====================
  Widget _buildMonthGrid() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final leading = firstDay.weekday - 1; // Mon=1 → 0 pad
    final daysInMonth = lastDay.day;

    final cells = <DateTime>[];
    for (int i = leading; i > 0; i--) {
      cells.add(firstDay.subtract(Duration(days: i)));
    }
    for (int i = 0; i < daysInMonth; i++) {
      cells.add(DateTime(_selectedDate.year, _selectedDate.month, i + 1));
    }
    // Fill trailing days
    int offset = 1;
    while (cells.length % 7 != 0) {
      cells.add(lastDay.add(Duration(days: offset)));
      offset++;
    }

    return Container(
      padding: const EdgeInsets.all(CalendarDesign.sm + 4),
      decoration: BoxDecoration(
        color: CalendarDesign.surface,
        borderRadius: BorderRadius.circular(CalendarDesign.radiusLg),
        border: Border.all(color: CalendarDesign.border, width: 1),
        boxShadow: CalendarDesign.softShadow,
      ),
      child: Column(
        children: [
          // Weekday header
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (d) => Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: CalendarDesign.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ),
            )
                .toList(),
          ),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: cells.length,
            itemBuilder: (context, index) =>
                _buildMonthDayCell(cells[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDayCell(DateTime date) {
    final isCurrentMonth = date.month == _selectedDate.month;
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final hasTasks = _hasTasks(date);

    return GestureDetector(
      onTap: () => _onDaySelected(date),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? CalendarDesign.primary
              : isToday
              ? CalendarDesign.primarySoft
              : Colors.transparent,
          borderRadius: BorderRadius.circular(CalendarDesign.radiusSm),
          border: Border.all(
            color: isSelected
                ? CalendarDesign.primary
                : isToday
                ? CalendarDesign.primaryLight
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight:
                isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : !isCurrentMonth
                    ? CalendarDesign.textMuted
                    : CalendarDesign.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasTasks
                    ? (isSelected
                    ? Colors.white
                    : CalendarDesign.primary)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== DAILY ENTRY CARD =====================
  Widget _buildDailyEntryCard(DailyTaskEntry entry) {
    final totalHours = entry.totalTime / 60;
    final hoursLabel = totalHours >= 1
        ? '${totalHours.toStringAsFixed(totalHours.truncateToDouble() == totalHours ? 0 : 1)}h'
        : '${entry.totalTime}m';

    return Container(
      padding: const EdgeInsets.all(CalendarDesign.md),
      decoration: BoxDecoration(
        color: CalendarDesign.surface,
        borderRadius: BorderRadius.circular(CalendarDesign.radiusLg),
        border: Border.all(color: CalendarDesign.border, width: 1),
        boxShadow: CalendarDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: status pill + hours
          Row(
            children: [
              _buildStatusPill(entry.status),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CalendarDesign.sm + 2,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: CalendarDesign.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: CalendarDesign.primaryLight,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: CalendarDesign.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hoursLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: CalendarDesign.primaryDark,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CalendarDesign.sm + 4),

          // Tasks list
          if (entry.tasks.isEmpty)
            _buildNoTasksRow()
          else
            ...entry.tasks.asMap().entries.map((e) {
              final idx = e.key;
              final task = e.value;
              final isLast = idx == entry.tasks.length - 1;
              return Padding(
                padding: EdgeInsets.only(
                    bottom: isLast ? 0 : CalendarDesign.sm),
                child: _buildTaskRow(task, idx + 1),
              );
            }),

          // Notes
          if ((entry.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: CalendarDesign.sm + 4),
            Container(
              padding: const EdgeInsets.all(CalendarDesign.sm + 4),
              decoration: BoxDecoration(
                color: CalendarDesign.warningSoft,
                borderRadius:
                BorderRadius.circular(CalendarDesign.radiusMd),
                border: Border.all(
                  color: CalendarDesign.warningBorder,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 14,
                    color: CalendarDesign.warning,
                  ),
                  const SizedBox(width: CalendarDesign.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NOTES',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: CalendarDesign.primaryDark,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.notes!.trim(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: CalendarDesign.textPrimary,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskRow(TaskItem task, int index) {
    final accent = _categoryColor(task.category);

    return Container(
      padding: const EdgeInsets.all(CalendarDesign.sm + 4),
      decoration: BoxDecoration(
        color: CalendarDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(CalendarDesign.radiusMd),
        border: Border.all(color: CalendarDesign.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number badge
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: accent.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: accent,
                letterSpacing: -0.1,
              ),
            ),
          ),
          const SizedBox(width: CalendarDesign.sm + 2),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title.isEmpty ? 'Untitled Task' : task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: CalendarDesign.textPrimary,
                    letterSpacing: -0.2,
                    height: 1.3,
                  ),
                ),
                if (task.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: CalendarDesign.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: CalendarDesign.sm),
                Row(
                  children: [
                    _buildCategoryPill(task.category),
                    const SizedBox(width: CalendarDesign.sm),
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: CalendarDesign.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(task.timeSpent),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: CalendarDesign.primaryDark,
                      ),
                    ),
                    if (task.project.trim().isNotEmpty) ...[
                      const SizedBox(width: CalendarDesign.sm),
                      Icon(
                        Icons.work_outline_rounded,
                        size: 12,
                        color: CalendarDesign.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          task.project,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: CalendarDesign.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(TaskCategory category) {
    final color = _categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Text(
        _formatCategory(category).toUpperCase(),
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusPill(TaskStatus status) {
    final (soft, border, fg, icon, label) = switch (status) {
      TaskStatus.draft => (
      CalendarDesign.warningSoft,
      CalendarDesign.warningBorder,
      CalendarDesign.warning,
      Icons.edit_outlined,
      'Draft',
      ),
      TaskStatus.submitted => (
      CalendarDesign.successSoft,
      CalendarDesign.successBorder,
      CalendarDesign.success,
      Icons.send_rounded,
      'Submitted',
      ),
      TaskStatus.approved => (
      CalendarDesign.infoSoft,
      CalendarDesign.infoBorder,
      CalendarDesign.info,
      Icons.verified_rounded,
      'Approved',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTasksRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CalendarDesign.md,
        vertical: CalendarDesign.sm + 4,
      ),
      decoration: BoxDecoration(
        color: CalendarDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(CalendarDesign.radiusMd),
        border: Border.all(color: CalendarDesign.border, width: 1),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 14,
            color: CalendarDesign.textMuted,
          ),
          SizedBox(width: CalendarDesign.sm),
          Text(
            'No individual tasks recorded',
            style: TextStyle(
              fontSize: 12,
              color: CalendarDesign.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== EMPTY / ERROR =====================
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(CalendarDesign.xl),
      decoration: BoxDecoration(
        color: CalendarDesign.surface,
        borderRadius: BorderRadius.circular(CalendarDesign.radiusLg),
        border: Border.all(color: CalendarDesign.border, width: 1),
        boxShadow: CalendarDesign.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CalendarDesign.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: CalendarDesign.primaryLight,
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 30,
              color: CalendarDesign.primary,
            ),
          ),
          const SizedBox(height: CalendarDesign.md),
          const Text(
            'No entries for this date',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: CalendarDesign.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick another day or submit tasks\nfrom the Daily Tasks screen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: CalendarDesign.textMuted,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CalendarDesign.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: CalendarDesign.dangerSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: CalendarDesign.dangerBorder,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: CalendarDesign.danger,
              ),
            ),
            const SizedBox(height: CalendarDesign.lg),
            const Text(
              'Unable to Load',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: CalendarDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: CalendarDesign.sm),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: CalendarDesign.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: CalendarDesign.lg),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _fetchTasksForRange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CalendarDesign.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: CalendarDesign.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(CalendarDesign.radiusMd),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== SKELETON =====================
  Widget _buildSkeleton() {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: Color(0xFFE8EAEE),
        highlightColor: Color(0xFFF6F7FB),
        duration: Duration(milliseconds: 1200),
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(CalendarDesign.radiusXl),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  CalendarDesign.md,
                  CalendarDesign.sm,
                  CalendarDesign.md,
                  CalendarDesign.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            CalendarDesign.radiusSm),
                      ),
                    ),
                    const SizedBox(width: CalendarDesign.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 140,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 100,
                            height: 11,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(CalendarDesign.md),
              children: [
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(CalendarDesign.radiusLg),
                  ),
                ),
                const SizedBox(height: CalendarDesign.md),
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(CalendarDesign.radiusLg),
                  ),
                ),
                const SizedBox(height: CalendarDesign.md),
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(CalendarDesign.radiusLg),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HELPERS =====================
  Color _categoryColor(TaskCategory c) {
    switch (c) {
      case TaskCategory.development:
        return const Color(0xFF4F46E5);
      case TaskCategory.meeting:
        return const Color(0xFF059669);
      case TaskCategory.testing:
        return const Color(0xFFDC2626);
      case TaskCategory.documentation:
        return const Color(0xFFD97706);
      case TaskCategory.research:
        return const Color(0xFF7C3AED);
      case TaskCategory.support:
        return const Color(0xFF0D9488);
      case TaskCategory.other:
        return const Color(0xFF6B7280);
    }
  }

  String _formatCategory(TaskCategory c) {
    switch (c) {
      case TaskCategory.development:
        return 'Development';
      case TaskCategory.meeting:
        return 'Meeting';
      case TaskCategory.testing:
        return 'Testing';
      case TaskCategory.documentation:
        return 'Documentation';
      case TaskCategory.research:
        return 'Research';
      case TaskCategory.support:
        return 'Support';
      case TaskCategory.other:
        return 'Other';
    }
  }

  String _formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    return '${m}m';
  }
}