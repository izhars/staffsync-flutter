import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../services/poll_service.dart';
import 'poll_results_screen.dart';

// ===================== SHARED DESIGN TOKENS =====================
class PollDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // Primary indigo palette
  static const Color primary = Color(0xFF4F46E5);       // indigo-600
  static const Color primaryDark = Color(0xFF4338CA);   // indigo-700
  static const Color primarySoft = Color(0xFFEEF2FF);   // indigo-50
  static const Color primaryLight = Color(0xFFC7D2FE);  // indigo-200

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Semantic
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

class PollScreen extends StatefulWidget {
  const PollScreen({Key? key}) : super(key: key);

  @override
  State<PollScreen> createState() => _PollScreenState();
}

class _PollScreenState extends State<PollScreen>
    with SingleTickerProviderStateMixin {
  final PollService _pollService = PollService();
  bool _loading = true;
  List<dynamic> _polls = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchPolls();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchPolls() async {
    try {
      setState(() => _loading = true);
      final polls = await _pollService.fetchPolls();
      if (!mounted) return;
      setState(() {
        _polls = polls;
        _loading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      debugPrint('Error fetching polls: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      _showErrorSnackBar('Failed to load polls');
    }
  }

  Future<void> _vote(String pollId, int optionIndex) async {
    try {
      final result = await _pollService.votePoll(pollId, optionIndex);
      if (!mounted) return;
      if (result['success'] == true) {
        _showSuccessSnackBar(
          result['message'] ?? 'Vote recorded successfully',
        );
        await _fetchPolls();
      }
    } catch (e) {
      debugPrint('Vote error: $e');
      _showErrorSnackBar('Failed to submit vote');
    }
  }

  // ===================== SNACKBARS =====================

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: PollDesign.sm + 2),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: PollDesign.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PollDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(PollDesign.md),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: PollDesign.sm + 2),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: PollDesign.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PollDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(PollDesign.md),
      ),
    );
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: PollDesign.bg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading ? _buildSkeletonLoading() : _buildContent(),
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
          colors: [PollDesign.primary, PollDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(PollDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: PollDesign.primary.withOpacity(0.25),
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
            PollDesign.md,
            PollDesign.sm,
            PollDesign.md,
            PollDesign.md,
          ),
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(PollDesign.radiusSm),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(PollDesign.radiusSm),
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
              const SizedBox(width: PollDesign.sm + 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community Polls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Share your opinion with the team',
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
                BorderRadius.circular(PollDesign.radiusSm),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.how_to_vote_rounded,
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

  // ===================== CONTENT =====================

  Widget _buildContent() {
    if (_polls.isEmpty) return _buildEmptyState();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _fetchPolls,
        color: PollDesign.primary,
        backgroundColor: PollDesign.surface,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            PollDesign.md,
            PollDesign.md,
            PollDesign.md,
            PollDesign.xl,
          ),
          itemCount: _polls.length,
          separatorBuilder: (_, __) =>
          const SizedBox(height: PollDesign.sm + 4),
          itemBuilder: (context, index) => _buildPollCard(_polls[index]),
        ),
      ),
    );
  }

  // ===================== EMPTY =====================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PollDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: PollDesign.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.poll_outlined,
                size: 42,
                color: PollDesign.primary,
              ),
            ),
            const SizedBox(height: PollDesign.lg),
            const Text(
              'No Polls Available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: PollDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: PollDesign.sm),
            const Text(
              'Check back later for new polls from your team.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: PollDesign.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== SKELETON =====================

  Widget _buildSkeletonLoading() {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: PollDesign.surfaceMuted,
        highlightColor: PollDesign.border,
        duration: Duration(seconds: 1),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          PollDesign.md,
          PollDesign.md,
          PollDesign.md,
          PollDesign.xl,
        ),
        itemCount: 3,
        separatorBuilder: (_, __) =>
        const SizedBox(height: PollDesign.sm + 4),
        itemBuilder: (_, __) => _buildSkeletonPollCard(),
      ),
    );
  }

  Widget _buildSkeletonPollCard() {
    return Container(
      padding: const EdgeInsets.all(PollDesign.md),
      decoration: BoxDecoration(
        color: PollDesign.surface,
        borderRadius: BorderRadius.circular(PollDesign.radiusLg),
        border: Border.all(color: PollDesign.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PollDesign.surfaceMuted,
                  borderRadius:
                  BorderRadius.circular(PollDesign.radiusSm),
                ),
              ),
              const SizedBox(width: PollDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: PollDesign.surfaceMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 11,
                      width: 100,
                      decoration: BoxDecoration(
                        color: PollDesign.surfaceMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PollDesign.md),
          ...List.generate(
            3,
                (_) => Container(
              margin: const EdgeInsets.only(
                bottom: PollDesign.sm,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: PollDesign.md,
                vertical: PollDesign.md - 2,
              ),
              decoration: BoxDecoration(
                color: PollDesign.surfaceMuted,
                borderRadius:
                BorderRadius.circular(PollDesign.radiusSm),
              ),
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: PollDesign.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: PollDesign.sm),
          Row(
            children: [
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: PollDesign.surfaceMuted,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 20,
                decoration: BoxDecoration(
                  color: PollDesign.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== POLL CARD =====================

  Widget _buildPollCard(Map<String, dynamic> poll) {
    final options = poll['options'] as List<dynamic>;
    final hasVoted = poll['hasVoted'] == true;
    final totalVotes = poll['totalVotes'] ?? 0;
    final isExpired = _isPollExpired(poll['expiresAt']);

    return Container(
      decoration: BoxDecoration(
        color: PollDesign.surface,
        borderRadius: BorderRadius.circular(PollDesign.radiusLg),
        border: Border.all(color: PollDesign.border, width: 1),
        boxShadow: PollDesign.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(PollDesign.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPollHeader(poll),
            const SizedBox(height: PollDesign.md),
            _buildPollOptions(
              options,
              poll['_id'],
              hasVoted,
              isExpired,
              totalVotes,
            ),
            const SizedBox(height: PollDesign.md),
            _buildPollFooter(poll, totalVotes, hasVoted, isExpired),
            if (totalVotes > 0) ...[
              const SizedBox(height: PollDesign.sm + 4),
              _buildResultsButton(poll),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsButton(Map<String, dynamic> poll) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PollResultsScreen(
                pollId: poll['_id'],
                pollQuestion: poll['question'] ?? 'Untitled Poll',
              ),
            ),
          );
        },
        icon: const Icon(Icons.bar_chart_rounded, size: 16),
        label: const Text('View Results'),
        style: OutlinedButton.styleFrom(
          foregroundColor: PollDesign.primary,
          backgroundColor: PollDesign.primarySoft,
          side: const BorderSide(
            color: PollDesign.primaryLight,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PollDesign.radiusSm),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: PollDesign.sm + 4,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildPollHeader(Map<String, dynamic> poll) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: PollDesign.primarySoft,
            borderRadius: BorderRadius.circular(PollDesign.radiusSm),
            border: Border.all(
              color: PollDesign.primaryLight,
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.poll_rounded,
            color: PollDesign.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: PollDesign.sm + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poll['question'] ?? 'Untitled Poll',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: PollDesign.textPrimary,
                  letterSpacing: -0.2,
                  height: 1.35,
                ),
              ),
              if (poll['expiresAt'] != null) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      _isPollExpired(poll['expiresAt'])
                          ? Icons.event_busy_rounded
                          : Icons.schedule_rounded,
                      size: 11,
                      color: _isPollExpired(poll['expiresAt'])
                          ? PollDesign.danger
                          : PollDesign.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Expires: ${_formatDate(poll['expiresAt'])}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _isPollExpired(poll['expiresAt'])
                            ? PollDesign.danger
                            : PollDesign.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPollOptions(
      List<dynamic> options,
      String pollId,
      bool hasVoted,
      bool isExpired,
      int totalVotes,
      ) {
    return Column(
      children: options.asMap().entries.map((entry) {
        final optionIndex = entry.key;
        final option = entry.value;
        final optionText = option['text'] ?? 'Option ${optionIndex + 1}';

        return Padding(
          padding: const EdgeInsets.only(bottom: PollDesign.sm),
          child: _buildOptionButton(
            optionText,
            optionIndex,
            pollId,
            hasVoted,
            isExpired,
            totalVotes,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOptionButton(
      String text,
      int index,
      String pollId,
      bool hasVoted,
      bool isExpired,
      int totalVotes,
      ) {
    final isDisabled = hasVoted || isExpired;

    // Button colors depend on state
    final Color bg = isDisabled
        ? PollDesign.surfaceMuted
        : PollDesign.primarySoft;
    final Color borderColor = isDisabled
        ? PollDesign.border
        : PollDesign.primaryLight;
    final Color textColor = isDisabled
        ? PollDesign.textMuted
        : PollDesign.textPrimary;
    final Color dotColor = isDisabled
        ? PollDesign.neutral
        : PollDesign.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(PollDesign.radiusSm),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(PollDesign.radiusSm),
          onTap: isDisabled ? null : () => _vote(pollId, index),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PollDesign.md,
              vertical: PollDesign.md - 2,
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: PollDesign.sm + 4),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (isDisabled)
                  Icon(
                    hasVoted
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    color: hasVoted
                        ? PollDesign.success
                        : PollDesign.textMuted,
                    size: 16,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: PollDesign.primary.withOpacity(0.5),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPollFooter(
      Map<String, dynamic> poll,
      int totalVotes,
      bool hasVoted,
      bool isExpired,
      ) {
    return Row(
      children: [
        Icon(
          Icons.how_to_vote_rounded,
          size: 13,
          color: PollDesign.textMuted,
        ),
        const SizedBox(width: 5),
        Text(
          '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
          style: const TextStyle(
            fontSize: 11.5,
            color: PollDesign.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const Spacer(),
        if (hasVoted)
          _buildStatusPill(
            label: 'VOTED',
            color: PollDesign.success,
            bg: PollDesign.successSoft,
            border: PollDesign.successBorder,
          )
        else if (isExpired)
          _buildStatusPill(
            label: 'EXPIRED',
            color: PollDesign.danger,
            bg: PollDesign.dangerSoft,
            border: PollDesign.dangerBorder,
          )
        else
          _buildStatusPill(
            label: 'ACTIVE',
            color: PollDesign.primary,
            bg: PollDesign.primarySoft,
            border: PollDesign.primaryLight,
          ),
      ],
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PollDesign.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
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
            label,
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

  // ===================== HELPERS =====================

  bool _isPollExpired(String? expiresAt) {
    if (expiresAt == null) return false;
    try {
      final expiry = DateTime.parse(expiresAt);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return false;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = date.difference(now);

      if (difference.inDays > 0) {
        return '${difference.inDays}d left';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h left';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m left';
      } else {
        return 'Expired';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }
}