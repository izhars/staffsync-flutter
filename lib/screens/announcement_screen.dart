import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:staffsync/services/announcement_api.dart';
import '../models/announcement.dart';

// ===================== SHARED DESIGN TOKENS =====================
class AnnouncementDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // Primary rose/pink palette (announcements = broadcast/urgent)
  static const Color primary = Color(0xFFDB2777);       // pink-600
  static const Color primaryDark = Color(0xFFBE185D);   // pink-700
  static const Color primarySoft = Color(0xFFFDF2F8);   // pink-50
  static const Color primaryLight = Color(0xFFFBCFE8);  // pink-200

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Priority
  static const Color high = Color(0xFFDC2626);
  static const Color highSoft = Color(0xFFFEF2F2);
  static const Color highBorder = Color(0xFFFECACA);

  static const Color medium = Color(0xFFD97706);
  static const Color mediumSoft = Color(0xFFFFFBEB);
  static const Color mediumBorder = Color(0xFFFDE68A);

  static const Color low = Color(0xFF059669);
  static const Color lowSoft = Color(0xFFECFDF5);
  static const Color lowBorder = Color(0xFFA7F3D0);

  // Type
  static const Color holiday = Color(0xFF7C3AED);
  static const Color holidaySoft = Color(0xFFF5F3FF);
  static const Color holidayBorder = Color(0xFFDDD6FE);

  static const Color general = Color(0xFF2563EB);
  static const Color generalSoft = Color(0xFFEFF6FF);
  static const Color generalBorder = Color(0xFFBFDBFE);

  static const Color event = Color(0xFFD97706);
  static const Color eventSoft = Color(0xFFFFFBEB);
  static const Color eventBorder = Color(0xFFFDE68A);

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

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  late Future<List<Announcement>> _futureAnnouncements;

  @override
  void initState() {
    super.initState();
    _futureAnnouncements = AnnouncementService().fetchAnnouncements();
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AnnouncementDesign.bg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FutureBuilder<List<Announcement>>(
                future: _futureAnnouncements,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildSkeletonLoader();
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }

                  final announcements = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _futureAnnouncements =
                            AnnouncementService().fetchAnnouncements();
                      });
                      await _futureAnnouncements;
                    },
                    color: AnnouncementDesign.primary,
                    backgroundColor: AnnouncementDesign.surface,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AnnouncementDesign.md,
                        AnnouncementDesign.md,
                        AnnouncementDesign.md,
                        AnnouncementDesign.xl,
                      ),
                      itemCount: announcements.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: AnnouncementDesign.sm + 4),
                      itemBuilder: (context, index) =>
                          _buildAnnouncementCard(announcements[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AnnouncementDesign.primary, AnnouncementDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AnnouncementDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: AnnouncementDesign.primary.withOpacity(0.25),
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
            AnnouncementDesign.md,
            AnnouncementDesign.sm,
            AnnouncementDesign.md,
            AnnouncementDesign.md,
          ),
          child: Row(
            children: [
              // Back button
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(AnnouncementDesign.radiusSm),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(AnnouncementDesign.radiusSm),
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
              const SizedBox(width: AnnouncementDesign.sm + 4),

              // Title block
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Announcements',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Stay up to date with the latest',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Broadcast icon in frosted square
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(AnnouncementDesign.radiusSm),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.campaign_rounded,
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

  // ===================== SKELETON =====================

  Widget _buildSkeletonLoader() {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: AnnouncementDesign.surfaceMuted,
        highlightColor: AnnouncementDesign.border,
        duration: Duration(seconds: 1),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AnnouncementDesign.md,
          AnnouncementDesign.md,
          AnnouncementDesign.md,
          AnnouncementDesign.xl,
        ),
        itemCount: 4,
        separatorBuilder: (_, __) =>
        const SizedBox(height: AnnouncementDesign.sm + 4),
        itemBuilder: (_, __) => _buildSkeletonCard(),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: AnnouncementDesign.surface,
        borderRadius: BorderRadius.circular(AnnouncementDesign.radiusLg),
        border: Border.all(color: AnnouncementDesign.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AnnouncementDesign.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AnnouncementDesign.surfaceMuted,
                    borderRadius: BorderRadius.circular(
                      AnnouncementDesign.radiusSm,
                    ),
                  ),
                ),
                const SizedBox(width: AnnouncementDesign.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 200,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AnnouncementDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 11,
                        decoration: BoxDecoration(
                          color: AnnouncementDesign.surfaceMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AnnouncementDesign.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AnnouncementDesign.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AnnouncementDesign.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AnnouncementDesign.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AnnouncementDesign.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AnnouncementDesign.md),
          Container(
            padding: const EdgeInsets.all(AnnouncementDesign.md),
            decoration: const BoxDecoration(
              color: AnnouncementDesign.surfaceMuted,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AnnouncementDesign.radiusLg),
                bottomRight: Radius.circular(AnnouncementDesign.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AnnouncementDesign.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AnnouncementDesign.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 80,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AnnouncementDesign.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== EMPTY / ERROR =====================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AnnouncementDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AnnouncementDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_outlined,
                size: 42,
                color: AnnouncementDesign.primary,
              ),
            ),
            const SizedBox(height: AnnouncementDesign.lg),
            const Text(
              'No Announcements Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AnnouncementDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AnnouncementDesign.sm),
            const Text(
              'Check back later for updates from your team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AnnouncementDesign.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AnnouncementDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AnnouncementDesign.highSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: AnnouncementDesign.high,
              ),
            ),
            const SizedBox(height: AnnouncementDesign.lg),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AnnouncementDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AnnouncementDesign.sm),
            const Text(
              'Failed to load announcements. Pull down to retry.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AnnouncementDesign.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AnnouncementDesign.lg),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _futureAnnouncements =
                      AnnouncementService().fetchAnnouncements();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AnnouncementDesign.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AnnouncementDesign.lg,
                  vertical: AnnouncementDesign.sm + 4,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(AnnouncementDesign.radiusSm),
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

  // ===================== CARD =====================

  Widget _buildAnnouncementCard(Announcement announcement) {
    final publishDate = DateFormat('MMM dd, yyyy • hh:mm a')
        .format(DateTime.parse(announcement.publishDate));

    final (typeColor, typeSoft, typeBorder) =
    _typeStyle(announcement.type);
    final (priorityColor, prioritySoft, priorityBorder) =
    _priorityStyle(announcement.priority);

    return Container(
      decoration: BoxDecoration(
        color: AnnouncementDesign.surface,
        borderRadius: BorderRadius.circular(AnnouncementDesign.radiusLg),
        border: Border.all(color: AnnouncementDesign.border, width: 1),
        boxShadow: AnnouncementDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Header =====
          Padding(
            padding: const EdgeInsets.all(AnnouncementDesign.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon tile
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeSoft,
                    borderRadius: BorderRadius.circular(
                      AnnouncementDesign.radiusSm,
                    ),
                    border: Border.all(color: typeBorder, width: 1),
                  ),
                  child: Icon(
                    _getTypeIcon(announcement.type),
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AnnouncementDesign.sm + 4),

                // Title + type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AnnouncementDesign.textPrimary,
                          letterSpacing: -0.2,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        announcement.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: typeColor,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // Priority pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AnnouncementDesign.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: prioritySoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: priorityBorder, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        announcement.priority.toUpperCase(),
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===== Divider =====
          Container(height: 1, color: AnnouncementDesign.border),

          // ===== Description =====
          Padding(
            padding: const EdgeInsets.all(AnnouncementDesign.md),
            child: Text(
              announcement.description,
              style: const TextStyle(
                fontSize: 13,
                color: AnnouncementDesign.textSecondary,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // ===== Footer =====
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AnnouncementDesign.md,
              vertical: AnnouncementDesign.sm + 4,
            ),
            decoration: const BoxDecoration(
              color: AnnouncementDesign.surfaceMuted,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AnnouncementDesign.radiusLg),
                bottomRight: Radius.circular(AnnouncementDesign.radiusLg),
              ),
              border: Border(
                top: BorderSide(
                  color: AnnouncementDesign.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Timestamp group
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: AnnouncementDesign.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _getRelativeTime(announcement.publishDate),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AnnouncementDesign.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AnnouncementDesign.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          publishDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AnnouncementDesign.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AnnouncementDesign.sm),

                // Author chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AnnouncementDesign.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AnnouncementDesign.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AnnouncementDesign.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 11,
                        color: AnnouncementDesign.textMuted,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          "${announcement.createdBy.firstName} ${announcement.createdBy.lastName}",
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AnnouncementDesign.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== STYLES =====================

  (Color, Color, Color) _priorityStyle(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return (
        AnnouncementDesign.high,
        AnnouncementDesign.highSoft,
        AnnouncementDesign.highBorder
        );
      case 'medium':
        return (
        AnnouncementDesign.medium,
        AnnouncementDesign.mediumSoft,
        AnnouncementDesign.mediumBorder
        );
      case 'low':
        return (
        AnnouncementDesign.low,
        AnnouncementDesign.lowSoft,
        AnnouncementDesign.lowBorder
        );
      default:
        return (
        AnnouncementDesign.neutral,
        AnnouncementDesign.neutralSoft,
        AnnouncementDesign.neutralBorder
        );
    }
  }

  (Color, Color, Color) _typeStyle(String type) {
    switch (type.toLowerCase()) {
      case 'holiday':
        return (
        AnnouncementDesign.holiday,
        AnnouncementDesign.holidaySoft,
        AnnouncementDesign.holidayBorder
        );
      case 'general':
        return (
        AnnouncementDesign.general,
        AnnouncementDesign.generalSoft,
        AnnouncementDesign.generalBorder
        );
      case 'event':
        return (
        AnnouncementDesign.event,
        AnnouncementDesign.eventSoft,
        AnnouncementDesign.eventBorder
        );
      default:
        return (
        AnnouncementDesign.neutral,
        AnnouncementDesign.neutralSoft,
        AnnouncementDesign.neutralBorder
        );
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'holiday':
        return Icons.celebration_rounded;
      case 'general':
        return Icons.campaign_rounded;
      case 'event':
        return Icons.event_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getRelativeTime(String dateString) {
    final DateTime date = DateTime.parse(dateString);
    final Duration difference = DateTime.now().difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}