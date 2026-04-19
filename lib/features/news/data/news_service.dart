import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../shared/models/news_article.dart';

class NewsService {
  NewsService() : _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));

  final Dio _dio;

  Future<List<NewsArticle>> fetchNews() async {
    final key = dotenv.env['NEWS_API_KEY'];

    if (key == null || key.isEmpty) {
      return _placeholderNews();
    }

    final response = await _dio.get(
      'https://newsapi.org/v2/everything',
      queryParameters: {
        'q': '(Tamil Nadu OR India) AND (government OR election OR politics OR policy)',
        'language': 'en',
        'sortBy': 'publishedAt',
        'pageSize': 20,
        'apiKey': key,
      },
    );

    final items = (response.data['articles'] as List<dynamic>?) ?? <dynamic>[];
    if (items.isEmpty) {
      return _placeholderNews();
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((e) {
          final fixed = Map<String, dynamic>.from(e);
          fixed['urlToImage'] = (fixed['urlToImage'] as String?)?.isNotEmpty == true
              ? fixed['urlToImage']
              : 'https://placehold.co/800x450/F7F5F2/2D2D2D.png?text=Political+News';
          return NewsArticle.fromMap(fixed);
        })
        .toList(growable: false);
  }

  List<NewsArticle> _placeholderNews() {
    final now = DateTime.now();
    return List<NewsArticle>.generate(
      6,
      (index) => NewsArticle(
        title: 'Tamil Nadu civic update ${index + 1}',
        description: 'Placeholder article until NEWS_API_KEY is configured in .env.',
        url: 'https://www.thehindu.com/news/national/tamil-nadu/',
        imageUrl: 'https://placehold.co/800x450/F7F5F2/2D2D2D.png?text=ConstituencyConnect',
        source: 'ConstituencyConnect',
        publishedAt: now.subtract(Duration(hours: index * 3)),
      ),
    );
  }
}
