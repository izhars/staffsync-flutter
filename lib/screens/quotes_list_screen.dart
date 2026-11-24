import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:staffsync/screens/search_quote_screen.dart';
import '../services/quote_service.dart';
import '../models/quote.dart';
import '../widgets/author_quotes_bottom_sheet.dart';
import 'quote_detail_screen.dart';


// lib/theme/quote_design.dart
import 'package:flutter/material.dart';

// ===================== QUOTE DESIGN TOKENS =====================
class QuoteDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primarySoft = Color(0xFFEEF2FF);
  static const Color primaryLight = Color(0xFFC7D2FE);

  static const Color accent = Color(0xFF7C3AED);
  static const Color accentDark = Color(0xFF6D28D9);
  static const Color accentSoft = Color(0xFFF5F3FF);
  static const Color accentLight = Color(0xFFDDD6FE);

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color favorite = Color(0xFFDB2777);
  static const Color favoriteSoft = Color(0xFFFDF2F8);
  static const Color favoriteBorder = Color(0xFFFBCFE8);

  static const Color upvote = Color(0xFF059669);
  static const Color upvoteSoft = Color(0xFFECFDF5);
  static const Color upvoteBorder = Color(0xFFA7F3D0);

  static const Color downvote = Color(0xFFEA580C);
  static const Color downvoteSoft = Color(0xFFFFF7ED);
  static const Color downvoteBorder = Color(0xFFFED7AA);

  static const Color dialogue = Color(0xFF2563EB);
  static const Color dialogueSoft = Color(0xFFEFF6FF);
  static const Color dialogueBorder = Color(0xFFBFDBFE);

  static const Color privateTag = Color(0xFFD97706);
  static const Color privateSoft = Color(0xFFFFFBEB);
  static const Color privateBorder = Color(0xFFFDE68A);

  static const Color tag = Color(0xFF0D9488);
  static const Color tagSoft = Color(0xFFF0FDFA);
  static const Color tagBorder = Color(0xFF99F6E4);

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

  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: primary.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
  ];

  static const LinearGradient headerGradient = LinearGradient(
    colors: [primary, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const TextStyle headerTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: -0.4,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 11.5,
    color: Colors.white70,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle quoteBody = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.55,
    letterSpacing: 0.1,
  );

  static const TextStyle quoteBodyDetail = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.italic,
    color: textPrimary,
    height: 1.6,
  );

  static const TextStyle label = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    color: textMuted,
    letterSpacing: 0.6,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    color: textMuted,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle tagText = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static (Color, Color, Color) statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'favorite':
      case 'liked':
        return (favorite, favoriteSoft, favoriteBorder);
      case 'upvote':
        return (upvote, upvoteSoft, upvoteBorder);
      case 'downvote':
        return (downvote, downvoteSoft, downvoteBorder);
      case 'dialogue':
        return (dialogue, dialogueSoft, dialogueBorder);
      case 'private':
        return (privateTag, privateSoft, privateBorder);
      case 'tag':
        return (tag, tagSoft, tagBorder);
      default:
        return (neutral, neutralSoft, neutralBorder);
    }
  }

  static Color statusMarkerColor(String status) => statusStyle(status).$1;
}

class QuotesListScreen extends StatefulWidget {
  const QuotesListScreen({super.key});

  @override
  State<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends State<QuotesListScreen>
    with SingleTickerProviderStateMixin {
  List<Quote> _quotes = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  bool _hasMorePages = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fetchQuotes();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        !_loadingMore &&
        _hasMorePages) {
      _loadMoreQuotes();
    }
  }

  Future<void> _fetchQuotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await QuoteService().fetchQuotes(page: _currentPage);
      final quotesJson = data['quotes'] as List<dynamic>;
      final lastPage = data['last_page'] as bool? ?? false;

      final quotes = quotesJson
          .map((json) => Quote.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _quotes = quotes;
        _isLoading = false;
        _hasMorePages = !lastPage;
      });

      _listAnimationController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreQuotes() async {
    if (_loadingMore || !_hasMorePages) return;
    setState(() => _loadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final data = await QuoteService().fetchQuotes(page: nextPage);
      final quotesJson = data['quotes'] as List<dynamic>;
      final lastPage = data['last_page'] as bool? ?? false;

      final newQuotes = quotesJson
          .map((json) => Quote.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _quotes = [..._quotes, ...newQuotes];
        _currentPage = nextPage;
        _loadingMore = false;
        _hasMorePages = !lastPage;
      });
    } catch (e) {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _refreshQuotes() async {
    setState(() {
      _currentPage = 1;
      _hasMorePages = true;
    });
    await _fetchQuotes();
  }

  String _getQuoteSummary(String text) {
    if (text.length <= 120) return text;
    return '${text.substring(0, 120)}...';
  }

  void _showAuthorQuotesBottomSheet(BuildContext context, Quote quote) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AuthorQuotesBottomSheet(
          author: quote.author,
          authorPermalink: quote.authorPermalink,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: QuoteDesign.bg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingScreen()
                  : _error != null
                  ? _buildErrorScreen()
                  : _buildContent(),
            ),
          ],
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: QuoteDesign.cardGradient,
            borderRadius: BorderRadius.circular(QuoteDesign.radiusLg),
            boxShadow: QuoteDesign.primaryGlow,
          ),
          child: FloatingActionButton(
            onPressed: _refreshQuotes,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: QuoteDesign.headerGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(QuoteDesign.radiusXl),
        ),
        boxShadow: QuoteDesign.primaryGlow,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            QuoteDesign.md,
            QuoteDesign.sm,
            QuoteDesign.md,
            QuoteDesign.md,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(QuoteDesign.radiusSm),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(QuoteDesign.radiusSm),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: QuoteDesign.sm + 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wisdom Quotes',
                            style: QuoteDesign.headerTitle),
                        SizedBox(height: 2),
                        Text('Discover timeless inspiration',
                            style: QuoteDesign.headerSubtitle),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                    BorderRadius.circular(QuoteDesign.radiusSm),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(QuoteDesign.radiusSm),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.search_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: QuoteDesign.md),
              _buildStatsBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(QuoteDesign.sm + 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(QuoteDesign.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeaderStat(
            Icons.format_quote_rounded,
            '${_quotes.length}',
            'Quotes',
          ),
          Container(
            height: 24,
            width: 1,
            color: Colors.white.withOpacity(0.2),
          ),
          _buildHeaderStat(
            Icons.person_rounded,
            '${_quotes.map((q) => q.author).toSet().length}',
            'Authors',
          ),
          Container(
            height: 24,
            width: 1,
            color: Colors.white.withOpacity(0.2),
          ),
          _buildHeaderStat(
            Icons.local_offer_rounded,
            '${_quotes.expand((q) => q.tags ?? []).toSet().length}',
            'Tags',
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ===================== CONTENT =====================

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _refreshQuotes,
      color: QuoteDesign.primary,
      backgroundColor: QuoteDesign.surface,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(
          QuoteDesign.md,
          QuoteDesign.md,
          QuoteDesign.md,
          QuoteDesign.xl + QuoteDesign.xxl,
        ),
        itemCount: _quotes.length + 1,
        itemBuilder: (context, index) {
          if (index == _quotes.length) {
            return _buildLoadingMoreIndicator();
          }
          final quote = _quotes[index];
          final animation = CurvedAnimation(
            parent: _listAnimationController,
            curve: Interval(
              (index / (_quotes.length + 1)).clamp(0.0, 1.0),
              1.0,
              curve: Curves.easeOutCubic,
            ),
          );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: _buildSlidableQuoteCard(quote: quote, index: index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    if (!_hasMorePages) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: QuoteDesign.lg),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: QuoteDesign.md, vertical: QuoteDesign.sm),
            decoration: BoxDecoration(
              color: QuoteDesign.neutralSoft,
              borderRadius:
              BorderRadius.circular(QuoteDesign.radiusPill),
              border: Border.all(color: QuoteDesign.neutralBorder),
            ),
            child: const Text(
              'All quotes loaded',
              style: TextStyle(
                color: QuoteDesign.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QuoteDesign.lg),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: QuoteDesign.primary,
          ),
        ),
      ),
    );
  }

  // ===================== SLIDABLE CARD =====================

  Widget _buildSlidableQuoteCard({
    required Quote quote,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QuoteDesign.md),
      child: Slidable(
        key: ValueKey('quote_${quote.id ?? quote.hashCode}_$index'),
        closeOnScroll: true,
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => _onToggleFavorite(index),
              backgroundColor: QuoteDesign.favorite,
              foregroundColor: Colors.white,
              icon: quote.favorite == true
                  ? Icons.favorite
                  : Icons.favorite_border,
              label: quote.favorite == true ? 'Unlike' : 'Like',
              borderRadius: BorderRadius.circular(QuoteDesign.radiusLg),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => _onShareQuote(quote),
              backgroundColor: QuoteDesign.dialogue,
              foregroundColor: Colors.white,
              icon: Icons.share_rounded,
              label: 'Share',
              borderRadius: BorderRadius.circular(QuoteDesign.radiusLg),
            ),
          ],
        ),
        child: _buildQuoteCard(quote, context),
      ),
    );
  }

  void _onToggleFavorite(int index) {
    final quote = _quotes[index];
    final updated = Quote(
      id: quote.id,
      text: quote.text,
      author: quote.author,
      authorPermalink: quote.authorPermalink,
      tags: quote.tags,
      favoritesCount: quote.favoritesCount,
      upvotesCount: quote.upvotesCount,
      downvotesCount: quote.downvotesCount,
      favorite: !(quote.favorite ?? false),
      dialogue: quote.dialogue,
      private: quote.private,
      url: quote.url,
      source: quote.source,
      context: quote.context,
      lines: quote.lines,
      body: '',
    );
    setState(() => _quotes[index] = updated);
  }

  void _onShareQuote(Quote quote) {
    // TODO: integrate share_plus
    // Share.share('${quote.text}\n\n— ${quote.author}');
  }

  // ===================== CARD =====================

  Widget _buildQuoteCard(Quote quote, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuoteDetailScreen(quote: quote),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: QuoteDesign.surface,
          borderRadius: BorderRadius.circular(QuoteDesign.radiusLg),
          border: Border.all(color: QuoteDesign.border, width: 1),
          boxShadow: QuoteDesign.softShadow,
        ),
        padding: const EdgeInsets.all(QuoteDesign.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags row
            if (quote.tags != null && quote.tags!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: QuoteDesign.sm + 4),
                child: Wrap(
                  spacing: QuoteDesign.sm - 2,
                  runSpacing: 6,
                  children: [
                    ...quote.tags!.take(2).map(_buildTagChip),
                    if (quote.tags!.length > 2)
                      _buildTagChip('+${quote.tags!.length - 2}',
                          soft: true),
                  ],
                ),
              ),

            // Quote text
            Text(
              '"${_getQuoteSummary(quote.text)}"',
              style: QuoteDesign.quoteBody,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: QuoteDesign.md),
            Container(height: 1, color: QuoteDesign.border),
            const SizedBox(height: QuoteDesign.sm + 2),

            // Author row (tappable)
            GestureDetector(
              onTap: () => _showAuthorQuotesBottomSheet(context, quote),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: QuoteDesign.primarySoft,
                    child: Text(
                      quote.author.isNotEmpty
                          ? quote.author[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: QuoteDesign.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: QuoteDesign.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quote.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: QuoteDesign.cardTitle,
                        ),
                        if (quote.authorPermalink != null)
                          Text(
                            '@${quote.authorPermalink!}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: QuoteDesign.caption,
                          ),
                      ],
                    ),
                  ),
                  if (quote.dialogue == true)
                    _buildPillBadge('DIALOGUE', 'dialogue'),
                ],
              ),
            ),

            const SizedBox(height: QuoteDesign.sm + 4),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: QuoteDesign.sm + 2,
                vertical: QuoteDesign.sm,
              ),
              decoration: BoxDecoration(
                color: QuoteDesign.surfaceMuted,
                borderRadius: BorderRadius.circular(QuoteDesign.radiusSm),
                border: Border.all(color: QuoteDesign.border, width: 1),
              ),
              child: Row(
                children: [
                  _buildCardStat(
                    icon: quote.favorite == true
                        ? Icons.favorite
                        : Icons.favorite_border_rounded,
                    value: '${quote.favoritesCount ?? 0}',
                    tone: 'favorite',
                  ),
                  const SizedBox(width: QuoteDesign.md),
                  _buildCardStat(
                    icon: Icons.thumb_up_rounded,
                    value: '${quote.upvotesCount ?? 0}',
                    tone: 'upvote',
                  ),
                  const SizedBox(width: QuoteDesign.md),
                  _buildCardStat(
                    icon: Icons.thumb_down_rounded,
                    value: '${quote.downvotesCount ?? 0}',
                    tone: 'downvote',
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: QuoteDesign.textMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String label, {bool soft = false}) {
    final (fg, bg, border) = QuoteDesign.statusStyle('tag');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QuoteDesign.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: soft ? QuoteDesign.neutralSoft : bg,
        borderRadius: BorderRadius.circular(QuoteDesign.radiusPill),
        border: Border.all(
            color: soft ? QuoteDesign.neutralBorder : border, width: 1),
      ),
      child: Text(
        soft ? label : '#$label',
        style: QuoteDesign.tagText.copyWith(
          color: soft ? QuoteDesign.textSecondary : fg,
        ),
      ),
    );
  }

  Widget _buildPillBadge(String label, String tone) {
    final (fg, bg, border) = QuoteDesign.statusStyle(tone);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: QuoteDesign.sm, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: QuoteDesign.tagText.copyWith(color: fg),
      ),
    );
  }

  Widget _buildCardStat({
    required IconData icon,
    required String value,
    required String tone,
  }) {
    final (fg, _, _) = QuoteDesign.statusStyle(tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ],
    );
  }

  // ===================== LOADING / ERROR =====================

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: QuoteDesign.cardGradient,
              shape: BoxShape.circle,
              boxShadow: QuoteDesign.primaryGlow,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: QuoteDesign.lg),
          const Text(
            'Loading quotes...',
            style: TextStyle(
              fontSize: 14,
              color: QuoteDesign.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QuoteDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: QuoteDesign.downvoteSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: QuoteDesign.downvote,
                size: 46,
              ),
            ),
            const SizedBox(height: QuoteDesign.lg),
            const Text(
              'Failed to load quotes',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: QuoteDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: QuoteDesign.sm),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: QuoteDesign.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: QuoteDesign.lg),
            ElevatedButton.icon(
              onPressed: _refreshQuotes,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: QuoteDesign.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: QuoteDesign.lg,
                  vertical: QuoteDesign.sm + 4,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(QuoteDesign.radiusSm),
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
}