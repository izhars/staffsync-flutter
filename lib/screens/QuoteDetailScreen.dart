// lib/screens/quote_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/quote.dart';

class QuoteDetailScreen extends StatefulWidget {
  final Quote quote;

  const QuoteDetailScreen({
    super.key,
    required this.quote,
  });

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  // Color schemes for different moods
  final List<ColorScheme> _colorSchemes = [
    const ColorScheme(
      primary: Color(0xFF6C63FF),
      secondary: Color(0xFFFF6584),
      surface: Colors.white,
      background: Color(0xFFF8F9FF),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onBackground: Colors.black,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    const ColorScheme(
      primary: Color(0xFF36D1DC),
      secondary: Color(0xFF5B86E5),
      surface: Colors.white,
      background: Color(0xFFF0F8FF),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onBackground: Colors.black,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    const ColorScheme(
      primary: Color(0xFFFF6B6B),
      secondary: Color(0xFF4ECDC4),
      surface: Colors.white,
      background: Color(0xFFFFF9F9),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onBackground: Colors.black,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    const ColorScheme(
      primary: Color(0xFF45B649),
      secondary: Color(0xFFDCE35B),
      surface: Colors.white,
      background: Color(0xFFF0FFF4),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black,
      onBackground: Colors.black,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
  ];

  late ColorScheme _currentColorScheme;

  @override
  void initState() {
    super.initState();
    _currentColorScheme = _getColorSchemeForQuote(widget.quote);
  }

  ColorScheme _getColorSchemeForQuote(Quote quote) {
    final text = quote.text.toLowerCase();
    final tags = quote.tags?.map((t) => t.toLowerCase()).toList() ?? [];

    if (quote.dialogue == true) {
      return _colorSchemes[1]; // Blue for dialogue
    } else if (tags.contains('love') || text.contains('love')) {
      return _colorSchemes[2];
    } else if (tags.contains('nature') || tags.contains('life')) {
      return _colorSchemes[3];
    } else if (tags.contains('science') || tags.contains('technology')) {
      return _colorSchemes[1];
    } else if (tags.contains('inspirational') || tags.contains('motivational')) {
      return _colorSchemes[0];
    }

    return _colorSchemes[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentColorScheme.background,
      appBar: AppBar(
        title: Text(
          widget.quote.dialogue == true ? 'Dialogue' : 'Quote Details',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: _currentColorScheme.primary,
        foregroundColor: _currentColorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: widget.quote.favorite == true
            ? [
          IconButton(
            icon: const Icon(Icons.favorite_rounded),
            onPressed: () {},
            tooltip: 'Favorite',
          ),
        ]
            : null,
      ),
      body: _buildQuoteContent(),
    );
  }

  Widget _buildQuoteContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main Quote Card
          _buildQuoteCard(),

          // Metadata Chips
          _buildMetadataChips(),

          // Source/Context Section
          if (widget.quote.source != null || widget.quote.context != null)
            _buildSourceContextSection(),

          // Stats Grid
          _buildStatsGrid(),

          // Dialogue Lines (if dialogue)
          if (widget.quote.dialogue == true && widget.quote.lines != null)
            _buildDialogueSection(),

          // Tags Section
          if (widget.quote.tags != null && widget.quote.tags!.isNotEmpty)
            _buildTagsSection(),

          // URL Section
          if (widget.quote.url != null && widget.quote.url!.isNotEmpty)
            _buildUrlSection(),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _currentColorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _currentColorScheme.primary.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: _currentColorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Decorative icons and dialogue badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                widget.quote.dialogue == true
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.format_quote_rounded,
                color: _currentColorScheme.primary.withOpacity(0.3),
                size: 32,
              ),
              if (widget.quote.dialogue == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.purple.shade400,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'DIALOGUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              Icon(
                widget.quote.dialogue == true
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.format_quote_rounded,
                color: _currentColorScheme.primary.withOpacity(0.3),
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quote text
          Text(
            widget.quote.text,
            style: TextStyle(
              fontSize: widget.quote.dialogue == true ? 20 : 24,
              fontWeight: widget.quote.dialogue == true ? FontWeight.w500 : FontWeight.w400,
              fontStyle: widget.quote.dialogue == true ? FontStyle.normal : FontStyle.italic,
              height: 1.6,
              color: Colors.black87,
              fontFamily: widget.quote.dialogue == true ? 'Roboto' : 'Georgia',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Author section
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: _currentColorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _currentColorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: _currentColorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.quote.author,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _currentColorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (widget.quote.authorPermalink != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@${widget.quote.authorPermalink!}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _currentColorScheme.primary.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildMetadataChip(
            Icons.tag_rounded,
            '#${widget.quote.id ?? 'N/A'}',
            _currentColorScheme.primary,
          ),
          if (widget.quote.private == true)
            _buildMetadataChip(
              Icons.lock_rounded,
              'Private',
              Colors.red,
            ),
          if (widget.quote.favorite == true)
            _buildMetadataChip(
              Icons.favorite_rounded,
              'Favorite',
              Colors.pink,
            ),
          if (widget.quote.dialogue == true)
            _buildMetadataChip(
              Icons.forum_rounded,
              'Dialogue',
              Colors.blue,
            ),
        ],
      ),
    );
  }

  Widget _buildSourceContextSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _currentColorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.quote.source != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.movie_rounded,
                      color: Colors.purple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Source',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.quote.source!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          if (widget.quote.context != null) ...[
            if (widget.quote.source != null) const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Context',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.quote.context!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _currentColorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: _currentColorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _currentColorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildStatCard(
                Icons.favorite_border_rounded,
                '${widget.quote.favoritesCount ?? 0}',
                'Favorites',
                Colors.pink,
              ),
              _buildStatCard(
                Icons.thumb_up_rounded,
                '${widget.quote.upvotesCount ?? 0}',
                'Upvotes',
                Colors.green,
              ),
              _buildStatCard(
                Icons.thumb_down_rounded,
                '${widget.quote.downvotesCount ?? 0}',
                'Downvotes',
                Colors.orange,
              ),
              _buildStatCard(
                Icons.trending_up_rounded,
                '${(widget.quote.upvotesCount ?? 0) - (widget.quote.downvotesCount ?? 0)}',
                'Net Score',
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialogueSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.message_rounded,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Dialogue Lines',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.quote.lines!.length} lines',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: widget.quote.lines!.map((line) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Line ${line.position}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (line.authorPermalink != null)
                            Text(
                              '@${line.authorPermalink!}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.withOpacity(0.6),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        line.text,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '— ${line.author}',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _currentColorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: _currentColorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Tags',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _currentColorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.quote.tags!.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _currentColorScheme.primary.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.quote.tags!.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _currentColorScheme.primary,
                      _currentColorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _currentColorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _currentColorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.link_rounded,
                color: _currentColorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Source URL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _currentColorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // Add url_launcher package and uncomment:
              // launchUrl(Uri.parse(widget.quote.url!));
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.quote.url!.replaceAll('https://', ''),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.blue,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}