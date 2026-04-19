import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/news_article.dart';
import '../data/news_service.dart';

final newsServiceProvider = Provider<NewsService>((ref) => NewsService());

final newsProvider = FutureProvider<List<NewsArticle>>((ref) {
  return ref.watch(newsServiceProvider).fetchNews();
});

