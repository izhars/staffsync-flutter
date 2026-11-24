import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../services/api_exception.dart';
import '../services/payroll_api.dart';
import 'sal_slip_detail_screen.dart';

class AppDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

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
}


class PayrollListScreen extends StatefulWidget {
  const PayrollListScreen({super.key});

  @override
  State<PayrollListScreen> createState() => _PayrollListScreenState();
}

class _PayrollListScreenState extends State<PayrollListScreen> {
  final PayrollService _payrollService = PayrollService();

  bool loading = true;
  String? error;
  List<dynamic> payrolls = [];

  @override
  void initState() {
    super.initState();
    _loadPayrolls();
  }

  Future<void> _loadPayrolls() async {
    try {
      payrolls = await _payrollService.fetchMyPayrolls();
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = "Something went wrong";
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> _refresh() async {
    setState(() => loading = true);
    await _loadPayrolls();
  }

  (Color, Color, Color) _payrollStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return (AppDesign.present, AppDesign.presentSoft, AppDesign.presentBorder);
      case 'pending':
        return (AppDesign.late, AppDesign.lateSoft, AppDesign.lateBorder);
      case 'failed':
        return (AppDesign.absent, AppDesign.absentSoft, AppDesign.absentBorder);
      default:
        return (AppDesign.neutral, AppDesign.neutralSoft, AppDesign.neutralBorder);
    }
  }

  IconData _getPaymentMethodIcon(String? method) {
    switch (method?.toLowerCase()) {
      case 'bank transfer':
        return Icons.account_balance_rounded;
      case 'upi':
        return Icons.qr_code_rounded;
      case 'cash':
        return Icons.payments_rounded;
      case 'cheque':
        return Icons.description_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }

  // ===================== HEADER =====================

  Widget _buildHeader() {
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
            AppDesign.md,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDesign.sm + 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Salary Slips',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'View your payment history',
                      style: TextStyle(
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
                borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  onTap: loading ? null : _refresh,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.refresh_rounded,
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

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (loading) return _buildSkeletonLoader();
    if (error != null) return _buildErrorWidget();
    if (payrolls.isEmpty) return _buildEmptyWidget();

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppDesign.primary,
      backgroundColor: AppDesign.surface,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppDesign.md,
          AppDesign.md,
          AppDesign.md,
          AppDesign.xl,
        ),
        itemCount: payrolls.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppDesign.sm + 4),
        itemBuilder: (context, index) {
          final payroll = payrolls[index] as Map<String, dynamic>;
          return _payrollCard(payroll, context);
        },
      ),
    );
  }

  // ===================== STATES =====================

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: AppDesign.neutralSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 46,
                color: AppDesign.textMuted,
              ),
            ),
            const SizedBox(height: AppDesign.lg),
            const Text(
              'No salary slips found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppDesign.sm),
            const Text(
              'Your payslips will appear here once generated',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppDesign.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: AppDesign.absentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 46,
                color: AppDesign.absent,
              ),
            ),
            const SizedBox(height: AppDesign.lg),
            const Text(
              'Failed to load salary slips',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppDesign.sm),
            Text(
              error ?? 'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppDesign.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDesign.lg),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesign.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.lg,
                  vertical: AppDesign.sm + 4,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
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

  Widget _buildSkeletonLoader() {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: Color(0xFFE5E7EB),
        highlightColor: Color(0xFFF3F4F6),
        duration: Duration(seconds: 1),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppDesign.md,
          AppDesign.md,
          AppDesign.md,
          AppDesign.xl,
        ),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: AppDesign.sm + 4),
        itemBuilder: (_, __) => _skeletonCard(),
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: AppDesign.border, width: 1),
      ),
      padding: const EdgeInsets.all(AppDesign.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppDesign.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                ),
              ),
              const SizedBox(width: AppDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppDesign.surfaceMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 160,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppDesign.surfaceMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 22,
                decoration: BoxDecoration(
                  color: AppDesign.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.md),
          Container(height: 1, color: AppDesign.border),
          const SizedBox(height: AppDesign.md),
          Row(
            children: [
              Expanded(child: _skeletonTile()),
              const SizedBox(width: AppDesign.sm),
              Expanded(child: _skeletonTile()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skeletonTile() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.sm + 4),
      decoration: BoxDecoration(
        color: AppDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppDesign.sm),
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== CARD =====================

  Widget _payrollCard(Map<String, dynamic> payroll, BuildContext context) {
    final status = (payroll['status'] ?? 'unknown').toString();
    final (statusColor, statusSoft, statusBorder) = _payrollStatusStyle(status);

    final netSalary = payroll['netSalary'];
    final netSalaryText = netSalary is num
        ? netSalary.toStringAsFixed(2)
        : double.tryParse(netSalary?.toString() ?? '')?.toStringAsFixed(2) ??
        '0.00';

    return Container(
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: AppDesign.border, width: 1),
        boxShadow: AppDesign.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusLg),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SalarySlipDetailScreen(payrollData: payroll),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Header row ----
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppDesign.primarySoft,
                        borderRadius:
                        BorderRadius.circular(AppDesign.radiusSm),
                        border: Border.all(
                            color: AppDesign.primaryLight, width: 1),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppDesign.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppDesign.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${payroll['month']} ${payroll['year']}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppDesign.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "TXN · ${payroll['transactionId'] ?? 'N/A'}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppDesign.textMuted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDesign.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesign.sm + 2,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusBorder, width: 1),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDesign.md),
                Container(height: 1, color: AppDesign.border),
                const SizedBox(height: AppDesign.md),

                // ---- Info tiles ----
                Row(
                  children: [
                    Expanded(
                      child: _infoTile(
                        label: 'NET SALARY',
                        value: '₹ $netSalaryText',
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppDesign.present,
                      ),
                    ),
                    const SizedBox(width: AppDesign.sm),
                    Expanded(
                      child: _infoTile(
                        label: 'PAYMENT',
                        value: payroll['paymentMethod']?.toString() ?? 'N/A',
                        icon: _getPaymentMethodIcon(
                            payroll['paymentMethod']?.toString()),
                        color: AppDesign.holiday,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDesign.sm + 4),

                // ---- Tap hint ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppDesign.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppDesign.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.sm + 4),
      decoration: BoxDecoration(
        color: AppDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppDesign.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
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
}