// lib/screens/leaves_screen.dart
import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../models/leave.dart';
import '../services/leave_api.dart';

// ===================== SHARED DESIGN TOKENS =====================
class LeaveDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const Color primary = Color(0xFF059669);
  static const Color primaryDark = Color(0xFF047857);
  static const Color primarySoft = Color(0xFFECFDF5);
  static const Color primaryLight = Color(0xFFA7F3D0);

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

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralSoft = Color(0xFFF3F4F6);
  static const Color neutralBorder = Color(0xFFE5E7EB);

  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFF5F3FF);
  static const Color purpleBorder = Color(0xFFDDD6FE);

  static const Color pink = Color(0xFFDB2777);
  static const Color pinkSoft = Color(0xFFFDF2F8);
  static const Color pinkBorder = Color(0xFFFBCFE8);

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

// ===================== LEAVE TYPES (casual + combo only) =====================
const List<String> kSupportedLeaveTypes = ['casual', 'combo'];

// ===================== DATE HELPERS =====================
/// Strip time component so date pickers don't block today.
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Format a DateTime as `YYYY-MM-DD` for API payloads.
/// Avoids timezone ambiguity (no `T00:00:00+05:30` suffix).
String _toApiDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({Key? key}) : super(key: key);

  @override
  _LeavesScreenState createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen>
    with SingleTickerProviderStateMixin {
  final LeavesService _leaveService = LeavesService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late TabController _tabController;
  int _selectedTab = 0;
  String? _userRole;

  // ── Probation state ──
  bool _isProbationCompleted = false;
  DateTime? _probationEndDate;

  List<Leave> _leaves = [];
  LeaveBalance? _leaveBalance;
  bool _isLoading = true;
  bool _isBalanceLoading = true;
  bool _isLeavesLoading = false;

  final List<Map<String, dynamic>> _tabs = const [
    {'label': 'All', 'icon': Icons.list_alt_rounded},
    {'label': 'Pending', 'icon': Icons.hourglass_bottom_rounded},
    {'label': 'Approved', 'icon': Icons.check_circle_rounded},
    {'label': 'Rejected', 'icon': Icons.cancel_rounded},
    {'label': 'Cancelled', 'icon': Icons.block_rounded},
  ];

  bool get isEmployee => _userRole == 'employee';

  bool get _isOnProbation =>
      !_isProbationCompleted &&
          _probationEndDate != null &&
          DateTime.now().isBefore(_probationEndDate!);

  int get _probationDaysLeft {
    if (_probationEndDate == null) return 0;
    final diff = _probationEndDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
        _fetchLeavesWithStatus(
          _tabController.index == 0
              ? null
              : (_tabs[_tabController.index]['label'] as String).toLowerCase(),
        );
      }
    });
    _loadUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final userData = await _secureStorage.read(key: 'user_data');
    if (!mounted) return;
    if (userData != null) {
      final userMap = jsonDecode(userData);
      DateTime? probationEnd;
      final rawEnd = userMap['probationEndDate'];
      if (rawEnd != null) {
        try {
          probationEnd = DateTime.parse(rawEnd.toString());
        } catch (_) {
          probationEnd = null;
        }
      }
      setState(() {
        _userRole = userMap['role'] ?? 'employee';
        _isProbationCompleted = userMap['isProbationCompleted'] == true;
        _probationEndDate = probationEnd;
        _isLoading = false;
        _fetchData();
      });
    } else {
      setState(() {
        _userRole = 'employee';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchLeaves(),
      if (isEmployee) _fetchLeaveBalance(),
    ]);
  }

  Future<void> _cancelLeave(Leave leave) async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LeaveDesign.surface,
        surfaceTintColor: LeaveDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LeaveDesign.radiusLg),
        ),
        title: const Text(
          'Cancel Leave?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: LeaveDesign.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        content: const Text(
          'Are you sure you want to cancel this leave request? This action cannot be undone.',
          style: TextStyle(
            fontSize: 13.5,
            color: LeaveDesign.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: LeaveDesign.md,
          vertical: LeaveDesign.sm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: LeaveDesign.textSecondary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: LeaveDesign.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: LeaveDesign.md,
                vertical: LeaveDesign.sm + 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _leaveService.cancelLeave(leave.id);
        _showSnackBar('Leave cancelled successfully');
        _fetchData();
      } catch (e) {
        _showSnackBar('Failed to cancel leave', isError: true);
      }
    }
  }

  Future<void> _fetchLeaves() async {
    setState(() => _isLeavesLoading = true);
    try {
      List<dynamic> leavesData;
      if (isEmployee) {
        leavesData = await _leaveService.getMyLeaves();
      } else {
        leavesData = await _leaveService.getPendingLeaves();
      }
      if (!mounted) return;
      setState(() {
        _leaves = leavesData.map((json) => Leave.fromJson(json)).toList();
      });
    } catch (e) {
      _showSnackBar('Failed to load leaves', isError: true);
    } finally {
      if (mounted) setState(() => _isLeavesLoading = false);
    }
  }

  Future<void> _fetchLeavesWithStatus(String? status) async {
    setState(() => _isLeavesLoading = true);
    try {
      final data = await _leaveService.getMyLeaves(status: status);
      if (!mounted) return;
      setState(() => _leaves = data.map((j) => Leave.fromJson(j)).toList());
    } catch (e) {
      _showSnackBar('Error loading leaves', isError: true);
    } finally {
      if (mounted) setState(() => _isLeavesLoading = false);
    }
  }

  Future<void> _fetchLeaveBalance() async {
    if (!isEmployee) return;
    setState(() => _isBalanceLoading = true);
    try {
      final data = await _leaveService.getLeaveBalance();
      if (!mounted) return;
      setState(() => _leaveBalance = LeaveBalance.fromJson(data));
    } catch (e) {
      print('Balance error: $e');
    } finally {
      if (mounted) setState(() => _isBalanceLoading = false);
    }
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: LeaveDesign.bg,
        body: _isLoading
            ? const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor:
              AlwaysStoppedAnimation<Color>(LeaveDesign.primary),
            ),
          ),
        )
            : Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Column(
                children: [
                  if (isEmployee) ...[
                    if (_isOnProbation) _buildProbationBanner(),
                    _buildLeaveBalanceCard(),
                    _buildSegmentedTabs(),
                  ] else
                    _buildManagerBanner(),
                  Expanded(child: _buildLeavesList()),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton:
        isEmployee && !_isOnProbation ? _buildFab() : null,
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader() {
    final title = isEmployee ? 'My Leaves' : 'Team Leaves';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LeaveDesign.primary, LeaveDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(LeaveDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: LeaveDesign.primary.withOpacity(0.25),
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
            LeaveDesign.md,
            LeaveDesign.sm,
            LeaveDesign.md,
            LeaveDesign.md,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
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
              const SizedBox(width: LeaveDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEmployee
                          ? 'Manage your leave requests'
                          : 'Review and approve team leaves',
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
                borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.beach_access_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== FAB =====================

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LeaveDesign.radiusMd),
        boxShadow: [
          BoxShadow(
            color: LeaveDesign.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _openApplyLeaveSheet,
        backgroundColor: LeaveDesign.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Apply Leave',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            letterSpacing: -0.1,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LeaveDesign.radiusMd),
        ),
      ),
    );
  }

  // ===================== PROBATION BANNER =====================

  Widget _buildProbationBanner() {
    final daysLeft = _probationDaysLeft;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        LeaveDesign.md,
        LeaveDesign.md,
        LeaveDesign.md,
        0,
      ),
      padding: const EdgeInsets.all(LeaveDesign.md - 2),
      decoration: BoxDecoration(
        color: LeaveDesign.warningSoft,
        borderRadius: BorderRadius.circular(LeaveDesign.radiusMd),
        border: Border.all(color: LeaveDesign.warningBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: LeaveDesign.surface,
              borderRadius: BorderRadius.circular(LeaveDesign.radiusSm - 2),
              border: Border.all(color: LeaveDesign.warningBorder, width: 1),
            ),
            child: const Icon(
              Icons.hourglass_bottom_rounded,
              color: LeaveDesign.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: LeaveDesign.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'On Probation',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: LeaveDesign.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  daysLeft > 0
                      ? 'Leave & Combo Off unlock in $daysLeft day${daysLeft == 1 ? "" : "s"}'
                      : 'Completing soon — check back tomorrow',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: LeaveDesign.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== BALANCE CARD =====================

  Widget _buildLeaveBalanceCard() {
    if (_isBalanceLoading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          LeaveDesign.md,
          LeaveDesign.md,
          LeaveDesign.md,
          0,
        ),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: LeaveDesign.surface,
            borderRadius: BorderRadius.circular(LeaveDesign.radiusLg),
            border: Border.all(color: LeaveDesign.border, width: 1),
          ),
        ),
      );
    }

    if (_leaveBalance == null) return const SizedBox.shrink();

    final balance = _leaveBalance!;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        LeaveDesign.md,
        LeaveDesign.md,
        LeaveDesign.md,
        LeaveDesign.sm,
      ),
      padding: const EdgeInsets.all(LeaveDesign.lg - 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LeaveDesign.primary, LeaveDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LeaveDesign.radiusLg),
        boxShadow: [
          BoxShadow(
            color: LeaveDesign.primary.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(LeaveDesign.radiusSm - 2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              const SizedBox(width: LeaveDesign.sm + 2),
              const Text(
                'Leave Balance',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: LeaveDesign.md),
          Row(
            children: [
              _buildBalanceItem('Casual', balance.casual),
              _buildBalanceDivider(),
              _buildBalanceItem('Combo', balance.combo),
            ],
          ),
          if (balance.combo > 0) ...[
            const SizedBox(height: LeaveDesign.md - 4),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Combo credits are earned by working on holidays/weekends',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withOpacity(0.78),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, int count) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withOpacity(0.2),
    );
  }

  // ===================== MANAGER BANNER =====================

  Widget _buildManagerBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        LeaveDesign.md,
        LeaveDesign.md,
        LeaveDesign.md,
        LeaveDesign.sm,
      ),
      padding: const EdgeInsets.all(LeaveDesign.md - 2),
      decoration: BoxDecoration(
        color: LeaveDesign.surface,
        borderRadius: BorderRadius.circular(LeaveDesign.radiusMd),
        border: Border.all(color: LeaveDesign.border, width: 1),
        boxShadow: LeaveDesign.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: LeaveDesign.primarySoft,
              borderRadius: BorderRadius.circular(LeaveDesign.radiusSm - 2),
              border: Border.all(color: LeaveDesign.primaryLight, width: 1),
            ),
            child: const Icon(
              Icons.supervisor_account_rounded,
              color: LeaveDesign.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: LeaveDesign.sm + 2),
          const Expanded(
            child: Text(
              'Pending Approvals',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: LeaveDesign.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TABS =====================

  Widget _buildSegmentedTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LeaveDesign.md,
        vertical: LeaveDesign.sm,
      ),
      padding: const EdgeInsets.all(4),
      height: 46,
      decoration: BoxDecoration(
        color: LeaveDesign.surface,
        borderRadius: BorderRadius.circular(LeaveDesign.radiusMd),
        border: Border.all(color: LeaveDesign.border, width: 1),
        boxShadow: LeaveDesign.softShadow,
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: LeaveDesign.primary,
          borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
          boxShadow: [
            BoxShadow(
              color: LeaveDesign.primary.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
              spreadRadius: -2,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.zero,
        labelColor: Colors.white,
        unselectedLabelColor: LeaveDesign.textSecondary,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        splashFactory: NoSplash.splashFactory,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          letterSpacing: -0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
          letterSpacing: -0.1,
        ),
        tabs: _tabs.map((tab) {
          return Tab(
            height: 38,
            child: Text(tab['label'] as String),
          );
        }).toList(),
      ),
    );
  }

  // ===================== LIST =====================

  Widget _buildLeavesList() {
    if (_isLeavesLoading) return _buildShimmerList();
    if (_leaves.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: LeaveDesign.primary,
      backgroundColor: LeaveDesign.surface,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          LeaveDesign.md,
          LeaveDesign.sm,
          LeaveDesign.md,
          LeaveDesign.xl,
        ),
        itemCount: _leaves.length,
        itemBuilder: (context, index) => _buildLeaveCard(_leaves[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LeaveDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: LeaveDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 40,
                color: LeaveDesign.primary,
              ),
            ),
            const SizedBox(height: LeaveDesign.lg),
            Text(
              'No ${_tabs[_selectedTab]['label'].toString().toLowerCase()} leaves',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: LeaveDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: LeaveDesign.sm),
            const Text(
              'Your leave requests will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: LeaveDesign.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        LeaveDesign.md,
        LeaveDesign.sm,
        LeaveDesign.md,
        LeaveDesign.xl,
      ),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        height: 96,
        margin: const EdgeInsets.only(bottom: LeaveDesign.sm + 4),
        decoration: BoxDecoration(
          color: LeaveDesign.surfaceMuted,
          borderRadius: BorderRadius.circular(LeaveDesign.radiusLg),
          border: Border.all(color: LeaveDesign.border, width: 1),
        ),
      ),
    );
  }

  // ===================== LEAVE CARD =====================

  Widget _buildLeaveCard(Leave leave) {
    final isManager = !isEmployee;
    final (statusColor, statusSoft, statusBorder) = _statusStyle(leave.status);

    return Container(
      margin: const EdgeInsets.only(bottom: LeaveDesign.sm + 4),
      decoration: BoxDecoration(
        color: LeaveDesign.surface,
        borderRadius: BorderRadius.circular(LeaveDesign.radiusLg),
        border: Border.all(color: LeaveDesign.border, width: 1),
        boxShadow: LeaveDesign.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(LeaveDesign.radiusLg),
          onTap: () => _showLeaveDetails(leave),
          child: Padding(
            padding: const EdgeInsets.all(LeaveDesign.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusSoft,
                        borderRadius:
                        BorderRadius.circular(LeaveDesign.radiusSm),
                        border: Border.all(color: statusBorder, width: 1),
                      ),
                      child: Icon(
                        _getStatusIcon(leave.status),
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: LeaveDesign.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isManager
                                ? leave.employeeName
                                : leave.displayLeaveType,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: LeaveDesign.textPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isManager) ...[
                            const SizedBox(height: 3),
                            Text(
                              leave.displayLeaveType,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: LeaveDesign.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 11,
                                color: LeaveDesign.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  leave.formattedDateRange,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: LeaveDesign.textSecondary,
                                    fontWeight: FontWeight.w600,
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
                  ],
                ),
                const SizedBox(height: LeaveDesign.md),
                Row(
                  children: [
                    _buildTypeChip(leave.leaveType),
                    const Spacer(),
                    if (isManager && leave.status == 'pending') ...[
                      _buildActionButton(
                        label: 'Approve',
                        icon: Icons.check_rounded,
                        color: LeaveDesign.success,
                        bg: LeaveDesign.successSoft,
                        border: LeaveDesign.successBorder,
                        onTap: () => _approveLeave(leave.id),
                      ),
                      const SizedBox(width: 6),
                      _buildActionButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        color: LeaveDesign.danger,
                        bg: LeaveDesign.dangerSoft,
                        border: LeaveDesign.dangerBorder,
                        onTap: () => _rejectLeave(leave.id),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: LeaveDesign.sm + 2,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusSoft,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              leave.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                                letterSpacing: 0.4,
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
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    final (color, bg, border) = _leaveTypeStyle(type);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LeaveDesign.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_leaveTypeIcon(type), size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LeaveDesign.sm + 2,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== STATUS / TYPE STYLES =====================

  (Color, Color, Color) _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return (
        LeaveDesign.success,
        LeaveDesign.successSoft,
        LeaveDesign.successBorder
        );
      case 'rejected':
        return (
        LeaveDesign.danger,
        LeaveDesign.dangerSoft,
        LeaveDesign.dangerBorder
        );
      case 'cancelled':
        return (
        LeaveDesign.neutral,
        LeaveDesign.neutralSoft,
        LeaveDesign.neutralBorder
        );
      default:
        return (
        LeaveDesign.warning,
        LeaveDesign.warningSoft,
        LeaveDesign.warningBorder
        );
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'cancelled':
        return Icons.block_rounded;
      default:
        return Icons.hourglass_bottom_rounded;
    }
  }

  (Color, Color, Color) _leaveTypeStyle(String type) {
    switch (type.toLowerCase()) {
      case 'casual':
        return (
        LeaveDesign.warning,
        LeaveDesign.warningSoft,
        LeaveDesign.warningBorder
        );
      case 'combo':
        return (
        LeaveDesign.purple,
        LeaveDesign.purpleSoft,
        LeaveDesign.purpleBorder
        );
      default:
        return (
        LeaveDesign.neutral,
        LeaveDesign.neutralSoft,
        LeaveDesign.neutralBorder
        );
    }
  }

  IconData _leaveTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'casual':
        return Icons.beach_access_rounded;
      case 'combo':
        return Icons.all_inclusive_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // ===================== LEAVE DETAILS SHEET =====================

  void _showLeaveDetails(Leave leave) {
    final (statusColor, statusSoft, statusBorder) =
    _statusStyle(leave.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: LeaveDesign.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(LeaveDesign.radiusXl),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: LeaveDesign.sm + 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: LeaveDesign.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(LeaveDesign.lg),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: statusSoft,
                            borderRadius: BorderRadius.circular(
                              LeaveDesign.radiusSm + 2,
                            ),
                            border:
                            Border.all(color: statusBorder, width: 1),
                          ),
                          child: Icon(
                            _getStatusIcon(leave.status),
                            color: statusColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: LeaveDesign.sm + 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                leave.displayLeaveType,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: LeaveDesign.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: LeaveDesign.sm + 2,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusSoft,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  leave.status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9.5,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: LeaveDesign.lg),
                    _buildDetailRow(
                      Icons.calendar_today_rounded,
                      'Duration',
                      leave.formattedDateRange,
                    ),
                    _buildDetailRow(
                      Icons.access_time_rounded,
                      'Total Days',
                      leave.durationDisplay,
                    ),
                    _buildDetailRow(
                      Icons.event_rounded,
                      'Applied On',
                      _formatDate(leave.appliedOn),
                    ),
                    if (leave.reason.isNotEmpty) ...[
                      const SizedBox(height: LeaveDesign.md),
                      const Text(
                        'REASON',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: LeaveDesign.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: LeaveDesign.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(LeaveDesign.sm + 4),
                        decoration: BoxDecoration(
                          color: LeaveDesign.surfaceMuted,
                          borderRadius:
                          BorderRadius.circular(LeaveDesign.radiusSm),
                          border: Border.all(
                            color: LeaveDesign.border,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          leave.reason,
                          style: const TextStyle(
                            fontSize: 13,
                            color: LeaveDesign.textPrimary,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (leave.status == 'rejected' &&
                        leave.rejectionReason != null) ...[
                      const SizedBox(height: LeaveDesign.md),
                      const Text(
                        'REJECTION REASON',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: LeaveDesign.danger,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: LeaveDesign.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(LeaveDesign.sm + 4),
                        decoration: BoxDecoration(
                          color: LeaveDesign.dangerSoft,
                          borderRadius:
                          BorderRadius.circular(LeaveDesign.radiusSm),
                          border: Border.all(
                            color: LeaveDesign.dangerBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          leave.rejectionReason!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: LeaveDesign.danger,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (leave.status == 'cancelled' &&
                        leave.cancellationReason != null) ...[
                      const SizedBox(height: LeaveDesign.md),
                      const Text(
                        'CANCELLATION REASON',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: LeaveDesign.neutral,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: LeaveDesign.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(LeaveDesign.sm + 4),
                        decoration: BoxDecoration(
                          color: LeaveDesign.neutralSoft,
                          borderRadius:
                          BorderRadius.circular(LeaveDesign.radiusSm),
                          border: Border.all(
                            color: LeaveDesign.neutralBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          leave.cancellationReason!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: LeaveDesign.neutral,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (isEmployee &&
                        (leave.status == 'pending' ||
                            leave.status == 'approved')) ...[
                      const SizedBox(height: LeaveDesign.lg),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelLeave(leave),
                          icon: const Icon(
                            Icons.cancel_outlined,
                            size: 18,
                          ),
                          label: const Text('Cancel Leave'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: LeaveDesign.danger,
                            side: const BorderSide(
                              color: LeaveDesign.dangerBorder,
                              width: 1,
                            ),
                            backgroundColor: LeaveDesign.dangerSoft,
                            padding: const EdgeInsets.symmetric(
                              vertical: LeaveDesign.md - 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                LeaveDesign.radiusSm,
                              ),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LeaveDesign.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: LeaveDesign.surfaceMuted,
              borderRadius:
              BorderRadius.circular(LeaveDesign.radiusSm - 2),
            ),
            child: Icon(
              icon,
              size: 15,
              color: LeaveDesign.textSecondary,
            ),
          ),
          const SizedBox(width: LeaveDesign.sm + 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: LeaveDesign.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: LeaveDesign.textPrimary,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // ===================== APPLY LEAVE SHEET =====================

  void _openApplyLeaveSheet() {
    final formKey = GlobalKey<FormState>();
    String? leaveType;
    DateTime? startDate;
    DateTime? endDate;
    String leaveDuration = 'full';
    String? halfDayType;
    final reasonController = TextEditingController();

    // First selectable date: today at midnight (so today is allowed)
    final today = _dateOnly(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: LeaveDesign.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(LeaveDesign.radiusXl),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: LeaveDesign.sm + 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LeaveDesign.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Form(
                    key: formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(LeaveDesign.lg),
                      children: [
                        const Text(
                          'Apply for Leave',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: LeaveDesign.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Fill in the details below to submit your request',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: LeaveDesign.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: LeaveDesign.lg),

                        // Leave Type — only casual + combo
                        _buildFieldLabel('LEAVE TYPE'),
                        const SizedBox(height: LeaveDesign.sm),
                        DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            isExpanded: true,
                            value: leaveType,
                            hint: Row(
                              children: [
                                const Icon(
                                  Icons.category_rounded,
                                  size: 18,
                                  color: LeaveDesign.textMuted,
                                ),
                                const SizedBox(width: LeaveDesign.sm),
                                Text(
                                  'Select leave type',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: LeaveDesign.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            items: kSupportedLeaveTypes.map((type) {
                              final (color, bg, border) =
                              _leaveTypeStyle(type);
                              return DropdownMenuItem(
                                value: type,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius:
                                        BorderRadius.circular(6),
                                        border: Border.all(
                                          color: border,
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        _leaveTypeIcon(type),
                                        size: 12,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(
                                        width: LeaveDesign.sm + 2),
                                    Text(
                                      type[0].toUpperCase() +
                                          type.substring(1),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: LeaveDesign.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setModalState(() => leaveType = val),
                            buttonStyleData: ButtonStyleData(
                              height: 52,
                              padding: const EdgeInsets.symmetric(
                                horizontal: LeaveDesign.md,
                              ),
                              decoration: BoxDecoration(
                                color: LeaveDesign.surfaceMuted,
                                borderRadius: BorderRadius.circular(
                                  LeaveDesign.radiusSm,
                                ),
                                border: Border.all(
                                  color: LeaveDesign.border,
                                  width: 1,
                                ),
                              ),
                            ),
                            iconStyleData: const IconStyleData(
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: LeaveDesign.textMuted,
                              ),
                              iconSize: 20,
                            ),
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  LeaveDesign.radiusMd,
                                ),
                                color: LeaveDesign.surface,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    Colors.black.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Combo hint
                        if (leaveType == 'combo') ...[
                          const SizedBox(height: LeaveDesign.sm),
                          Container(
                            padding: const EdgeInsets.all(
                              LeaveDesign.sm + 2,
                            ),
                            decoration: BoxDecoration(
                              color: LeaveDesign.purpleSoft,
                              borderRadius: BorderRadius.circular(
                                LeaveDesign.radiusSm,
                              ),
                              border: Border.all(
                                color: LeaveDesign.purpleBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: LeaveDesign.purple,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Combo available: ${_leaveBalance?.combo ?? 0} day(s). Full-day only.',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: LeaveDesign.purple,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: LeaveDesign.md),

                        // Duration toggle
                        _buildFieldLabel('DURATION'),
                        const SizedBox(height: LeaveDesign.sm),
                        _buildDurationSelector(
                          current: leaveDuration,
                          onChanged: (val) {
                            setModalState(() {
                              leaveDuration = val;
                              if (val == 'full') halfDayType = null;
                            });
                          },
                        ),

                        if (leaveDuration == 'half') ...[
                          const SizedBox(height: LeaveDesign.md),
                          _buildFieldLabel('HALF DAY TYPE'),
                          const SizedBox(height: LeaveDesign.sm),
                          _buildHalfDaySelector(
                            current: halfDayType,
                            onChanged: (val) => setModalState(
                                  () => halfDayType = val,
                            ),
                          ),
                        ],

                        const SizedBox(height: LeaveDesign.md),

                        // Start Date
                        _buildFieldLabel('START DATE'),
                        const SizedBox(height: LeaveDesign.sm),
                        _buildDateField(
                          label: startDate != null
                              ? DateFormat('EEE, MMM dd, yyyy')
                              .format(startDate!)
                              : 'Select start date',
                          hasValue: startDate != null,
                          icon: Icons.calendar_today_rounded,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? today,
                              firstDate: today, // ✅ allows today
                              lastDate: today.add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                startDate = _dateOnly(picked);
                                if (leaveDuration == 'half') {
                                  endDate = _dateOnly(picked);
                                }
                                // If endDate is now before new startDate, clear it
                                if (endDate != null &&
                                    endDate!.isBefore(startDate!)) {
                                  endDate = null;
                                }
                              });
                            }
                          },
                        ),

                        // End Date (full day only)
                        if (leaveDuration == 'full') ...[
                          const SizedBox(height: LeaveDesign.md),
                          _buildFieldLabel('END DATE'),
                          const SizedBox(height: LeaveDesign.sm),
                          _buildDateField(
                            label: endDate != null
                                ? DateFormat('EEE, MMM dd, yyyy')
                                .format(endDate!)
                                : 'Select end date',
                            hasValue: endDate != null,
                            icon: Icons.event_rounded,
                            onTap: () async {
                              final minEnd = startDate ?? today;
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                endDate ?? startDate ?? today,
                                firstDate: minEnd, // ✅ no earlier than start
                                lastDate:
                                today.add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setModalState(
                                      () => endDate = _dateOnly(picked),
                                );
                              }
                            },
                          ),
                        ],

                        const SizedBox(height: LeaveDesign.md),

                        // Reason
                        _buildFieldLabel('REASON'),
                        const SizedBox(height: LeaveDesign.sm),
                        TextFormField(
                          controller: reasonController,
                          maxLines: 4,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: LeaveDesign.textPrimary,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText:
                            'Provide a brief reason for your leave request...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: LeaveDesign.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            filled: true,
                            fillColor: LeaveDesign.surfaceMuted,
                            contentPadding:
                            const EdgeInsets.all(LeaveDesign.md),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                LeaveDesign.radiusSm,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                LeaveDesign.radiusSm,
                              ),
                              borderSide: const BorderSide(
                                color: LeaveDesign.border,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                LeaveDesign.radiusSm,
                              ),
                              borderSide: const BorderSide(
                                color: LeaveDesign.primary,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                LeaveDesign.radiusSm,
                              ),
                              borderSide: const BorderSide(
                                color: LeaveDesign.danger,
                                width: 1,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                LeaveDesign.radiusSm,
                              ),
                              borderSide: const BorderSide(
                                color: LeaveDesign.danger,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Please enter a reason'
                              : null,
                        ),

                        const SizedBox(height: LeaveDesign.lg),

                        // Submit
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              if (leaveType == null) {
                                _showSnackBar(
                                  'Please select leave type',
                                  isError: true,
                                );
                                return;
                              }
                              if (startDate == null) {
                                _showSnackBar(
                                  'Please select start date',
                                  isError: true,
                                );
                                return;
                              }

                              // Combo + half-day guard
                              if (leaveType == 'combo' &&
                                  leaveDuration == 'half') {
                                _showSnackBar(
                                  'Combo leave cannot be half-day',
                                  isError: true,
                                );
                                return;
                              }

                              // Combo balance guard
                              if (leaveType == 'combo' &&
                                  (_leaveBalance?.combo ?? 0) < 1) {
                                _showSnackBar(
                                  'You have no combo credits available',
                                  isError: true,
                                );
                                return;
                              }

                              // Half-day type guard
                              if (leaveDuration == 'half' &&
                                  halfDayType == null) {
                                _showSnackBar(
                                  'Please select half-day type',
                                  isError: true,
                                );
                                return;
                              }

                              final effectiveEndDate =
                              leaveDuration == 'half'
                                  ? startDate
                                  : endDate;

                              if (effectiveEndDate == null) {
                                _showSnackBar(
                                  'Please select end date',
                                  isError: true,
                                );
                                return;
                              }

                              // End >= Start guard
                              if (leaveDuration == 'full' &&
                                  effectiveEndDate.isBefore(startDate!)) {
                                _showSnackBar(
                                  'End date cannot be before start date',
                                  isError: true,
                                );
                                return;
                              }

                              Navigator.pop(context);

                              try {
                                final leaveData = <String, dynamic>{
                                  "leaveType": leaveType,
                                  // ✅ Send YYYY-MM-DD (no time/timezone)
                                  "startDate": _toApiDate(startDate!),
                                  "endDate": _toApiDate(effectiveEndDate),
                                  "reason": reasonController.text.trim(),
                                  "leaveDuration": leaveDuration,
                                };

                                if (leaveDuration == 'half' &&
                                    halfDayType != null) {
                                  leaveData["halfDayType"] = halfDayType!;
                                }

                                await _leaveService.applyLeave(leaveData);
                                _showSnackBar(
                                  'Leave applied successfully!',
                                );
                                _fetchData();
                              } catch (e) {
                                _showSnackBar(
                                  'Failed to apply leave',
                                  isError: true,
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.send_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Submit Application',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LeaveDesign.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  LeaveDesign.radiusMd,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: LeaveDesign.md),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: LeaveDesign.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildDurationSelector({
    required String current,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LeaveDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
        border: Border.all(color: LeaveDesign.border, width: 1),
      ),
      child: Row(
        children: [
          _buildDurationOption(
            label: 'Full Day',
            icon: Icons.calendar_today_rounded,
            value: 'full',
            selected: current == 'full',
            onTap: () => onChanged('full'),
          ),
          const SizedBox(width: 4),
          _buildDurationOption(
            label: 'Half Day',
            icon: Icons.timer_outlined,
            value: 'half',
            selected: current == 'half',
            onTap: () => onChanged('half'),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption({
    required String label,
    required IconData icon,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(LeaveDesign.radiusSm - 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(LeaveDesign.radiusSm - 2),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
            const EdgeInsets.symmetric(vertical: LeaveDesign.sm + 4),
            decoration: BoxDecoration(
              color: selected ? LeaveDesign.surface : Colors.transparent,
              borderRadius:
              BorderRadius.circular(LeaveDesign.radiusSm - 2),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? LeaveDesign.primary
                      : LeaveDesign.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                    selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? LeaveDesign.textPrimary
                        : LeaveDesign.textSecondary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHalfDaySelector({
    required String? current,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LeaveDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
        border: Border.all(color: LeaveDesign.border, width: 1),
      ),
      child: Row(
        children: [
          _buildDurationOption(
            label: 'First Half',
            icon: Icons.wb_twilight_rounded,
            value: 'first_half',
            selected: current == 'first_half',
            onTap: () => onChanged('first_half'),
          ),
          const SizedBox(width: 4),
          _buildDurationOption(
            label: 'Second Half',
            icon: Icons.wb_sunny_outlined,
            value: 'second_half',
            selected: current == 'second_half',
            onTap: () => onChanged('second_half'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required bool hasValue,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LeaveDesign.md,
            vertical: LeaveDesign.md - 2,
          ),
          decoration: BoxDecoration(
            color: LeaveDesign.surfaceMuted,
            borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
            border: Border.all(color: LeaveDesign.border, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: hasValue
                    ? LeaveDesign.primary
                    : LeaveDesign.textMuted,
              ),
              const SizedBox(width: LeaveDesign.sm + 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight:
                    hasValue ? FontWeight.w600 : FontWeight.w500,
                    color: hasValue
                        ? LeaveDesign.textPrimary
                        : LeaveDesign.textMuted,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: LeaveDesign.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== APPROVE / REJECT =====================

  Future<void> _approveLeave(String id) async {
    try {
      await _leaveService.approveLeave(id);
      _showSnackBar('Leave approved');
      _fetchData();
    } catch (e) {
      _showSnackBar('Failed to approve leave', isError: true);
    }
  }

  Future<void> _rejectLeave(String id) async {
    final reason = await _showRejectionDialog();
    if (reason == null) return;
    try {
      await _leaveService.rejectLeave(id, reason);
      _showSnackBar('Leave rejected');
      _fetchData();
    } catch (e) {
      _showSnackBar('Failed to reject leave', isError: true);
    }
  }

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LeaveDesign.surface,
        surfaceTintColor: LeaveDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LeaveDesign.radiusLg),
        ),
        title: const Text(
          'Reject Leave',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: LeaveDesign.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: LeaveDesign.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Reason for rejection...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: LeaveDesign.textMuted,
            ),
            filled: true,
            fillColor: LeaveDesign.surfaceMuted,
            contentPadding: const EdgeInsets.all(LeaveDesign.sm + 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
              borderSide: const BorderSide(
                color: LeaveDesign.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
              borderSide: const BorderSide(
                color: LeaveDesign.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: LeaveDesign.md,
          vertical: LeaveDesign.sm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: LeaveDesign.textSecondary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: LeaveDesign.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor:
        isError ? LeaveDesign.danger : LeaveDesign.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LeaveDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(LeaveDesign.md),
      ),
    );
  }
}