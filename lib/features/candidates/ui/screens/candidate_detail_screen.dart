import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/candidate_profile.dart';

class CandidateDetailScreen extends StatelessWidget {
  const CandidateDetailScreen({super.key, required this.candidate});

  final CandidateProfile candidate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(candidate.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CachedNetworkImage(
              imageUrl: candidate.photoUrl,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 240,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              errorWidget: (_, __, ___) => Container(
                height: 240,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const Icon(Icons.person_rounded, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(candidate.partyAbbreviation)),
              Chip(label: Text(candidate.constituencyLabel)),
              Chip(label: Text(candidate.leader)),
            ],
          ),
          const SizedBox(height: 16),
          Text(candidate.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(candidate.partyName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          _DetailCard(
            title: 'Police cases',
            icon: Icons.gavel_outlined,
            body: candidate.policeCasesSummary,
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Good things',
            icon: Icons.thumb_up_alt_outlined,
            body: candidate.goodThings.join('\n• '),
            bulletPrefix: '• ',
          ),
          const SizedBox(height: 12),
          _DetailCard(
            title: 'Affidavit summary',
            icon: Icons.description_outlined,
            body: candidate.affidavitSummary,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.push('/webview', extra: {'title': candidate.name, 'url': candidate.sourceUrl}),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(candidate.sourceLabel),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.icon,
    required this.body,
    this.bulletPrefix = '',
  });

  final String title;
  final IconData icon;
  final String body;
  final String bulletPrefix;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              bulletPrefix.isEmpty ? body : body.split('\n').map((line) => '$bulletPrefix${line.trim()}').join('\n'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

