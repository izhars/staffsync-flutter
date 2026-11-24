import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../component/daily_report_widget.dart';
import '../component/monthly_report_widget.dart';
import '../component/monthly_work_hours_bottom_sheet.dart';
import '../component/weekly_report_widget.dart';
import '../services/attendance_api.dart';

// ===================== SHARED DESIGN TOKENS =====================
class ReportDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // Primary indigo palette (matches original report theme, refined)
  static const Color primary = Color(0xFF4F46E5); // indigo-600
  static const Color primaryDark = Color(0xFF4338CA); // indigo-700
  static const Color primarySoft = Color(0xFFEEF2FF); // indigo-50
  static const Color primaryLight = Color(0xFFC7D2FE); // indigo-200

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Attendance semantic colors
  static const Color present = Color(0xFF059669); // emerald
  static const Color presentSoft = Color(0xFFECFDF5);
  static const Color presentBorder = Color(0xFFA7F3D0);

  static const Color late = Color(0xFFD97706); // amber
  static const Color lateSoft = Color(0xFFFFFBEB);
  static const Color lateBorder = Color(0xFFFDE68A);

  static const Color short = Color(0xFFEA580C); // orange
  static const Color shortSoft = Color(0xFFFFF7ED);
  static const Color shortBorder = Color(0xFFFED7AA);

  static const Color absent = Color(0xFFDC2626); // red
  static const Color absentSoft = Color(0xFFFEF2F2);
  static const Color absentBorder = Color(0xFFFECACA);

  static const Color leave = Color(0xFF7C3AED); // violet
  static const Color leaveSoft = Color(0xFFF5F3FF);
  static const Color leaveBorder = Color(0xFFDDD6FE);

  static const Color holiday = Color(0xFF2563EB); // blue
  static const Color holidaySoft = Color(0xFFEFF6FF);
  static const Color holidayBorder = Color(0xFFBFDBFE);

  static const Color comboOff = Color(0xFF0D9488); // teal
  static const Color comboOffSoft = Color(0xFFF0FDFA);
  static const Color comboOffBorder = Color(0xFF99F6E4);

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

  // ===================== STATUS → COLOR =====================

  static (Color, Color, Color) statusStyle(
      String status, {
        bool? isLate,
        bool? isShortAttendance,
      }) {
    if (isShortAttendance == true) {
      return (short, shortSoft, shortBorder);
    }
    if (isLate == true) {
      return (late, lateSoft, lateBorder);
    }

    switch (status.toLowerCase()) {
      case 'present':
        return (present, presentSoft, presentBorder);
      case 'absent':
        return (absent, absentSoft, absentBorder);
      case 'half-day':
      case 'halfday':
        return (short, shortSoft, shortBorder);
      case 'on-leave':
        return (leave, leaveSoft, leaveBorder);
      case 'public-holiday':
      case 'holiday':
        return (holiday, holidaySoft, holidayBorder);
      case 'combo-off':
        return (comboOff, comboOffSoft, comboOffBorder);
      case 'weekly-off':
      case 'weeklyoff':
        return (leave, leaveSoft, leaveBorder);
      case 'non-working-day':
      default:
        return (neutral, neutralSoft, neutralBorder);
    }
  }

  static Color statusMarkerColor(
      String status, {
        bool? isLate,
        bool? isShortAttendance,
      }) {
    return statusStyle(status,
        isLate: isLate, isShortAttendance: isShortAttendance)
        .$1;
  }
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Calendar', 'icon': Icons.calendar_month_outlined},
    {'label': 'Daily', 'icon': Icons.today_outlined},
    {'label': 'Weekly', 'icon': Icons.date_range_outlined},
    {'label': 'Monthly', 'icon': Icons.calendar_view_month_outlined},
  ];

  Map<String, dynamic>? _attendanceData;
  bool _isLoading = true;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _attendanceEvents = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _selectedIndex = _tabController.index);
    });
    _loadAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendance({int? month, int? year}) async {
    setState(() => _isLoading = true);
    try {
      final data = await _attendanceService.fetchMyAttendance(
        month: month ?? _focusedDay.month,
        year: year ?? _focusedDay.year,
      );
      if (!mounted) return;
      setState(() {
        _attendanceData = data;
        _isLoading = false;
        _processAttendanceEvents();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attendanceData = null;
        _isLoading = false;
      });
      print('Error loading attendance: $e');
    }
  }

  void _processAttendanceEvents() {
    if (_attendanceData == null || _attendanceData!['attendance'] == null) {
      return;
    }

    _attendanceEvents.clear();
    final attendanceList = _attendanceData!['attendance'] as List<dynamic>;

    for (var attendance in attendanceList) {
      final dateStr = attendance['date'];
      if (dateStr != null) {
        final date = DateTime.parse(dateStr).toLocal();
        final normalizedDate = DateTime(date.year, date.month, date.day);

        if (_attendanceEvents[normalizedDate] != null) {
          _attendanceEvents[normalizedDate]!.add(attendance);
        } else {
          _attendanceEvents[normalizedDate] = [attendance];
        }
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _attendanceEvents[normalizedDay] ?? [];
  }

  // ===================== CALENDAR DAY CELL =====================

  /// Builds a fully-filled calendar day cell colored by attendance status.
  Widget _buildDayCell(
      DateTime day, {
        required bool isToday,
        required bool isSelected,
      }) {
    final events = _getEventsForDay(day);

    // Day with no attendance record
    if (events.isEmpty) {
      final isWeekend = day.weekday == DateTime.saturday ||
          day.weekday == DateTime.sunday;

      return Container(
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? ReportDesign.primary
              : isToday
              ? ReportDesign.primaryLight
              : null,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : isToday
                ? ReportDesign.primaryDark
                : isWeekend
                ? ReportDesign.absent.withOpacity(0.7)
                : ReportDesign.textPrimary,
          ),
        ),
      );
    }

    final event = events.first;
    final (color, _, _) = _statusStyle(
      event['status']?.toString() ?? '',
      isLate: event['isLate'] == true,
      isShortAttendance: event['isShortAttendance'] == true,
    );

    return Container(
      margin: const EdgeInsets.all(3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Selected = solid status color, otherwise a visible tinted fill
        color: isSelected ? color : color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday
              ? ReportDesign.textPrimary
              : (isSelected ? color : color.withOpacity(0.55)),
          width: isToday ? 2 : 1.2,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: -2,
          ),
        ]
            : null,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: isSelected ? Colors.white : color,
        ),
      ),
    );
  }

  // ===================== STATUS → COLOR =====================

  (Color, Color, Color) _statusStyle(
      String status, {
        bool? isLate,
        bool? isShortAttendance,
      }) {
    if (isShortAttendance == true) {
      return (
      ReportDesign.short,
      ReportDesign.shortSoft,
      ReportDesign.shortBorder
      );
    }
    if (isLate == true) {
      return (
      ReportDesign.late,
      ReportDesign.lateSoft,
      ReportDesign.lateBorder
      );
    }

    switch (status.toLowerCase()) {
      case 'present':
        return (
        ReportDesign.present,
        ReportDesign.presentSoft,
        ReportDesign.presentBorder
        );
      case 'absent':
        return (
        ReportDesign.absent,
        ReportDesign.absentSoft,
        ReportDesign.absentBorder
        );
      case 'half-day':
      case 'halfday':
        return (
        ReportDesign.short,
        ReportDesign.shortSoft,
        ReportDesign.shortBorder
        );
      case 'on-leave':
        return (
        ReportDesign.leave,
        ReportDesign.leaveSoft,
        ReportDesign.leaveBorder
        );
      case 'public-holiday':
      case 'holiday':
        return (
        ReportDesign.holiday,
        ReportDesign.holidaySoft,
        ReportDesign.holidayBorder
        );
      case 'combo-off':
        return (
        ReportDesign.comboOff,
        ReportDesign.comboOffSoft,
        ReportDesign.comboOffBorder
        );
      case 'weekly-off':
      case 'weeklyoff':
        return (
        ReportDesign.leave,
        ReportDesign.leaveSoft,
        ReportDesign.leaveBorder
        );
      case 'non-working-day':
      default:
        return (
        ReportDesign.neutral,
        ReportDesign.neutralSoft,
        ReportDesign.neutralBorder
        );
    }
  }

  Color _statusMarkerColor(
      String status, {
        bool? isLate,
        bool? isShortAttendance,
      }) {
    return _statusStyle(status,
        isLate: isLate, isShortAttendance: isShortAttendance)
        .$1;
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ReportDesign.bg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildSkeletonLoading()
                  : (_attendanceData == null ||
                  _attendanceData!['success'] != true)
                  ? _buildErrorWidget()
                  : TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildCalendarView(),
                  DailyReportWidget(
                    attendanceList: _attendanceData!['attendance']
                    as List<dynamic>? ??
                        [],
                    onRefresh: _loadAttendance,
                  ),
                  WeeklyReportWidget(
                    attendanceList: _attendanceData!['attendance']
                    as List<dynamic>? ??
                        [],
                    onRefresh: _loadAttendance,
                  ),
                  MonthlyReportWidget(
                    attendanceList: _attendanceData!['attendance']
                    as List<dynamic>? ??
                        [],
                    onRefresh: _loadAttendance,
                  ),
                ],
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
          colors: [ReportDesign.primary, ReportDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(ReportDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: ReportDesign.primary.withOpacity(0.25),
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
            ReportDesign.md,
            ReportDesign.sm,
            ReportDesign.md,
            ReportDesign.md,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Back button
                  Material(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(ReportDesign.radiusSm),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(ReportDesign.radiusSm),
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
                  const SizedBox(width: ReportDesign.sm + 4),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Reports',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Track your work history',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Refresh button
                  Material(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(ReportDesign.radiusSm),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(ReportDesign.radiusSm),
                      onTap: () => _loadAttendance(),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: ReportDesign.md),

              // Segmented tab bar
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius:
                  BorderRadius.circular(ReportDesign.radiusMd),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: ReportDesign.surface,
                    borderRadius:
                    BorderRadius.circular(ReportDesign.radiusSm),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  labelColor: ReportDesign.primary,
                  unselectedLabelColor: Colors.white.withOpacity(0.85),
                  labelPadding: EdgeInsets.zero,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor:
                  MaterialStateProperty.all(Colors.transparent),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: -0.1,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: -0.1,
                  ),
                  tabs: _tabs.map((tab) {
                    return Tab(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(tab['icon'] as IconData, size: 15),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              tab['label'] as String,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== ERROR =====================

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ReportDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: ReportDesign.absentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 46,
                color: ReportDesign.absent,
              ),
            ),
            const SizedBox(height: ReportDesign.lg),
            const Text(
              'Failed to load reports',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ReportDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: ReportDesign.sm),
            const Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: ReportDesign.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: ReportDesign.lg),
            ElevatedButton.icon(
              onPressed: () => _loadAttendance(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ReportDesign.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: ReportDesign.lg,
                  vertical: ReportDesign.sm + 4,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(ReportDesign.radiusSm),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== SKELETON =====================

  Widget _buildSkeletonLoading() {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(ReportDesign.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skeletonCard(
              height: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Status Legend',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: ReportDesign.md),
                  Wrap(
                    spacing: ReportDesign.sm,
                    runSpacing: ReportDesign.sm,
                    children: List.generate(
                      6,
                          (i) => Container(
                        width: 80,
                        height: 28,
                        decoration: BoxDecoration(
                          color: ReportDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ReportDesign.md),
            _skeletonCard(
              height: 340,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 100,
                        height: 18,
                        decoration: BoxDecoration(
                          color: ReportDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 28,
                        decoration: BoxDecoration(
                          color: ReportDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ReportDesign.md),
                  SizedBox(
                    height: 250,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: 42,
                      itemBuilder: (_, __) => Container(
                        decoration: BoxDecoration(
                          color: ReportDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ReportDesign.md),
            _skeletonCard(
              height: 200,
              child: Column(
                children: [
                  Container(
                    width: 180,
                    height: 16,
                    decoration: BoxDecoration(
                      color: ReportDesign.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: ReportDesign.md),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: ReportDesign.sm,
                      mainAxisSpacing: ReportDesign.sm,
                    ),
                    itemCount: 6,
                    itemBuilder: (_, __) => Container(
                      decoration: BoxDecoration(
                        color: ReportDesign.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
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

  Widget _skeletonCard({required double height, required Widget child}) {
    return Container(
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.all(ReportDesign.md),
      decoration: BoxDecoration(
        color: ReportDesign.surface,
        borderRadius: BorderRadius.circular(ReportDesign.radiusLg),
        border: Border.all(color: ReportDesign.border, width: 1),
      ),
      child: child,
    );
  }

  // ===================== CALENDAR VIEW =====================

  Widget _buildCalendarView() {
    return RefreshIndicator(
      onRefresh: () => _loadAttendance(),
      color: ReportDesign.primary,
      backgroundColor: ReportDesign.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ReportDesign.md,
          ReportDesign.md,
          ReportDesign.md,
          ReportDesign.xl,
        ),
        child: Column(
          children: [
            _buildLegendCard(),
            const SizedBox(height: ReportDesign.md),
            _buildCalendarCard(),
            if (_selectedDay != null) ...[
              const SizedBox(height: ReportDesign.md),
              _buildSelectedDayEvents(),
            ],
            const SizedBox(height: ReportDesign.md),
            _buildStatsOverview(),
          ],
        ),
      ),
    );
  }

  // ===================== LEGEND =====================

  Widget _buildLegendCard() {
    return Container(
      padding: const EdgeInsets.all(ReportDesign.md),
      decoration: BoxDecoration(
        color: ReportDesign.surface,
        borderRadius: BorderRadius.circular(ReportDesign.radiusLg),
        border: Border.all(color: ReportDesign.border, width: 1),
        boxShadow: ReportDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ReportDesign.primarySoft,
                  borderRadius:
                  BorderRadius.circular(ReportDesign.radiusSm - 2),
                  border: Border.all(
                    color: ReportDesign.primaryLight,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: ReportDesign.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: ReportDesign.sm + 2),
              const Text(
                'Status Legend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ReportDesign.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: ReportDesign.md),
          Wrap(
            spacing: ReportDesign.sm,
            runSpacing: ReportDesign.sm,
            children: [
              _legendItem('Present', ReportDesign.present,
                  ReportDesign.presentSoft, ReportDesign.presentBorder),
              _legendItem('Late', ReportDesign.late, ReportDesign.lateSoft,
                  ReportDesign.lateBorder),
              _legendItem('Short', ReportDesign.short, ReportDesign.shortSoft,
                  ReportDesign.shortBorder),
              _legendItem('Absent', ReportDesign.absent,
                  ReportDesign.absentSoft, ReportDesign.absentBorder),
              _legendItem('Half Day', ReportDesign.short,
                  ReportDesign.shortSoft, ReportDesign.shortBorder),
              _legendItem('On Leave', ReportDesign.leave,
                  ReportDesign.leaveSoft, ReportDesign.leaveBorder),
              _legendItem('Holiday', ReportDesign.holiday,
                  ReportDesign.holidaySoft, ReportDesign.holidayBorder),
              _legendItem('Comp Off', ReportDesign.comboOff,
                  ReportDesign.comboOffSoft, ReportDesign.comboOffBorder),
              _legendItem('Weekly Off', ReportDesign.leave,
                  ReportDesign.leaveSoft, ReportDesign.leaveBorder),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
      String label,
      Color color,
      Color bg,
      Color border,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ReportDesign.sm + 2,
        vertical: ReportDesign.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== CALENDAR =====================

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: ReportDesign.surface,
        borderRadius: BorderRadius.circular(ReportDesign.radiusLg),
        border: Border.all(color: ReportDesign.border, width: 1),
        boxShadow: ReportDesign.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ReportDesign.radiusLg),
        child: TableCalendar<dynamic>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() => _calendarFormat = format);
            }
          },
          onPageChanged: (focusedDay) {
            setState(() => _focusedDay = focusedDay);
            _loadAttendance(month: focusedDay.month, year: focusedDay.year);
          },
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            markersMaxCount: 0,
            cellMargin: EdgeInsets.zero,
            cellPadding: EdgeInsets.zero,
          ),
          calendarBuilders: CalendarBuilders(
            // Hide the tiny dot marker completely
            markerBuilder: (context, day, events) => const SizedBox.shrink(),

            defaultBuilder: (context, day, focusedDay) =>
                _buildDayCell(day, isToday: false, isSelected: false),

            todayBuilder: (context, day, focusedDay) =>
                _buildDayCell(day, isToday: true, isSelected: false),

            selectedBuilder: (context, day, focusedDay) => _buildDayCell(
              day,
              isToday: isSameDay(day, DateTime.now()),
              isSelected: true,
            ),

            holidayBuilder: (context, day, focusedDay) =>
                _buildDayCell(day, isToday: false, isSelected: false),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            formatButtonDecoration: BoxDecoration(
              color: ReportDesign.primarySoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ReportDesign.primaryLight,
                width: 1,
              ),
            ),
            formatButtonTextStyle: const TextStyle(
              color: ReportDesign.primaryDark,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
              letterSpacing: 0.3,
            ),
            titleTextStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ReportDesign.textPrimary,
              letterSpacing: -0.2,
            ),
            leftChevronIcon: const Icon(
              Icons.chevron_left_rounded,
              color: ReportDesign.primary,
              size: 24,
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right_rounded,
              color: ReportDesign.primary,
              size: 24,
            ),
            headerPadding:
            const EdgeInsets.symmetric(vertical: ReportDesign.sm + 4),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: const TextStyle(
              color: ReportDesign.textMuted,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
            weekendStyle: TextStyle(
              color: ReportDesign.absent.withOpacity(0.6),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ===================== SELECTED DAY EVENTS =====================

  Widget _buildSelectedDayEvents() {
    final events = _getEventsForDay(_selectedDay!);

    return Container(
      decoration: BoxDecoration(
        color: ReportDesign.surface,
        borderRadius: BorderRadius.circular(ReportDesign.radiusLg),
        border: Border.all(color: ReportDesign.border, width: 1),
        boxShadow: ReportDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ReportDesign.md,
              ReportDesign.md,
              ReportDesign.md,
              ReportDesign.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ReportDesign.primarySoft,
                    borderRadius:
                    BorderRadius.circular(ReportDesign.radiusSm - 2),
                    border: Border.all(
                      color: ReportDesign.primaryLight,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: ReportDesign.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: ReportDesign.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ReportDesign.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('EEE, MMM d, yyyy').format(_selectedDay!),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: ReportDesign.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: ReportDesign.border),

          // Content
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(ReportDesign.xl),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: ReportDesign.neutralSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_busy_rounded,
                        size: 32,
                        color: ReportDesign.textMuted,
                      ),
                    ),
                    const SizedBox(height: ReportDesign.md),
                    const Text(
                      'No records for this day',
                      style: TextStyle(
                        fontSize: 13,
                        color: ReportDesign.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(ReportDesign.md - 2),
              child: Column(
                children: events.map<Widget>((attendance) {
                  final status = attendance['status'] ?? 'N/A';
                  if (status == 'holiday' ||
                      status == 'public-holiday') {
                    return _buildHolidayCard(attendance);
                  }
                  return _buildAttendanceCard(attendance);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ===================== HOLIDAY CARD =====================

  Widget _buildHolidayCard(Map<String, dynamic> attendance) {
    final holidayName = attendance['holidayName'] ?? 'Holiday';
    final holidayType = attendance['holidayType'] ?? 'General';

    IconData holidayIcon = Icons.celebration_outlined;
    Color holidayColor = ReportDesign.comboOff;

    if (holidayType.toLowerCase().contains('religious')) {
      holidayIcon = Icons.church_outlined;
      holidayColor = ReportDesign.leave;
    } else if (holidayType.toLowerCase().contains('national')) {
      holidayIcon = Icons.flag_outlined;
      holidayColor = ReportDesign.absent;
    } else if (holidayType.toLowerCase().contains('public')) {
      holidayIcon = Icons.beach_access_outlined;
      holidayColor = ReportDesign.holiday;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: ReportDesign.xs + 2),
      padding: const EdgeInsets.all(ReportDesign.md),
      decoration: BoxDecoration(
        color: holidayColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(ReportDesign.radiusMd),
        border: Border.all(
          color: holidayColor.withOpacity(0.25),
          width: 1,
        ),
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
                  color: holidayColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
                ),
                child: Icon(holidayIcon, color: holidayColor, size: 20),
              ),
              const SizedBox(width: ReportDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holidayName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: holidayColor,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ReportDesign.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: holidayColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        holidayType.toUpperCase(),
                        style: TextStyle(
                          color: holidayColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ReportDesign.md),
          Container(height: 1, color: holidayColor.withOpacity(0.15)),
          const SizedBox(height: ReportDesign.sm + 2),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: holidayColor.withOpacity(0.7),
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'No attendance required. Enjoy your holiday!',
                  style: TextStyle(
                    fontSize: 12,
                    color: holidayColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== ATTENDANCE CARD =====================

  Widget _buildAttendanceCard(Map<String, dynamic> attendance) {
    final checkInRaw =
        attendance['checkInTimeFormatted'] ?? attendance['checkIn']?['time'];
    final checkOutRaw = attendance['checkOutTimeFormatted'] ??
        attendance['checkOut']?['time'];

    final checkIn = _formatTime(checkInRaw);
    final checkOut = _formatTime(checkOutRaw);
    final workHours = (attendance['workHours'] ?? 0) as num;
    final status = attendance['status'] ?? 'N/A';
    final isLate = attendance['isLate'] == true;
    final lateBy = attendance['lateBy'] ?? 0;
    final isShortAttendance = attendance['isShortAttendance'] == true;
    final shortByMinutes = attendance['shortByMinutes'] ?? 0;
    final missedCheckout = attendance['missedCheckout'] == true;
    final holidayName = attendance['holidayName'];
    final holidayType = attendance['holidayType'];
    final isWeeklyOffWork = attendance['isWeeklyOffWork'] == true;
    final shift = attendance['shiftSnapshot'] as Map<String, dynamic>?;

    final (statusColor, statusSoft, statusBorder) = _statusStyle(
      status,
      isLate: isLate,
      isShortAttendance: isShortAttendance,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: ReportDesign.xs + 2),
      padding: const EdgeInsets.all(ReportDesign.md - 2),
      decoration: BoxDecoration(
        color: statusSoft,
        borderRadius: BorderRadius.circular(ReportDesign.radiusMd),
        border: Border.all(color: statusBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Header =====
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius:
                  BorderRadius.circular(ReportDesign.radiusSm - 2),
                ),
                child: Icon(Icons.verified_user_rounded,
                    color: statusColor, size: 17),
              ),
              const SizedBox(width: ReportDesign.sm + 2),
              Text(
                status.toString().replaceAll('-', ' ').toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              if (isLate)
                _buildTag('LATE · ${lateBy}m', ReportDesign.late,
                    ReportDesign.lateSoft, ReportDesign.lateBorder),
              if (isShortAttendance) ...[
                if (isLate) const SizedBox(width: 6),
                _buildTag('SHORT · ${shortByMinutes}m', ReportDesign.short,
                    ReportDesign.shortSoft, ReportDesign.shortBorder),
              ],
            ],
          ),

          const SizedBox(height: ReportDesign.md),

          // ===== Check In (full punch) =====
          _buildPunchTile(
            title: 'CHECK IN',
            icon: Icons.login_rounded,
            color: ReportDesign.present,
            timeFormatted: checkIn,
            punch: attendance['checkIn'] as Map<String, dynamic>?,
          ),

          const SizedBox(height: ReportDesign.sm),

          // ===== Check Out (full punch) =====
          _buildPunchTile(
            title: 'CHECK OUT',
            icon: Icons.logout_rounded,
            color: missedCheckout
                ? ReportDesign.absent
                : ReportDesign.absent,
            timeFormatted: missedCheckout ? 'Missed' : checkOut,
            punch: attendance['checkOut'] as Map<String, dynamic>?,
            isMissed: missedCheckout,
          ),

          const SizedBox(height: ReportDesign.sm + 2),

          // ===== Work hours =====
          _buildInfoRow(
            icon: Icons.timer_outlined,
            label: 'WORK HOURS',
            value: '${workHours.toStringAsFixed(2)} hrs',
            color: ReportDesign.late,
          ),

          // ===== Shift =====
          if (shift != null) ...[
            const SizedBox(height: ReportDesign.sm),
            _buildInfoRow(
              icon: Icons.work_outline_rounded,
              label: 'SHIFT',
              value: '${shift['name']} · '
                  '${shift['startTime']}–${shift['endTime']}',
              color: ReportDesign.primary,
            ),
          ],

          // ===== Holiday worked =====
          if (holidayName != null && holidayName.toString().isNotEmpty) ...[
            const SizedBox(height: ReportDesign.sm),
            _buildInfoRow(
              icon: Icons.celebration_outlined,
              label: 'HOLIDAY',
              value: holidayType != null
                  ? '$holidayName · $holidayType'
                  : holidayName.toString(),
              color: ReportDesign.holiday,
              softBg: ReportDesign.holidaySoft,
              borderColor: ReportDesign.holidayBorder,
            ),
          ],

          // ===== Weekly off worked =====
          if (isWeeklyOffWork) ...[
            const SizedBox(height: ReportDesign.sm),
            _buildInfoRow(
              icon: Icons.weekend_rounded,
              label: 'WEEKLY OFF WORK',
              value: 'Worked on weekly off',
              color: ReportDesign.leave,
              softBg: ReportDesign.leaveSoft,
              borderColor: ReportDesign.leaveBorder,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPunchTile({
    required String title,
    required IconData icon,
    required Color color,
    required String timeFormatted,
    required Map<String, dynamic>? punch,
    bool isMissed = false,
  }) {
    final location = punch?['location'] as Map<String, dynamic>?;
    final address = location?['address']?.toString();
    final matchedName = location?['matchedLocationName']?.toString();
    final distance = location?['distanceFromOffice'];
    final deviceInfo = punch?['deviceInfo']?.toString();
    final punchedFrom = punch?['punchedFrom']?.toString();
    final verification = punch?['verificationMethod']?.toString();
    final faceVerified = punch?['faceVerified'] == true;
    final faceSimilarity = punch?['faceSimilarity'];
    final gpsBypassed = punch?['isGpsBypassed'] == true;
    final hasPunch = punch != null && punch['time'] != null;

    return Container(
      padding: const EdgeInsets.all(ReportDesign.sm + 4),
      decoration: BoxDecoration(
        color: ReportDesign.surface,
        borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
        border: Border.all(color: ReportDesign.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header ----
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Text(
                timeFormatted,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isMissed ? ReportDesign.absent : ReportDesign.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),

          if (hasPunch) ...[
            // ---- Location ----
            if (matchedName != null || address != null) ...[
              const SizedBox(height: ReportDesign.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: ReportDesign.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (matchedName != null)
                          Text(
                            matchedName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ReportDesign.textPrimary,
                            ),
                          ),
                        if (address != null)
                          Text(
                            address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: ReportDesign.textMuted,
                              height: 1.3,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (distance != null)
                    _buildTag(
                      '${distance}m',
                      ReportDesign.primary,
                      ReportDesign.primarySoft,
                      ReportDesign.primaryLight,
                    ),
                ],
              ),
            ],

            // ---- Verification / device chips ----
            if (verification != null ||
                deviceInfo != null ||
                punchedFrom != null ||
                faceVerified ||
                gpsBypassed) ...[
              const SizedBox(height: ReportDesign.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (verification != null)
                    _buildChip(
                      Icons.verified_outlined,
                      verification,
                      ReportDesign.present,
                      ReportDesign.presentSoft,
                      ReportDesign.presentBorder,
                    ),
                  if (faceVerified)
                    _buildChip(
                      Icons.face_retouching_natural,
                      faceSimilarity != null
                          ? 'Face ${((double.tryParse(faceSimilarity.toString()) ?? 0) * 100).round()}%'
                          : 'Face ✓',
                      ReportDesign.present,
                      ReportDesign.presentSoft,
                      ReportDesign.presentBorder,
                    ),
                  if (punchedFrom != null)
                    _buildChip(
                      Icons.smartphone_rounded,
                      punchedFrom,
                      ReportDesign.primary,
                      ReportDesign.primarySoft,
                      ReportDesign.primaryLight,
                    ),
                  if (deviceInfo != null)
                    _buildChip(
                      Icons.phone_android_rounded,
                      deviceInfo,
                      ReportDesign.neutral,
                      ReportDesign.neutralSoft,
                      ReportDesign.neutralBorder,
                    ),
                  if (gpsBypassed)
                    _buildChip(
                      Icons.warning_amber_rounded,
                      'GPS bypassed',
                      ReportDesign.absent,
                      ReportDesign.absentSoft,
                      ReportDesign.absentBorder,
                    ),
                ],
              ),
            ],
          ],

          // ---- Missed checkout hint ----
          if (isMissed) ...[
            const SizedBox(height: ReportDesign.sm),
            const Text(
              'No checkout punch recorded for this day.',
              style: TextStyle(
                fontSize: 11,
                color: ReportDesign.absent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(
      IconData icon,
      String label,
      Color color,
      Color bg,
      Color border,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ReportDesign.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildTimeTile({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(ReportDesign.sm + 4),
        decoration: BoxDecoration(
          color: ReportDesign.surface,
          borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
          border: Border.all(color: ReportDesign.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 13),
                const SizedBox(width: 5),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ReportDesign.sm),
            Text(
              time,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: ReportDesign.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== INFO ROW HELPER =====================

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    Color? softBg,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ReportDesign.sm + 4,
        vertical: ReportDesign.sm,
      ),
      decoration: BoxDecoration(
        color: softBg ?? ReportDesign.surface,
        borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
        border: Border.all(
          color: borderColor ?? ReportDesign.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: ReportDesign.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: ReportDesign.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== STATS OVERVIEW =====================

  Widget _buildStatsOverview() {
    final stats = _attendanceData!['stats'] as Map<String, dynamic>? ?? {};

    return Container(
      decoration: BoxDecoration(
        color: ReportDesign.surface,
        borderRadius: BorderRadius.circular(ReportDesign.radiusLg),
        border: Border.all(color: ReportDesign.border, width: 1),
        boxShadow: ReportDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(ReportDesign.md),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ReportDesign.primarySoft,
                    borderRadius:
                    BorderRadius.circular(ReportDesign.radiusSm - 2),
                    border: Border.all(
                      color: ReportDesign.primaryLight,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: ReportDesign.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: ReportDesign.sm + 2),
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ReportDesign.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: ReportDesign.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ReportDesign.md - 2,
              22, // Top spacing reduced
              ReportDesign.md - 2,
              ReportDesign.md - 2,
            ),
            child: GridView.count(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: ReportDesign.sm + 2,
              mainAxisSpacing: ReportDesign.sm + 2,
              children: stats.entries
                  .map<Widget>((entry) =>
                  _buildStatCard(context, entry.key, entry.value))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String key,
      dynamic value,
      ) {
    final normalizedKey = key.toLowerCase().replaceAll(' ', '');

    final Map<String, Map<String, dynamic>> statConfig = {
      'totaldays': {
        'icon': Icons.calendar_month_rounded,
        'color': ReportDesign.holiday,
        'bg': ReportDesign.holidaySoft,
        'border': ReportDesign.holidayBorder,
      },
      'present': {
        'icon': Icons.check_circle_rounded,
        'color': ReportDesign.present,
        'bg': ReportDesign.presentSoft,
        'border': ReportDesign.presentBorder,
      },
      'absent': {
        'icon': Icons.cancel_rounded,
        'color': ReportDesign.absent,
        'bg': ReportDesign.absentSoft,
        'border': ReportDesign.absentBorder,
      },
      'halfday': {
        'icon': Icons.remove_circle_outline_rounded,
        'color': ReportDesign.short,
        'bg': ReportDesign.shortSoft,
        'border': ReportDesign.shortBorder,
      },
      'onleave': {
        'icon': Icons.beach_access_rounded,
        'color': ReportDesign.leave,
        'bg': ReportDesign.leaveSoft,
        'border': ReportDesign.leaveBorder,
      },
      'holiday': {
        'icon': Icons.card_giftcard_rounded,
        'color': ReportDesign.holiday,
        'bg': ReportDesign.holidaySoft,
        'border': ReportDesign.holidayBorder,
      },
      'weeklyoff': {
        'icon': Icons.weekend_rounded,
        'color': ReportDesign.leave,
        'bg': ReportDesign.leaveSoft,
        'border': ReportDesign.leaveBorder,
      },
      'combooff': {
        'icon': Icons.event_available_rounded,
        'color': ReportDesign.comboOff,
        'bg': ReportDesign.comboOffSoft,
        'border': ReportDesign.comboOffBorder,
      },
      'totalworkhours': {
        'icon': Icons.schedule_rounded,
        'color': ReportDesign.primary,
        'bg': ReportDesign.primarySoft,
        'border': ReportDesign.primaryLight,
      },
      'latecount': {
        'icon': Icons.access_time_rounded,
        'color': ReportDesign.late,
        'bg': ReportDesign.lateSoft,
        'border': ReportDesign.lateBorder,
      },
    };

    final config = statConfig[normalizedKey] ??
        {
          'icon': Icons.info_rounded,
          'color': ReportDesign.neutral,
          'bg': ReportDesign.neutralSoft,
          'border': ReportDesign.neutralBorder,
        };

    final String formattedValue =
    value is double ? value.toStringAsFixed(1) : '$value';

    return GestureDetector(
      onTap: () {
        if (normalizedKey == 'totalworkhours') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const MonthlyWorkHoursBottomSheet(),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: config['bg'] as Color,
          borderRadius: BorderRadius.circular(ReportDesign.radiusSm + 2),
          border: Border.all(
            color: config['border'] as Color,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(ReportDesign.sm + 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              config['icon'] as IconData,
              color: config['color'] as Color,
              size: 20,
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formattedValue,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: config['color'] as Color,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatKey(key),
              style: const TextStyle(
                fontSize: 10.5,
                color: ReportDesign.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HELPERS =====================

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
        .join(' ');
  }

  String _formatTime(dynamic timeValue) {
    if (timeValue == null || timeValue.toString().isEmpty) return '—';
    try {
      final dt = DateTime.parse(timeValue.toString()).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeValue.toString();
    }
  }
}