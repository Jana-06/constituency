import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/shimmer_box.dart';
import '../data/tn_constituency_data.dart';
import '../providers/parties_provider.dart';

class PartyDetailScreen extends ConsumerStatefulWidget {
  const PartyDetailScreen({super.key, required this.partyId});

  final String partyId;

  @override
  ConsumerState<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends ConsumerState<PartyDetailScreen> {
  String? selectedDistrict;
  String? selectedConstituency;

  @override
  Widget build(BuildContext context) {
    final partyAsync = ref.watch(partyByIdProvider(widget.partyId));

    return partyAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Party')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(height: 180),
              SizedBox(height: 14),
              ShimmerBox(height: 22, width: 220),
              SizedBox(height: 8),
              ShimmerBox(height: 14),
              SizedBox(height: 16),
              ShimmerBox(height: 50),
            ],
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Party')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load party details: $error'),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => ref.invalidate(partiesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (party) {
        if (party == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Party')),
            body: const Center(child: Text('Party details not found.')),
          );
        }

        final constituencies = selectedDistrict == null
            ? const <String>[]
            : tnDistrictConstituencies[selectedDistrict] ?? const <String>[];

        return Scaffold(
          appBar: AppBar(title: Text(party.shortName)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: party.flagUrl,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ShimmerBox(height: 180),
                ),
              ),
              const SizedBox(height: 14),
              Text(party.fullName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(party.ideology),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.groups_2_outlined),
                title: const Text('Current leadership'),
                subtitle: Text(party.leadership),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedDistrict,
                decoration: const InputDecoration(labelText: 'Select district'),
                items: sortedDistricts
                    .map((district) => DropdownMenuItem(value: district, child: Text(district)))
                    .toList(),
                onChanged: (value) => setState(() {
                  selectedDistrict = value;
                  selectedConstituency = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedConstituency,
                decoration: const InputDecoration(labelText: 'Select constituency'),
                items: constituencies
                    .map((constituency) => DropdownMenuItem(value: constituency, child: Text(constituency)))
                    .toList(),
                onChanged: (value) => setState(() => selectedConstituency = value),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: (selectedDistrict == null || selectedConstituency == null)
                    ? null
                    : () {
                        context.push(
                          '/party/nominees',
                          extra: {
                            'partyId': party.id,
                            'district': selectedDistrict!,
                            'constituency': selectedConstituency!,
                          },
                        );
                      },
                child: const Text('View Nominees'),
              ),
            ],
          ),
        );
      },
    );
  }
}

