import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/holiday_api.dart';

// ===================== SHARED DESIGN TOKENS =====================
class HolidayDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // Primary indigo palette (matches Reports module)
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color primaryLight = Color(0xFFC7D2FE);

  // Accent — celebration pink/rose
  static const Color accent = Color(0xFFE11D48);
  static const Color accentSoft = Color(0xFFFFE4E6);
  static const Color accentBorder = Color(0xFFFECDD3);

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Semantic
  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);

  static const Color teal = Color(0xFF0D9488);
  static const Color tealSoft = Color(0xFFF0FDFA);
  static const Color tealBorder = Color(0xFF99F6E4);

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

  static List<BoxShadow> get imageShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
}

class PremiumHolidayCalendar extends StatefulWidget {
  const PremiumHolidayCalendar({super.key});

  @override
  State<PremiumHolidayCalendar> createState() => _PremiumHolidayCalendarState();
}

class _PremiumHolidayCalendarState extends State<PremiumHolidayCalendar>
    with TickerProviderStateMixin {
  // Updated to store full holiday data including images
  Map<DateTime, List<Map<String, dynamic>>> _holidays = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late AnimationController _fadeController;

  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _focusedDay = _convertToIST(DateTime.now());
    _loadHolidays(_focusedDay.year, _focusedDay.month);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ===================== IST HELPERS =====================

  DateTime _convertToIST(DateTime utcDateTime) {
    return utcDateTime.toUtc().add(_istOffset);
  }

  DateTime _getCurrentIST() {
    return _convertToIST(DateTime.now().toUtc());
  }

  DateTime _normalizeDateIST(DateTime dateTime) {
    final istDate = _convertToIST(dateTime);
    return DateTime(istDate.year, istDate.month, istDate.day);
  }

  DateTime _createDateKey(int year, int month, int day) {
    return DateTime(year, month, day);
  }

  // ===================== DATA =====================

  Future<void> _loadHolidays(int year, int month) async {
    setState(() => _loading = true);

    try {
      final service = HolidayService();
      final holidays = await service.fetchHolidays(year: year, month: month);

      debugPrint('📦 Received ${holidays.length} holidays for $year-$month');

      final Map<DateTime, List<Map<String, dynamic>>> processedHolidays = {};

      for (var holiday in holidays) {
        DateTime holidayDate;

        final raw = holiday['date'];
        if (raw is DateTime) {
          // Convert UTC ISO string → IST calendar day
          holidayDate = raw.isUtc
              ? _normalizeDateIST(raw)
              : DateTime(raw.year, raw.month, raw.day);
        } else if (raw is String) {
          final parsed = DateTime.parse(raw).toUtc();
          holidayDate = _normalizeDateIST(parsed);
        } else {
          debugPrint('⚠️ Skipping holiday with invalid date: $holiday');
          continue;
        }

        processedHolidays.putIfAbsent(holidayDate, () => []);
        processedHolidays[holidayDate]!.add(holiday);
      }

      if (!mounted) return;
      setState(() {
        _holidays = processedHolidays;
        _loading = false;
      });

      _fadeController.forward();
    } catch (e, stack) {
      debugPrint('❌ _loadHolidays error: $e');
      debugPrint('$stack');
      if (!mounted) return;
      setState(() => _loading = false);
      _showErrorSnackBar("Failed to load holidays: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: HolidayDesign.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: HolidayDesign.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(HolidayDesign.md),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = _createDateKey(day.year, day.month, day.day);
    return _holidays[normalizedDay] ?? [];
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: HolidayDesign.bg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? _buildSkeletonLoader()
                  : FadeTransition(
                opacity: _fadeController,
                child: _buildCalendarContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HolidayDesign.primary, HolidayDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(HolidayDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: HolidayDesign.primary.withOpacity(0.25),
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
            HolidayDesign.md,
            HolidayDesign.sm,
            HolidayDesign.md,
            HolidayDesign.md,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
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
              const SizedBox(width: HolidayDesign.sm + 4),

              const Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Holiday Calendar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(width: HolidayDesign.sm),
                    _IstBadge(),
                  ],
                ),
              ),

              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
                  onTap: () {
                    final currentIST = _getCurrentIST();
                    setState(() {
                      _focusedDay = currentIST;
                      _selectedDay = currentIST;
                    });
                    _loadHolidays(currentIST.year, currentIST.month);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.today_rounded,
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

  // ===================== SKELETON =====================

  Widget _buildSkeletonLoader() {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: HolidayDesign.surfaceMuted,
        highlightColor: HolidayDesign.border,
        duration: Duration(seconds: 1),
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(HolidayDesign.md),
        child: Column(
          children: [
            // Calendar skeleton
            Container(
              height: 360,
              padding: const EdgeInsets.all(HolidayDesign.md),
              decoration: BoxDecoration(
                color: HolidayDesign.surface,
                borderRadius: BorderRadius.circular(HolidayDesign.radiusXl),
                border: Border.all(color: HolidayDesign.border, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: HolidayDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 22,
                        decoration: BoxDecoration(
                          color: HolidayDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: HolidayDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HolidayDesign.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      7,
                          (_) => Container(
                        width: 28,
                        height: 14,
                        decoration: BoxDecoration(
                          color: HolidayDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: HolidayDesign.md),
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 42,
                      itemBuilder: (_, __) => Container(
                        decoration: BoxDecoration(
                          color: HolidayDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HolidayDesign.md),
            // Events skeleton with image placeholder
            Container(
              padding: const EdgeInsets.all(HolidayDesign.md),
              decoration: BoxDecoration(
                color: HolidayDesign.surface,
                borderRadius: BorderRadius.circular(HolidayDesign.radiusXl),
                border: Border.all(color: HolidayDesign.border, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: HolidayDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
                        ),
                      ),
                      const SizedBox(width: HolidayDesign.sm + 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 16,
                              decoration: BoxDecoration(
                                color: HolidayDesign.surfaceMuted,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 180,
                              height: 12,
                              decoration: BoxDecoration(
                                color: HolidayDesign.surfaceMuted,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HolidayDesign.md),
                  ...List.generate(
                    3,
                        (i) => Container(
                      margin: const EdgeInsets.only(bottom: HolidayDesign.sm + 4),
                      height: 160,
                      decoration: BoxDecoration(
                        color: HolidayDesign.surfaceMuted,
                        borderRadius: BorderRadius.circular(HolidayDesign.radiusMd),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== CALENDAR CONTENT =====================

  Widget _buildCalendarContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(HolidayDesign.md),
      child: Column(
        children: [
          _buildCalendarCard(),
          const SizedBox(height: HolidayDesign.md),
          _buildEventsList(),
        ],
      ),
    );
  }

  // ===================== CALENDAR CARD =====================

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: HolidayDesign.surface,
        borderRadius: BorderRadius.circular(HolidayDesign.radiusXl),
        border: Border.all(color: HolidayDesign.border, width: 1),
        boxShadow: HolidayDesign.softShadow,
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          Container(height: 1, color: HolidayDesign.border),
          TableCalendar<Map<String, dynamic>>(
            firstDay: DateTime(2023, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              if (_selectedDay == null) return false;
              final selectedIST = _createDateKey(
                _selectedDay!.year,
                _selectedDay!.month,
                _selectedDay!.day,
              );
              final dayIST = _createDateKey(day.year, day.month, day.day);
              return isSameDay(selectedIST, dayIST);
            },
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronVisible: false,
              rightChevronVisible: false,
              titleTextStyle: TextStyle(fontSize: 0),
              headerPadding: EdgeInsets.zero,
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(
                color: HolidayDesign.accent,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
              holidayTextStyle: const TextStyle(
                color: HolidayDesign.accent,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
              defaultTextStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: HolidayDesign.textPrimary,
              ),
              todayDecoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    HolidayDesign.primary,
                    HolidayDesign.primaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: HolidayDesign.primary.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                    spreadRadius: -2,
                  ),
                ],
              ),
              todayTextStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: Colors.white,
              ),
              selectedDecoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    HolidayDesign.accent,
                    HolidayDesign.accent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: HolidayDesign.accent.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                    spreadRadius: -2,
                  ),
                ],
              ),
              selectedTextStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: Colors.white,
              ),
              markersMaxCount: 1,
              markerSize: 6.0,
              markersOffset: const PositionedOffset(bottom: 4, start: 0),
              cellMargin: const EdgeInsets.all(4),
              cellPadding: EdgeInsets.zero,
              tablePadding: const EdgeInsets.all(HolidayDesign.md),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: const TextStyle(
                color: HolidayDesign.textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              weekendStyle: TextStyle(
                color: HolidayDesign.accent.withOpacity(0.6),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
              _loadHolidays(focusedDay.year, focusedDay.month);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: HolidayDesign.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
              todayBuilder: (context, date, _) {
                final currentIST = _getCurrentIST();
                final isToday = isSameDay(date, currentIST);
                if (!isToday) return null;

                return Container(
                  margin: const EdgeInsets.all(2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        HolidayDesign.primary,
                        HolidayDesign.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: HolidayDesign.primary.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Text(
                    date.day.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===================== CALENDAR HEADER =====================

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HolidayDesign.md,
        HolidayDesign.md,
        HolidayDesign.md,
        HolidayDesign.sm,
      ),
      child: Row(
        children: [
          _buildNavButton(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              final newFocusedDay = DateTime(
                _focusedDay.year,
                _focusedDay.month - 1,
              );
              setState(() => _focusedDay = newFocusedDay);
              _loadHolidays(newFocusedDay.year, newFocusedDay.month);
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  "${_getMonthName(_focusedDay.month)} ${_focusedDay.year}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: HolidayDesign.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap a date to view holidays',
                  style: TextStyle(
                    fontSize: 11,
                    color: HolidayDesign.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildNavButton(
            icon: Icons.chevron_right_rounded,
            onTap: () {
              final newFocusedDay = DateTime(
                _focusedDay.year,
                _focusedDay.month + 1,
              );
              setState(() => _focusedDay = newFocusedDay);
              _loadHolidays(newFocusedDay.year, newFocusedDay.month);
            },
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
      color: HolidayDesign.primarySoft,
      borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
            border: Border.all(
              color: HolidayDesign.primaryLight,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: HolidayDesign.primary,
          ),
        ),
      ),
    );
  }

  // ===================== EVENTS LIST =====================

  Widget _buildEventsList() {
    final selectedDate = _selectedDay ?? _focusedDay;
    final events = _getEventsForDay(selectedDate);

    return Container(
      decoration: BoxDecoration(
        color: HolidayDesign.surface,
        borderRadius: BorderRadius.circular(HolidayDesign.radiusXl),
        border: Border.all(color: HolidayDesign.border, width: 1),
        boxShadow: HolidayDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(HolidayDesign.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: HolidayDesign.primarySoft,
                    borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
                    border: Border.all(
                      color: HolidayDesign.primaryLight,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: HolidayDesign.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: HolidayDesign.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Holiday Events',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: HolidayDesign.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '${events.length} ${events.length == 1 ? 'event' : 'events'}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: HolidayDesign.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: HolidayDesign.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatEventDate(selectedDate),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: HolidayDesign.textMuted,
                              fontWeight: FontWeight.w600,
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
          Container(height: 1, color: HolidayDesign.border),

          // Content
          if (events.isEmpty)
            _buildEmptyState()
          else
            Padding(
              padding: const EdgeInsets.all(HolidayDesign.md - 2),
              child: AnimationLimiter(
                child: Column(
                  children: List.generate(
                    events.length,
                        (index) => AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: 30,
                        child: FadeInAnimation(
                          child: _buildEventCardWithImage(
                            events[index],
                            index,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(HolidayDesign.xl),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: HolidayDesign.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 36,
                color: HolidayDesign.textMuted,
              ),
            ),
            const SizedBox(height: HolidayDesign.md),
            const Text(
              'No holidays',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: HolidayDesign.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: HolidayDesign.xs + 2),
            const Text(
              'Select another date to view holidays',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: HolidayDesign.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== EVENT CARD WITH IMAGE =====================

  Widget _buildEventCardWithImage(Map<String, dynamic> event, int index) {
    final hasImage = event['hasImage'] == true && event['imageUrl'] != null;
    final isMandatory = event['isMandatory'] == true;
    final isRestricted = event['isRestricted'] == true;

    // Color based on type/category
    final palettes = [
      (HolidayDesign.primary, HolidayDesign.primarySoft, HolidayDesign.primaryLight),
      (HolidayDesign.accent, HolidayDesign.accentSoft, HolidayDesign.accentBorder),
      (HolidayDesign.teal, HolidayDesign.tealSoft, HolidayDesign.tealBorder),
      (HolidayDesign.warning, HolidayDesign.warningSoft, HolidayDesign.warningBorder),
      (HolidayDesign.info, HolidayDesign.infoSoft, HolidayDesign.infoBorder),
    ];

    final (color, bg, border) = palettes[index % palettes.length];

    return Container(
      margin: const EdgeInsets.only(bottom: HolidayDesign.md),
      decoration: BoxDecoration(
        color: HolidayDesign.surface,
        borderRadius: BorderRadius.circular(HolidayDesign.radiusLg),
        border: Border.all(color: HolidayDesign.border, width: 1),
        boxShadow: HolidayDesign.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HolidayDesign.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================== IMAGE SECTION =====================
            if (hasImage)
              _buildImageHeader(event, color),
            // ===================== CONTENT SECTION =====================
            Padding(
              padding: EdgeInsets.all(hasImage ? HolidayDesign.md : HolidayDesign.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['name'] ?? 'Holiday',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: HolidayDesign.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Type + Category badges
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildTypeBadge(event['type'] ?? 'General', color, bg, border),
                                if (isMandatory)
                                  _buildStatusBadge(
                                    'Mandatory',
                                    HolidayDesign.success,
                                    HolidayDesign.successSoft,
                                    HolidayDesign.successBorder,
                                  ),
                                if (isRestricted)
                                  _buildStatusBadge(
                                    'Restricted',
                                    HolidayDesign.warning,
                                    HolidayDesign.warningSoft,
                                    HolidayDesign.warningBorder,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Weekday badge
                      if (event['weekday'] != null && event['weekday'].isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: HolidayDesign.sm + 2,
                            vertical: HolidayDesign.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: HolidayDesign.surfaceMuted,
                            borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
                            border: Border.all(
                              color: HolidayDesign.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            event['weekday'].substring(0, 3).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: HolidayDesign.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: HolidayDesign.sm + 2),
                  // Description
                  Text(
                    event['description'] ?? 'No description available',
                    style: const TextStyle(
                      fontSize: 13,
                      color: HolidayDesign.textSecondary,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Max allowed info for restricted holidays
                  if (isRestricted && event['maxAllowed'] != null) ...[
                    const SizedBox(height: HolidayDesign.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: HolidayDesign.sm + 2,
                        vertical: HolidayDesign.xs + 2,
                      ),
                      decoration: BoxDecoration(
                        color: HolidayDesign.warningSoft,
                        borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
                        border: Border.all(
                          color: HolidayDesign.warningBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: HolidayDesign.warning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Max ${event['maxAllowed']} allowed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: HolidayDesign.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader(Map<String, dynamic> event, Color color) {
    return Stack(
      children: [
        // Main image — taller box (240) for square source images
        SizedBox(
          height: 320,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: event['imageUrl'],
            fit: BoxFit.cover,
            alignment: Alignment.center,
            placeholder: (context, url) => Container(
              color: HolidayDesign.surfaceMuted,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: HolidayDesign.surfaceMuted,
              child: const Center(
                child: Icon(
                  Icons.image_not_supported_rounded,
                  color: HolidayDesign.textMuted,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        // Gradient overlay for text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.65),
                ],
              ),
            ),
          ),
        ),
        // Type badge on image
        Positioned(
          top: HolidayDesign.sm + 4,
          left: HolidayDesign.sm + 4,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: HolidayDesign.sm + 2,
              vertical: HolidayDesign.xs + 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(HolidayDesign.radiusSm),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  event['type'] ?? 'General',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Celebration icon on image
        Positioned(
          bottom: HolidayDesign.sm + 4,
          right: HolidayDesign.sm + 4,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildTypeBadge(String type, Color color, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HolidayDesign.sm + 2,
        vertical: HolidayDesign.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(HolidayDesign.radiusSm - 2),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HolidayDesign.sm,
        vertical: HolidayDesign.xs - 1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(HolidayDesign.radiusSm - 4),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ===================== HELPERS =====================

  String _formatEventDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November',
      'December'
    ];
    return months[month - 1];
  }
}

// ===================== IST BADGE =====================

class _IstBadge extends StatelessWidget {
  const _IstBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HolidayDesign.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: const Text(
        'IST',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}