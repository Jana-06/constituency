import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../providers/parties_provider.dart';

class PartyListScreen extends ConsumerWidget {
  const PartyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(partiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tamil Nadu Parties')),
      body: partiesAsync.when(
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (_, __) => const Card(child: Padding(padding: EdgeInsets.all(12), child: ShimmerBox(height: 160))),
        ),
        error: (error, _) => Center(
          child: Text('Unable to load parties: $error'),
        ),
        data: (parties) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.86,
          ),
          itemCount: parties.length,
          itemBuilder: (context, index) {
            final party = parties[index];
            return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 250 + (index * 20)),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(offset: Offset(0, (1 - value) * 18), child: child),
                  ),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        ref.read(analyticsProvider).logEvent(
                          name: 'party_tapped',
                          parameters: {'party_id': party.id, 'party_name': party.shortName},
                        );
                        context.push('/app/parties/detail/${party.id}');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: party.flagUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, _) => const ShimmerBox(height: 120),
                                  errorWidget: (_, __, ___) => Container(
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.flag_outlined),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TamilText(
                              party.tamilName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              party.englishName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Chip(label: Text(party.shortName)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
          },
        ),
      ),
    );
  }
}


