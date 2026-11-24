// lib/widgets/author_quotes_bottom_sheet.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/quotes_list_screen.dart';
import '../services/quote_service.dart';
import '../models/quote.dart';
import '../screens/quote_detail_screen.dart';

class AuthorQuotesBottomSheet extends StatefulWidget {
  final String author;
  final String? authorPermalink;

  const AuthorQuotesBottomSheet({
    super.key,
    required this.author,
    this.authorPermalink,
  });

  @override
  State<AuthorQuotesBottomSheet> createState() =>
      _AuthorQuotesBottomSheetState();
}

class _AuthorQuotesBottomSheetState extends State<AuthorQuotesBottomSheet> {
  List<Quote> _quotes = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  int _currentPage = 1;
  bool _hasMorePages = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAuthorQuotes();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100 &&
        !_loadingMore &&
        _hasMorePages) {
      _loadMoreAuthorQuotes();
    }
  }

  Future<void> _fetchAuthorQuotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await QuoteService().fetchQuotesByAuthor(
        author: widget.author,
        page: _currentPage,
      );
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
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreAuthorQuotes() async {
    if (_loadingMore || !_hasMorePages) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final data = await QuoteService().fetchQuotesByAuthor(
        author: widget.author,
        page: nextPage,
      );
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

  Future<void> _onRefresh() async {
    _currentPage = 1;
    await _fetchAuthorQuotes();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: QuoteDesign.bg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(QuoteDesign.radiusXl),
              topRight: Radius.circular(QuoteDesign.radiusXl),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(
                    top: QuoteDesign.sm + 4, bottom: QuoteDesign.sm),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: QuoteDesign.neutralBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              _buildHeader(context),
              _buildStatsBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: QuoteDesign.primary,
                  backgroundColor: QuoteDesign.surface,
                  child: _isLoading
                      ? _buildLoading()
                      : _error != null
                      ? _buildError()
                      : _quotes.isEmpty
                      ? _buildEmptyState()
                      : _buildList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: QuoteDesign.md),
      padding: const EdgeInsets.all(QuoteDesign.md),
      decoration: BoxDecoration(
        gradient: QuoteDesign.headerGradient,
        borderRadius: BorderRadius.circular(QuoteDesign.radiusLg),
        boxShadow: QuoteDesign.primaryGlow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: Text(
              widget.author.isNotEmpty
                  ? widget.author[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: QuoteDesign.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QuoteDesign.headerTitle.copyWith(fontSize: 16),
                ),
                if (widget.authorPermalink != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@${widget.authorPermalink!}',
                    style: QuoteDesign.headerSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(QuoteDesign.radiusSm),
            child: InkWell(
              borderRadius: BorderRadius.circular(QuoteDesign.radiusSm),
              onTap: () => Navigator.pop(context),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== STATS =====================

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.all(QuoteDesign.md),
      padding: const EdgeInsets.all(QuoteDesign.sm + 2),
      decoration: BoxDecoration(
        color: QuoteDesign.surface,
        borderRadius: BorderRadius.circular(QuoteDesign.radiusMd),
        border: Border.all(color: QuoteDesign.border, width: 1),
        boxShadow: QuoteDesign.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatTile(
            Icons.format_quote_rounded,
            '${_quotes.length}',
            'Quotes',
            'tag',
          ),
          Container(
              height: 24, width: 1, color: QuoteDesign.border),
          _buildStatTile(
            Icons.local_offer_rounded,
            '${_quotes.expand((q) => q.tags ?? []).toSet().length}',
            'Tags',
            'dialogue',
          ),
          Container(
              height: 24, width: 1, color: QuoteDesign.border),
          _buildStatTile(
            Icons.favorite_rounded,
            '${_quotes.fold<int>(0, (sum, q) => sum + (q.favoritesCount ?? 0))}',
            'Likes',
            'favorite',
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
      IconData icon, String value, String label, String tone) {
    final (fg, _, _) = QuoteDesign.statusStyle(tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: fg, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: QuoteDesign.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===================== LIST =====================

  Widget _buildList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: QuoteDesign.md),
      itemCount: _quotes.length + 1,
      itemBuilder: (context, index) {
        if (index == _quotes.length) return _buildLoadMoreIndicator();
        return Padding(
          padding: const EdgeInsets.only(bottom: QuoteDesign.md),
          child: _buildQuoteItem(_quotes[index], context),
        );
      },
    );
  }

  Widget _buildQuoteItem(Quote quote, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuoteDetailScreen(quote: quote),
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
            // ID badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: QuoteDesign.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: QuoteDesign.neutralSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: QuoteDesign.neutralBorder, width: 1),
                  ),
                  child: Text(
                    '#${quote.id ?? 'N/A'}',
                    style: QuoteDesign.tagText
                        .copyWith(color: QuoteDesign.textSecondary),
                  ),
                ),
                const Spacer(),
                if (quote.dialogue == true)
                  _buildPill('DIALOGUE', Icons.chat_bubble_rounded,
                      'dialogue'),
                if (quote.private == true) ...[
                  const SizedBox(width: 6),
                  _buildPill('PRIVATE', Icons.lock_rounded, 'private'),
                ],
              ],
            ),
            const SizedBox(height: QuoteDesign.sm + 4),
            Text(
              '"${quote.body.isNotEmpty ? quote.body : quote.text}"',
              style: QuoteDesign.quoteBody,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
            if (quote.tags != null && quote.tags!.isNotEmpty) ...[
              const SizedBox(height: QuoteDesign.sm + 2),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: quote.tags!.map((tag) {
                  final (fg, bg, border) =
                  QuoteDesign.statusStyle('tag');
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: QuoteDesign.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius:
                      BorderRadius.circular(QuoteDesign.radiusPill),
                      border: Border.all(color: border, width: 1),
                    ),
                    child: Text('#$tag',
                        style: QuoteDesign.tagText.copyWith(color: fg)),
                  );
                }).toList(),
              ),
            ],
            if (quote.url != null && quote.url!.isNotEmpty) ...[
              const SizedBox(height: QuoteDesign.sm + 2),
              GestureDetector(
                onTap: () => _openUrl(context, quote.url!),
                child: Container(
                  padding: const EdgeInsets.all(QuoteDesign.sm + 2),
                  decoration: BoxDecoration(
                    color: QuoteDesign.primarySoft,
                    borderRadius:
                    BorderRadius.circular(QuoteDesign.radiusSm),
                    border: Border.all(
                        color: QuoteDesign.primaryLight, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded,
                          size: 14, color: QuoteDesign.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _truncateUrl(quote.url!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: QuoteDesign.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.open_in_new_rounded,
                          size: 12, color: QuoteDesign.primary),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: QuoteDesign.md),
            Container(height: 1, color: QuoteDesign.border),
            const SizedBox(height: QuoteDesign.sm + 2),
            Row(
              children: [
                _buildMetaStat(Icons.favorite_rounded,
                    quote.favoritesCount ?? 0, 'favorite'),
                const SizedBox(width: QuoteDesign.md),
                _buildMetaStat(Icons.thumb_up_rounded,
                    quote.upvotesCount ?? 0, 'upvote'),
                const SizedBox(width: QuoteDesign.md),
                _buildMetaStat(Icons.thumb_down_rounded,
                    quote.downvotesCount ?? 0, 'downvote'),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: QuoteDesign.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String label, IconData icon, String tone) {
    final (fg, bg, border) = QuoteDesign.statusStyle(tone);
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(label, style: QuoteDesign.tagText.copyWith(color: fg)),
        ],
      ),
    );
  }

  Widget _buildMetaStat(IconData icon, int count, String tone) {
    final (fg, _, _) = QuoteDesign.statusStyle(tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ],
    );
  }

  // ===================== STATES =====================

  Widget _buildLoading() {
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
              color: QuoteDesign.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QuoteDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: QuoteDesign.downvoteSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: QuoteDesign.downvote, size: 40),
            ),
            const SizedBox(height: QuoteDesign.md),
            const Text(
              'Failed to load quotes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: QuoteDesign.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: QuoteDesign.sm),
            Text(
              _error ?? 'Please try again',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: QuoteDesign.textMuted,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: QuoteDesign.lg),
            ElevatedButton.icon(
              onPressed: _fetchAuthorQuotes,
              icon: const Icon(Icons.refresh_rounded, size: 16),
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
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QuoteDesign.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: QuoteDesign.neutralSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.format_quote_rounded,
                  size: 40, color: QuoteDesign.textMuted),
            ),
            const SizedBox(height: QuoteDesign.md),
            const Text(
              'No quotes found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: QuoteDesign.textPrimary,
              ),
            ),
            const SizedBox(height: QuoteDesign.sm),
            Text(
              "Couldn't find any quotes for ${widget.author}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: QuoteDesign.textMuted,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!_hasMorePages) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: QuoteDesign.lg),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: QuoteDesign.md, vertical: QuoteDesign.sm),
            decoration: BoxDecoration(
              color: QuoteDesign.neutralSoft,
              borderRadius: BorderRadius.circular(QuoteDesign.radiusPill),
              border: Border.all(color: QuoteDesign.neutralBorder),
            ),
            child: const Text(
              'All quotes loaded',
              style: TextStyle(
                color: QuoteDesign.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: QuoteDesign.lg),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: QuoteDesign.primary,
          ),
        ),
      ),
    );
  }

  // ===================== HELPERS =====================

  String _truncateUrl(String url) {
    if (url.length <= 40) return url;
    return '${url.substring(0, 37)}...';
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String rawUrlInput) async {
    try {
      String rawUrl = rawUrlInput.trim();
      if (rawUrl.isEmpty) {
        _showSnackBar(context, 'URL is empty');
        return;
      }
      if (!rawUrl.startsWith('http://') &&
          !rawUrl.startsWith('https://')) {
        rawUrl = 'https://$rawUrl';
      }
      final uri = Uri.tryParse(rawUrl);
      if (uri == null) {
        _showSnackBar(context, 'Invalid URL format');
        return;
      }
      bool? launched;
      await Future.any([
            () async {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }(),
        Future.delayed(const Duration(seconds: 5), () => false),
      ]);
      if (launched != true && context.mounted) {
        await _showUrlDialog(context, rawUrl);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Could not open link');
        if (kDebugMode) debugPrint('URL launch error: $e');
      }
    }
  }

  Future<void> _showUrlDialog(BuildContext context, String url) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unable to open automatically:'),
            const SizedBox(height: QuoteDesign.sm),
            Container(
              padding: const EdgeInsets.all(QuoteDesign.sm + 2),
              decoration: BoxDecoration(
                color: QuoteDesign.neutralSoft,
                borderRadius:
                BorderRadius.circular(QuoteDesign.radiusSm),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(
                    fontFamily: 'DM Mono', fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL copied to clipboard')),
                );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: QuoteDesign.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Copy URL'),
          ),
        ],
      ),
    );
  }
}