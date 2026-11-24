import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../models/about.dart';

// ===================== SHARED DESIGN TOKENS =====================
class AboutDesign {
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
  static const Color danger = Color(0xFFDC2626);

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

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  late AboutDataModel aboutData;
  DataState _dataState = DataState.loading;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final String _apiUrl = 'http://192.168.1.51:7000/api/about';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAboutData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Future<void> _loadAboutData() async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          aboutData = AboutDataModel.fromJson(jsonData['data']);
          _dataState = DataState.success;
        });
        await Future.delayed(const Duration(milliseconds: 300));
        _animationController.forward();
      } else {
        setState(() => _dataState = DataState.error);
      }
    } on http.ClientException catch (e) {
      _handleError('Network error: ${e.message}');
    } on TimeoutException catch (_) {
      _handleError('Request timeout. Please check your connection.');
    } catch (e) {
      _handleError('Failed to load data');
    }
  }

  void _handleError(String message) {
    setState(() => _dataState = DataState.error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AboutDesign.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AboutDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(AboutDesign.md),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() => _dataState = DataState.loading);
    await _loadAboutData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AboutDesign.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ===================== HEADER (mirrors Feedback) =====================

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AboutDesign.primary, AboutDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AboutDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: AboutDesign.primary.withOpacity(0.25),
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
            AboutDesign.md,
            AboutDesign.sm,
            AboutDesign.md,
            AboutDesign.md,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AboutDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AboutDesign.radiusSm),
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
              const SizedBox(width: AboutDesign.sm + 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Us',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Learn more about our story',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_dataState == DataState.error)
                Material(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AboutDesign.radiusSm),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AboutDesign.radiusSm),
                    onTap: _refreshData,
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
                )
              else
                Material(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AboutDesign.radiusSm),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.info_outline_rounded,
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

  Widget _buildBody() {
    switch (_dataState) {
      case DataState.loading:
        return const _LoadingView();
      case DataState.error:
        return _ErrorView(onRetry: _refreshData);
      case DataState.success:
        return _buildSuccessView();
    }
  }

  Widget _buildSuccessView() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      backgroundColor: AboutDesign.surface,
      color: AboutDesign.primary,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(AboutDesign.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(),
                  const SizedBox(height: AboutDesign.lg),

                  if (aboutData.stats.isNotEmpty) ...[
                    _buildSectionLabel('BY THE NUMBERS', 'Our impact at a glance'),
                    const SizedBox(height: AboutDesign.sm + 4),
                    _StatsGrid(stats: aboutData.stats),
                    const SizedBox(height: AboutDesign.lg),
                  ],

                  _buildSectionLabel('WHO WE ARE', 'Our purpose and direction'),
                  const SizedBox(height: AboutDesign.sm + 4),
                  _MissionVisionSection(about: aboutData.about),
                  const SizedBox(height: AboutDesign.lg),

                  if (aboutData.about.values.isNotEmpty) ...[
                    _buildSectionLabel('CORE VALUES', 'What drives us every day'),
                    const SizedBox(height: AboutDesign.sm + 4),
                    _ValuesSection(values: aboutData.about.values),
                    const SizedBox(height: AboutDesign.lg),
                  ],

                  if (aboutData.timeline.isNotEmpty) ...[
                    _buildSectionLabel('OUR JOURNEY', 'Milestones along the way'),
                    const SizedBox(height: AboutDesign.sm + 4),
                    _TimelineSection(timeline: aboutData.timeline),
                    const SizedBox(height: AboutDesign.lg),
                  ],

                  if (aboutData.achievements.isNotEmpty) ...[
                    _buildSectionLabel('ACHIEVEMENTS', 'What we are proud of'),
                    const SizedBox(height: AboutDesign.sm + 4),
                    _AchievementsSection(achievements: aboutData.achievements),
                    const SizedBox(height: AboutDesign.lg),
                  ],

                  if (aboutData.team.isNotEmpty) ...[
                    _buildSectionLabel('MEET THE TEAM', 'The people behind it all'),
                    const SizedBox(height: AboutDesign.sm + 4),
                    _TeamSection(team: aboutData.team),
                  ],

                  const SizedBox(height: AboutDesign.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===================== INTRO CARD =====================

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(AboutDesign.md + 2),
      decoration: BoxDecoration(
        color: AboutDesign.surface,
        borderRadius: BorderRadius.circular(AboutDesign.radiusLg),
        border: Border.all(color: AboutDesign.border, width: 1),
        boxShadow: AboutDesign.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AboutDesign.primarySoft,
              borderRadius: BorderRadius.circular(AboutDesign.radiusSm),
              border: Border.all(color: AboutDesign.primaryLight, width: 1),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AboutDesign.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AboutDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aboutData.about.companyName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AboutDesign.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _stripHtmlTags(aboutData.about.description),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AboutDesign.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stripHtmlTags(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
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
            color: AboutDesign.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AboutDesign.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AboutDesign.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AboutDesign.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum DataState { loading, success, error }

// ===================== LOADING (shimmer restyled) =====================

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AboutDesign.md),
      children: [
        _shimmer(height: 90),
        const SizedBox(height: AboutDesign.lg),
        _shimmer(height: 20, width: 140),
        const SizedBox(height: AboutDesign.sm + 4),
        Row(
          children: [
            Expanded(child: _shimmer(height: 110)),
            const SizedBox(width: AboutDesign.sm + 4),
            Expanded(child: _shimmer(height: 110)),
          ],
        ),
        const SizedBox(height: AboutDesign.lg),
        _shimmer(height: 20, width: 140),
        const SizedBox(height: AboutDesign.sm + 4),
        _shimmer(height: 160),
      ],
    );
  }

  Widget _shimmer({required double height, double? width}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF3F4F6),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AboutDesign.radiusLg),
        ),
      ),
    );
  }
}

// ===================== ERROR VIEW =====================

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AboutDesign.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AboutDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: AboutDesign.primary,
              ),
            ),
            const SizedBox(height: AboutDesign.lg),
            const Text(
              'Unable to load data',
              style: TextStyle(
                fontSize: 18,
                color: AboutDesign.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: AboutDesign.sm),
            const Text(
              'Please check your connection and try again',
              style: TextStyle(
                color: AboutDesign.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AboutDesign.lg),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Retry',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AboutDesign.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AboutDesign.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(AboutDesign.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== STATS GRID =====================

class _StatsGrid extends StatelessWidget {
  final List<StatItem> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: AboutDesign.sm + 4,
        mainAxisSpacing: AboutDesign.sm + 4,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return _StatCard(stat: stats[index], index: index);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final StatItem stat;
  final int index;

  const _StatCard({required this.stat, required this.index});

  // Same semantic palette as Feedback categories
  static const List<Map<String, dynamic>> _palette = [
    {'fg': Color(0xFF4F46E5), 'soft': Color(0xFFEEF2FF), 'border': Color(0xFFC7D2FE)},
    {'fg': Color(0xFF0D9488), 'soft': Color(0xFFF0FDFA), 'border': Color(0xFF99F6E4)},
    {'fg': Color(0xFFD97706), 'soft': Color(0xFFFFFBEB), 'border': Color(0xFFFDE68A)},
    {'fg': Color(0xFF7C3AED), 'soft': Color(0xFFF5F3FF), 'border': Color(0xFFDDD6FE)},
    {'fg': Color(0xFF059669), 'soft': Color(0xFFECFDF5), 'border': Color(0xFFA7F3D0)},
    {'fg': Color(0xFF6B7280), 'soft': Color(0xFFF3F4F6), 'border': Color(0xFFE5E7EB)},
  ];

  @override
  Widget build(BuildContext context) {
    final p = _palette[index % _palette.length];
    final fg = p['fg'] as Color;
    final soft = p['soft'] as Color;
    final border = p['border'] as Color;

    return Container(
      padding: const EdgeInsets.all(AboutDesign.md + 2),
      decoration: BoxDecoration(
        color: AboutDesign.surface,
        borderRadius: BorderRadius.circular(AboutDesign.radiusMd),
        border: Border.all(color: AboutDesign.border, width: 1),
        boxShadow: AboutDesign.softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: soft,
              borderRadius:
              BorderRadius.circular(AboutDesign.radiusSm - 2),
              border: Border.all(color: border, width: 1),
            ),
            child: Icon(Icons.insights_rounded, color: fg, size: 18),
          ),
          const SizedBox(height: AboutDesign.sm + 2),
          Text(
            '${stat.value}${stat.suffix}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 12,
              color: AboutDesign.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ===================== MISSION / VISION =====================

class _MissionVisionSection extends StatelessWidget {
  final AboutSection about;

  const _MissionVisionSection({required this.about});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          icon: Icons.rocket_launch_rounded,
          fg: const Color(0xFF059669),
          soft: const Color(0xFFECFDF5),
          border: const Color(0xFFA7F3D0),
          title: 'Our Mission',
          content: about.mission,
        ),
        const SizedBox(height: AboutDesign.sm + 4),
        _InfoCard(
          icon: Icons.auto_awesome_rounded,
          fg: const Color(0xFF7C3AED),
          soft: const Color(0xFFF5F3FF),
          border: const Color(0xFFDDD6FE),
          title: 'Our Vision',
          content: about.vision,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color fg;
  final Color soft;
  final Color border;
  final String title;
  final String content;

  const _InfoCard({
    required this.icon,
    required this.fg,
    required this.soft,
    required this.border,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AboutDesign.md + 2),
      decoration: BoxDecoration(
        color: AboutDesign.surface,
        borderRadius: BorderRadius.circular(AboutDesign.radiusLg),
        border: Border.all(color: AboutDesign.border, width: 1),
        boxShadow: AboutDesign.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(AboutDesign.radiusSm),
              border: Border.all(color: border, width: 1),
            ),
            child: Icon(icon, color: fg, size: 22),
          ),
          const SizedBox(width: AboutDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AboutDesign.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AboutDesign.textSecondary,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== VALUES =====================

class _ValuesSection extends StatelessWidget {
  final List<String> values;

  const _ValuesSection({required this.values});

  static const List<Map<String, Color>> _palette = [
    {'fg': Color(0xFF4F46E5), 'soft': Color(0xFFEEF2FF), 'border': Color(0xFFC7D2FE)},
    {'fg': Color(0xFF0D9488), 'soft': Color(0xFFF0FDFA), 'border': Color(0xFF99F6E4)},
    {'fg': Color(0xFFD97706), 'soft': Color(0xFFFFFBEB), 'border': Color(0xFFFDE68A)},
    {'fg': Color(0xFF7C3AED), 'soft': Color(0xFFF5F3FF), 'border': Color(0xFFDDD6FE)},
    {'fg': Color(0xFF059669), 'soft': Color(0xFFECFDF5), 'border': Color(0xFFA7F3D0)},
    {'fg': Color(0xFF6B7280), 'soft': Color(0xFFF3F4F6), 'border': Color(0xFFE5E7EB)},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AboutDesign.sm,
      runSpacing: AboutDesign.sm,
      children: values.asMap().entries.map((entry) {
        final p = _palette[entry.key % _palette.length];
        return Container(
          // Constrain each chip so it can never exceed available width
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - (AboutDesign.md * 2),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AboutDesign.md,
            vertical: AboutDesign.sm + 4,
          ),
          decoration: BoxDecoration(
            color: p['soft'],
            borderRadius: BorderRadius.circular(AboutDesign.radiusSm),
            border: Border.all(color: p['border']!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 14, color: p['fg']),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p['fg'],
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ===================== TIMELINE =====================

class _TimelineSection extends StatelessWidget {
  final List<TimelineItem> timeline;

  const _TimelineSection({required this.timeline});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: timeline.asMap().entries.map((entry) {
        return _TimelineItemWidget(
          item: entry.value,
          isLast: entry.key == timeline.length - 1,
        );
      }).toList(),
    );
  }
}

class _TimelineItemWidget extends StatelessWidget {
  final TimelineItem item;
  final bool isLast;

  const _TimelineItemWidget({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AboutDesign.primary, AboutDesign.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                  BorderRadius.circular(AboutDesign.radiusSm),
                  boxShadow: [
                    BoxShadow(
                      color: AboutDesign.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    item.year.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AboutDesign.border,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AboutDesign.sm + 4),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(
                bottom: isLast ? 0 : AboutDesign.md + 4,
              ),
              padding: const EdgeInsets.all(AboutDesign.md),
              decoration: BoxDecoration(
                color: AboutDesign.surface,
                borderRadius:
                BorderRadius.circular(AboutDesign.radiusMd),
                border: Border.all(color: AboutDesign.border, width: 1),
                boxShadow: AboutDesign.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AboutDesign.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AboutDesign.textSecondary,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== ACHIEVEMENTS =====================

class _AchievementsSection extends StatelessWidget {
  final List<String> achievements;

  const _AchievementsSection({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: achievements.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: entry.key == achievements.length - 1
                ? 0
                : AboutDesign.sm + 4,
          ),
          child: _AchievementItem(
            index: entry.key + 1,
            text: entry.value,
          ),
        );
      }).toList(),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final int index;
  final String text;

  const _AchievementItem({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AboutDesign.md),
      decoration: BoxDecoration(
        color: AboutDesign.surface,
        borderRadius: BorderRadius.circular(AboutDesign.radiusMd),
        border: Border.all(color: AboutDesign.border, width: 1),
        boxShadow: AboutDesign.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AboutDesign.primarySoft,
              borderRadius:
              BorderRadius.circular(AboutDesign.radiusSm - 2),
              border: Border.all(color: AboutDesign.primaryLight, width: 1),
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: const TextStyle(
                  color: AboutDesign.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: AboutDesign.sm + 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: AboutDesign.textSecondary,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================== TEAM =====================

class _TeamSection extends StatelessWidget {
  final List<TeamMember> team;

  const _TeamSection({required this.team});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: AboutDesign.sm + 4,
        mainAxisSpacing: AboutDesign.sm + 4,
      ),
      itemCount: team.length,
      itemBuilder: (context, index) {
        return _TeamMemberCard(member: team[index]);
      },
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final TeamMember member;

  const _TeamMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AboutDesign.md),
      decoration: BoxDecoration(
        color: AboutDesign.surface,
        borderRadius: BorderRadius.circular(AboutDesign.radiusMd),
        border: Border.all(color: AboutDesign.border, width: 1),
        boxShadow: AboutDesign.softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AboutDesign.primary, AboutDesign.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AboutDesign.primary.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: member.imageUrl != null
                    ? Image.network(
                  member.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: AboutDesign.primary,
                  ),
                )
                    : const Icon(
                  Icons.person_rounded,
                  size: 36,
                  color: AboutDesign.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AboutDesign.sm + 4),
          Text(
            member.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AboutDesign.textPrimary,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            member.role,
            style: const TextStyle(
              fontSize: 11,
              color: AboutDesign.textMuted,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}