import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../models/Award.dart';
import '../services/award_service.dart';

// ===================== SHARED DESIGN TOKENS =====================
class AwardDesign {
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

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  // Trophy tier accents (gold / silver / bronze / platinum / emerald)
  static const List<List<Color>> tierAccents = [
    [Color(0xFFF59E0B), Color(0xFFFCD34D)], // gold
    [Color(0xFF94A3B8), Color(0xFFCBD5E1)], // silver
    [Color(0xFFB45309), Color(0xFFFBBF24)], // bronze
    [Color(0xFF6366F1), Color(0xFFA5B4FC)], // platinum
    [Color(0xFF059669), Color(0xFF6EE7B7)], // emerald
  ];

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

class AwardScreen extends StatefulWidget {
  const AwardScreen({super.key});

  @override
  State<AwardScreen> createState() => _AwardScreenState();
}

class _AwardScreenState extends State<AwardScreen>
    with SingleTickerProviderStateMixin {
  final AwardService _awardService = AwardService();
  late Future<List<Award>> _awardsFuture;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _awardsFuture = _awardService.fetchMyAwards();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _refreshAwards() {
    setState(() {
      _awardsFuture = _awardService.fetchMyAwards();
      _animationController
        ..reset()
        ..forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AwardDesign.bg,
        body: FutureBuilder<List<Award>>(
          future: _awardsFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            if (snapshot.hasError) {
              return Column(
                children: [
                  _buildHeader(count: 0, subtitle: 'Your achievements'),
                  Expanded(
                    child: _buildStateShell(
                      icon: Icons.error_outline_rounded,
                      iconColor: AwardDesign.danger,
                      iconBg: AwardDesign.dangerSoft,
                      iconBorder: AwardDesign.dangerBorder,
                      title: 'Unable to Load',
                      message: snapshot.error.toString(),
                      actionLabel: 'Try Again',
                      actionIcon: Icons.refresh_rounded,
                      onAction: _refreshAwards,
                    ),
                  ),
                ],
              );
            }

            final awards = snapshot.data ?? const [];
            final isEmpty = !isLoading && awards.isEmpty;

            return Column(
              children: [
                _buildHeader(
                  count: awards.length,
                  subtitle: isEmpty
                      ? 'Your achievements'
                      : '${awards.length} ${awards.length == 1 ? "award" : "awards"} earned',
                ),
                Expanded(
                  child: isLoading
                      ? _buildSkeletonLoader()
                      : isEmpty
                      ? _buildStateShell(
                    icon: Icons.emoji_events_outlined,
                    iconColor: AwardDesign.primary,
                    iconBg: AwardDesign.primarySoft,
                    iconBorder: AwardDesign.primaryLight,
                    title: 'No Awards Yet',
                    message:
                    'Keep up the great work!\nYour achievements will appear here.',
                    actionLabel: 'Refresh',
                    actionIcon: Icons.refresh_rounded,
                    onAction: _refreshAwards,
                  )
                      : RefreshIndicator(
                    color: AwardDesign.primary,
                    onRefresh: () async => _refreshAwards(),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AwardDesign.md,
                        AwardDesign.md,
                        AwardDesign.md,
                        AwardDesign.lg,
                      ),
                      itemCount: awards.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final delay = index * 0.1;
                            final v = (_animationController.value -
                                delay)
                                .clamp(0.0, 1.0);
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - v)),
                              child: Opacity(
                                  opacity: v, child: child),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(
                                bottom: AwardDesign.sm + 2),
                            child: _buildAwardCard(
                                awards[index], index),
                          ),
                        );
                      },
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
    required int count,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AwardDesign.primary, AwardDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AwardDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: AwardDesign.primary.withOpacity(0.25),
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
            AwardDesign.md,
            AwardDesign.sm,
            AwardDesign.md,
            AwardDesign.md,
          ),
          child: Row(
            children: [
              // Back button
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(AwardDesign.radiusSm),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(AwardDesign.radiusSm),
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
              const SizedBox(width: AwardDesign.sm + 4),

              // Title block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'My Awards',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: AwardDesign.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: AwardDesign.primaryDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Trophy icon in frosted square
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(AwardDesign.radiusSm),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.emoji_events_rounded,
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

  // ===================== AWARD CARD =====================

  Widget _buildAwardCard(Award award, int index) {
    final tier = AwardDesign.tierAccents[index % AwardDesign.tierAccents.length];
    final accent = tier[0];
    final accentLight = tier[1];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAwardDetails(award, tier),
        borderRadius: BorderRadius.circular(AwardDesign.radiusLg),
        splashColor: accent.withOpacity(0.05),
        highlightColor: accent.withOpacity(0.03),
        child: Container(
          padding: const EdgeInsets.all(AwardDesign.md),
          decoration: BoxDecoration(
            color: AwardDesign.surface,
            borderRadius: BorderRadius.circular(AwardDesign.radiusLg),
            border: Border.all(color: AwardDesign.border, width: 1),
            boxShadow: AwardDesign.softShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBadge(award, accent, accentLight, size: 56),
              const SizedBox(width: AwardDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            award.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AwardDesign.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          color: accent,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      award.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AwardDesign.textSecondary,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMetaRow(
                      Icons.person_outline_rounded,
                      award.awardedBy,
                    ),
                    const SizedBox(height: 3),
                    _buildMetaRow(
                      Icons.calendar_today_rounded,
                      _formatDate(award.dateAwarded),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AwardDesign.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AwardDesign.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AwardDesign.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: AwardDesign.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(
      Award award,
      Color accent,
      Color accentLight, {
        required double size,
      }) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accent, accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: AwardDesign.surface,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.network(
            award.badgeUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accent, accentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: size * 0.5,
                color: Colors.white,
              ),
            ),
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
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AwardDesign.md,
          AwardDesign.md,
          AwardDesign.md,
          AwardDesign.lg,
        ),
        itemCount: 5,
        separatorBuilder: (_, __) =>
        const SizedBox(height: AwardDesign.sm + 2),
        itemBuilder: (_, __) => _buildSkeletonCard(),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(AwardDesign.md),
      decoration: BoxDecoration(
        color: AwardDesign.surface,
        borderRadius: BorderRadius.circular(AwardDesign.radiusLg),
        border: Border.all(color: AwardDesign.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AwardDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 120,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 100,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AwardDesign.sm),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== EMPTY / ERROR SHELL =====================

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
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AwardDesign.xl),
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
            const SizedBox(height: AwardDesign.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AwardDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AwardDesign.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AwardDesign.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AwardDesign.lg),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AwardDesign.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AwardDesign.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(AwardDesign.radiusMd),
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

  // ===================== DETAILS SHEET =====================

  void _showAwardDetails(Award award, List<Color> tier) {
    final accent = tier[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AwardDesign.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AwardDesign.radiusXl),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AwardDesign.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AwardDesign.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AwardDesign.lg),

                // Hero badge
                Hero(
                  tag: 'award_${award.id}',
                  child: _buildBadge(
                    award,
                    tier[0],
                    tier[1],
                    size: 120,
                  ),
                ),
                const SizedBox(height: AwardDesign.lg),

                Text(
                  award.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AwardDesign.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AwardDesign.sm),
                Text(
                  award.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AwardDesign.textSecondary,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AwardDesign.lg),

                _buildDetailRow(
                  Icons.person_rounded,
                  'Awarded By',
                  award.awardedBy,
                  accent,
                ),
                const SizedBox(height: AwardDesign.sm + 2),
                _buildDetailRow(
                  Icons.calendar_today_rounded,
                  'Date Awarded',
                  _formatDate(award.dateAwarded),
                  accent,
                ),
                const SizedBox(height: AwardDesign.lg),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AwardDesign.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AwardDesign.radiusMd),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon,
      String label,
      String value,
      Color accent,
      ) {
    return Container(
      padding: const EdgeInsets.all(AwardDesign.sm + 4),
      decoration: BoxDecoration(
        color: AwardDesign.surfaceMuted,
        borderRadius: BorderRadius.circular(AwardDesign.radiusMd),
        border: Border.all(color: AwardDesign.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AwardDesign.radiusSm),
              border: Border.all(
                color: accent.withOpacity(0.20),
                width: 1,
              ),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: AwardDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AwardDesign.textMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AwardDesign.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString.split('T').first;
    }
  }
}