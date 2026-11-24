// screens/celebration_screen.dart

import 'package:flutter/material.dart';
import '../models/celebration.dart';
import '../services/auth_service.dart';
import '../services/celebration_api.dart';
import 'received_regards_screen.dart';

// ===================== SHARED DESIGN TOKENS =====================
class CelebrationDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color primaryLight = Color(0xFFC7D2FE);

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color birthday = Color(0xFFEC4899);
  static const Color birthdaySoft = Color(0xFFFDF2F8);

  static const Color workAnniversary = Color(0xFF8B5CF6);
  static const Color workAnniversarySoft = Color(0xFFF5F3FF);

  static const Color marriageAnniversary = Color(0xFFF59E0B);
  static const Color marriageAnniversarySoft = Color(0xFFFFFBEB);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

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

  static Color colorFor(CelebrationType t) {
    switch (t) {
      case CelebrationType.birthday:
        return birthday;
      case CelebrationType.workAnniversary:
        return workAnniversary;
      case CelebrationType.marriageAnniversary:
        return marriageAnniversary;
    }
  }

  static Color softFor(CelebrationType t) {
    switch (t) {
      case CelebrationType.birthday:
        return birthdaySoft;
      case CelebrationType.workAnniversary:
        return workAnniversarySoft;
      case CelebrationType.marriageAnniversary:
        return marriageAnniversarySoft;
    }
  }
}

class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({super.key});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with SingleTickerProviderStateMixin {
  final CelebrationService _celebrationService = CelebrationService();
  final AuthService _authService = AuthService(); // 👈 your auth service
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  String? _currentUserEmployeeId;

  TodayCelebrations? _todayCelebrations;
  UpcomingCelebrations? _upcomingCelebrations;
  int _unreadRegards = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCelebrations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCelebrations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 👇 Load current user first, so we know who "self" is
      final currentUser = await _authService.getCurrentUser();
      _currentUserEmployeeId =
          currentUser?.employeeId?.toString().trim().toLowerCase();

      final todayResponse = await _celebrationService.getTodayCelebrations();
      final upcomingResponse = await _celebrationService.getUpcomingCelebrations();
      final unread = await _celebrationService.getUnreadReceivedCount();

      setState(() {
        _todayCelebrations = todayResponse.data.today;
        _upcomingCelebrations = upcomingResponse.data.upcoming;
        _unreadRegards = unread;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Returns true if [employeeId] belongs to the currently logged-in user.
  bool _isSelf(String? employeeId) {
    if (employeeId == null || _currentUserEmployeeId == null) return false;
    return employeeId.trim().toLowerCase() == _currentUserEmployeeId;
  }

  Future<void> _openRegards() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReceivedRegardsScreen()),
    );
    // refresh badge after returning
    final n = await _celebrationService.getUnreadReceivedCount();
    if (!mounted) return;
    setState(() => _unreadRegards = n);
  }

  Future<void> _onRegardSent() async {
    final n = await _celebrationService.getUnreadReceivedCount();
    if (!mounted) return;
    setState(() => _unreadRegards = n);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CelebrationDesign.bg,
      body: _isLoading ? _buildSkeleton() : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildHeader(),
        if (_error != null)
          Expanded(child: _buildErrorView())
        else
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayView(),
                _buildUpcomingView(),
              ],
            ),
          ),
      ],
    );
  }

  // ===================== HEADER =====================
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            CelebrationDesign.primary,
            CelebrationDesign.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(CelebrationDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: CelebrationDesign.primary.withOpacity(0.25),
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
            CelebrationDesign.md,
            CelebrationDesign.sm,
            CelebrationDesign.md,
            CelebrationDesign.sm,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(CelebrationDesign.radiusSm),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(CelebrationDesign.radiusSm),
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
                  const SizedBox(width: CelebrationDesign.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Celebrations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Birthdays, anniversaries & milestones',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Inbox / received regards with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(
                            CelebrationDesign.radiusSm),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                              CelebrationDesign.radiusSm),
                          onTap: _openRegards,
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.card_giftcard_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      if (_unreadRegards > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            decoration: const BoxDecoration(
                              color: CelebrationDesign.birthday,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_unreadRegards',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: CelebrationDesign.sm),
                  Material(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(CelebrationDesign.radiusSm),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(CelebrationDesign.radiusSm),
                      onTap: _loadCelebrations,
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
              const SizedBox(height: CelebrationDesign.sm + 4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius:
                  BorderRadius.circular(CelebrationDesign.radiusMd),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: CelebrationDesign.surface,
                    borderRadius:
                    BorderRadius.circular(CelebrationDesign.radiusSm),
                    boxShadow: CelebrationDesign.softShadow,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: CelebrationDesign.primaryDark,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: -0.1,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Today'),
                    Tab(text: 'Upcoming'),
                  ],
                ),
              ),
              const SizedBox(height: CelebrationDesign.sm),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== ERROR =====================
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CelebrationDesign.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CelebrationDesign.dangerSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: CelebrationDesign.dangerBorder,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: CelebrationDesign.danger,
              ),
            ),
            const SizedBox(height: CelebrationDesign.md),
            const Text(
              'Error loading celebrations',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: CelebrationDesign.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: CelebrationDesign.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: CelebrationDesign.md),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _loadCelebrations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CelebrationDesign.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: CelebrationDesign.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(CelebrationDesign.radiusMd),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== TODAY =====================
  Widget _buildTodayView() {
    if (_todayCelebrations == null) {
      return _buildEmptyState(
        'No data available',
        '📅',
        'Pull to refresh',
      );
    }

    final total = _todayCelebrations!.birthdays.count +
        _todayCelebrations!.marriageAnniversaries.count +
        _todayCelebrations!.workAnniversaries.count;

    if (total == 0) {
      return _buildEmptyState(
        'No celebrations today',
        '🎈',
        'Check back tomorrow for milestones',
      );
    }

    return RefreshIndicator(
      color: CelebrationDesign.primary,
      onRefresh: _loadCelebrations,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          CelebrationDesign.md,
          CelebrationDesign.md,
          CelebrationDesign.md,
          CelebrationDesign.lg,
        ),
        children: [
          if (_todayCelebrations!.birthdays.count > 0) ...[
            _buildSectionLabel(
              '🎂 BIRTHDAYS',
              '${_todayCelebrations!.birthdays.count} celebrating today',
            ),
            const SizedBox(height: CelebrationDesign.sm + 4),
            ..._todayCelebrations!.birthdays.data.map(
                  (e) => Padding(
                padding:
                const EdgeInsets.only(bottom: CelebrationDesign.sm + 2),
                child: _buildTodayCard(e, CelebrationType.birthday),
              ),
            ),
            const SizedBox(height: CelebrationDesign.md),
          ],
          if (_todayCelebrations!.workAnniversaries.count > 0) ...[
            _buildSectionLabel(
              '💼 WORK ANNIVERSARIES',
              '${_todayCelebrations!.workAnniversaries.count} milestone${_todayCelebrations!.workAnniversaries.count == 1 ? "" : "s"} today',
            ),
            const SizedBox(height: CelebrationDesign.sm + 4),
            ..._todayCelebrations!.workAnniversaries.data.map(
                  (e) => Padding(
                padding:
                const EdgeInsets.only(bottom: CelebrationDesign.sm + 2),
                child:
                _buildTodayCard(e, CelebrationType.workAnniversary),
              ),
            ),
            const SizedBox(height: CelebrationDesign.md),
          ],
          if (_todayCelebrations!.marriageAnniversaries.count > 0) ...[
            _buildSectionLabel(
              '💍 MARRIAGE ANNIVERSARIES',
              '${_todayCelebrations!.marriageAnniversaries.count} couple${_todayCelebrations!.marriageAnniversaries.count == 1 ? "" : "s"} today',
            ),
            const SizedBox(height: CelebrationDesign.sm + 4),
            ..._todayCelebrations!.marriageAnniversaries.data.map(
                  (e) => Padding(
                padding:
                const EdgeInsets.only(bottom: CelebrationDesign.sm + 2),
                child:
                _buildTodayCard(e, CelebrationType.marriageAnniversary),
              ),
            ),
            const SizedBox(height: CelebrationDesign.md),
          ],
        ],
      ),
    );
  }

  // ===================== UPCOMING =====================
  Widget _buildUpcomingView() {
    if (_upcomingCelebrations == null) {
      return _buildEmptyState(
        'No data available',
        '📅',
        'Pull to refresh',
      );
    }

    final total = _upcomingCelebrations!.birthdays.length +
        _upcomingCelebrations!.marriageAnniversaries.length +
        _upcomingCelebrations!.workAnniversaries.length;

    if (total == 0) {
      return _buildEmptyState(
        'No upcoming celebrations',
        '📅',
        'Nothing scheduled in the near future',
      );
    }

    return RefreshIndicator(
      color: CelebrationDesign.primary,
      onRefresh: _loadCelebrations,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          CelebrationDesign.md,
          CelebrationDesign.md,
          CelebrationDesign.md,
          CelebrationDesign.lg,
        ),
        children: [
          if (_upcomingCelebrations!.birthdays.isNotEmpty) ...[
            _buildSectionLabel(
              '🎂 UPCOMING BIRTHDAYS',
              '${_upcomingCelebrations!.birthdays.length} coming up',
            ),
            const SizedBox(height: CelebrationDesign.sm + 4),
            ..._upcomingCelebrations!.birthdays.map(
                  (e) => Padding(
                padding:
                const EdgeInsets.only(bottom: CelebrationDesign.sm + 2),
                child: _buildUpcomingCard(e, CelebrationType.birthday),
              ),
            ),
            const SizedBox(height: CelebrationDesign.md),
          ],
          if (_upcomingCelebrations!.workAnniversaries.isNotEmpty) ...[
            _buildSectionLabel(
              '💼 UPCOMING WORK ANNIVERSARIES',
              '${_upcomingCelebrations!.workAnniversaries.length} coming up',
            ),
            const SizedBox(height: CelebrationDesign.sm + 4),
            ..._upcomingCelebrations!.workAnniversaries.map(
                  (e) => Padding(
                padding:
                const EdgeInsets.only(bottom: CelebrationDesign.sm + 2),
                child: _buildUpcomingCard(
                    e, CelebrationType.workAnniversary),
              ),
            ),
            const SizedBox(height: CelebrationDesign.md),
          ],
          if (_upcomingCelebrations!.marriageAnniversaries.isNotEmpty) ...[
            _buildSectionLabel(
              '💍 UPCOMING MARRIAGE ANNIVERSARIES',
              '${_upcomingCelebrations!.marriageAnniversaries.length} coming up',
            ),
            const SizedBox(height: CelebrationDesign.sm + 4),
            ..._upcomingCelebrations!.marriageAnniversaries.map(
                  (e) => Padding(
                padding:
                const EdgeInsets.only(bottom: CelebrationDesign.sm + 2),
                child: _buildUpcomingCard(
                    e, CelebrationType.marriageAnniversary),
              ),
            ),
            const SizedBox(height: CelebrationDesign.md),
          ],
        ],
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
            color: CelebrationDesign.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: CelebrationDesign.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: CelebrationDesign.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: CelebrationDesign.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===================== TODAY CARD =====================
  Widget _buildTodayCard(Employee employee, CelebrationType type) {
    final color = CelebrationDesign.colorFor(type);
    final soft = CelebrationDesign.softFor(type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(CelebrationDesign.radiusLg),
        onTap: () {},
        splashColor: color.withOpacity(0.05),
        highlightColor: color.withOpacity(0.03),
        child: Container(
          padding: const EdgeInsets.all(CelebrationDesign.md),
          decoration: BoxDecoration(
            color: CelebrationDesign.surface,
            borderRadius: BorderRadius.circular(CelebrationDesign.radiusLg),
            border: Border.all(color: CelebrationDesign.border, width: 1),
            boxShadow: CelebrationDesign.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius:
                  BorderRadius.circular(CelebrationDesign.radiusMd),
                  border: Border.all(
                    color: color.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  employee.firstName.isNotEmpty
                      ? employee.firstName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: CelebrationDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CelebrationDesign.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildMetaChip(
                          Icons.badge_outlined,
                          employee.employeeId,
                        ),
                        const SizedBox(width: CelebrationDesign.sm),
                        Flexible(
                          child: _buildMetaChip(
                            Icons.business_outlined,
                            employee.department,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CelebrationDesign.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CelebrationDesign.sm + 2,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: color.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: color,
                      ),
                    ),
                  ),

                  // 👇 Hide the send button when the celebration is for the current user
                  if (_isSelf(employee.employeeId)) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: soft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: color.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        "IT'S YOU 🎉",
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: color,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 6),
                    SendRegardsButton(
                      employeeId: employee.employeeId,
                      type: type,
                      color: color,
                      soft: soft,
                      onSent: _onRegardSent,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== UPCOMING CARD =====================
  Widget _buildUpcomingCard(UpcomingEvent event, CelebrationType type) {
    final color = CelebrationDesign.colorFor(type);
    final soft = CelebrationDesign.softFor(type);

    final daysText = event.daysUntil == 0
        ? 'Today'
        : event.daysUntil == 1
        ? 'Tomorrow'
        : 'In ${event.daysUntil} days';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(CelebrationDesign.radiusLg),
        onTap: () {},
        splashColor: color.withOpacity(0.05),
        highlightColor: color.withOpacity(0.03),
        child: Container(
          padding: const EdgeInsets.all(CelebrationDesign.md),
          decoration: BoxDecoration(
            color: CelebrationDesign.surface,
            borderRadius: BorderRadius.circular(CelebrationDesign.radiusLg),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: CelebrationDesign.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius:
                  BorderRadius.circular(CelebrationDesign.radiusMd),
                  border: Border.all(
                    color: color.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  event.firstName.isNotEmpty
                      ? event.firstName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: CelebrationDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CelebrationDesign.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildMetaChip(
                          Icons.badge_outlined,
                          event.employeeId,
                        ),
                        const SizedBox(width: CelebrationDesign.sm),
                        Flexible(
                          child: _buildMetaChip(
                            Icons.business_outlined,
                            event.department,
                          ),
                        ),
                      ],
                    ),
                    if (event.yearsOfService != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${event.yearsOfService} ${event.yearsOfService == 1 ? 'year' : 'years'} of service',
                        style: const TextStyle(
                          fontSize: 11,
                          color: CelebrationDesign.textMuted,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: CelebrationDesign.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CelebrationDesign.sm + 2,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: color.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      daysText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.celebrationDate,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: CelebrationDesign.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== META CHIP =====================
  Widget _buildMetaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: CelebrationDesign.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: CelebrationDesign.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  // ===================== EMPTY STATE =====================
  Widget _buildEmptyState(String title, String emoji, String subtitle) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(CelebrationDesign.lg),
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(CelebrationDesign.xl),
          decoration: BoxDecoration(
            color: CelebrationDesign.surface,
            borderRadius: BorderRadius.circular(CelebrationDesign.radiusLg),
            border: Border.all(color: CelebrationDesign.border, width: 1),
            boxShadow: CelebrationDesign.softShadow,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CelebrationDesign.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CelebrationDesign.primaryLight,
                    width: 1,
                  ),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: CelebrationDesign.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CelebrationDesign.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: CelebrationDesign.textMuted,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================== SKELETON =====================
  Widget _buildSkeleton() {
    Widget bar({double w = 100, double h = 12, double r = 4}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: CelebrationDesign.surface,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    Widget card() => Container(
      padding: const EdgeInsets.all(CelebrationDesign.md),
      margin: const EdgeInsets.only(bottom: CelebrationDesign.sm + 2),
      decoration: BoxDecoration(
        color: CelebrationDesign.surface,
        borderRadius: BorderRadius.circular(CelebrationDesign.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CelebrationDesign.surfaceMuted,
              borderRadius:
              BorderRadius.circular(CelebrationDesign.radiusMd),
            ),
          ),
          const SizedBox(width: CelebrationDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(w: 160, h: 12),
                const SizedBox(height: 6),
                bar(w: 120, h: 10),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(CelebrationDesign.radiusXl),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                CelebrationDesign.md,
                CelebrationDesign.sm,
                CelebrationDesign.md,
                CelebrationDesign.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(w: 160, h: 18),
                  const SizedBox(height: 8),
                  bar(w: 220, h: 11),
                  const SizedBox(height: CelebrationDesign.md),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: CelebrationDesign.surface,
                      borderRadius:
                      BorderRadius.circular(CelebrationDesign.radiusMd),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(CelebrationDesign.md),
            children: [
              bar(w: 140, h: 11),
              const SizedBox(height: CelebrationDesign.sm + 4),
              card(),
              card(),
              card(),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SEND REGARDS BUTTON (self-contained, reusable)
// ═══════════════════════════════════════════════════════════════

class SendRegardsButton extends StatefulWidget {
  final String employeeId;
  final CelebrationType type;
  final Color color;
  final Color soft;
  final Future<void> Function() onSent;

  const SendRegardsButton({
    super.key,
    required this.employeeId,
    required this.type,
    required this.color,
    required this.soft,
    required this.onSent,
  });

  @override
  State<SendRegardsButton> createState() => _SendRegardsButtonState();
}

class _SendRegardsButtonState extends State<SendRegardsButton> {
  final CelebrationService _service = CelebrationService();
  bool _sending = false;
  bool _sent = false;

  String _backendType() {
    switch (widget.type) {
      case CelebrationType.birthday:
        return 'birthday';
      case CelebrationType.marriageAnniversary:
        return 'marriage';
      case CelebrationType.workAnniversary:
        return 'work';
    }
  }

  String _typeLabel() {
    switch (widget.type) {
      case CelebrationType.birthday:
        return '🎂 Birthday';
      case CelebrationType.marriageAnniversary:
        return '💍 Marriage Anniversary';
      case CelebrationType.workAnniversary:
        return '💼 Work Anniversary';
    }
  }

  Future<void> _openDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.card_giftcard_rounded, color: widget.color),
            const SizedBox(width: 8),
            const Text('Send Regards'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: widget.soft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.color.withOpacity(0.25)),
              ),
              child: Text(
                _typeLabel(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 500,
              maxLines: 4,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Write your wishes...',
                filled: true,
                fillColor: CelebrationDesign.surfaceMuted,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Delivered: today',
              style: TextStyle(
                fontSize: 11,
                color: CelebrationDesign.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please write a message')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    setState(() => _sending = true);
    try {
      await _service.sendRegards(
        employeeId: widget.employeeId,
        celebrationType: _backendType(),
        message: controller.text.trim(),
        // celebrationDate omitted → defaults to today in service
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Regards sent successfully')),
            ],
          ),
          backgroundColor: CelebrationDesign.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      await widget.onSent();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: CelebrationDesign.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.soft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: widget.color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 12, color: widget.color),
            const SizedBox(width: 4),
            Text(
              'SENT',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: widget.color,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 30,
      child: ElevatedButton.icon(
        onPressed: _sending ? null : _openDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        icon: _sending
            ? const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : const Icon(Icons.card_giftcard_rounded, size: 14),
        label: Text(_sending ? 'Sending…' : 'Send'),
      ),
    );
  }
}

enum CelebrationType {
  birthday,
  marriageAnniversary,
  workAnniversary,
}