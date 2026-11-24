// models/quote.dart
class Quote {
  final int? id;
  final String text;          // 'body' in /quotes, 'body' in /qotd
  final String author;
  final String body;  // Quote text
  final String? authorPermalink;
  final List<String>? tags;
  final int? favoritesCount;
  final int? upvotesCount;
  final int? downvotesCount;
  final bool? favorite;
  final bool? dialogue;
  final bool? private;
  final String? url;
  final String? source;       // Added for movie/source info
  final String? context;      // Added for dialogue context
  final List<QuoteLine>? lines; // Added for dialogue lines

  Quote({
    this.id,
    required this.text,
    required this.author,
    required this.body,
    this.authorPermalink,
    this.tags,
    this.favoritesCount,
    this.upvotesCount,
    this.downvotesCount,
    this.favorite,
    this.dialogue,
    this.private,
    this.url,
    this.source,
    this.context,
    this.lines,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    // Handle dialogue quotes differently
    final isDialogue = json['dialogue'] as bool? ?? false;
    List<QuoteLine>? lines;

    if (isDialogue && json['lines'] != null) {
      lines = (json['lines'] as List<dynamic>)
          .map((line) => QuoteLine.fromJson(line as Map<String, dynamic>))
          .toList();
    }

    return Quote(
      id: json['id'] as int?,
      text: isDialogue && lines != null && lines.isNotEmpty
          ? _buildDialogueText(lines)
          : json['body'] as String? ?? json['text'] as String? ?? '',
      author: json['author'] as String? ?? 'Unknown',
      authorPermalink: json['author_permalink'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      favoritesCount: json['favorites_count'] as int?,
      upvotesCount: json['upvotes_count'] as int?,
      downvotesCount: json['downvotes_count'] as int?,
      favorite: json['favorite'] as bool?,
      dialogue: isDialogue,
      body: json['body'] ?? '',
      private: json['private'] as bool?,
      url: json['url'] as String?,
      source: json['source'] as String?,
      context: json['context'] as String?,
      lines: lines,
    );
  }

  static String _buildDialogueText(List<QuoteLine> lines) {
    return lines.map((line) => '${line.author}: ${line.text}').join('\n');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': text,
      'author': author,
      'author_permalink': authorPermalink,
      'tags': tags,
      'favorites_count': favoritesCount,
      'upvotes_count': upvotesCount,
      'downvotes_count': downvotesCount,
      'favorite': favorite,
      'dialogue': dialogue,
      'private': private,
      'url': url,
      'source': source,
      'context': context,
      'lines': lines?.map((line) => line.toJson()).toList(),
    };
  }
}

class QuoteLine {
  final int position;
  final String text;
  final String author;
  final String? authorPermalink;

  QuoteLine({
    required this.position,
    required this.text,
    required this.author,
    this.authorPermalink,
  });

  factory QuoteLine.fromJson(Map<String, dynamic> json) {
    return QuoteLine(
      position: json['position'] as int? ?? 0,
      text: json['body'] as String? ?? '',
      author: json['author'] as String? ?? 'Unknown',
      authorPermalink: json['author_permalink'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'body': text,
      'author': author,
      'author_permalink': authorPermalink,
    };
  }
}