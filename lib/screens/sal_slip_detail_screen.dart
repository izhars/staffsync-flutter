import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:staffsync/screens/payroll_screen.dart';

class SalarySlipDetailScreen extends StatelessWidget {
  final Map<String, dynamic> payrollData;

  const SalarySlipDetailScreen({
    super.key,
    required this.payrollData,
  });

  @override
  Widget build(BuildContext context) {
    final earnings = (payrollData['earnings'] ?? {}) as Map;
    final deductions = (payrollData['deductions'] ?? {}) as Map;
    final attendance = (payrollData['attendance'] ?? {}) as Map;
    final month = payrollData['month'];
    final year = payrollData['year'];
    final status = (payrollData['status'] ?? 'unknown').toString();
    final transactionId = payrollData['transactionId']?.toString();

    final netSalary = _toNum(payrollData['netSalary']);

    return Scaffold(
      backgroundColor: AppDesign.bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(context, month, year, status),
            const SizedBox(height: AppDesign.sm),
            _buildSummaryCards(earnings, deductions, netSalary),
            _buildEarningsSection(earnings),
            _buildDeductionsSection(deductions),
            _buildAttendanceSection(attendance),
            _buildPaymentInfo(transactionId),
            _buildFooter(netSalary),
            const SizedBox(height: AppDesign.lg),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader(
      BuildContext context, dynamic month, dynamic year, String status) {
    final (statusColor, statusSoft, statusBorder) = _slipStatusStyle(status);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppDesign.primary, AppDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: AppDesign.primary.withOpacity(0.25),
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
            AppDesign.md,
            AppDesign.sm,
            AppDesign.md,
            AppDesign.lg,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _glassIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _glassIconButton(
                    icon: Icons.share_rounded,
                    onTap: () => _shareSalarySlip(context),
                  ),
                  const SizedBox(width: AppDesign.sm),
                  _glassIconButton(
                    icon: Icons.download_rounded,
                    onTap: () => _downloadSalarySlip(context),
                  ),
                ],
              ),
              const SizedBox(height: AppDesign.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                ),
                child: const Text(
                  'COMPANY NAME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: AppDesign.md),
              const Text(
                'SALARY SLIP',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$month $year",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: AppDesign.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusSoft.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  border: Border.all(color: statusBorder, width: 1),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(AppDesign.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // ===================== SUMMARY =====================

  Widget _buildSummaryCards(Map earnings, Map deductions, double netSalary) {
    return Padding(
      padding: const EdgeInsets.all(AppDesign.md),
      child: Column(
        children: [
          // Hero net salary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDesign.md + 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppDesign.primary, AppDesign.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDesign.radiusLg),
              boxShadow: AppDesign.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white.withOpacity(0.85),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'NET SALARY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.85),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDesign.sm + 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '₹ ${netSalary.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesign.sm + 4),
          Row(
            children: [
              Expanded(
                child: _miniSummaryCard(
                  label: 'EARNINGS',
                  value: '₹ ${_toNum(earnings['total']).toStringAsFixed(2)}',
                  icon: Icons.trending_up_rounded,
                  color: AppDesign.present,
                  bg: AppDesign.presentSoft,
                  border: AppDesign.presentBorder,
                ),
              ),
              const SizedBox(width: AppDesign.sm + 2),
              Expanded(
                child: _miniSummaryCard(
                  label: 'DEDUCTIONS',
                  value:
                  '₹ ${_toNum(deductions['total']).toStringAsFixed(2)}',
                  icon: Icons.trending_down_rounded,
                  color: AppDesign.absent,
                  bg: AppDesign.absentSoft,
                  border: AppDesign.absentBorder,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.md - 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: AppDesign.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.sm + 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppDesign.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== SECTIONS =====================

  Widget _buildEarningsSection(Map earnings) {
    final items = earnings.entries.where((e) => e.key != 'total').toList();

    return _sectionContainer(
      title: 'Earnings Breakdown',
      icon: Icons.add_circle_outline_rounded,
      color: AppDesign.present,
      children: [
        if (items.isEmpty)
          _emptyRow('No earnings items')
        else
          ...items.map((e) =>
              _amountRow(e.key.toString(), e.value, AppDesign.present)),
        const Divider(height: AppDesign.lg, color: AppDesign.border),
        _amountRow(
          'Total Earnings',
          earnings['total'] ?? 0,
          AppDesign.present,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildDeductionsSection(Map deductions) {
    final items = deductions.entries.where((e) => e.key != 'total').toList();

    return _sectionContainer(
      title: 'Deductions',
      icon: Icons.remove_circle_outline_rounded,
      color: AppDesign.absent,
      children: [
        if (items.isEmpty)
          _emptyRow('No deductions')
        else
          ...items.map((e) =>
              _amountRow(e.key.toString(), e.value, AppDesign.absent)),
        const Divider(height: AppDesign.lg, color: AppDesign.border),
        _amountRow(
          'Total Deductions',
          deductions['total'] ?? 0,
          AppDesign.absent,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildAttendanceSection(Map attendance) {
    return _sectionContainer(
      title: 'Attendance Summary',
      icon: Icons.calendar_today_rounded,
      color: AppDesign.late,
      children: [
        _attendanceRow('Total Working Days', attendance['workDays'] ?? 0,
            Icons.work_outline_rounded),
        _attendanceRow('Present Days', attendance['presentDays'] ?? 0,
            Icons.check_circle_outline_rounded),
        _attendanceRow('Absent Days', attendance['absentDays'] ?? 0,
            Icons.cancel_outlined),
        _attendanceRow('Leave Days', attendance['leaveDays'] ?? 0,
            Icons.beach_access_rounded),
        _attendanceRow('Half Days', attendance['halfDays'] ?? 0,
            Icons.access_time_rounded),
      ],
    );
  }

  Widget _buildPaymentInfo(String? transactionId) {
    final paymentDate = payrollData['paymentDate'];

    return _sectionContainer(
      title: 'Payment Information',
      icon: Icons.payment_rounded,
      color: AppDesign.holiday,
      children: [
        _paymentRow(
          icon: Icons.credit_card_rounded,
          label: 'Payment Method',
          value: payrollData['paymentMethod']?.toString() ?? 'Not specified',
          color: AppDesign.holiday,
        ),
        _paymentRow(
          icon: Icons.receipt_long_rounded,
          label: 'Transaction ID',
          value: transactionId ?? 'N/A',
          color: AppDesign.present,
        ),
        if (paymentDate != null)
          _paymentRow(
            icon: Icons.date_range_rounded,
            label: 'Payment Date',
            value: _formatDate(paymentDate),
            color: AppDesign.late,
          ),
      ],
    );
  }

  // ===================== CONTAINERS / ROWS =====================

  Widget _sectionContainer({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesign.md,
        vertical: AppDesign.sm,
      ),
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: AppDesign.border, width: 1),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDesign.md),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(AppDesign.radiusSm - 2),
                    border: Border.all(
                        color: color.withOpacity(0.25), width: 1),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: AppDesign.sm + 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppDesign.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppDesign.border),
          Padding(
            padding: const EdgeInsets.all(AppDesign.md - 2),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, dynamic value, Color color,
      {bool isTotal = false}) {
    final numValue = _toNum(value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _formatLabel(label),
              style: TextStyle(
                fontSize: isTotal ? 13.5 : 12.5,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                color: isTotal
                    ? AppDesign.textPrimary
                    : AppDesign.textSecondary,
                letterSpacing: -0.1,
              ),
            ),
          ),
          Text(
            '₹ ${numValue.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 13.5,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceRow(String label, dynamic value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.xs),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppDesign.primarySoft,
              borderRadius: BorderRadius.circular(AppDesign.radiusSm - 2),
              border: Border.all(color: AppDesign.primaryLight, width: 1),
            ),
            child: Icon(icon, color: AppDesign.primary, size: 15),
          ),
          const SizedBox(width: AppDesign.sm + 2),
          Expanded(
            child: Text(
              _formatLabel(label),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppDesign.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.sm + 2,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppDesign.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppDesign.border, width: 1),
            ),
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppDesign.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.xs + 2),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesign.radiusSm - 2),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppDesign.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppDesign.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppDesign.textPrimary,
                    letterSpacing: -0.2,
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

  Widget _emptyRow(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.sm),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12,
          color: AppDesign.textMuted,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // ===================== FOOTER =====================

  Widget _buildFooter(double netSalary) {
    return Container(
      margin: const EdgeInsets.all(AppDesign.md),
      padding: const EdgeInsets.all(AppDesign.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppDesign.primary, AppDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        boxShadow: AppDesign.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.white.withOpacity(0.85),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'NET SALARY RECEIVED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.85),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.sm + 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '₹ ${netSalary.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: AppDesign.sm + 2),
          Text(
            'This is an electronically generated document',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HELPERS =====================

  (Color, Color, Color) _slipStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return (
        AppDesign.present,
        AppDesign.presentSoft,
        AppDesign.presentBorder
        );
      case 'pending':
        return (AppDesign.late, AppDesign.lateSoft, AppDesign.lateBorder);
      case 'failed':
        return (
        AppDesign.absent,
        AppDesign.absentSoft,
        AppDesign.absentBorder
        );
      default:
        return (
        AppDesign.neutral,
        AppDesign.neutralSoft,
        AppDesign.neutralBorder
        );
    }
  }

  double _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatDate(dynamic dateValue) {
    try {
      return DateFormat('dd MMMM yyyy')
          .format(DateTime.parse(dateValue.toString()));
    } catch (_) {
      return dateValue.toString();
    }
  }

  String _formatLabel(String label) {
    return label
        .split(RegExp(r'(?=[A-Z])|_'))
        .map((word) => word.isEmpty
        ? word
        : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  void _shareSalarySlip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share functionality coming soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppDesign.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        ),
      ),
    );
  }

  void _downloadSalarySlip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Download functionality coming soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppDesign.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        ),
      ),
    );
  }
}