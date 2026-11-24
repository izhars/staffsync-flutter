import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/report_screen.dart';

// (Import ReportDesign from above)

class WeeklyReportWidget extends StatelessWidget {
  final List<dynamic> attendanceList;
  final VoidCallback onRefresh;

  const WeeklyReportWidget({
    Key? key,
    required this.attendanceList,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final weeklyData = _groupByWeek(attendanceList);

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
          _buildReportHeader(),
          const SizedBox(height: ReportDesign.md),
          if (weeklyData.isEmpty)
            _buildEmptyState()
          else
            ...weeklyData.entries
                .map((entry) => _buildWeekCard(entry))
                .toList(),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByWeek(
      List<dynamic> attendance,
      ) {
    final Map<String, List<Map<String, dynamic>>> weeklyData = {};

    for (var att in attendance) {
      final date = DateTime.parse(att['date']).toLocal();
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekKey =
          '${DateFormat('dd MMM').format(weekStart)} — ${DateFormat('dd MMM yyyy').format(weekEnd)}';

      weeklyData.putIfAbsent(weekKey, () => []);
      weeklyData[weekKey]!.add(att as Map<String, dynamic>);
    }

    return weeklyData;
  }

  // ===================== HEADER =====================

  Widget _buildReportHeader() {
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
            child: const Icon(
              Icons.date_range_rounded,
              color: ReportDesign.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: ReportDesign.sm + 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Report',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ReportDesign.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Summary grouped by week',
                  style: TextStyle(
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
            'No weekly records',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ReportDesign.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: ReportDesign.xs + 2),
          const Text(
            'Weekly summaries will appear here',
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

  // ===================== WEEK CARD =====================

  Widget _buildWeekCard(
      MapEntry<String, List<Map<String, dynamic>>> weekEntry,
      ) {
    final weekLabel = weekEntry.key;
    final weekAttendance = weekEntry.value;

    int presentDays = 0;
    int absentDays = 0;
    int lateDays = 0;
    double totalWorkHours = 0.0;

    for (var att in weekAttendance) {
      final status = att['status']?.toString().toLowerCase() ?? '';
      if (status == 'present') presentDays++;
      if (status == 'absent') absentDays++;
      if (att['isLate'] == true) lateDays++;
      totalWorkHours += (att['workHours'] ?? 0.0);
    }

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
          // ===== Week header =====
          Padding(
            padding: const EdgeInsets.all(ReportDesign.md),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
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
                    Icons.calendar_view_week_rounded,
                    color: ReportDesign.primary,
                    size: 17,
                  ),
                ),
                const SizedBox(width: ReportDesign.sm + 4),
                Expanded(
                  child: Text(
                    weekLabel,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: ReportDesign.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ReportDesign.sm + 2,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ReportDesign.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${weekAttendance.length} DAYS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: ReportDesign.border),

          // ===== Stats grid =====
          Padding(
            padding: const EdgeInsets.all(ReportDesign.md - 2),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        'Present',
                        '$presentDays',
                        Icons.check_circle_rounded,
                        ReportDesign.present,
                        ReportDesign.presentSoft,
                        ReportDesign.presentBorder,
                      ),
                    ),
                    const SizedBox(width: ReportDesign.sm),
                    Expanded(
                      child: _buildStatTile(
                        'Absent',
                        '$absentDays',
                        Icons.cancel_rounded,
                        ReportDesign.absent,
                        ReportDesign.absentSoft,
                        ReportDesign.absentBorder,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ReportDesign.sm),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        'Late',
                        '$lateDays',
                        Icons.access_time_rounded,
                        ReportDesign.late,
                        ReportDesign.lateSoft,
                        ReportDesign.lateBorder,
                      ),
                    ),
                    const SizedBox(width: ReportDesign.sm),
                    Expanded(
                      child: _buildStatTile(
                        'Hours',
                        '${totalWorkHours.toStringAsFixed(1)}h',
                        Icons.timer_outlined,
                        ReportDesign.primary,
                        ReportDesign.primarySoft,
                        ReportDesign.primaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ===== Daily breakdown =====
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ReportDesign.md - 2,
              0,
              ReportDesign.md - 2,
              ReportDesign.md - 2,
            ),
            child: Container(
              padding: const EdgeInsets.all(ReportDesign.sm + 4),
              decoration: BoxDecoration(
                color: ReportDesign.surfaceMuted,
                borderRadius: BorderRadius.circular(ReportDesign.radiusSm),
                border: Border.all(color: ReportDesign.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 14,
                        color: ReportDesign.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DAILY BREAKDOWN',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ReportDesign.textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ReportDesign.sm),
                  ...weekAttendance
                      .map((att) => _buildDayRow(att))
                      .toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
      String label,
      String value,
      IconData icon,
      Color color,
      Color bg,
      Color border,
      ) {
    return Container(
      padding: const EdgeInsets.all(ReportDesign.sm + 2),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ReportDesign.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayRow(Map<String, dynamic> att) {
    final date = DateTime.parse(att['date']).toLocal();
    final dayName = DateFormat('EEE').format(date);
    final dayDate = DateFormat('dd MMM').format(date);
    final status = att['status']?.toString() ?? 'Unknown';
    final isLate = att['isLate'] == true;
    final workHours = att['workHours'] ?? 0.0;

    final (statusColor, statusSoft, statusBorder) = ReportDesign.statusStyle(
      status,
      isLate: isLate,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(ReportDesign.sm + 2),
      decoration: BoxDecoration(
        color: ReportDesign.surface,
        borderRadius: BorderRadius.circular(ReportDesign.radiusSm - 2),
        border: Border.all(color: ReportDesign.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: ReportDesign.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: ReportDesign.textPrimary,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dayDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: ReportDesign.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusSoft,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: statusBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    if (isLate) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ReportDesign.lateSoft,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: ReportDesign.lateBorder,
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'LATE',
                          style: TextStyle(
                            fontSize: 9,
                            color: ReportDesign.late,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${workHours.toStringAsFixed(1)}h',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: ReportDesign.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}