import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/party.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../providers/parties_provider.dart';

class PartyListScreen extends ConsumerStatefulWidget {
  const PartyListScreen({super.key});

  @override
  ConsumerState<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends ConsumerState<PartyListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partiesAsync = ref.watch(partiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tamil Nadu Parties')),
      body: partiesAsync.when(
        loading: () => const _PartyGridLoading(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Unable to load parties: $error'),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => ref.invalidate(partiesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (parties) {
          final query = _searchController.text.trim().toLowerCase();
          final filteredParties = parties.where((party) {
            final haystack = '${party.shortName} ${party.englishName} ${party.tamilName}'.toLowerCase();
            return haystack.contains(query);
          }).toList(growable: false);

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search party by Tamil or English name',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filteredParties.isEmpty
                      ? const Center(
                          child: Text('No parties found for this search.'),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 220,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filteredParties.length,
                          itemBuilder: (context, index) {
                            final party = filteredParties[index];
                            return _PartyCard(
                              party: party,
                              onTap: () {
                                context.push('/party/detail/${party.id}');
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PartyGridLoading extends StatelessWidget {
  const _PartyGridLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 220,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(height: 56),
              SizedBox(height: 10),
              Expanded(child: ShimmerBox(height: 120)),
              SizedBox(height: 8),
              ShimmerBox(height: 12, width: 100),
              SizedBox(height: 6),
              ShimmerBox(height: 10, width: 140),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.party, required this.onTap});

  final Party party;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const bannerColors = <String, Color>{
      'dmk': Color(0xFF333333),
      'aiadmk': Color(0xFFB71C1C),
      'bjp': Color(0xFFFF6B35),
      'inc': Color(0xFF0066CC),
      'pmk': Color(0xFFF6C300),
      'vck': Color(0xFF8B0000),
      'ntk': Color(0xFF1A1A1A),
      'tvk': Color(0xFFAD1457),
      'mdmk': Color(0xFF6A1B9A),
      'mnm': Color(0xFF00897B),
      'admk': Color(0xFF2E7D32),
    };
    final bannerColor = bannerColors[party.id] ?? const Color(0xFF424242);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              width: double.infinity,
              color: bannerColor,
              alignment: Alignment.center,
              child: Text(
                party.shortName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: party.flagUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: const Color(0xFFF2F2F2)),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF2F2F2),
                            alignment: Alignment.center,
                            child: const Icon(Icons.flag_outlined, color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      party.shortName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      party.englishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      party.tamilName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Text(
                          party.shortName,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.black,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
