import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme.dart';
import '../../../parties/data/tn_constituency_data.dart';

class ConstituencySearchScreen extends ConsumerStatefulWidget {
  const ConstituencySearchScreen({super.key});

  @override
  ConsumerState<ConstituencySearchScreen> createState() => _ConstituencySearchScreenState();
}

class _ConstituencySearchScreenState extends ConsumerState<ConstituencySearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  _ConstituencyChoice? _selectedChoice;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  List<_ConstituencyChoice> get _allChoices {
    final items = <_ConstituencyChoice>[];
    tnDistrictConstituencies.forEach((district, constituencies) {
      for (final constituency in constituencies) {
        items.add(_ConstituencyChoice(district: district, constituency: constituency));
      }
    });
    items.sort((a, b) => a.constituency.compareTo(b.constituency));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final query = _queryController.text.trim().toLowerCase();

    final results = _allChoices.where((item) {
      return query.isEmpty || '${item.constituency} ${item.district}'.toLowerCase().contains(query);
    }).toList(growable: false);
    final suggestions = query.isEmpty ? const <_ConstituencyChoice>[] : results.take(6).toList(growable: false);
    final hasSuggestions = suggestions.isNotEmpty;
    final hasSelection = _selectedChoice != null;
    final expandedHeight = 238.0 + (hasSuggestions ? 46.0 : 0.0) + (hasSelection ? 62.0 : 0.0);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: expandedHeight,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF5ED), Color(0xFFEAF6F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'ConstituencyConnect',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Search by district or constituency and open verified candidate links instantly.',
                          style: TextStyle(color: Colors.black87, height: 1.3),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _queryController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Type district or constituency name',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _queryController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _queryController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        if (suggestions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 38,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: suggestions
                                    .map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ActionChip(
                                          avatar: const Icon(Icons.search_rounded, size: 16),
                                          label: Text('${item.constituency} (${item.district})'),
                                          onPressed: () {
                                            _queryController.text = item.constituency;
                                            setState(() => _selectedChoice = item);
                                            _openCandidates(item);
                                          },
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (_selectedChoice != null)
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 58),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                            ),

                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 18, color: AppTheme.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Selected: ${_selectedChoice!.constituency} (${_selectedChoice!.district})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(54, 34),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => _openCandidates(_selectedChoice!),
                                  child: const Text('Open'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Constituencies (${results.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          if (results.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No matching constituency found.\nTry district or constituency keywords.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: results.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = results[index];
                  final selected = _selectedChoice == item;

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() => _selectedChoice = item);
                        _openCandidates(item);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.saffron.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.place_rounded, color: Colors.black),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.constituency,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.district,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              selected ? Icons.check_circle : Icons.arrow_forward_ios_rounded,
                              size: selected ? 22 : 18,
                              color: selected ? AppTheme.green : Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  void _openCandidates(_ConstituencyChoice choice) {
    context.push(
      '/party/nominees',
      extra: {
        'district': choice.district,
        'constituency': choice.constituency,
      },
    );
  }
}

class _ConstituencyChoice {
  const _ConstituencyChoice({required this.district, required this.constituency});

  final String district;
  final String constituency;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ConstituencyChoice && other.district == district && other.constituency == constituency;
  }

  @override
  int get hashCode => Object.hash(district, constituency);
}

