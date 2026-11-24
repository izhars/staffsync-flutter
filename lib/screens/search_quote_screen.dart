// lib/screens/search_quote_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:staffsync/screens/quotes_list_screen.dart';
import '../services/quote_service.dart';
import '../models/quote.dart';
import '../models/activity.dart';
import 'quote_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final QuoteService _quoteService = QuoteService();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  String _searchType = 'author';
  String _searchMode = 'quotes';
  String _activityType = 'author';

  final List<Map<String, dynamic>> _quoteSearchTypes = const [
    {'value': 'author', 'label': 'Author', 'icon': Icons.person_rounded},
    {'value': 'tag', 'label': 'Tag', 'icon': Icons.tag_rounded},
    {'value': 'keyword', 'label': 'Keyword', 'icon': Icons.search_rounded},
  ];

  final List<Map<String, dynamic>> _activitySearchTypes = const [
    {'value': 'author', 'label': 'By Author', 'icon': Icons.person_rounded},
    {'value': 'tag', 'label': 'By Tag', 'icon': Icons.tag_rounded},
  ];

  final List<Map<String, dynamic>> _searchModes = const [
    {'value': 'quotes', 'label': 'Quotes', 'icon': Icons.format_quote_rounded},
    {
      'value': 'activities',
      'label': 'Activities',
      'icon': Icons.timeline_rounded
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        _hasMore &&
        _results.isNotEmpty) {
      _search(loadMore: true);
    }
  }

  Future<void> _search({bool loadMore = false}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _error = null;
        _results.clear();
        _currentPage = 1;
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final page = loadMore ? _currentPage + 1 : 1;

      if (_searchMode == 'quotes') {
        final data = await _quoteService.fetchQuotes(
          filter: query,
          type: _searchType,
          page: page,
        );
        final quotesJson = data['quotes'] as List<dynamic>;
        final lastPage = data['last_page'] as bool? ?? false;
        final newResults = quotesJson
            .map((json) => Quote.fromJson(json as Map<String, dynamic>))
            .toList();
        setState(() {
          if (loadMore) {
            _results.addAll(newResults);
            _currentPage++;
          } else {
            _results = newResults;
            _currentPage = 1;
          }
          _hasMore = !lastPage;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        final data = await _quoteService.fetchActivities(
          type: _activityType,
          filter: query,
          page: page,
        );
        final activitiesJson = data['activities'] as List<dynamic>;
        final lastPage = data['last_page'] as bool? ?? false;
        final newResults = activitiesJson
            .map((json) => Activity.fromJson(json as Map<String, dynamic>))
            .toList();
        setState(() {
          if (loadMore) {
            _results.addAll(newResults);
            _currentPage++;
          } else {
            _results = newResults;
            _currentPage = 1;
          }
          _hasMore = !lastPage;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _results.clear();
      _error = null;
    });
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
            _buildSearchBar(),
            _buildFilters(),
            Expanded(child: _buildContent()),
          ],
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
          child: Row(
            children: [
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(QuoteDesign.radiusSm),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(QuoteDesign.radiusSm),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: QuoteDesign.sm + 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search', style: QuoteDesign.headerTitle),
                    SizedBox(height: 2),
                    Text('Find quotes & activities',
                        style: QuoteDesign.headerSubtitle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== SEARCH BAR =====================

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          QuoteDesign.md, QuoteDesign.md, QuoteDesign.md, QuoteDesign.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: QuoteDesign.sm + 2, vertical: 4),
      decoration: BoxDecoration(
        color: QuoteDesign.surface,
        borderRadius: BorderRadius.circular(QuoteDesign.radiusMd),
        border: Border.all(color: QuoteDesign.border, width: 1),
        boxShadow: QuoteDesign.softShadow,
      ),
      child: Row(
        children: [
          const SizedBox(width: QuoteDesign.sm),
          Icon(
            _searchMode == 'quotes'
                ? Icons.format_quote_rounded
                : Icons.timeline_rounded,
            color: QuoteDesign.primary,
            size: 18,
          ),
          const SizedBox(width: QuoteDesign.sm),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: QuoteDesign.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: _searchMode == 'quotes'
                    ? 'Search quotes...'
                    : 'Search activities...',
                hintStyle: const TextStyle(
                  color: QuoteDesign.textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded,
                  color: QuoteDesign.textMuted, size: 18),
              onPressed: _clearSearch,
            ),
          Material(
            color: QuoteDesign.primary,
            borderRadius: BorderRadius.circular(QuoteDesign.radiusSm - 2),
            child: InkWell(
              borderRadius:
              BorderRadius.circular(QuoteDesign.radiusSm - 2),
              onTap: _search,
              child: const SizedBox(
                width: 38,
                height: 38,
                child: Icon(Icons.search_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== FILTERS =====================

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          QuoteDesign.md, 0, QuoteDesign.md, QuoteDesign.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterRow('Mode', _searchModes, _searchMode, (v) {
            setState(() {
              _searchMode = v;
              _results.clear();
            });
          }),
          const SizedBox(height: QuoteDesign.sm),
          _buildFilterRow(
            'Search by',
            _searchMode == 'quotes'
                ? _quoteSearchTypes
                : _activitySearchTypes,
            _searchMode == 'quotes' ? _searchType : _activityType,
                (v) {
              setState(() {
                if (_searchMode == 'quotes') {
                  _searchType = v;
                } else {
                  _activityType = v;
                }
                _results.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
      String label,
      List<Map<String, dynamic>> options,
      String selected,
      ValueChanged<String> onSelected,
      ) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(label.toUpperCase(),
              style: QuoteDesign.label),
        ),
        Expanded(
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, __) =>
              const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selected == option['value'];
                return GestureDetector(
                  onTap: () => onSelected(option['value'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: QuoteDesign.sm + 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? QuoteDesign.primary
                          : QuoteDesign.surface,
                      borderRadius:
                      BorderRadius.circular(QuoteDesign.radiusPill),
                      border: Border.all(
                        color: isSelected
                            ? QuoteDesign.primary
                            : QuoteDesign.border,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: QuoteDesign.primary
                              .withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                          spreadRadius: -2,
                        ),
                      ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          size: 12,
                          color: isSelected
                              ? Colors.white
                              : QuoteDesign.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          option['label'] as String,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : QuoteDesign.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ===================== CONTENT =====================

  Widget _buildContent() {
    if (_isLoading && _results.isEmpty) return _buildLoadingState();
    if (_error != null && _results.isEmpty) return _buildErrorState();
    if (_results.isEmpty) return _buildEmptyState();

    return Column(
      children: [
        _buildResultsCount(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(
                horizontal: QuoteDesign.md),
            itemCount: _results.length + 1,
            itemBuilder: (context, index) {
              if (index == _results.length) {
                return _buildLoadMoreIndicator();
              }
              final item = _results[index];
              if (item is Quote) return _buildQuoteCard(item);
              if (item is Activity) return _buildActivityCard(item);
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: QuoteDesign.md,
        vertical: QuoteDesign.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: QuoteDesign.primarySoft,
              borderRadius: BorderRadius.circular(
                  QuoteDesign.radiusSm - 2),
              border: Border.all(color: QuoteDesign.primaryLight),
            ),
            child: Text(
              '${_results.length}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: QuoteDesign.primary,
              ),
            ),
          ),
          const SizedBox(width: QuoteDesign.sm),
          Text(
            _results.length == 1
                ? 'result found'
                : 'results found',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: QuoteDesign.textSecondary,
            ),
          ),
          const Spacer(),
          if (_hasMore)
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: QuoteDesign.primary,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Scroll for more',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: QuoteDesign.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ===================== QUOTE CARD =====================

  Widget _buildQuoteCard(Quote quote) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QuoteDesign.md),
      child: Material(
        color: QuoteDesign.surface,
        borderRadius: BorderRadius.circular(QuoteDesign.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(QuoteDesign.radiusLg),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    QuoteDetailScreen(quote: quote),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(QuoteDesign.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(QuoteDesign.radiusLg),
              border: Border.all(color: QuoteDesign.border, width: 1),
              boxShadow: QuoteDesign.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (quote.tags != null &&
                        quote.tags!.isNotEmpty)
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: quote.tags!
                              .take(2)
                              .map(_buildTagChip)
                              .toList(),
                        ),
                      )
                    else
                      const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: QuoteDesign.textMuted),
                  ],
                ),
                const SizedBox(height: QuoteDesign.sm + 2),
                Text(
                  '"${quote.text}"',
                  style: QuoteDesign.quoteBody,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: QuoteDesign.md),
                Container(height: 1, color: QuoteDesign.border),
                const SizedBox(height: QuoteDesign.sm + 2),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: QuoteDesign.primarySoft,
                      child: Text(
                        quote.author.isNotEmpty
                            ? quote.author[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: QuoteDesign.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: QuoteDesign.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            quote.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: QuoteDesign.textPrimary,
                            ),
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
                    _buildStat(Icons.favorite_rounded,
                        quote.favoritesCount ?? 0, 'favorite'),
                    const SizedBox(width: QuoteDesign.sm),
                    _buildStat(Icons.thumb_up_rounded,
                        quote.upvotesCount ?? 0, 'upvote'),
                    const SizedBox(width: QuoteDesign.sm),
                    _buildStat(Icons.thumb_down_rounded,
                        quote.downvotesCount ?? 0, 'downvote'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final (fg, bg, border) = QuoteDesign.statusStyle('tag');
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: QuoteDesign.sm, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(QuoteDesign.radiusPill),
        border: Border.all(color: border, width: 1),
      ),
      child: Text('#$tag',
          style: QuoteDesign.tagText.copyWith(color: fg)),
    );
  }

  Widget _buildStat(IconData icon, int count, String tone) {
    final (fg, _, _) = QuoteDesign.statusStyle(tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ],
    );
  }

  // ===================== ACTIVITY CARD =====================

  Widget _buildActivityCard(Activity activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QuoteDesign.md),
      child: Container(
        padding: const EdgeInsets.all(QuoteDesign.md),
        decoration: BoxDecoration(
          color: QuoteDesign.surface,
          borderRadius: BorderRadius.circular(QuoteDesign.radiusLg),
          border: Border.all(color: QuoteDesign.border, width: 1),
          boxShadow: QuoteDesign.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: QuoteDesign.dialogueSoft,
                    borderRadius:
                    BorderRadius.circular(QuoteDesign.radiusSm),
                    border: Border.all(color: QuoteDesign.dialogueBorder),
                  ),
                  child: const Icon(Icons.timeline_rounded,
                      color: QuoteDesign.dialogue, size: 18),
                ),
                const SizedBox(width: QuoteDesign.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity.ownerType.toUpperCase(),
                          style: QuoteDesign.label),
                      const SizedBox(height: 2),
                      Text(
                        activity.ownerValue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: QuoteDesign.cardTitle,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: QuoteDesign.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: QuoteDesign.dialogueSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: QuoteDesign.dialogueBorder),
                  ),
                  child: Text(
                    activity.action.toUpperCase(),
                    style: QuoteDesign.tagText
                        .copyWith(color: QuoteDesign.dialogue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: QuoteDesign.sm + 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(QuoteDesign.sm + 4),
              decoration: BoxDecoration(
                color: QuoteDesign.surfaceMuted,
                borderRadius: BorderRadius.circular(QuoteDesign.radiusSm),
                border: Border.all(color: QuoteDesign.border, width: 1),
              ),
              child: Text(
                activity.message,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: QuoteDesign.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: QuoteDesign.sm + 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(QuoteDesign.sm + 4),
              decoration: BoxDecoration(
                color: QuoteDesign.primarySoft,
                borderRadius: BorderRadius.circular(QuoteDesign.radiusSm),
                border: Border.all(color: QuoteDesign.primaryLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 12, color: QuoteDesign.primary),
                      const SizedBox(width: 5),
                      Text(
                        activity.trackableType.toUpperCase(),
                        style: QuoteDesign.label
                            .copyWith(color: QuoteDesign.primary),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: QuoteDesign.primaryLight),
                        ),
                        child: Text(
                          '#${activity.activityId}',
                          style: QuoteDesign.tagText.copyWith(
                              color: QuoteDesign.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: QuoteDesign.sm),
                  Text(
                    activity.trackableValue,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: QuoteDesign.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== STATES =====================

  Widget _buildLoadingState() {
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
            'Searching...',
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

  Widget _buildErrorState() {
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
              'Search failed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: QuoteDesign.textPrimary,
              ),
            ),
            const SizedBox(height: QuoteDesign.sm),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: QuoteDesign.textMuted,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: QuoteDesign.lg),
            ElevatedButton.icon(
              onPressed: _search,
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
              child: const Icon(Icons.search_off_rounded,
                  size: 40, color: QuoteDesign.textMuted),
            ),
            const SizedBox(height: QuoteDesign.md),
            const Text(
              'No results yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: QuoteDesign.textPrimary,
              ),
            ),
            const SizedBox(height: QuoteDesign.sm),
            const Text(
              'Enter a search query and tap search',
              textAlign: TextAlign.center,
              style: TextStyle(
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
    if (!_hasMore) {
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
              'End of results',
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
}