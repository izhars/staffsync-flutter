// screens/search_screen.dart
import 'package:flutter/material.dart';
import '../services/quote_service.dart';
import '../models/quote.dart';
import '../models/activity.dart';
import 'QuoteDetailScreen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final QuoteService _quoteService = QuoteService();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _results = []; // Can hold either Quote or Activity objects
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  // Search configuration
  String _searchType = 'author'; // 'author', 'tag', 'keyword' for quotes
  String _searchMode = 'quotes'; // 'quotes' or 'activities'
  String _activityType = 'author'; // 'author' or 'tag' for activities

  // Filter chips data
  final List<Map<String, dynamic>> _quoteSearchTypes = [
    {'value': 'author', 'label': 'Author', 'icon': Icons.person},
    {'value': 'tag', 'label': 'Tag', 'icon': Icons.tag},
    {'value': 'keyword', 'label': 'Keyword', 'icon': Icons.search},
  ];

  final List<Map<String, dynamic>> _activitySearchTypes = [
    {'value': 'author', 'label': 'By Author', 'icon': Icons.person},
    {'value': 'tag', 'label': 'By Tag', 'icon': Icons.tag},
  ];

  final List<Map<String, dynamic>> _searchModes = [
    {'value': 'quotes', 'label': 'Quotes', 'icon': Icons.format_quote},
    {'value': 'activities', 'label': 'Activities', 'icon': Icons.timeline},
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
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMore && _results.isNotEmpty) {
        _loadMoreResults();
      }
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
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      if (_searchMode == 'quotes') {
        final data = await _quoteService.fetchQuotes(
          filter: query,
          type: _searchType,
          page: loadMore ? _currentPage + 1 : 1,
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
        // For activities, use activityType instead of searchType
        final data = await _quoteService.fetchActivities(
          type: _activityType,
          filter: query,
          page: loadMore ? _currentPage + 1 : 1,
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

  Future<void> _loadMoreResults() async {
    await _search(loadMore: true);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _results.clear();
      _error = null;
    });
  }

  // In _buildSearchHeader method, replace the existing code with:

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search mode selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.category, color: Colors.deepPurple, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Search Mode:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _searchModes.map((mode) {
                    final isSelected = _searchMode == mode['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(mode['icon'] as IconData, size: 16),
                            const SizedBox(width: 4),
                            Text(mode['label'] as String),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _searchMode = mode['value'];
                            _results.clear();
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: Colors.deepPurple.withOpacity(0.2),
                        checkmarkColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.deepPurple : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search type selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.deepPurple, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Search By:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (_searchMode == 'quotes' ? _quoteSearchTypes : _activitySearchTypes).map((type) {
                    final isSelected = _searchMode == 'quotes'
                        ? _searchType == type['value']
                        : _activityType == type['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(type['icon'] as IconData, size: 16),
                            const SizedBox(width: 4),
                            Text(type['label'] as String),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            if (_searchMode == 'quotes') {
                              _searchType = type['value'];
                            } else {
                              _activityType = type['value'];
                            }
                            _results.clear();
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: Colors.deepPurple.withOpacity(0.2),
                        checkmarkColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.deepPurple : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _searchMode == 'quotes'
                        ? 'Search quotes...'
                        : 'Search activities...',
                    border: InputBorder.none,
                    icon: Icon(
                      _searchMode == 'quotes' ? Icons.format_quote : Icons.timeline,
                      color: Colors.deepPurple,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                  onSubmitted: (_) => _search(),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: _clearSearch,
                ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _search,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCount() {
    if (_results.isEmpty || _isLoading) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Found ${_results.length} ${_searchMode == 'quotes' ? 'quotes' : 'activities'}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (_hasMore)
            Text(
              'Scroll for more',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(Quote quote) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuoteDetailScreen(quote: quote),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '"${quote.text}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quote.author,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        if (quote.authorPermalink != null)
                          Text(
                            '@${quote.authorPermalink!}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (quote.tags?.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tag, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            '${quote.tags!.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Stats row
              Row(
                children: [
                  _buildStatItem(
                    Icons.favorite_border,
                    '${quote.favoritesCount ?? 0}',
                    Colors.pink,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    Icons.thumb_up,
                    '${quote.upvotesCount ?? 0}',
                    Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildStatItem(
                    Icons.thumb_down,
                    '${quote.downvotesCount ?? 0}',
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Activity activity) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.ownerType,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        activity.ownerValue,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activity.action.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                activity.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Trackable item
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${activity.trackableType}:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${activity.activityId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity.trackableValue,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchMode == 'quotes' ? Icons.search_off : Icons.timeline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'No ${_searchMode == 'quotes' ? 'quotes' : 'activities'} found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.deepPurple,
          ),
          SizedBox(height: 16),
          Text(
            'Searching...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red[400],
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Search Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _results.length + (_hasMore ? 1 : 0) + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading more indicator
        if (index == _results.length && _hasMore) {
          return _buildLoadingMoreIndicator();
        }

        // Extra loading indicator during pagination
        if (index > _results.length) {
          return const SizedBox();
        }

        final item = _results[index];

        if (item is Quote) {
          return _buildQuoteCard(item);
        } else if (item is Activity) {
          return _buildActivityCard(item);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.deepPurple,
        )
            : Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_downward,
                color: Colors.deepPurple,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scroll for more results',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _results.isEmpty) {
      return _buildLoadingState();
    }

    if (_error != null && _results.isEmpty) {
      return _buildErrorState();
    }

    if (_results.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildResultsCount(),
        Expanded(
          child: _buildResultsList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          _buildSearchBar(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }
}