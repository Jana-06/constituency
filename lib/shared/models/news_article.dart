class NewsArticle {
  const NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
  });

  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String source;
  final DateTime publishedAt;

  factory NewsArticle.fromMap(Map<String, dynamic> map) {
    return NewsArticle(
      title: map['title'] as String? ?? 'Untitled',
      description: map['description'] as String? ?? '',
      url: map['url'] as String? ?? '',
      imageUrl: map['urlToImage'] as String? ?? '',
      source: (map['source'] as Map<String, dynamic>? ?? const <String, dynamic>{})['name'] as String? ?? 'Unknown',
      publishedAt: DateTime.tryParse(map['publishedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

