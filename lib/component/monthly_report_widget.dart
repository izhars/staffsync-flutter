import 'package:flutter/material.dart';
import '../screens/report_screen.dart';

class MonthlyReportWidget extends StatelessWidget {
  final List<dynamic> attendanceList;
  final VoidCallback onRefresh;

  const MonthlyReportWidget({
    Key? key,
    required this.attendanceList,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthlyStats = _calculateMonthlyStats(attendanceList);

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
          if (attendanceList.isEmpty)
            _buildEmptyState()
          else ...[
            _buildMonthlyOverview(monthlyStats),
            const SizedBox(height: ReportDesign.md),
            _buildMonthlyChart(monthlyStats),
            const SizedBox(height: ReportDesign.md),
            _buildDetailedStats(monthlyStats),
          ],
        ],
      ),
    );
  }

  // ===================== CALCULATIONS =====================

  Map<String, dynamic> _calculateMonthlyStats(List<dynamic> attendance) {
    int totalDays = attendance.length;
    int presentDays = 0;
    int absentDays = 0;
    int lateDays = 0;
    int halfDays = 0;
    int leaveDays = 0;
    int weeklyOffDays = 0;
    int holidayDays = 0;
    int comboOffDays = 0;
    double totalWorkHours = 0.0;
    double totalLateMinutes = 0.0;

    for (var att in attendance) {
      final status = att['status']?.toString().toLowerCase() ?? '';

      if (status == 'present') {
        presentDays++;
      } else if (status == 'absent') {
        absentDays++;
      } else if (status == 'half-day' || status == 'halfday') {
        halfDays++;
      } else if (status == 'on-leave' || status == 'leave') {
        leaveDays++;
      } else if (status == 'weekly-off' || status == 'weeklyoff') {
        weeklyOffDays++;
      } else if (status == 'holiday' || status == 'public-holiday') {
        holidayDays++;
      } else if (status == 'combo-off') {
        comboOffDays++;
      }

      if (att['isLate'] == true) {
        lateDays++;
        totalLateMinutes += (att['lateBy'] ?? 0.0);
      }
      totalWorkHours += (att['workHours'] ?? 0.0);
    }

    final workableDays = presentDays + absentDays + halfDays + leaveDays;
    final effectiveWorkingDays = workableDays > 0 ? workableDays : (totalDays - weeklyOffDays - holidayDays);

    final attendancePercentage = effectiveWorkingDays > 0
        ? (((presentDays + halfDays * 0.5) / effectiveWorkingDays) * 100)
        : 0.0;
    final avgWorkHours = effectiveWorkingDays > 0 ? totalWorkHours / effectiveWorkingDays : 0.0;
    final avgLateMinutes = lateDays > 0 ? totalLateMinutes / lateDays : 0.0;

    return {
      'totalDays': totalDays,
      'workingDays': effectiveWorkingDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'halfDays': halfDays,
      'leaveDays': leaveDays,
      'weeklyOffDays': weeklyOffDays,
      'holidayDays': holidayDays,
      'comboOffDays': comboOffDays,
      'totalWorkHours': totalWorkHours,
      'avgWorkHours': avgWorkHours,
      'attendancePercentage': attendancePercentage,
      'avgLateMinutes': avgLateMinutes,
    };
  }

  // ===================== HEADER / EMPTY =====================

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
              Icons.calendar_view_month_rounded,
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
                  'Monthly Report',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: ReportDesign.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Full month summary & insights',
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
            'No monthly records',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ReportDesign.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: ReportDesign.xs + 2),
          const Text(
            'Monthly analytics will appear here',
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

  // ===================== OVERVIEW CARD =====================

  Widget _buildMonthlyOverview(Map<String, dynamic> stats) {
    final attendancePercentage = stats['attendancePercentage'] as double;

    return Container(
      padding: const EdgeInsets.all(ReportDesign.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ReportDesign.primary, ReportDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ReportDesign.radiusLg),
        boxShadow: [
          BoxShadow(
            color: ReportDesign.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius:
                  BorderRadius.circular(ReportDesign.radiusSm - 2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              const SizedBox(width: ReportDesign.sm + 2),
              const Text(
                'Monthly Overview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: ReportDesign.lg),

          // Attendance ring
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: (attendancePercentage / 100).clamp(0.0, 1.0),
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${attendancePercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'ATTENDANCE',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: ReportDesign.lg),

          // Inline stats
          Row(
            children: [
              _buildOverviewStat('TOTAL', '${stats['totalDays']}'),
              _buildOverviewDivider(),
              _buildOverviewStat('PRESENT', '${stats['presentDays']}'),
              _buildOverviewDivider(),
              _buildOverviewStat('ABSENT', '${stats['absentDays']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withOpacity(0.2),
    );
  }

  // ===================== BAR CHART =====================

  Widget _buildMonthlyChart(Map<String, dynamic> stats) {
    final totalDays = stats['totalDays'] as int;
    final presentDays = stats['presentDays'] as int;
    final absentDays = stats['absentDays'] as int;
    final leaveDays = stats['leaveDays'] as int;

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
                  Icons.bar_chart_rounded,
                  color: ReportDesign.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: ReportDesign.sm + 2),
              const Text(
                'Attendance Breakdown',
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
          _buildBarChart(
            'Present',
            presentDays,
            totalDays,
            ReportDesign.present,
            ReportDesign.presentSoft,
            ReportDesign.presentBorder,
          ),
          const SizedBox(height: ReportDesign.sm + 4),
          _buildBarChart(
            'Absent',
            absentDays,
            totalDays,
            ReportDesign.absent,
            ReportDesign.absentSoft,
            ReportDesign.absentBorder,
          ),
          const SizedBox(height: ReportDesign.sm + 4),
          _buildBarChart(
            'On Leave',
            leaveDays,
            totalDays,
            ReportDesign.leave,
            ReportDesign.leaveSoft,
            ReportDesign.leaveBorder,
          ),
          const SizedBox(height: ReportDesign.sm + 4),
          _buildBarChart(
            'Late',
            stats['lateDays'] as int,
            totalDays,
            ReportDesign.late,
            ReportDesign.lateSoft,
            ReportDesign.lateBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
      String label,
      int value,
      int total,
      Color color,
      Color bg,
      Color border,
      ) {
    final double percentage = total > 0 ? (value / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: ReportDesign.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: border, width: 1),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: percentage >= 0.15
                    ? Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                )
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===================== DETAILED STATS =====================

  Widget _buildDetailedStats(Map<String, dynamic> stats) {
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
                  Icons.insights_rounded,
                  color: ReportDesign.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: ReportDesign.sm + 2),
              const Text(
                'Detailed Statistics',
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
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: ReportDesign.sm + 2,
            mainAxisSpacing: ReportDesign.sm + 2,
            children: [
              _buildStatCard(
                'Total Hours',
                '${stats['totalWorkHours'].toStringAsFixed(1)}h',
                Icons.timer_outlined,
                ReportDesign.primary,
                ReportDesign.primarySoft,
                ReportDesign.primaryLight,
              ),
              _buildStatCard(
                'Avg Hours / Day',
                '${stats['avgWorkHours'].toStringAsFixed(1)}h',
                Icons.speed_rounded,
                ReportDesign.comboOff,
                ReportDesign.comboOffSoft,
                ReportDesign.comboOffBorder,
              ),
              _buildStatCard(
                'Half Days',
                '${stats['halfDays']}',
                Icons.timer_off_outlined,
                ReportDesign.short,
                ReportDesign.shortSoft,
                ReportDesign.shortBorder,
              ),
              _buildStatCard(
                'Avg Late Time',
                '${stats['avgLateMinutes'].toStringAsFixed(0)}m',
                Icons.warning_amber_rounded,
                ReportDesign.late,
                ReportDesign.lateSoft,
                ReportDesign.lateBorder,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
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
        borderRadius: BorderRadius.circular(ReportDesign.radiusSm + 2),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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
    );
  }
}