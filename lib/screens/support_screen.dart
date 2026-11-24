import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../services/employee_service.dart';

// ===================== SHARED DESIGN TOKENS =====================
class SupportDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const Color primary = Color(0xFFD97706);
  static const Color primaryDark = Color(0xFFB45309);
  static const Color primarySoft = Color(0xFFFFFBEB);
  static const Color primaryLight = Color(0xFFFDE68A);

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

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

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

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final EmployeeService _employeeService = EmployeeService();
  late Future<List<Map<String, dynamic>>> _futureHRs;
  bool _showAvailableOnly = true;

  @override
  void initState() {
    super.initState();
    _futureHRs = _employeeService.getAllHRs();
  }

  void _refreshHRs() {
    setState(() {
      _futureHRs = _employeeService.getAllHRs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SupportDesign.bg,
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureHRs,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeletonLoader();
            } else if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final hrs = snapshot.data ?? [];
            final availableCount =
                hrs.where((hr) => hr['isAvailable'] == true).length;
            final totalCount = hrs.length;
            final availabilityPercent = totalCount > 0
                ? (availableCount / totalCount * 100).round()
                : 0;

            final filteredHRs = _showAvailableOnly
                ? hrs.where((hr) => hr['isAvailable'] == true).toList()
                : [...hrs];

            filteredHRs.sort((a, b) {
              if (a['isAvailable'] != b['isAvailable']) {
                return a['isAvailable'] ? -1 : 1;
              }
              final nameA = '${a['firstName']} ${a['lastName']}';
              final nameB = '${b['firstName']} ${b['lastName']}';
              return nameA.compareTo(nameB);
            });

            return Column(
              children: [
                _buildHeader(
                  availableCount: availableCount,
                  totalCount: totalCount,
                  availabilityPercent: availabilityPercent,
                ),
                _buildFilterBar(filteredHRs.length),
                Expanded(
                  child: hrs.isEmpty
                      ? _buildEmptyState()
                      : filteredHRs.isEmpty
                      ? _buildNoResultsState()
                      : RefreshIndicator(
                    color: SupportDesign.primary,
                    onRefresh: () async => _refreshHRs(),
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        SupportDesign.md,
                        SupportDesign.sm,
                        SupportDesign.md,
                        SupportDesign.lg,
                      ),
                      itemCount: filteredHRs.length,
                      separatorBuilder: (_, __) => const SizedBox(
                          height: SupportDesign.sm + 2),
                      itemBuilder: (context, index) =>
                          _buildHRCard(filteredHRs[index]),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader({
    required int availableCount,
    required int totalCount,
    required int availabilityPercent,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SupportDesign.primary, SupportDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(SupportDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: SupportDesign.primary.withOpacity(0.25),
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
            SupportDesign.md,
            SupportDesign.sm,
            SupportDesign.md,
            SupportDesign.md,
          ),
          child: Column(
            children: [
              // Top row: back + title + refresh
              Row(
                children: [
                  Material(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(SupportDesign.radiusSm),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(SupportDesign.radiusSm),
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
                  const SizedBox(width: SupportDesign.sm + 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HR Support',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Connect with available HR staff',
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
                    borderRadius:
                    BorderRadius.circular(SupportDesign.radiusSm),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(SupportDesign.radiusSm),
                      onTap: _refreshHRs,
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
              const SizedBox(height: SupportDesign.lg),

              // Stats row
              Container(
                padding: const EdgeInsets.symmetric(vertical: SupportDesign.sm + 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius:
                  BorderRadius.circular(SupportDesign.radiusMd),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStat(
                        availableCount.toString(),
                        'Available',
                        Icons.check_circle_rounded,
                      ),
                    ),
                    _buildStatDivider(),
                    Expanded(
                      child: _buildStat(
                        totalCount.toString(),
                        'Total HR',
                        Icons.people_rounded,
                      ),
                    ),
                    _buildStatDivider(),
                    Expanded(
                      child: _buildStat(
                        '$availabilityPercent%',
                        'Online Rate',
                        Icons.bar_chart_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() => Container(
    height: 32,
    width: 1,
    color: Colors.white.withOpacity(0.2),
  );

  // ===================== FILTER BAR =====================

  Widget _buildFilterBar(int resultCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SupportDesign.md,
        SupportDesign.md,
        SupportDesign.md,
        SupportDesign.sm,
      ),
      child: Row(
        children: [
          // Segmented toggle
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: SupportDesign.surfaceMuted,
                borderRadius:
                BorderRadius.circular(SupportDesign.radiusMd),
                border: Border.all(color: SupportDesign.border, width: 1),
              ),
              child: Row(
                children: [
                  _buildSegmentButton(
                    label: 'Available',
                    icon: Icons.check_circle_rounded,
                    isSelected: _showAvailableOnly,
                    onTap: () =>
                        setState(() => _showAvailableOnly = true),
                  ),
                  _buildSegmentButton(
                    label: 'All',
                    icon: Icons.people_rounded,
                    isSelected: !_showAvailableOnly,
                    onTap: () =>
                        setState(() => _showAvailableOnly = false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: SupportDesign.sm + 2),
          // Count badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SupportDesign.sm + 4,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: SupportDesign.primarySoft,
              borderRadius: BorderRadius.circular(SupportDesign.radiusMd),
              border: Border.all(
                color: SupportDesign.primaryLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_search_rounded,
                  size: 14,
                  color: SupportDesign.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$resultCount',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: SupportDesign.primaryDark,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? SupportDesign.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(SupportDesign.radiusSm + 1),
            boxShadow: isSelected ? SupportDesign.softShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? SupportDesign.primary
                    : SupportDesign.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? SupportDesign.primaryDark
                      : SupportDesign.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== HR CARD =====================

  Widget _buildHRCard(Map<String, dynamic> hr) {
    final bool isAvailable = hr['isAvailable'] ?? false;
    final String availabilityStatus = hr['availabilityStatus'] ?? '';
    final String firstName = hr['firstName'] ?? '';
    final String lastName = hr['lastName'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String email = hr['email'] ?? '';
    final String designation = hr['designation'] ?? '';
    final String profilePicture = hr['profilePicture'] ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAvailable ? () => _navigateToChat(hr) : null,
        borderRadius: BorderRadius.circular(SupportDesign.radiusLg),
        splashColor: SupportDesign.primary.withOpacity(0.05),
        highlightColor: SupportDesign.primary.withOpacity(0.03),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(SupportDesign.md),
          decoration: BoxDecoration(
            color: isAvailable
                ? SupportDesign.surface
                : SupportDesign.surfaceMuted,
            borderRadius: BorderRadius.circular(SupportDesign.radiusLg),
            border: Border.all(
              color: isAvailable
                  ? SupportDesign.primary.withOpacity(0.25)
                  : SupportDesign.border,
              width: isAvailable ? 1.5 : 1,
            ),
            boxShadow: isAvailable
                ? [
              BoxShadow(
                color: SupportDesign.primary.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ]
                : SupportDesign.softShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with status dot
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAvailable
                          ? SupportDesign.primarySoft
                          : SupportDesign.surfaceMuted,
                      border: Border.all(
                        color: isAvailable
                            ? SupportDesign.primaryLight
                            : SupportDesign.border,
                        width: 1.5,
                      ),
                      image: profilePicture.isNotEmpty
                          ? DecorationImage(
                        image: NetworkImage(profilePicture),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: profilePicture.isEmpty
                        ? Icon(
                      Icons.person_rounded,
                      color: isAvailable
                          ? SupportDesign.primary
                          : SupportDesign.textMuted,
                      size: 26,
                    )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? SupportDesign.success
                            : SupportDesign.textMuted,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SupportDesign.surface,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: SupportDesign.sm + 4),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fullName.isEmpty ? '—' : fullName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isAvailable
                                  ? SupportDesign.textPrimary
                                  : SupportDesign.textSecondary,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusPill(
                          isAvailable: isAvailable,
                          availabilityStatus: availabilityStatus,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (designation.isNotEmpty)
                      Text(
                        designation,
                        style: const TextStyle(
                          fontSize: 12,
                          color: SupportDesign.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          size: 12,
                          color: SupportDesign.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            email.isEmpty ? '—' : email,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: SupportDesign.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chat button
              const SizedBox(width: SupportDesign.sm + 2),
              _buildChatButton(isAvailable, hr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required bool isAvailable,
    required String availabilityStatus,
  }) {
    final color =
    isAvailable ? SupportDesign.success : SupportDesign.warning;
    final soft =
    isAvailable ? SupportDesign.successSoft : SupportDesign.warningSoft;
    final border = isAvailable
        ? SupportDesign.successBorder
        : SupportDesign.warningBorder;
    final label = isAvailable
        ? 'Available'
        : (availabilityStatus.isNotEmpty ? availabilityStatus : 'Away');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
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
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton(bool isAvailable, Map<String, dynamic> hr) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: isAvailable
            ? const LinearGradient(
          colors: [SupportDesign.primary, SupportDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isAvailable ? null : SupportDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(SupportDesign.radiusSm),
        border: isAvailable
            ? null
            : Border.all(color: SupportDesign.border, width: 1),
        boxShadow: isAvailable
            ? [
          BoxShadow(
            color: SupportDesign.primary.withOpacity(0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(SupportDesign.radiusSm),
          onTap: isAvailable ? () => _navigateToChat(hr) : null,
          child: Icon(
            Icons.chat_bubble_rounded,
            color: isAvailable ? Colors.white : SupportDesign.textMuted,
            size: 19,
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
        baseColor: Color(0xFFE8EAEE),
        highlightColor: Color(0xFFF6F7FB),
        duration: Duration(milliseconds: 1200),
      ),
      child: Column(
        children: [
          // Header skeleton (matches real header structure)
          Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(SupportDesign.radiusXl),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SupportDesign.md,
                  SupportDesign.sm,
                  SupportDesign.md,
                  SupportDesign.md,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                SupportDesign.radiusSm),
                          ),
                        ),
                        const SizedBox(width: SupportDesign.sm + 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 140,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 180,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                SupportDesign.radiusSm),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: SupportDesign.lg),
                    Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            SupportDesign.radiusMd),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filter bar skeleton
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SupportDesign.md,
              SupportDesign.md,
              SupportDesign.md,
              SupportDesign.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(SupportDesign.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(width: SupportDesign.sm + 2),
                Container(
                  width: 60,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(SupportDesign.radiusMd),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: SupportDesign.sm),

          // Card skeletons
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: SupportDesign.md,
                vertical: SupportDesign.sm,
              ),
              physics: const BouncingScrollPhysics(),
              itemCount: 6,
              separatorBuilder: (_, __) =>
              const SizedBox(height: SupportDesign.sm + 2),
              itemBuilder: (_, __) => _buildSkeletonCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(SupportDesign.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SupportDesign.radiusLg),
        border: Border.all(color: SupportDesign.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: SupportDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 70,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 160,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SupportDesign.sm + 2),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(SupportDesign.radiusSm),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== EMPTY / ERROR / NO RESULTS =====================

  Widget _buildEmptyState() {
    return _buildStateShell(
      icon: Icons.support_agent_rounded,
      iconColor: SupportDesign.primary,
      iconBg: SupportDesign.primarySoft,
      iconBorder: SupportDesign.primaryLight,
      title: 'No HR Staff Found',
      message:
      'There are currently no HR team members registered in the system.',
      actionLabel: 'Refresh',
      actionIcon: Icons.refresh_rounded,
      onAction: _refreshHRs,
    );
  }

  Widget _buildNoResultsState() {
    return _buildStateShell(
      icon: Icons.search_off_rounded,
      iconColor: SupportDesign.primary,
      iconBg: SupportDesign.primarySoft,
      iconBorder: SupportDesign.primaryLight,
      title: _showAvailableOnly
          ? 'No Available HR Staff'
          : 'No HR Staff Found',
      message: _showAvailableOnly
          ? 'All HR team members are currently busy or offline.\nTry again later.'
          : 'Check your connection and try refreshing.',
      actionLabel:
      _showAvailableOnly ? 'Show All HR' : 'Show Available Only',
      actionIcon: _showAvailableOnly
          ? Icons.people_rounded
          : Icons.check_circle_rounded,
      onAction: () => setState(() => _showAvailableOnly = !_showAvailableOnly),
      outlined: true,
    );
  }

  Widget _buildErrorState(String error) {
    return _buildStateShell(
      icon: Icons.error_outline_rounded,
      iconColor: SupportDesign.danger,
      iconBg: SupportDesign.dangerSoft,
      iconBorder: SupportDesign.dangerBorder,
      title: 'Unable to Load',
      message: error,
      actionLabel: 'Try Again',
      actionIcon: Icons.refresh_rounded,
      onAction: _refreshHRs,
      fullScreen: true,
    );
  }

  Widget _buildStateShell({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color iconBorder,
    required String title,
    required String message,
    required String actionLabel,
    required IconData actionIcon,
    required VoidCallback onAction,
    bool outlined = false,
    bool fullScreen = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SupportDesign.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
                border: Border.all(color: iconBorder, width: 1),
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: SupportDesign.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: SupportDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: SupportDesign.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: SupportDesign.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: SupportDesign.lg),
            SizedBox(
              height: 46,
              child: outlined
                  ? OutlinedButton.icon(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: SupportDesign.primary,
                  side: const BorderSide(
                    color: SupportDesign.primary,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: SupportDesign.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        SupportDesign.radiusMd),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                icon: Icon(actionIcon, size: 18),
                label: Text(actionLabel),
              )
                  : ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SupportDesign.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: SupportDesign.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        SupportDesign.radiusMd),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                icon: Icon(actionIcon, size: 18),
                label: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== NAVIGATION =====================

  void _navigateToChat(Map<String, dynamic> hr) {
    debugPrint('📦 Full HR object: $hr');
    final userId = hr['_id'] ?? hr['id'];
    final firstName = hr['firstName'] ?? '';
    final lastName = hr['lastName'] ?? '';

    if (userId == null || userId.isEmpty) {
      debugPrint('❌ Error: HR ID is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Cannot start chat: HR ID is missing',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: SupportDesign.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SupportDesign.radiusSm),
          ),
          margin: const EdgeInsets.all(SupportDesign.md),
        ),
      );
      return;
    }

    debugPrint('📨 Navigating to chat with: $userId | $firstName $lastName');

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => ChatScreen(targetUser: hr),
    //   ),
    // );
  }
}