import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/polls_provider.dart';

class PollsScreen extends ConsumerWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollsAsync = ref.watch(pollsProvider);
    final user = ref.watch(currentUserDocProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Citizen Polls')),
      body: pollsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load polls: $error')),
        data: (polls) {
          if (polls.isEmpty) {
            return const Center(child: Text('No active polls right now.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: polls.length,
            itemBuilder: (context, index) {
              final poll = polls[index];
              final voted = user?.votedPollIds.contains(poll.id) ?? false;
              return _PollCard(
                poll: poll,
                locked: voted || poll.isClosed,
                onVote: (option) async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) return;
                  try {
                    await ref.read(pollsRepositoryProvider).castVote(
                          pollId: poll.id,
                          selectedOption: option,
                          uid: uid,
                        );
                    await ref.read(analyticsProvider).logEvent(
                      name: 'vote_cast',
                      parameters: {'poll_id': poll.id, 'option_index': option},
                    );
                  } catch (e) {
                    if (context.mounted) {
                      showErrorSnackBar(context, e.toString());
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PollCard extends StatefulWidget {
  const _PollCard({required this.poll, required this.locked, required this.onVote});

  final dynamic poll;
  final bool locked;
  final Future<void> Function(int option) onVote;

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> {
  int? selected;

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(poll.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (poll.isClosed)
              const Chip(
                label: Text('Poll closed'),
                avatar: Icon(Icons.lock_clock_rounded, size: 16),
              ),
            ...poll.options.asMap().entries.map(
                  (entry) => RadioListTile<int>(
                    value: entry.key,
                    groupValue: selected,
                    onChanged: widget.locked ? null : (value) => setState(() => selected = value),
                    title: Text(entry.value),
                  ),
                ),
            if (!widget.locked)
              FilledButton(
                onPressed: selected == null
                    ? null
                    : () async {
                        await widget.onVote(selected!);
                      },
                child: const Text('Vote'),
              ),
            if (widget.locked) ...[
              const SizedBox(height: 8),
              ...poll.options.asMap().entries.map((entry) {
                final count = poll.votes[entry.key] ?? 0;
                final total = poll.totalVotes == 0 ? 1 : poll.totalVotes;
                final pct = count / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.value} - ${(pct * 100).toStringAsFixed(1)}%'),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: pct),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, _) => LinearProgressIndicator(value: value),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Chip(label: Text('Total votes: ${poll.totalVotes}')),
            ],
          ],
        ),
      ),
    );
  }
}


