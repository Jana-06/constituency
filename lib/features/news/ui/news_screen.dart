import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../shared/widgets/shimmer_box.dart';
import '../providers/news_provider.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  static const _categories = ['All', 'Politics', 'Economy', 'Infrastructure', 'Health'];
  String _selected = 'All';

  @override
  Widget build(BuildContext context) {
    final asyncNews = ref.watch(newsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Government News')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(newsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: _selected == c,
                          label: Text(c),
                          onSelected: (_) => setState(() => _selected = c),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            asyncNews.when(
              loading: () => Column(
                children: List.generate(
                  4,
                  (_) => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerBox(height: 150),
                          SizedBox(height: 12),
                          ShimmerBox(width: 220),
                          SizedBox(height: 8),
                          ShimmerBox(width: 160),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              error: (error, _) => Text('Unable to load news: $error'),
              data: (articles) {
                final filtered = _selected == 'All'
                    ? articles
                    : articles.where((a) {
                        final haystack = '${a.title} ${a.description}'.toLowerCase();
                        return haystack.contains(_selected.toLowerCase());
                      }).toList();

                return Column(
                  children: filtered
                      .map(
                        (article) => Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => context.push('/webview', extra: {'title': article.source, 'url': article.url}),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: article.imageUrl,
                                      height: 170,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const ShimmerBox(height: 170),
                                      errorWidget: (_, __, ___) => Container(
                                        height: 170,
                                        color: Theme.of(context).colorScheme.surfaceContainer,
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.newspaper),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(article.title, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${article.source} · ${timeago.format(article.publishedAt)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(article.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

