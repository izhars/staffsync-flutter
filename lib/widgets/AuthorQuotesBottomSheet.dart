// lib/widgets/author_quotes_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../services/quote_service.dart';
import '../models/quote.dart';

class AuthorQuotesBottomSheet extends StatefulWidget {
  final String author;
  final String? authorPermalink;

  const AuthorQuotesBottomSheet({
    super.key,
    required this.author,
    this.authorPermalink,
  });

  @override
  State<AuthorQuotesBottomSheet> createState() => _AuthorQuotesBottomSheetState();
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
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
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

    setState(() {
      _loadingMore = true;
    });

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
      setState(() {
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF667eea).withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF667eea),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.author,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      if (widget.authorPermalink != null)
                        Text(
                          '@${widget.authorPermalink!}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),

          // Stats
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Quotes',
                  '${_quotes.length}',
                  Icons.format_quote_rounded,
                  const Color(0xFF667eea),
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                _buildStatItem(
                  'Tags',
                  '${_quotes.expand((q) => q.tags ?? []).toSet().length}',
                  Icons.local_offer_rounded,
                  const Color(0xFF764ba2),
                ),
              ],
            ),
          ),

          // Quotes List
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _error != null
                ? _buildError()
                : _quotes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _quotes.length + (_loadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _quotes.length) {
                  return _buildLoadMoreIndicator();
                }

                final quote = _quotes[index];
                return _buildQuoteItem(quote, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF667eea),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load quotes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAuthorQuotes,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No quotes found for ${widget.author}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (!_hasMorePages) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No more quotes',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF667eea),
        ),
      ),
    );
  }

  Widget _buildQuoteItem(Quote quote, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${quote.text}"',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (quote.tags != null && quote.tags!.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: quote.tags!
                  .take(3)
                  .map(
                    (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF667eea),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.thumb_up_rounded,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                '${quote.upvotesCount ?? 0}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.favorite_border_rounded,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                '${quote.favoritesCount ?? 0}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              if (quote.source != null)
                Text(
                  'Source: ${quote.source!}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}