import 'package:flutter/material.dart';
import 'package:staffsync/services/announcement_api.dart';
import 'package:staffsync/models/announcement.dart';
import '../screens/announcement_screen.dart';

// ===================== DESIGN TOKENS =====================

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

  // Neutral palette
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFEAECEF);
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Priority colors
  static const Color high = Color(0xFFDC2626);       // red-600
  static const Color highSoft = Color(0xFFFEF2F2);
  static const Color highBorder = Color(0xFFFECACA);

  static const Color medium = Color(0xFFD97706);     // amber-600
  static const Color mediumSoft = Color(0xFFFFFBEB);
  static const Color mediumBorder = Color(0xFFFDE68A);

  static const Color low = Color(0xFF059669);        // emerald-600
  static const Color lowSoft = Color(0xFFECFDF5);
  static const Color lowBorder = Color(0xFFA7F3D0);

  // Type colors
  static const Color holiday = Color(0xFF7C3AED);    // violet-600
  static const Color holidaySoft = Color(0xFFF5F3FF);
  static const Color holidayBorder = Color(0xFFDDD6FE);

  static const Color general = Color(0xFF4F46E5);    // indigo-600
  static const Color generalSoft = Color(0xFFEEF2FF);
  static const Color generalBorder = Color(0xFFC7D2FE);

  static const Color event = Color(0xFFEA580C);      // orange-600
  static const Color eventSoft = Color(0xFFFFF7ED);
  static const Color eventBorder = Color(0xFFFED7AA);

  static const Color info = Color(0xFF0F766E);       // teal-700
  static const Color infoSoft = Color(0xFFF0FDFA);
  static const Color infoBorder = Color(0xFF99F6E4);

  // Brand accent
  static const Color brand = Color(0xFFEC4899);      // pink-500
  static const Color brandSoft = Color(0xFFFDF2F8);
  static const Color brandBorder = Color(0xFFFBCFE8);

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

class AnnouncementsHomeWidget extends StatefulWidget {
  final int maxItems;
  final bool showViewAll;

  const AnnouncementsHomeWidget({
    super.key,
    this.maxItems = 3,
    this.showViewAll = true,
  });

  @override
  State<AnnouncementsHomeWidget> createState() => _AnnouncementsHomeWidgetState();
}

class _AnnouncementsHomeWidgetState extends State<AnnouncementsHomeWidget> {
  late Future<List<Announcement>> _futureAnnouncements;

  @override
  void initState() {
    super.initState();
    _futureAnnouncements = AnnouncementService().fetchAnnouncements();
  }

  void _retry() {
    setState(() {
      _futureAnnouncements = AnnouncementService().fetchAnnouncements();
    });
  }

  // ===================== COLOR MAPPING =====================

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AnnouncementDesign.high;
      case 'medium':
        return AnnouncementDesign.medium;
      case 'low':
        return AnnouncementDesign.low;
      default:
        return AnnouncementDesign.general;
    }
  }

  Color _getPrioritySoftColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AnnouncementDesign.highSoft;
      case 'medium':
        return AnnouncementDesign.mediumSoft;
      case 'low':
        return AnnouncementDesign.lowSoft;
      default:
        return AnnouncementDesign.generalSoft;
    }
  }

  Color _getPriorityBorderColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AnnouncementDesign.highBorder;
      case 'medium':
        return AnnouncementDesign.mediumBorder;
      case 'low':
        return AnnouncementDesign.lowBorder;
      default:
        return AnnouncementDesign.generalBorder;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'holiday':
        return AnnouncementDesign.holiday;
      case 'general':
        return AnnouncementDesign.general;
      case 'event':
        return AnnouncementDesign.event;
      default:
        return AnnouncementDesign.info;
    }
  }

  Color _getTypeSoftColor(String type) {
    switch (type.toLowerCase()) {
      case 'holiday':
        return AnnouncementDesign.holidaySoft;
      case 'general':
        return AnnouncementDesign.generalSoft;
      case 'event':
        return AnnouncementDesign.eventSoft;
      default:
        return AnnouncementDesign.infoSoft;
    }
  }

  Color _getTypeBorderColor(String type) {
    switch (type.toLowerCase()) {
      case 'holiday':
        return AnnouncementDesign.holidayBorder;
      case 'general':
        return AnnouncementDesign.generalBorder;
      case 'event':
        return AnnouncementDesign.eventBorder;
      default:
        return AnnouncementDesign.infoBorder;
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

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AnnouncementDesign.surface,
        borderRadius: BorderRadius.circular(AnnouncementDesign.radiusLg),
        border: Border.all(color: AnnouncementDesign.border, width: 1),
        boxShadow: AnnouncementDesign.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AnnouncementDesign.radiusLg),
        child: Column(
          children: [
            // ===== ACCENT HEADER BAR =====
            _buildAccentBar(),
            Padding(
              padding: const EdgeInsets.all(AnnouncementDesign.md + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AnnouncementDesign.md),
                  _buildDivider(),
                  const SizedBox(height: AnnouncementDesign.md),
                  FutureBuilder<List<Announcement>>(
                    future: _futureAnnouncements,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      } else if (snapshot.hasError) {
                        return _buildErrorState();
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState();
                      }

                      final announcements =
                      snapshot.data!.take(widget.maxItems).toList();

                      return Column(
                        children: announcements
                            .map((a) => _buildAnnouncementCard(a))
                            .toList(),
                      );
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
            AnnouncementDesign.brand,
            AnnouncementDesign.holiday,
            AnnouncementDesign.general,
            AnnouncementDesign.event,
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
            color: AnnouncementDesign.brandSoft,
            borderRadius: BorderRadius.circular(AnnouncementDesign.radiusSm + 2),
            border: Border.all(color: AnnouncementDesign.brandBorder, width: 1),
          ),
          child: const Icon(
            Icons.campaign_rounded,
            color: AnnouncementDesign.brand,
            size: 22,
          ),
        ),
        const SizedBox(width: AnnouncementDesign.md - 2),

        // Title + subtitle
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Announcements',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AnnouncementDesign.textPrimary,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    size: 11,
                    color: AnnouncementDesign.textMuted,
                  ),
                  SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Latest updates & news',
                      style: TextStyle(
                        fontSize: 12,
                        color: AnnouncementDesign.textSecondary,
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

        const SizedBox(width: AnnouncementDesign.sm),

        if (widget.showViewAll) _buildViewAllButton(),
      ],
    );
  }

  Widget _buildViewAllButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AnnouncementDesign.radiusSm),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AnnouncementsPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AnnouncementDesign.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AnnouncementDesign.sm + 4,
            vertical: AnnouncementDesign.xs + 2,
          ),
          decoration: BoxDecoration(
            color: AnnouncementDesign.generalSoft,
            borderRadius: BorderRadius.circular(AnnouncementDesign.radiusSm),
            border: Border.all(color: AnnouncementDesign.generalBorder, width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AnnouncementDesign.general,
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AnnouncementDesign.general,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AnnouncementDesign.border,
    );
  }

  // ===================== STATES =====================

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AnnouncementDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(AnnouncementDesign.radiusMd),
        border: Border.all(color: AnnouncementDesign.border, width: 1),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(AnnouncementDesign.md),
      decoration: BoxDecoration(
        color: AnnouncementDesign.highSoft,
        borderRadius: BorderRadius.circular(AnnouncementDesign.radiusMd),
        border: Border.all(color: AnnouncementDesign.highBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AnnouncementDesign.high.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AnnouncementDesign.high,
              size: 18,
            ),
          ),
          const SizedBox(width: AnnouncementDesign.sm + 4),
          const Expanded(
            child: Text(
              'Failed to load announcements',
              style: TextStyle(
                color: AnnouncementDesign.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _retry,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AnnouncementDesign.sm + 2,
                  vertical: AnnouncementDesign.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: AnnouncementDesign.high,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
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
      padding: const EdgeInsets.all(AnnouncementDesign.lg),
      decoration: BoxDecoration(
        color: AnnouncementDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(AnnouncementDesign.radiusMd),
        border: Border.all(color: AnnouncementDesign.border, width: 1),
      ),
      child: Column(
        children: [
          // ✅ Full-width image
          SizedBox(
            width: double.infinity,
            child: Image.asset(
              'assets/promotion.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,            // set your desired height
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.speaker_notes_off_rounded,
                  color: AnnouncementDesign.textMuted,
                  size: 48,
                );
              },
            ),
          ),
          const SizedBox(height: AnnouncementDesign.md),
          const Text(
            'No announcements yet',
            style: TextStyle(
              fontSize: 14,
              color: AnnouncementDesign.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AnnouncementDesign.xs),
          const Text(
            'Check back later for updates',
            style: TextStyle(
              fontSize: 12,
              color: AnnouncementDesign.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== ANNOUNCEMENT CARD =====================

  Widget _buildAnnouncementCard(Announcement announcement) {
    final priorityColor = _getPriorityColor(announcement.priority);
    final prioritySoft = _getPrioritySoftColor(announcement.priority);
    final priorityBorder = _getPriorityBorderColor(announcement.priority);

    final typeColor = _getTypeColor(announcement.type);
    final typeSoft = _getTypeSoftColor(announcement.type);
    final typeBorder = _getTypeBorderColor(announcement.type);
    final typeIcon = _getTypeIcon(announcement.type);

    return Container(
      margin: const EdgeInsets.only(bottom: AnnouncementDesign.sm + 4),
      decoration: BoxDecoration(
        color: AnnouncementDesign.surface,
        borderRadius: BorderRadius.circular(AnnouncementDesign.radiusMd),
        border: Border.all(color: priorityBorder, width: 1),
        boxShadow: AnnouncementDesign.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AnnouncementDesign.radiusMd),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnnouncementsPage(),
                ),
              );
            },
            child: Column(
              children: [
                // Accent bar (priority colored)
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [priorityColor, priorityColor.withOpacity(0.5)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AnnouncementDesign.sm + 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: typeSoft,
                          borderRadius:
                          BorderRadius.circular(AnnouncementDesign.radiusSm),
                          border: Border.all(color: typeBorder, width: 1),
                        ),
                        child: Icon(typeIcon, color: typeColor, size: 20),
                      ),
                      const SizedBox(width: AnnouncementDesign.sm + 4),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title + priority badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    announcement.title,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: AnnouncementDesign.textPrimary,
                                      letterSpacing: -0.2,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AnnouncementDesign.sm),
                                _buildPriorityBadge(
                                  announcement.priority,
                                  priorityColor,
                                  prioritySoft,
                                  priorityBorder,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            // Description
                            Text(
                              announcement.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AnnouncementDesign.textSecondary,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AnnouncementDesign.sm + 2),

                            // Meta row
                            _buildMetaRow(announcement),
                          ],
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
    );
  }

  Widget _buildPriorityBadge(
      String priority,
      Color color,
      Color soft,
      Color border,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AnnouncementDesign.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(Announcement announcement) {
    return Row(
      children: [
        // Time
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AnnouncementDesign.surfaceMuted,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AnnouncementDesign.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 11,
                color: AnnouncementDesign.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                _getRelativeTime(announcement.publishDate),
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AnnouncementDesign.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AnnouncementDesign.sm),

        // Author
        Expanded(
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AnnouncementDesign.general, Color(0xFF8B5CF6)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AnnouncementDesign.general.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    announcement.createdBy.firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${announcement.createdBy.firstName} ${announcement.createdBy.lastName}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AnnouncementDesign.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}