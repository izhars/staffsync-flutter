import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/attendance_api.dart';

// ===================== SHARED TOKENS (copy in each file or import) =====================
class ReportDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color primaryLight = Color(0xFFC7D2FE);

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color present = Color(0xFF059669);
  static const Color presentSoft = Color(0xFFECFDF5);
  static const Color presentBorder = Color(0xFFA7F3D0);

  static const Color late = Color(0xFFD97706);
  static const Color lateSoft = Color(0xFFFFFBEB);
  static const Color lateBorder = Color(0xFFFDE68A);

  static const Color short = Color(0xFFEA580C);
  static const Color shortSoft = Color(0xFFFFF7ED);
  static const Color shortBorder = Color(0xFFFED7AA);

  static const Color absent = Color(0xFFDC2626);
  static const Color absentSoft = Color(0xFFFEF2F2);
  static const Color absentBorder = Color(0xFFFECACA);

  static const Color leave = Color(0xFF7C3AED);
  static const Color leaveSoft = Color(0xFFF5F3FF);
  static const Color leaveBorder = Color(0xFFDDD6FE);

  static const Color holiday = Color(0xFF2563EB);
  static const Color holidaySoft = Color(0xFFEFF6FF);
  static const Color holidayBorder = Color(0xFFBFDBFE);

  static const Color comboOff = Color(0xFF0D9488);
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

  static (Color, Color, Color) statusStyle(
      String status, {
        bool isLate = false,
        bool isShort = false,
      }) {
    if (isShort) return (short, shortSoft, shortBorder);
    if (isLate) return (late, lateSoft, lateBorder);

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
      default:
        return (neutral, neutralSoft, neutralBorder);
    }
  }
}

class DailyReportWidget extends StatelessWidget {
  final List<dynamic> attendanceList;
  final VoidCallback onRefresh;

  const DailyReportWidget({
    Key? key,
    required this.attendanceList,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: ReportDesign.primary,
      backgroundColor: ReportDesign.surface,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ReportDesign.md,
          ReportDesign.md,
          ReportDesign.md,
          ReportDesign.xl,
        ),
        children: [
          _buildReportHeader('Daily', Icons.today_rounded),
          const SizedBox(height: ReportDesign.md),
          if (attendanceList.isEmpty)
            _buildEmptyState()
          else
            ...attendanceList
                .map<Widget>((att) => _buildAttendanceCard(
              att as Map<String, dynamic>,
              context,
            ))
                .toList(),
        ],
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildReportHeader(String reportType, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(ReportDesign.md),
      decoration: BoxDecoration(
        color: ReportDesign.surface,
        borderRadius: BorderRadius.circular(ReportDesign.radiusLg),
        border: Border.all(color: ReportDesign.border, width: 1),
        boxShadow: ReportDesign.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ReportDesign.primarySoft,
              borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
              border: Border.all(
                color: ReportDesign.primaryLight,
                width: 1,
              ),
            ),
            child: Icon(icon, color: ReportDesign.primary, size: 20),
          ),
          const SizedBox(width: ReportDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$reportType Report',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ReportDesign.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${attendanceList.length} record${attendanceList.length != 1 ? 's' : ''}',
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
    );
  }

  // ===================== EMPTY =====================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(ReportDesign.xl),
      decoration: BoxDecoration(
        color: ReportDesign.surface,
        borderRadius: BorderRadius.circular(ReportDesign.radiusLg),
        border: Border.all(color: ReportDesign.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: ReportDesign.neutralSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 36,
              color: ReportDesign.textMuted,
            ),
          ),
          const SizedBox(height: ReportDesign.md),
          const Text(
            'No attendance records',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ReportDesign.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: ReportDesign.xs + 2),
          const Text(
            'Records will appear here once available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: ReportDesign.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== ATTENDANCE CARD =====================

  Widget _buildAttendanceCard(
      Map<String, dynamic> attendance,
      BuildContext context,
      ) {
    final checkIn = attendance['checkIn'] as Map<String, dynamic>?;
    final checkOut = attendance['checkOut'] as Map<String, dynamic>?;
    final isLate = attendance['isLate'] as bool? ?? false;
    final isShortAttendance = attendance['isShortAttendance'] == true;
    final status = attendance['status']?.toString() ?? 'Unknown';

    final date = DateTime.parse(attendance['date']).toLocal();
    final formattedDate = DateFormat('EEE, dd MMM yyyy').format(date);

    final checkInTime = attendance['checkInTimeFormatted']?.toString() ?? '-';
    final checkOutTime =
        attendance['checkOutTimeFormatted']?.toString() ?? '-';

    String formatTime(String timeStr) {
      try {
        final dateTime = DateTime.parse(timeStr).toLocal();
        return DateFormat('hh:mm a').format(dateTime);
      } catch (_) {
        return timeStr;
      }
    }

    final formattedCheckIn =
    checkInTime != '-' ? formatTime(checkInTime) : '-';
    final formattedCheckOut =
    checkOutTime != '-' ? formatTime(checkOutTime) : '-';

    final (statusColor, statusSoft, statusBorder) = ReportDesign.statusStyle(
      status,
      isLate: isLate,
      isShort: isShortAttendance,
    );

    final statusIcon = isShortAttendance
        ? Icons.timer_off_outlined
        : isLate
        ? Icons.access_time_rounded
        : status.toLowerCase() == 'present'
        ? Icons.check_circle_rounded
        : status.toLowerCase() == 'absent'
        ? Icons.cancel_rounded
        : Icons.help_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: ReportDesign.sm + 4),
      decoration: BoxDecoration(
        color: ReportDesign.surface,
        borderRadius: BorderRadius.circular(ReportDesign.radiusLg),
        border: Border.all(color: ReportDesign.border, width: 1),
        boxShadow: ReportDesign.softShadow,
      ),
      child: Column(
        children: [
          // ===== Header strip (tinted) =====
          Container(
            padding: const EdgeInsets.all(ReportDesign.md),
            decoration: BoxDecoration(
              color: statusSoft,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(ReportDesign.radiusLg),
                topRight: Radius.circular(ReportDesign.radiusLg),
              ),
              border: Border(
                bottom: BorderSide(color: statusBorder, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(ReportDesign.radiusSm),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: ReportDesign.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: ReportDesign.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusTag(
                            status.toUpperCase(),
                            statusColor,
                            statusColor.withOpacity(0.15),
                          ),
                          if (isLate) ...[
                            const SizedBox(width: 6),
                            _buildStatusTag(
                              'LATE',
                              ReportDesign.late,
                              ReportDesign.lateSoft,
                            ),
                          ],
                          if (isShortAttendance) ...[
                            const SizedBox(width: 6),
                            _buildStatusTag(
                              'SHORT',
                              ReportDesign.short,
                              ReportDesign.shortSoft,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===== Body =====
          Padding(
            padding: const EdgeInsets.all(ReportDesign.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile(
                        icon: Icons.timer_outlined,
                        label: 'WORK HOURS',
                        value: '${attendance['workHours'] ?? 0} hrs',
                        color: ReportDesign.primary,
                        bg: ReportDesign.primarySoft,
                        border: ReportDesign.primaryLight,
                      ),
                    ),
                    const SizedBox(width: ReportDesign.sm + 4),
                    Expanded(
                      child: _buildInfoTile(
                        icon: Icons.hourglass_bottom_rounded,
                        label: 'LATE BY',
                        value: '${attendance['lateBy'] ?? 0} min',
                        color: isLate
                            ? ReportDesign.late
                            : ReportDesign.neutral,
                        bg: isLate
                            ? ReportDesign.lateSoft
                            : ReportDesign.neutralSoft,
                        border: isLate
                            ? ReportDesign.lateBorder
                            : ReportDesign.neutralBorder,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ReportDesign.sm + 2),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoTile(
                        icon: Icons.login_rounded,
                        label: 'CHECK IN',
                        value: formattedCheckIn,
                        color: ReportDesign.present,
                        bg: ReportDesign.presentSoft,
                        border: ReportDesign.presentBorder,
                      ),
                    ),
                    const SizedBox(width: ReportDesign.sm + 4),
                    Expanded(
                      child: _buildInfoTile(
                        icon: Icons.logout_rounded,
                        label: 'CHECK OUT',
                        value: formattedCheckOut,
                        color: ReportDesign.absent,
                        bg: ReportDesign.absentSoft,
                        border: ReportDesign.absentBorder,
                      ),
                    ),
                  ],
                ),
                if (checkIn != null) ...[
                  const SizedBox(height: ReportDesign.sm + 2),
                  _buildLocationTile(
                    'Check-in Location',
                    checkIn['location']?['address']?.toString() ?? '-',
                    Icons.my_location_rounded,
                    ReportDesign.present,
                  ),
                ],
                if (checkOut != null) ...[
                  const SizedBox(height: ReportDesign.sm),
                  _buildLocationTile(
                    'Check-out Location',
                    checkOut['location']?['address']?.toString() ?? '-',
                    Icons.location_on_rounded,
                    ReportDesign.absent,
                  ),
                ],
                if (_canRegularize(attendance, date)) ...[
                  const SizedBox(height: ReportDesign.sm + 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openRegularizationModal(context, attendance, date),
                      icon: const Icon(Icons.edit_calendar_rounded, size: 15),
                      label: const Text(
                        'Request Regularization',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ReportDesign.primary,
                        side: const BorderSide(color: ReportDesign.primaryLight),
                        backgroundColor: ReportDesign.primarySoft.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
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

  bool _canRegularize(Map<String, dynamic> attendance, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cardDate = DateTime(date.year, date.month, date.day);
    if (cardDate.isAfter(today)) return false;

    final status = (attendance['status'] ?? '').toString().toLowerCase();
    if (status == 'holiday' ||
        status == 'public-holiday' ||
        status == 'weekly-off' ||
        status == 'upcoming') {
      return false;
    }
    return true;
  }

  void _openRegularizationModal(
    BuildContext context,
    Map<String, dynamic> attendance,
    DateTime date,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RegularizationSheet(
        attendance: attendance,
        date: date,
        onSuccess: onRefresh,
      ),
    );
  }

  Widget _buildStatusTag(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ReportDesign.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
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

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(ReportDesign.sm + 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: ReportDesign.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(ReportDesign.sm + 4),
      decoration: BoxDecoration(
        color: ReportDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
        border: Border.all(color: ReportDesign.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: ReportDesign.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: ReportDesign.textMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: ReportDesign.textPrimary,
                    fontWeight: FontWeight.w600,
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
}

class _RegularizationSheet extends StatefulWidget {
  final Map<String, dynamic> attendance;
  final DateTime date;
  final VoidCallback onSuccess;

  const _RegularizationSheet({
    required this.attendance,
    required this.date,
    required this.onSuccess,
  });

  @override
  State<_RegularizationSheet> createState() => _RegularizationSheetState();
}

class _RegularizationSheetState extends State<_RegularizationSheet> {
  final _reasonController = TextEditingController();
  TimeOfDay _checkInTime = const TimeOfDay(hour: 9, minute: 30);
  TimeOfDay _checkOutTime = const TimeOfDay(hour: 18, minute: 30);
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _quickReasons = const [
    'Forgot to punch',
    'Client visit / On duty',
    'Biometric error',
    'Work from home',
    'Missed checkout punch',
    'Half-day correction',
  ];

  @override
  void initState() {
    super.initState();
    _initTimes();
  }

  void _initTimes() {
    try {
      final checkInTimeFormatted = widget.attendance['checkInTimeFormatted']?.toString();
      if (checkInTimeFormatted != null && checkInTimeFormatted.isNotEmpty && checkInTimeFormatted != '-') {
        final parsed = DateTime.tryParse(checkInTimeFormatted);
        if (parsed != null) {
          final local = parsed.toLocal();
          _checkInTime = TimeOfDay(hour: local.hour, minute: local.minute);
        }
      }
    } catch (_) {}

    try {
      final checkOutTimeFormatted = widget.attendance['checkOutTimeFormatted']?.toString();
      if (checkOutTimeFormatted != null && checkOutTimeFormatted.isNotEmpty && checkOutTimeFormatted != '-') {
        final parsed = DateTime.tryParse(checkOutTimeFormatted);
        if (parsed != null) {
          final local = parsed.toLocal();
          _checkOutTime = TimeOfDay(hour: local.hour, minute: local.minute);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isCheckIn}) async {
    final initial = isCheckIn ? _checkInTime : _checkOutTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ReportDesign.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ReportDesign.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInTime = picked;
        } else {
          _checkOutTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  String _timeOfDayToApi(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _errorMessage = 'Please provide a reason for regularization';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
      final checkInStr = _timeOfDayToApi(_checkInTime);
      final checkOutStr = _timeOfDayToApi(_checkOutTime);

      final res = await AttendanceService().requestRegularization(
        date: dateStr,
        checkInTime: checkInStr,
        checkOutTime: checkOutStr,
        reason: reason,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    res['message']?.toString() ?? 'Regularization request submitted successfully',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: ReportDesign.present,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, dd MMM yyyy').format(widget.date);
    final status = widget.attendance['status']?.toString() ?? 'UNKNOWN';

    return Container(
      decoration: const BoxDecoration(
        color: ReportDesign.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(ReportDesign.radiusLg)),
      ),
      padding: EdgeInsets.fromLTRB(
        ReportDesign.md,
        ReportDesign.sm,
        ReportDesign.md,
        MediaQuery.of(context).viewInsets.bottom + ReportDesign.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: ReportDesign.neutralBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ReportDesign.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_calendar_rounded,
                    color: ReportDesign.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Regularize Attendance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ReportDesign.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Submit time correction for approval',
                        style: TextStyle(
                          fontSize: 12,
                          color: ReportDesign.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  color: ReportDesign.textMuted,
                ),
              ],
            ),
            const SizedBox(height: ReportDesign.md),

            // Date & Current Status Card
            Container(
              padding: const EdgeInsets.all(ReportDesign.sm + 4),
              decoration: BoxDecoration(
                color: ReportDesign.surfaceMuted,
                borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
                border: Border.all(color: ReportDesign.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: ReportDesign.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ReportDesign.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ReportDesign.neutralSoft,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ReportDesign.neutralBorder),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ReportDesign.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ReportDesign.md),

            // Time Pickers Row
            Row(
              children: [
                Expanded(
                  child: _buildTimePickerTile(
                    label: 'CHECK-IN TIME',
                    timeText: _formatTimeOfDay(_checkInTime),
                    icon: Icons.login_rounded,
                    color: ReportDesign.present,
                    onTap: () => _pickTime(isCheckIn: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimePickerTile(
                    label: 'CHECK-OUT TIME',
                    timeText: _formatTimeOfDay(_checkOutTime),
                    icon: Icons.logout_rounded,
                    color: ReportDesign.absent,
                    onTap: () => _pickTime(isCheckIn: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ReportDesign.md),

            // Quick reasons
            const Text(
              'QUICK REASONS',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: ReportDesign.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickReasons.map((qr) {
                return InkWell(
                  onTap: () {
                    _reasonController.text = qr;
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: _reasonController.text == qr
                          ? ReportDesign.primarySoft
                          : ReportDesign.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _reasonController.text == qr
                            ? ReportDesign.primaryLight
                            : ReportDesign.border,
                      ),
                    ),
                    child: Text(
                      qr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: _reasonController.text == qr ? FontWeight.w700 : FontWeight.w500,
                        color: _reasonController.text == qr
                            ? ReportDesign.primary
                            : ReportDesign.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: ReportDesign.md),

            // Reason Text Field
            const Text(
              'DETAILED REASON *',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: ReportDesign.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: ReportDesign.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter reason or details for this request...',
                hintStyle: const TextStyle(fontSize: 12.5, color: ReportDesign.textMuted),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: ReportDesign.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
                  borderSide: const BorderSide(color: ReportDesign.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
                  borderSide: const BorderSide(color: ReportDesign.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
                  borderSide: const BorderSide(color: ReportDesign.primary, width: 1.5),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ReportDesign.absentSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ReportDesign.absentBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: ReportDesign.absent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ReportDesign.absent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: ReportDesign.lg),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ReportDesign.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Regularization Request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerTile({
    required String label,
    required String timeText,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ReportDesign.surfaceMuted,
          borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
          border: Border.all(color: ReportDesign.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ReportDesign.textPrimary,
                  ),
                ),
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: ReportDesign.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}