import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

// ===================== DESIGN TOKENS =====================

class AttendanceDesign {
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

  // State colors
  static const Color success = Color(0xFF059669);       // emerald-600
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color warning = Color(0xFFD97706);       // amber-600
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color danger = Color(0xFFDC2626);        // red-600
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF4F46E5);          // indigo-600
  static const Color infoSoft = Color(0xFFEEF2FF);
  static const Color infoBorder = Color(0xFFC7D2FE);

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFF5F3FF);
  static const Color purpleBorder = Color(0xFFDDD6FE);

  static const Color teal = Color(0xFF0F766E);
  static const Color tealSoft = Color(0xFFF0FDFA);
  static const Color tealBorder = Color(0xFF99F6E4);

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

class AttendanceSummaryCard extends StatefulWidget {
  final String? statusTitle;
  final String? currentDate;
  final String? checkInTime;
  final String? checkOutTime;
  final double? currentWorkHours;
  final double? latenessMinutes;
  final String? statusMessage;
  final String? deviceModel;
  final String? deviceOS;
  final String? deviceLocation;
  final bool isCheckedIn;
  final bool isCheckedOut;
  final bool isLoading;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;

  const AttendanceSummaryCard({
    super.key,
    this.statusTitle,
    this.currentDate,
    this.checkInTime,
    this.checkOutTime,
    this.currentWorkHours,
    this.latenessMinutes,
    this.statusMessage,
    this.deviceModel,
    this.deviceOS,
    this.deviceLocation,
    this.isCheckedIn = false,
    this.isCheckedOut = false,
    this.isLoading = false,
    this.onCheckIn,
    this.onCheckOut,
  });

  @override
  State<AttendanceSummaryCard> createState() => _AttendanceSummaryCardState();
}

class _AttendanceSummaryCardState extends State<AttendanceSummaryCard> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isAuthenticating = false;

  Future<void> _handleCheckIn() async {
    widget.onCheckIn?.call();
  }

  Future<void> _handleCheckOut() async {
    widget.onCheckOut?.call();
  }

  // ===================== STATE / COLOR LOGIC =====================

  _AttendanceState get _state {
    if (widget.isCheckedOut) return _AttendanceState.completed;
    if (widget.isCheckedIn) {
      if (widget.latenessMinutes != null && widget.latenessMinutes! > 0) {
        return _AttendanceState.late;
      }
      return _AttendanceState.active;
    }
    return _AttendanceState.pending;
  }

  Color get _stateColor {
    switch (_state) {
      case _AttendanceState.completed:
        return AttendanceDesign.teal;
      case _AttendanceState.active:
        return AttendanceDesign.success;
      case _AttendanceState.late:
        return AttendanceDesign.warning;
      case _AttendanceState.pending:
        return AttendanceDesign.info;
    }
  }

  Color get _stateSoftColor {
    switch (_state) {
      case _AttendanceState.completed:
        return AttendanceDesign.tealSoft;
      case _AttendanceState.active:
        return AttendanceDesign.successSoft;
      case _AttendanceState.late:
        return AttendanceDesign.warningSoft;
      case _AttendanceState.pending:
        return AttendanceDesign.infoSoft;
    }
  }

  Color get _stateBorderColor {
    switch (_state) {
      case _AttendanceState.completed:
        return AttendanceDesign.tealBorder;
      case _AttendanceState.active:
        return AttendanceDesign.successBorder;
      case _AttendanceState.late:
        return AttendanceDesign.warningBorder;
      case _AttendanceState.pending:
        return AttendanceDesign.infoBorder;
    }
  }

  String get _stateLabel {
    switch (_state) {
      case _AttendanceState.completed:
        return 'Completed';
      case _AttendanceState.active:
        return 'Active';
      case _AttendanceState.late:
        return 'Late';
      case _AttendanceState.pending:
        return 'Pending';
    }
  }

  IconData get _stateIcon {
    switch (_state) {
      case _AttendanceState.completed:
        return Icons.task_alt_rounded;
      case _AttendanceState.active:
        return Icons.timelapse_rounded;
      case _AttendanceState.late:
        return Icons.warning_amber_rounded;
      case _AttendanceState.pending:
        return Icons.schedule_rounded;
    }
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E2640) : AttendanceDesign.surface;
    final border = isDark ? const Color(0xFF2D3748) : AttendanceDesign.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AttendanceDesign.radiusLg),
        border: Border.all(color: border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AttendanceDesign.radiusLg),
        child: Column(
          children: [
            // ===== ACCENT HEADER BAR =====
            _buildAccentBar(),

            Padding(
              padding: const EdgeInsets.all(AttendanceDesign.md + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AttendanceDesign.md + 2),
                  _buildDivider(),
                  const SizedBox(height: AttendanceDesign.md + 2),
                  _buildTimeInfoRow(),
                  const SizedBox(height: AttendanceDesign.md),
                  _buildInfoChips(),
                  if (_hasDeviceOrLocationInfo()) ...[
                    const SizedBox(height: AttendanceDesign.sm + 4),
                    _buildDeviceLocationSection(),
                  ],
                  const SizedBox(height: AttendanceDesign.md + 4),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== ACCENT BAR =====================

  Widget _buildAccentBar() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _stateColor,
            _stateColor.withOpacity(0.6),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Status icon container
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _stateSoftColor,
            borderRadius: BorderRadius.circular(AttendanceDesign.radiusSm + 2),
            border: Border.all(
              color: _stateBorderColor,
              width: 1,
            ),
          ),
          child: Icon(
            _getHeaderIcon(),
            color: _stateColor,
            size: 22,
          ),
        ),
        const SizedBox(width: AttendanceDesign.md - 2),

        // Title + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.statusTitle ?? "Attendance",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF8FAFC)
                      : AttendanceDesign.textPrimary,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF64748B)
                        : AttendanceDesign.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      widget.currentDate ?? "Today",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF94A3B8)
                            : AttendanceDesign.textSecondary,
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

        const SizedBox(width: AttendanceDesign.sm),

        // Status badge
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(
        horizontal: AttendanceDesign.sm + 4,
        vertical: AttendanceDesign.xs + 2,
      ),
      decoration: BoxDecoration(
        color: _stateSoftColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _stateBorderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _stateColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _stateColor.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _stateLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _stateColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getHeaderIcon() {
    if (widget.isCheckedOut) return Icons.task_alt_rounded;
    if (widget.isCheckedIn) return Icons.access_time_filled_rounded;
    return Icons.schedule_rounded;
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1,
      color: isDark ? const Color(0xFF2D3748) : AttendanceDesign.border,
    );
  }

  // ===================== TIME INFO ROW =====================

  Widget _buildTimeInfoRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedBg = isDark ? const Color(0xFF28334E) : AttendanceDesign.surfaceMuted;
    final mutedBorder = isDark ? const Color(0xFF2D3748) : AttendanceDesign.border;

    return Row(
      children: [
        Expanded(
          child: _buildTimeInfo(
            "Check In",
            widget.checkInTime ?? "--:--",
            Icons.login_rounded,
            widget.isCheckedIn
                ? AttendanceDesign.success
                : (isDark ? const Color(0xFF64748B) : AttendanceDesign.textMuted),
            widget.isCheckedIn
                ? (isDark ? const Color(0xFF064E3B).withOpacity(0.3) : AttendanceDesign.successSoft)
                : mutedBg,
            widget.isCheckedIn
                ? AttendanceDesign.successBorder
                : mutedBorder,
          ),
        ),
        const SizedBox(width: AttendanceDesign.sm + 4),
        Expanded(
          child: _buildTimeInfo(
            "Check Out",
            widget.checkOutTime ?? "--:--",
            Icons.logout_rounded,
            widget.isCheckedOut
                ? AttendanceDesign.danger
                : (isDark ? const Color(0xFF64748B) : AttendanceDesign.textMuted),
            widget.isCheckedOut
                ? (isDark ? const Color(0xFF7F1D1D).withOpacity(0.3) : AttendanceDesign.dangerSoft)
                : mutedBg,
            widget.isCheckedOut
                ? AttendanceDesign.dangerBorder
                : mutedBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(
      String title,
      String value,
      IconData icon,
      Color color,
      Color bgColor,
      Color borderColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(AttendanceDesign.sm + 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AttendanceDesign.radiusSm),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: color.withOpacity(0.85),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AttendanceDesign.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: (color == AttendanceDesign.textMuted || color == const Color(0xFF64748B))
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF64748B)
                      : AttendanceDesign.textMuted)
                  : (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF8FAFC)
                      : AttendanceDesign.textPrimary),
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== INFO CHIPS =====================

  Widget _buildInfoChips() {
    return Row(
      children: [
        if (widget.currentWorkHours != null) ...[
          Expanded(
            child: _buildInfoChip(
              "Work Time",
              _formatWorkHours(widget.currentWorkHours!),
              Icons.timer_outlined,
              AttendanceDesign.info,
              AttendanceDesign.infoSoft,
              AttendanceDesign.infoBorder,
            ),
          ),
          const SizedBox(width: AttendanceDesign.sm),
        ],
        Expanded(
          child: _buildInfoChip(
            "Status",
            _getStatusText(),
            _getStatusIcon(),
            _getStatusColor(),
            _getStatusBgColor(),
            _getStatusBorderColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
      String title,
      String value,
      IconData icon,
      Color color,
      Color bgColor,
      Color borderColor,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AttendanceDesign.sm + 4,
        vertical: AttendanceDesign.sm + 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AttendanceDesign.radiusSm),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: AttendanceDesign.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    color: color.withOpacity(0.75),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AttendanceDesign.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== DEVICE & LOCATION =====================

  Widget _buildDeviceLocationSection() {
    return Column(
      children: [
        if (widget.deviceModel != null)
          _buildDetailRow(
            icon: Icons.smartphone_rounded,
            label: "Device",
            value: "${widget.deviceOS ?? ''} · ${widget.deviceModel ?? ''}",
            color: AttendanceDesign.purple,
            bgColor: AttendanceDesign.purpleSoft,
            borderColor: AttendanceDesign.purpleBorder,
          ),
        if (widget.deviceModel != null && widget.deviceLocation != null)
          const SizedBox(height: AttendanceDesign.sm),
        if (widget.deviceLocation != null)
          _buildDetailRow(
            icon: Icons.location_on_rounded,
            label: "Location",
            value: widget.deviceLocation!,
            color: AttendanceDesign.teal,
            bgColor: AttendanceDesign.tealSoft,
            borderColor: AttendanceDesign.tealBorder,
          ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AttendanceDesign.sm + 4,
        vertical: AttendanceDesign.sm + 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AttendanceDesign.radiusSm),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: AttendanceDesign.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    color: color.withOpacity(0.75),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AttendanceDesign.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== ACTION BUTTONS =====================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: _buildCheckInButton()),
        const SizedBox(width: AttendanceDesign.sm + 4),
        Expanded(child: _buildCheckOutButton()),
      ],
    );
  }

  Widget _buildCheckInButton() {
    final bool canCheckIn =
        !widget.isCheckedIn && !widget.isLoading && !_isAuthenticating;
    final bool showLoading = (widget.isLoading && !widget.isCheckedIn) ||
        (_isAuthenticating && !widget.isCheckedIn);
    final bool isDone = widget.isCheckedIn;

    return _buildActionButton(
      label: isDone ? "Checked In" : "Check In",
      icon: isDone ? Icons.check_circle_rounded : Icons.fingerprint_rounded,
      isEnabled: canCheckIn,
      isLoading: showLoading,
      isCompleted: isDone,
      color: AttendanceDesign.success,
      softColor: AttendanceDesign.successSoft,
      borderColor: AttendanceDesign.successBorder,
      onTap: canCheckIn ? _handleCheckIn : null,
    );
  }

  Widget _buildCheckOutButton() {
    final bool canCheckOut = widget.isCheckedIn &&
        !widget.isCheckedOut &&
        !widget.isLoading &&
        !_isAuthenticating;
    final bool showLoading = (widget.isLoading &&
        widget.isCheckedIn &&
        !widget.isCheckedOut) ||
        (_isAuthenticating && widget.isCheckedIn);
    final bool isDone = widget.isCheckedOut;

    return _buildActionButton(
      label: isDone ? "Checked Out" : "Check Out",
      icon: isDone ? Icons.check_circle_rounded : Icons.fingerprint_rounded,
      isEnabled: canCheckOut,
      isLoading: showLoading,
      isCompleted: isDone,
      color: AttendanceDesign.danger,
      softColor: AttendanceDesign.dangerSoft,
      borderColor: AttendanceDesign.dangerBorder,
      onTap: canCheckOut ? _handleCheckOut : null,
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isEnabled,
    required bool isLoading,
    required bool isCompleted,
    required Color color,
    required Color softColor,
    required Color borderColor,
    required VoidCallback? onTap,
  }) {
    // Filled gradient button when enabled or completed
    final bool isFilled = isEnabled || isCompleted;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AttendanceDesign.radiusSm + 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AttendanceDesign.radiusSm + 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            vertical: AttendanceDesign.sm + 6,
            horizontal: AttendanceDesign.sm,
          ),
          decoration: BoxDecoration(
            gradient: isFilled
                ? LinearGradient(
              colors: [
                color,
                color.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isFilled ? null : AttendanceDesign.surfaceMuted,
            borderRadius: BorderRadius.circular(AttendanceDesign.radiusSm + 2),
            border: Border.all(
              color: isFilled ? Colors.transparent : AttendanceDesign.border,
              width: 1,
            ),
            boxShadow: isEnabled
                ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFilled ? Colors.white : color,
                    ),
                  ),
                )
              else
                Icon(
                  icon,
                  color: isFilled ? Colors.white : AttendanceDesign.textMuted,
                  size: 18,
                ),
              const SizedBox(width: AttendanceDesign.sm),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                    isFilled ? Colors.white : AttendanceDesign.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== HELPERS =====================

  bool _hasDeviceOrLocationInfo() =>
      widget.deviceModel != null || widget.deviceLocation != null;

  String _getStatusText() {
    if (widget.latenessMinutes != null && widget.latenessMinutes! > 0) {
      return _formatLateTime(widget.latenessMinutes!);
    }
    return widget.statusMessage ?? "On time";
  }

  IconData _getStatusIcon() {
    return (widget.latenessMinutes != null && widget.latenessMinutes! > 0)
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;
  }

  Color _getStatusColor() {
    return (widget.latenessMinutes != null && widget.latenessMinutes! > 0)
        ? AttendanceDesign.warning
        : AttendanceDesign.success;
  }

  Color _getStatusBgColor() {
    return (widget.latenessMinutes != null && widget.latenessMinutes! > 0)
        ? AttendanceDesign.warningSoft
        : AttendanceDesign.successSoft;
  }

  Color _getStatusBorderColor() {
    return (widget.latenessMinutes != null && widget.latenessMinutes! > 0)
        ? AttendanceDesign.warningBorder
        : AttendanceDesign.successBorder;
  }

  String _formatWorkHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return h > 0 ? "${h}h ${m}m" : "${m}m";
  }

  String _formatLateTime(double mins) {
    final hours = (mins / 60).floor();
    final remainingMinutes = (mins % 60).round();
    return hours > 0
        ? "${hours}h ${remainingMinutes}m late"
        : "${remainingMinutes.toInt()}m late";
  }
}

// ===================== ATTENDANCE STATE =====================

enum _AttendanceState { pending, active, late, completed }