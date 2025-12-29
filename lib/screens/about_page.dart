import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../models/about.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with SingleTickerProviderStateMixin {
  late AboutDataModel aboutData;
  DataState _dataState = DataState.loading;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final String _apiUrl = 'http://192.168.1.67:5000/api/about';

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
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.05),
            const Color(0xFF8B5CF6).withOpacity(0.03),
            const Color(0xFFF8FAFC),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: const Text(
        'About Us',
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_dataState == DataState.error)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3B82F6)),
            ),
          ),
      ],
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
      backgroundColor: Colors.white,
      color: const Color(0xFF3B82F6),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroSection(data: aboutData.about),
                const SizedBox(height: 32),
                if (aboutData.stats.isNotEmpty) ...[
                  _StatsGrid(stats: aboutData.stats),
                  const SizedBox(height: 32),
                ],
                _MissionVisionSection(about: aboutData.about),
                const SizedBox(height: 32),
                if (aboutData.about.values.isNotEmpty) ...[
                  _ValuesSection(values: aboutData.about.values),
                  const SizedBox(height: 32),
                ],
                if (aboutData.timeline.isNotEmpty) ...[
                  _TimelineSection(timeline: aboutData.timeline),
                  const SizedBox(height: 32),
                ],
                if (aboutData.achievements.isNotEmpty) ...[
                  _AchievementsSection(achievements: aboutData.achievements),
                  const SizedBox(height: 32),
                ],
                if (aboutData.team.isNotEmpty) ...[
                  _TeamSection(team: aboutData.team),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum DataState { loading, success, error }

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 100, left: 20, right: 20),
      children: [
        _buildShimmerHero(),
        const SizedBox(height: 32),
        _buildShimmerStats(),
        const SizedBox(height: 32),
        _buildShimmerCards(),
      ],
    );
  }

  Widget _buildShimmerHero() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildShimmerStats() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[50]!,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCards() {
    return Column(
      children: List.generate(2, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[50]!,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
            ),
          ),
        ),
      )),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Unable to load data',
            style: TextStyle(
              fontSize: 22,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your connection and try again',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final AboutSection data;

  const _HeroSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF8B5CF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '✨ Welcome',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            data.companyName,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.slogan,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _stripHtmlTags(data.description),
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.95),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  String _stripHtmlTags(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

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
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
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

  @override
  Widget build(BuildContext context) {
    final colors = [
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFFF59E0B), const Color(0xFFD97706)],
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors[index % colors.length][0].withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[index % colors.length][0].withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${stat.value}${stat.suffix}',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: colors[index % colors.length][0],
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionVisionSection extends StatelessWidget {
  final AboutSection about;

  const _MissionVisionSection({required this.about});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          icon: Icons.rocket_launch_rounded,
          gradient: const [Color(0xFF10B981), Color(0xFF059669)],
          title: 'Our Mission',
          content: about.mission,
        ),
        const SizedBox(height: 16),
        _InfoCard(
          icon: Icons.auto_awesome_rounded,
          gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          title: 'Our Vision',
          content: about.vision,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String content;

  const _InfoCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gradient[0].withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    height: 1.6,
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

class _ValuesSection extends StatelessWidget {
  final List<String> values;

  const _ValuesSection({required this.values});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Core Values',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: values.asMap().entries.map((entry) {
            final colors = [
              [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
              [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
              [const Color(0xFF10B981), const Color(0xFF059669)],
              [const Color(0xFFF59E0B), const Color(0xFFD97706)],
              [const Color(0xFFEF4444), const Color(0xFFDC2626)],
            ];
            final colorIndex = entry.key % colors.length;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: colors[colorIndex][0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors[colorIndex][0].withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors[colorIndex][0],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final List<TimelineItem> timeline;

  const _TimelineSection({required this.timeline});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Our Journey',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        ...timeline.asMap().entries.map((entry) {
          return _TimelineItemWidget(
            item: entry.value,
            isLast: entry.key == timeline.length - 1,
          );
        }).toList(),
      ],
    );
  }
}

class _TimelineItemWidget extends StatelessWidget {
  final TimelineItem item;
  final bool isLast;

  const _TimelineItemWidget({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  item.year.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.3),
                      const Color(0xFFE2E8F0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 28),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final List<String> achievements;

  const _AchievementsSection({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Achievements',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        Column(
          children: achievements.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key == achievements.length - 1 ? 0 : 12),
              child: _AchievementItem(index: entry.key + 1, text: entry.value),
            );
          }).toList(),
        ),
      ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  final List<TeamMember> team;

  const _TeamSection({required this.team});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meet Our Team',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: team.length,
          itemBuilder: (context, index) {
            return _TeamMemberCard(member: team[index]);
          },
        ),
      ],
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final TeamMember member;

  const _TeamMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: member.imageUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(45),
              child: Image.network(
                member.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.person_rounded, size: 44, color: Colors.white),
              ),
            )
                : const Icon(Icons.person_rounded, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            member.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            member.role,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
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