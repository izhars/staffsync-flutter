// lib/screens/quote_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:staffsync/screens/quotes_list_screen.dart';
import '../models/quote.dart';

class QuoteDetailScreen extends StatelessWidget {
  final Quote quote;
  const QuoteDetailScreen({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: QuoteDesign.bg,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader(BuildContext context) {
    final title = quote.dialogue == true ? 'Dialogue' : 'Quote Details';
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
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: QuoteDesign.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: QuoteDesign.headerTitle),
                    const SizedBox(height: 2),
                    Text(
                      quote.dialogue == true
                          ? 'Multi-line dialogue'
                          : 'Full quote & metadata',
                      style: QuoteDesign.headerSubtitle,
                    ),
                  ],
                ),
              ),
              if (quote.favorite == true)
                Material(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius:
                  BorderRadius.circular(QuoteDesign.radiusSm),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.favorite_rounded,
                        color: Colors.white, size: 20),
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        QuoteDesign.md,
        QuoteDesign.md,
        QuoteDesign.md,
        QuoteDesign.xl,
      ),
      child: Column(
        children: [
          _buildQuoteCard(),
          const SizedBox(height: QuoteDesign.md),
          _buildMetadataChips(),
          if (quote.source != null || quote.context != null) ...[
            const SizedBox(height: QuoteDesign.md),
            _buildSourceContextSection(),
          ],
          const SizedBox(height: QuoteDesign.md),
          _buildStatsGrid(),
          if (quote.dialogue == true &&
              quote.lines != null &&
              quote.lines!.isNotEmpty) ...[
            const SizedBox(height: QuoteDesign.md),
            _buildDialogueSection(),
          ],
          if (quote.tags != null && quote.tags!.isNotEmpty) ...[
            const SizedBox(height: QuoteDesign.md),
            _buildTagsSection(),
          ],
          if (quote.url != null && quote.url!.isNotEmpty) ...[
            const SizedBox(height: QuoteDesign.md),
            _buildUrlSection(),
          ],
        ],
      ),
    );
  }

  // ===================== MAIN QUOTE CARD =====================

  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(QuoteDesign.lg),
      decoration: BoxDecoration(
        gradient: QuoteDesign.cardGradient,
        borderRadius: BorderRadius.circular(QuoteDesign.radiusXl),
        boxShadow: [
          BoxShadow(
            color: QuoteDesign.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                quote.dialogue == true
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.format_quote_rounded,
                color: Colors.white.withOpacity(0.35),
                size: 30,
              ),
              if (quote.dialogue == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: QuoteDesign.sm + 2, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius:
                    BorderRadius.circular(QuoteDesign.radiusPill),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: const Text(
                    'DIALOGUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              Icon(
                quote.dialogue == true
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.format_quote_rounded,
                color: Colors.white.withOpacity(0.35),
                size: 30,
              ),
            ],
          ),
          const SizedBox(height: QuoteDesign.lg),
          Text(
            quote.text,
            style: QuoteDesign.quoteBodyDetail.copyWith(
              color: Colors.white,
              fontSize: quote.dialogue == true ? 18 : 20,
              fontStyle: quote.dialogue == true
                  ? FontStyle.normal
                  : FontStyle.italic,
              fontWeight: quote.dialogue == true
                  ? FontWeight.w500
                  : FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: QuoteDesign.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: QuoteDesign.md,
              vertical: QuoteDesign.sm + 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(QuoteDesign.radiusPill),
              border: Border.all(
                  color: Colors.white.withOpacity(0.25), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  quote.author,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (quote.authorPermalink != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '@${quote.authorPermalink!}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
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

  // ===================== METADATA CHIPS =====================

  Widget _buildMetadataChips() {
    return Wrap(
      spacing: QuoteDesign.sm,
      runSpacing: QuoteDesign.sm,
      alignment: WrapAlignment.center,
      children: [
        _buildPill('ID: #${quote.id ?? 'N/A'}', Icons.tag_rounded, 'tag'),
        if (quote.private == true)
          _buildPill('PRIVATE', Icons.lock_rounded, 'private'),
        if (quote.favorite == true)
          _buildPill('FAVORITE', Icons.favorite_rounded, 'favorite'),
        if (quote.dialogue == true)
          _buildPill('DIALOGUE', Icons.forum_rounded, 'dialogue'),
      ],
    );
  }

  Widget _buildPill(String label, IconData icon, String tone) {
    final (fg, bg, border) = QuoteDesign.statusStyle(tone);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: QuoteDesign.sm + 2, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(QuoteDesign.radiusPill),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(label, style: QuoteDesign.tagText.copyWith(color: fg)),
        ],
      ),
    );
  }

  // ===================== SOURCE / CONTEXT =====================

  Widget _buildSourceContextSection() {
    return _buildSectionCard(
      title: 'Source & Context',
      icon: Icons.movie_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quote.source != null) ...[
            _buildKV(
              label: 'Source',
              value: quote.source!,
              icon: Icons.movie_rounded,
              tone: 'tag',
            ),
          ],
          if (quote.source != null && quote.context != null)
            const SizedBox(height: QuoteDesign.md),
          if (quote.context != null) ...[
            _buildKV(
              label: 'Context',
              value: quote.context!,
              icon: Icons.info_outline_rounded,
              tone: 'dialogue',
              italic: true,
            ),
          ],
        ],
      ),
    );
  }

  // ===================== STATS GRID =====================

  Widget _buildStatsGrid() {
    return _buildSectionCard(
      title: 'Statistics',
      icon: Icons.insights_rounded,
      child: GridView.count(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: QuoteDesign.sm + 2,
        mainAxisSpacing: QuoteDesign.sm + 2,
        childAspectRatio: 2.2,
        children: [
          _buildStatTile(
            icon: Icons.favorite_border_rounded,
            value: '${quote.favoritesCount ?? 0}',
            label: 'Favorites',
            tone: 'favorite',
          ),
          _buildStatTile(
            icon: Icons.thumb_up_rounded,
            value: '${quote.upvotesCount ?? 0}',
            label: 'Upvotes',
            tone: 'upvote',
          ),
          _buildStatTile(
            icon: Icons.thumb_down_rounded,
            value: '${quote.downvotesCount ?? 0}',
            label: 'Downvotes',
            tone: 'downvote',
          ),
          _buildStatTile(
            icon: Icons.trending_up_rounded,
            value:
            '${(quote.upvotesCount ?? 0) - (quote.downvotesCount ?? 0)}',
            label: 'Net Score',
            tone: 'tag',
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String value,
    required String label,
    required String tone,
  }) {
    final (fg, bg, border) = QuoteDesign.statusStyle(tone);
    return Container(
      padding: const EdgeInsets.all(QuoteDesign.sm + 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(QuoteDesign.radiusSm + 2),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: QuoteDesign.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: QuoteDesign.statValue.copyWith(color: fg)),
                ),
                const SizedBox(height: 2),
                Text(label, style: QuoteDesign.label),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== DIALOGUE LINES =====================

  Widget _buildDialogueSection() {
    return _buildSectionCard(
      title: 'Dialogue Lines',
      icon: Icons.message_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: QuoteDesign.sm, vertical: 3),
        decoration: BoxDecoration(
          color: QuoteDesign.dialogueSoft,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: QuoteDesign.dialogueBorder),
        ),
        child: Text(
          '${quote.lines!.length} LINES',
          style: QuoteDesign.tagText.copyWith(color: QuoteDesign.dialogue),
        ),
      ),
      child: Column(
        children: quote.lines!
            .map((line) => Padding(
          padding: const EdgeInsets.only(bottom: QuoteDesign.sm + 2),
          child: _buildDialogueLine(line),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildDialogueLine(dynamic line) {
    return Container(
      padding: const EdgeInsets.all(QuoteDesign.sm + 4),
      decoration: BoxDecoration(
        color: QuoteDesign.dialogueSoft,
        borderRadius: BorderRadius.circular(QuoteDesign.radiusMd),
        border: Border.all(color: QuoteDesign.dialogueBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: QuoteDesign.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: QuoteDesign.dialogueBorder),
                ),
                child: Text(
                  'LINE ${line.position}',
                  style: QuoteDesign.tagText
                      .copyWith(color: QuoteDesign.dialogue),
                ),
              ),
              const Spacer(),
              if (line.authorPermalink != null)
                Text(
                  '@${line.authorPermalink}',
                  style: QuoteDesign.caption,
                ),
            ],
          ),
          const SizedBox(height: QuoteDesign.sm),
          Text(line.text, style: QuoteDesign.quoteBody),
          const SizedBox(height: 6),
          Text(
            '— ${line.author}',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: QuoteDesign.dialogue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TAGS =====================

  Widget _buildTagsSection() {
    return _buildSectionCard(
      title: 'Tags',
      icon: Icons.local_offer_rounded,
      trailing: Text(
        '${quote.tags!.length}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: QuoteDesign.textSecondary,
        ),
      ),
      child: Wrap(
        spacing: QuoteDesign.sm - 2,
        runSpacing: QuoteDesign.sm - 2,
        children: quote.tags!.map((t) {
          final (fg, bg, border) = QuoteDesign.statusStyle('tag');
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: QuoteDesign.sm + 2, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(QuoteDesign.radiusPill),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tag_rounded, size: 12, color: fg),
                const SizedBox(width: 4),
                Text(t,
                    style: QuoteDesign.tagText.copyWith(color: fg)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===================== URL =====================

  Widget _buildUrlSection() {
    return _buildSectionCard(
      title: 'Source URL',
      icon: Icons.link_rounded,
      child: Container(
        padding: const EdgeInsets.all(QuoteDesign.sm + 4),
        decoration: BoxDecoration(
          color: QuoteDesign.primarySoft,
          borderRadius: BorderRadius.circular(QuoteDesign.radiusSm),
          border: Border.all(color: QuoteDesign.primaryLight, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.open_in_new_rounded,
                size: 16, color: QuoteDesign.primary),
            const SizedBox(width: QuoteDesign.sm),
            Expanded(
              child: Text(
                quote.url!.replaceAll('https://', ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: QuoteDesign.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== SHARED BUILDERS =====================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: QuoteDesign.surface,
        borderRadius: BorderRadius.circular(QuoteDesign.radiusLg),
        border: Border.all(color: QuoteDesign.border, width: 1),
        boxShadow: QuoteDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(QuoteDesign.md),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: QuoteDesign.primarySoft,
                    borderRadius: BorderRadius.circular(
                        QuoteDesign.radiusSm - 2),
                    border: Border.all(
                        color: QuoteDesign.primaryLight, width: 1),
                  ),
                  child:
                  Icon(icon, color: QuoteDesign.primary, size: 16),
                ),
                const SizedBox(width: QuoteDesign.sm + 2),
                Expanded(
                  child: Text(title, style: QuoteDesign.sectionTitle),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Container(height: 1, color: QuoteDesign.border),
          Padding(
            padding: const EdgeInsets.all(QuoteDesign.md),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildKV({
    required String label,
    required String value,
    required IconData icon,
    required String tone,
    bool italic = false,
  }) {
    final (fg, bg, border) = QuoteDesign.statusStyle(tone);
    return Container(
      padding: const EdgeInsets.all(QuoteDesign.sm + 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(QuoteDesign.radiusSm),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: QuoteDesign.label.copyWith(color: fg),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: QuoteDesign.textPrimary,
              height: 1.5,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}