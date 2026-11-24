import 'package:flutter/material.dart';
import '../services/holiday_api.dart';
import 'package:intl/intl.dart';

// ===================== DESIGN TOKENS =====================

class FestivalDesign {
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

  // Festival type colors
  static const Color festival = Color(0xFF4F46E5);     // indigo-600
  static const Color festivalSoft = Color(0xFFEEF2FF);
  static const Color festivalBorder = Color(0xFFC7D2FE);

  static const Color holiday = Color(0xFF059669);      // emerald-600
  static const Color holidaySoft = Color(0xFFECFDF5);
  static const Color holidayBorder = Color(0xFFA7F3D0);

  static const Color celebration = Color(0xFFEC4899);  // pink-500
  static const Color celebrationSoft = Color(0xFFFDF2F8);
  static const Color celebrationBorder = Color(0xFFFBCFE8);

  static const Color special = Color(0xFFD97706);      // amber-600
  static const Color specialSoft = Color(0xFFFFFBEB);
  static const Color specialBorder = Color(0xFFFDE68A);

  static const Color soon = Color(0xFFDC2626);         // red-600
  static const Color soonSoft = Color(0xFFFEF2F2);
  static const Color soonBorder = Color(0xFFFECACA);

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

// ===================== WIDGET =====================

class UpcomingFestivals extends StatefulWidget {
  const UpcomingFestivals({Key? key}) : super(key: key);

  @override
  State<UpcomingFestivals> createState() => _UpcomingFestivalsState();
}

class _UpcomingFestivalsState extends State<UpcomingFestivals>
    with SingleTickerProviderStateMixin {
  final HolidayService _holidayService = HolidayService();
  late Future<List<Map<String, dynamic>>> _holidaysFuture;
  late AnimationController _animationController;

  // IST offset is +5:30 hours from UTC
  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  @override
  void initState() {
    super.initState();
    _holidaysFuture = _holidayService.fetchUpcomingHolidays();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _holidaysFuture = _holidayService.fetchUpcomingHolidays();
    });
  }

  // ===================== IST HELPERS =====================

  DateTime _convertToIST(DateTime utcDateTime) {
    return utcDateTime.toUtc().add(_istOffset);
  }

  DateTime _getCurrentIST() {
    return _convertToIST(DateTime.now().toUtc());
  }

  DateTime _normalizeDateIST(DateTime dateTime) {
    final istDate = _convertToIST(dateTime);
    return DateTime(istDate.year, istDate.month, istDate.day);
  }

  DateTime _processHolidayDate(DateTime holidayDate) {
    return holidayDate.isUtc
        ? _normalizeDateIST(holidayDate)
        : DateTime(holidayDate.year, holidayDate.month, holidayDate.day);
  }

  int _calculateDaysUntil(DateTime holidayDate) {
    final currentIST = _getCurrentIST();
    final currentISTDate =
    DateTime(currentIST.year, currentIST.month, currentIST.day);
    final processedHolidayDate = _processHolidayDate(holidayDate);

    return processedHolidayDate.difference(currentISTDate).inDays;
  }

  String _getWeekdayName(DateTime date) {
    final istDate = _processHolidayDate(date);
    return DateFormat('EEEE').format(istDate);
  }

  // ===================== COLOR MAPPING =====================

  Color _getFestivalColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'festival':
        return FestivalDesign.festival;
      case 'holiday':
        return FestivalDesign.holiday;
      case 'celebration':
        return FestivalDesign.celebration;
      default:
        return FestivalDesign.special;
    }
  }

  Color _getFestivalSoftColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'festival':
        return FestivalDesign.festivalSoft;
      case 'holiday':
        return FestivalDesign.holidaySoft;
      case 'celebration':
        return FestivalDesign.celebrationSoft;
      default:
        return FestivalDesign.specialSoft;
    }
  }

  Color _getFestivalBorderColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'festival':
        return FestivalDesign.festivalBorder;
      case 'holiday':
        return FestivalDesign.holidayBorder;
      case 'celebration':
        return FestivalDesign.celebrationBorder;
      default:
        return FestivalDesign.specialBorder;
    }
  }

  IconData _getFestivalIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'festival':
        return Icons.celebration_rounded;
      case 'holiday':
        return Icons.beach_access_rounded;
      case 'celebration':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month];
  }

  String _getDaysUntilText(int days) {
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days < 7) return 'In $days days';
    if (days < 30) return 'In ${(days / 7).floor()} weeks';
    return 'In ${(days / 30).floor()} months';
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FestivalDesign.surface,
        borderRadius: BorderRadius.circular(FestivalDesign.radiusLg),
        border: Border.all(color: FestivalDesign.border, width: 1),
        boxShadow: FestivalDesign.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FestivalDesign.radiusLg),
        child: Column(
          children: [
            // ===== ACCENT HEADER BAR =====
            _buildAccentBar(),
            Padding(
              padding: const EdgeInsets.all(FestivalDesign.md + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: FestivalDesign.md),
                  _buildDivider(),
                  const SizedBox(height: FestivalDesign.md),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _holidaysFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmerLoading();
                      } else if (snapshot.hasError) {
                        return _buildErrorState();
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Filter upcoming holidays using IST dates
                      final upcomingHolidays = snapshot.data!.where((h) {
                        final holidayDate = _processHolidayDate(h['date']);
                        final currentIST = _getCurrentIST();
                        final currentISTDate = DateTime(
                          currentIST.year,
                          currentIST.month,
                          currentIST.day,
                        );
                        return holidayDate.isAfter(currentISTDate) ||
                            holidayDate.isAtSameMomentAs(currentISTDate);
                      }).toList();

                      // Sort by IST dates
                      upcomingHolidays.sort((a, b) {
                        final dateA = _processHolidayDate(a['date']);
                        final dateB = _processHolidayDate(b['date']);
                        return dateA.compareTo(dateB);
                      });

                      if (upcomingHolidays.isEmpty) {
                        return _buildEmptyState();
                      }

                      return _buildFestivalsList(upcomingHolidays);
                    },
                  ),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FestivalDesign.festival,
            FestivalDesign.holiday,
            FestivalDesign.celebration,
            FestivalDesign.special,
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
        // Icon container
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: FestivalDesign.festivalSoft,
            borderRadius: BorderRadius.circular(FestivalDesign.radiusSm + 2),
            border: Border.all(color: FestivalDesign.festivalBorder, width: 1),
          ),
          child: const Icon(
            Icons.event_available_rounded,
            color: FestivalDesign.festival,
            size: 22,
          ),
        ),
        const SizedBox(width: FestivalDesign.md - 2),

        // Title + subtitle
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upcoming Festivals',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: FestivalDesign.textPrimary,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.public_rounded,
                    size: 11,
                    color: FestivalDesign.textMuted,
                  ),
                  SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Indian Standard Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: FestivalDesign.textSecondary,
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
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: FestivalDesign.border,
    );
  }

  // ===================== STATES =====================

  Widget _buildShimmerLoading() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: FestivalDesign.sm + 4),
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-1.0, -0.3),
                  end: const Alignment(1.0, 0.3),
                  colors: const [
                    Color(0xFFF0F4FF),
                    Color(0xFFFFFFFF),
                    Color(0xFFF0F4FF),
                  ],
                  stops: [
                    _animationController.value - 0.3,
                    _animationController.value,
                    _animationController.value + 0.3,
                  ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                ),
                borderRadius: BorderRadius.circular(FestivalDesign.radiusMd),
                border: Border.all(color: FestivalDesign.border, width: 1),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(FestivalDesign.lg),
      decoration: BoxDecoration(
        color: FestivalDesign.soonSoft,
        borderRadius: BorderRadius.circular(FestivalDesign.radiusMd),
        border: Border.all(color: FestivalDesign.soonBorder, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(FestivalDesign.md),
            decoration: BoxDecoration(
              color: FestivalDesign.soon.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: FestivalDesign.soon,
              size: 28,
            ),
          ),
          const SizedBox(height: FestivalDesign.md),
          const Text(
            'Unable to load festivals',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: FestivalDesign.textPrimary,
            ),
          ),
          const SizedBox(height: FestivalDesign.xs),
          const Text(
            'Please check your connection',
            style: TextStyle(
              fontSize: 12,
              color: FestivalDesign.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: FestivalDesign.md),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(FestivalDesign.radiusSm),
            child: InkWell(
              onTap: _retry,
              borderRadius: BorderRadius.circular(FestivalDesign.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FestivalDesign.lg,
                  vertical: FestivalDesign.sm + 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [FestivalDesign.festival, Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(FestivalDesign.radiusSm),
                  boxShadow: [
                    BoxShadow(
                      color: FestivalDesign.festival.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(FestivalDesign.lg),
      decoration: BoxDecoration(
        color: FestivalDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(FestivalDesign.radiusMd),
        border: Border.all(color: FestivalDesign.border, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(FestivalDesign.md),
            decoration: BoxDecoration(
              color: FestivalDesign.surface,
              shape: BoxShape.circle,
              border: Border.all(color: FestivalDesign.border, width: 1),
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              color: FestivalDesign.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(height: FestivalDesign.md),
          const Text(
            'No Upcoming Festivals',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: FestivalDesign.textPrimary,
            ),
          ),
          const SizedBox(height: FestivalDesign.xs),
          const Text(
            'Check back later for new celebrations',
            style: TextStyle(
              fontSize: 12,
              color: FestivalDesign.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== FESTIVALS LIST =====================

  Widget _buildFestivalsList(List<Map<String, dynamic>> holidays) {
    return Column(
      children: holidays
          .asMap()
          .entries
          .map((entry) => _buildFestivalCard(entry.value, entry.key))
          .toList(),
    );
  }

  Widget _buildFestivalCard(Map<String, dynamic> holiday, int index) {
    final DateTime originalDate = holiday['date'];
    final DateTime processedDate = _processHolidayDate(originalDate);
    final int daysUntil = _calculateDaysUntil(originalDate);
    final String? type = holiday['type'];
    final color = _getFestivalColor(type);
    final softColor = _getFestivalSoftColor(type);
    final borderColor = _getFestivalBorderColor(type);
    final icon = _getFestivalIcon(type);
    final String weekdayName = _getWeekdayName(originalDate);
    final bool isSoon = daysUntil <= 7;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: FestivalDesign.sm + 4),
        decoration: BoxDecoration(
          color: FestivalDesign.surface,
          borderRadius: BorderRadius.circular(FestivalDesign.radiusMd),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: FestivalDesign.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FestivalDesign.radiusMd),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showHolidayDetails(context, holiday),
              child: Column(
                children: [
                  // Accent bar (type colored)
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.5)],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(FestivalDesign.sm + 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Date badge
                        _buildDateBadge(processedDate, color),
                        const SizedBox(width: FestivalDesign.sm + 4),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + Soon badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      holiday['name'],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: FestivalDesign.textPrimary,
                                        letterSpacing: -0.2,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSoon) ...[
                                    const SizedBox(width: FestivalDesign.sm),
                                    _buildSoonBadge(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Type chip + Days
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: FestivalDesign.sm,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: softColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: borderColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon, size: 10, color: color),
                                        const SizedBox(width: 4),
                                        Text(
                                          (type ?? 'Special').toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: color,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: FestivalDesign.sm),
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 11,
                                    color: color,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _getDaysUntilText(daysUntil),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: color,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Weekday + Date
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 11,
                                    color: FestivalDesign.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '$weekdayName · ${DateFormat('MMM d, y').format(processedDate)}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: FestivalDesign.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              // Description preview
                              if (holiday['description'] != null &&
                                  holiday['description'].toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  holiday['description'],
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: FestivalDesign.textMuted,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: FestivalDesign.sm),

                        // Arrow
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: softColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FestivalDesign.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: FestivalDesign.soonSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FestivalDesign.soonBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: FestivalDesign.soon,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'SOON',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: FestivalDesign.soon,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge(DateTime date, Color color) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(FestivalDesign.radiusSm),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date.day.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _getMonthName(date.month),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== BOTTOM SHEET DETAILS =====================

  void _showHolidayDetails(BuildContext context, Map<String, dynamic> holiday) {
    final String? type = holiday['type'];
    final color = _getFestivalColor(type);
    final softColor = _getFestivalSoftColor(type);
    final borderColor = _getFestivalBorderColor(type);
    final icon = _getFestivalIcon(type);
    final DateTime originalDate = holiday['date'];
    final DateTime processedDate = _processHolidayDate(originalDate);
    final int daysUntil = _calculateDaysUntil(originalDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: FestivalDesign.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(FestivalDesign.radiusXl),
            topRight: Radius.circular(FestivalDesign.radiusXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.5)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(FestivalDesign.radiusXl),
                  topRight: Radius.circular(FestivalDesign.radiusXl),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(FestivalDesign.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: FestivalDesign.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: FestivalDesign.lg),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.8)],
                          ),
                          borderRadius:
                          BorderRadius.circular(FestivalDesign.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: FestivalDesign.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              holiday['name'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: FestivalDesign.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: FestivalDesign.sm,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: softColor,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    (type ?? 'Special').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: FestivalDesign.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: FestivalDesign.festivalSoft,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: FestivalDesign.festivalBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'IST',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: FestivalDesign.festival,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FestivalDesign.lg),

                  // Date card
                  Container(
                    padding: const EdgeInsets.all(FestivalDesign.md),
                    decoration: BoxDecoration(
                      color: softColor,
                      borderRadius:
                      BorderRadius.circular(FestivalDesign.radiusMd),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(FestivalDesign.sm + 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius:
                            BorderRadius.circular(FestivalDesign.radiusSm),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: FestivalDesign.sm + 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM d, y')
                                    .format(processedDate),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: FestivalDesign.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${_getDaysUntilText(daysUntil)} • Indian Standard Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Description
                  if (holiday['description'] != null &&
                      holiday['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: FestivalDesign.lg),
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: FestivalDesign.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: FestivalDesign.sm),
                    Container(
                      padding: const EdgeInsets.all(FestivalDesign.md),
                      decoration: BoxDecoration(
                        color: FestivalDesign.surfaceMuted,
                        borderRadius:
                        BorderRadius.circular(FestivalDesign.radiusMd),
                        border: Border.all(
                          color: FestivalDesign.border,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        holiday['description'],
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: FestivalDesign.textSecondary,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: FestivalDesign.lg),

                  // Close button
                  Material(
                    color: Colors.transparent,
                    borderRadius:
                    BorderRadius.circular(FestivalDesign.radiusSm + 2),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius:
                      BorderRadius.circular(FestivalDesign.radiusSm + 2),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: FestivalDesign.md,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.85)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                          BorderRadius.circular(FestivalDesign.radiusSm + 2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: FestivalDesign.sm),
                            Text(
                              'Got it!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}