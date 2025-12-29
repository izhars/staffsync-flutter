// lib/screens/quotes_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:staffsync/screens/search_quote_screen.dart';
import '../services/quote_service.dart';
import '../models/quote.dart';
import '../widgets/AuthorQuotesBottomSheet.dart';
import 'QuoteDetailScreen.dart';

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

  final List<List<Color>> _cardGradients = const [
    [Color(0xFF667eea), Color(0xFF764ba2)], // Purple Dream
    [Color(0xFFf093fb), Color(0xFFf5576c)], // Pink Sunset
    [Color(0xFF4facfe), Color(0xFF00f2fe)], // Sky Blue
    [Color(0xFF43e97b), Color(0xFF38f9d7)], // Mint Fresh
    [Color(0xFFfa709a), Color(0xFFfee140)], // Peach Glow
    [Color(0xFF30cfd0), Color(0xFF330867)], // Deep Ocean
    [Color(0xFFa8edea), Color(0xFEfed6e3)], // Cotton Candy
    [Color(0xFFff9a9e), Color(0xFFfecfef)], // Rose Garden
  ];

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

    setState(() {
      _loadingMore = true;
    });

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
      setState(() {
        _loadingMore = false;
      });
    }
  }

  Future<void> _refreshQuotes() async {
    setState(() {
      _currentPage = 1;
      _hasMorePages = true;
    });
    await _fetchQuotes();
  }

  List<Color> _getCardGradientForIndex(int index) {
    return _cardGradients[index % _cardGradients.length];
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          if (_isLoading)
            SliverFillRemaining(child: _buildLoadingScreen())
          else if (_error != null)
            SliverFillRemaining(child: _buildErrorScreen())
          else
            ...[
              SliverToBoxAdapter(child: _buildStatsSection()),
              _buildQuotesGrid(),
            ],
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _refreshQuotes,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: FlexibleSpaceBar(
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
          title: const Text(
            'Wisdom Quotes',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 28,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          background: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Icon(
                  Icons.format_quote_rounded,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading quotes...',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF667eea),
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _error ?? 'Something went wrong while loading quotes.',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _refreshQuotes,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.format_quote_rounded,
            '${_quotes.length}',
            'Quotes',
            const Color(0xFF667eea),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
          _buildStatItem(
            Icons.person_rounded,
            '${_quotes.map((q) => q.author).toSet().length}',
            'Authors',
            const Color(0xFF764ba2),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
          _buildStatItem(
            Icons.local_offer_rounded,
            '${_quotes.expand((q) => q.tags ?? []).toSet().length}',
            'Tags',
            const Color(0xFFf5576c),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuotesGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            if (index == _quotes.length) {
              return _buildLoadingMoreIndicator();
            }

            final quote = _quotes[index];
            final gradientColors = _getCardGradientForIndex(index);

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
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: _buildSlidableQuoteCard(
                  quote: quote,
                  gradientColors: gradientColors,
                  index: index,
                ),
              ),
            );
          },
          childCount: _quotes.length + (_loadingMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    if (!_hasMorePages) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'No more quotes',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF667eea),
        ),
      ),
    );
  }

  Widget _buildSlidableQuoteCard({
    required Quote quote,
    required List<Color> gradientColors,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey('quote_${quote.id ?? quote.hashCode}_$index'),
        closeOnScroll: true,
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => _onToggleFavorite(index),
              backgroundColor: const Color(0xFFf093fb),
              foregroundColor: Colors.white,
              icon: quote.favorite == true ? Icons.favorite : Icons.favorite_border,
              label: quote.favorite == true ? 'Unlike' : 'Like',
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => _onShareQuote(quote),
              backgroundColor: const Color(0xFF4facfe),
              foregroundColor: Colors.white,
              icon: Icons.share_rounded,
              label: 'Share',
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
        child: _buildQuoteCard(quote, gradientColors, context),
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
    );

    setState(() {
      _quotes[index] = updated;
    });
  }

  void _onShareQuote(Quote quote) {
    // TODO: Integrate share_plus package
    // Share.share('${quote.text}\n\n— ${quote.author}');
  }

  Widget _buildQuoteCard(Quote quote, List<Color> gradientColors, BuildContext context) {
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.format_quote_rounded,
                    size: 120,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (quote.tags != null && quote.tags!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              ...quote.tags!.take(2).map(
                                    (t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white.withOpacity(0.25),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    t,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              if (quote.tags!.length > 2)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  child: Text(
                                    '+${quote.tags!.length - 2}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Text(
                        '"${_getQuoteSummary(quote.text)}"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      // FIXED: Properly structured Row with GestureDetector on the entire author section
                      GestureDetector(
                        onTap: () => _showAuthorQuotesBottomSheet(context, quote),
                        child: Container(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white.withOpacity(0.25),
                                  child: Text(
                                    quote.author.isNotEmpty
                                        ? quote.author[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // FIXED: Expanded must be direct child of Row
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quote.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (quote.authorPermalink != null)
                                      Text(
                                        '@${quote.authorPermalink!}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (quote.dialogue == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_rounded,
                                        size: 12,
                                        color: gradientColors[0],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Dialogue',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: gradientColors[0],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildQuoteStat(
                              icon: quote.favorite == true
                                  ? Icons.favorite
                                  : Icons.favorite_border_rounded,
                              value: '${quote.favoritesCount ?? 0}',
                            ),
                            const SizedBox(width: 20),
                            _buildQuoteStat(
                              icon: Icons.thumb_up_rounded,
                              value: '${quote.upvotesCount ?? 0}',
                            ),
                            const SizedBox(width: 20),
                            _buildQuoteStat(
                              icon: Icons.thumb_down_rounded,
                              value: '${quote.downvotesCount ?? 0}',
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
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

  Widget _buildQuoteStat({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}