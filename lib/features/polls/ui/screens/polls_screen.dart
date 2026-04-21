import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/poll.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/polls_provider.dart';

class PollsScreen extends ConsumerWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollsAsync = ref.watch(pollsProvider);
    final authUser = ref.watch(authStateProvider).value;
    final userData = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizen Polls', style: TextStyle(color: Color(0xFF111111))),
      ),
      body: pollsAsync.when(
        loading: () => const _PollsLoadingView(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load polls: $error',
              style: const TextStyle(color: Color(0xFF111111)),
            ),
          ),
        ),
        data: (polls) {
          final homeConstituency = (userData?['homeConstituency'] as String?)?.trim().toLowerCase();
          final visiblePolls = polls.where((poll) {
            final scope = poll.constituency.trim().toLowerCase();
            return scope == 'all' || (homeConstituency != null && homeConstituency.isNotEmpty && scope == homeConstituency);
          }).toList();

          if (visiblePolls.isEmpty) {
            return const Center(
              child: Text(
                'No live polls available for your constituency yet.',
                style: TextStyle(color: Color(0xFF111111)),
              ),
            );
          }

          final votedIds = ((userData?['votedPollIds'] as List<dynamic>?) ?? const <dynamic>[])
              .map((e) => e.toString())
              .toSet();

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: visiblePolls.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final poll = visiblePolls[index];
              final locked = poll.isClosed || votedIds.contains(poll.id);

              return _PollCard(
                poll: poll,
                locked: locked,
                onVote: (selectedOption) async {
                  final uid = authUser?.uid;
                  if (uid == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please sign in again to cast your vote.')),
                      );
                    }
                    return;
                  }

                  try {
                    await ref.read(pollsRepositoryProvider).castVote(
                          pollId: poll.id,
                          selectedOption: selectedOption,
                          uid: uid,
                        );
                    ref.invalidate(currentUserProvider);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Your vote has been recorded.')),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.toString())),
                      );
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
  const _PollCard({
    required this.poll,
    required this.locked,
    required this.onVote,
  });

  final Poll poll;
  final bool locked;
  final Future<void> Function(int selectedOption) onVote;

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> {
  int? _selectedOption;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.question,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF111111),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text(
                    poll.constituency == 'all' ? 'Statewide' : poll.constituency,
                    style: const TextStyle(color: Color(0xFF111111)),
                  ),
                ),
                Chip(
                  avatar: Icon(
                    poll.isClosed ? Icons.lock_clock_rounded : Icons.how_to_vote,
                    size: 16,
                    color: const Color(0xFF111111),
                  ),
                  label: Text(
                    poll.isClosed ? 'Poll closed' : (widget.locked ? 'Already voted' : 'Open'),
                    style: const TextStyle(color: Color(0xFF111111)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...poll.options.asMap().entries.map((entry) {
              return RadioListTile<int>(
                value: entry.key,
                groupValue: _selectedOption,
                contentPadding: EdgeInsets.zero,
                onChanged: widget.locked || _submitting ? null : (value) => setState(() => _selectedOption = value),
                title: Text(entry.value, style: const TextStyle(color: Color(0xFF111111))),
              );
            }),
            if (!widget.locked)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: (_selectedOption == null || _submitting)
                      ? null
                      : () async {
                          setState(() => _submitting = true);
                          await widget.onVote(_selectedOption!);
                          if (mounted) {
                            setState(() => _submitting = false);
                          }
                        },
                  icon: _submitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.how_to_vote),
                  label: const Text('Vote'),
                ),
              ),
            if (widget.locked) ...[
              const SizedBox(height: 8),
              ...poll.options.asMap().entries.map((entry) {
                final count = poll.votes[entry.key] ?? 0;
                final total = poll.totalVotes == 0 ? 1 : poll.totalVotes;
                final percent = count / total;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${(percent * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(color: Color(0xFF111111)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: percent),
                        duration: const Duration(milliseconds: 350),
                        builder: (context, value, _) {
                          return LinearProgressIndicator(value: value);
                        },
                      ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(
                    'Total votes: ${poll.totalVotes}',
                    style: const TextStyle(color: Color(0xFF111111)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PollsLoadingView extends StatelessWidget {
  const _PollsLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        ShimmerBox(height: 220),
        SizedBox(height: 8),
        ShimmerBox(height: 220),
        SizedBox(height: 8),
        ShimmerBox(height: 220),
      ],
    );
  }
}
