import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../polls/providers/polls_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firestoreProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(tabs: [Tab(text: 'Messages'), Tab(text: 'Users'), Tab(text: 'Polls')]),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: _MetricsCards(firestore: firestore),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ModerationTab(search: search, onSearch: (v) => setState(() => search = v)),
                  const _UsersTab(),
                  const _PollManagementTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsCards extends StatelessWidget {
  const _MetricsCards({required this.firestore});

  final FirebaseFirestore firestore;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        firestore.collection(AppConstants.firestoreUsers).count().get(),
        firestore.collectionGroup('items').where('isDeleted', isEqualTo: false).count().get(),
        firestore.collection(AppConstants.firestorePolls).where('expiresAt', isNull: true).count().get(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final values = snapshot.data!;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricTile(title: 'Users', value: '${values[0].count ?? 0}'),
            _MetricTile(title: 'Messages', value: '${values[1].count ?? 0}'),
            _MetricTile(title: 'Open polls', value: '${values[2].count ?? 0}'),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(title),
        ],
      ),
    );
  }
}

class _ModerationTab extends ConsumerWidget {
  const _ModerationTab({required this.search, required this.onSearch});

  final String search;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(firestoreProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search constituency or keyword'),
            onChanged: onSearch,
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: firestore.collectionGroup('items').orderBy('timestamp', descending: true).limit(200).snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs.where((doc) {
                final text = (doc['text'] ?? '').toString().toLowerCase();
                final constituency = (doc['constituency'] ?? '').toString().toLowerCase();
                return text.contains(search.toLowerCase()) || constituency.contains(search.toLowerCase());
              }).toList() ?? [];

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final parentId = doc.reference.parent.parent?.id;
                  return ListTile(
                    title: Text(doc['userName']?.toString() ?? 'Citizen'),
                    subtitle: Text('${doc['constituency'] ?? ''} · ${doc['text'] ?? ''}'),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          color: Colors.red,
                          onPressed: () => doc.reference.update({'isDeleted': true}),
                          icon: const Icon(Icons.delete_sweep_outlined),
                        ),
                        IconButton(
                          onPressed: () => _hardDelete(context, parentId ?? '', doc.id, firestore),
                          icon: const Icon(Icons.delete_forever_outlined),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _hardDelete(BuildContext context, String roomId, String id, FirebaseFirestore firestore) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hard delete message?'),
        content: const Text('This action permanently removes the message.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (sure == true && roomId.isNotEmpty) {
      await firestore.collection(AppConstants.firestoreMessages).doc(roomId).collection('items').doc(id).delete();
    }
  }
}

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(firestoreProvider);

    return StreamBuilder(
      stream: firestore.collection(AppConstants.firestoreUsers).limit(100).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final role = doc['role']?.toString() ?? 'user';
            final isBanned = doc['isBanned'] == true;
            return ListTile(
              title: Text(doc['name']?.toString() ?? ''),
              subtitle: Text(doc['email']?.toString() ?? ''),
              leading: Chip(label: Text(role)),
              trailing: Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded),
                    onPressed: () {
                      doc.reference.update({'role': role == 'admin' ? 'user' : 'admin'});
                    },
                  ),
                  IconButton(
                    icon: Icon(isBanned ? Icons.lock_open_rounded : Icons.gpp_bad_rounded),
                    onPressed: () {
                      doc.reference.update({'isBanned': !isBanned});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PollManagementTab extends ConsumerStatefulWidget {
  const _PollManagementTab();

  @override
  ConsumerState<_PollManagementTab> createState() => _PollManagementTabState();
}

class _PollManagementTabState extends ConsumerState<_PollManagementTab> {
  final _questionController = TextEditingController();
  final _options = List.generate(4, (_) => TextEditingController());

  @override
  Widget build(BuildContext context) {
    final pollsAsync = ref.watch(pollsProvider);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Create poll', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(controller: _questionController, decoration: const InputDecoration(labelText: 'Question')),
        const SizedBox(height: 8),
        ..._options.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(controller: entry.value, decoration: InputDecoration(labelText: 'Option ${entry.key + 1}')),
              ),
            ),
        FilledButton(
          onPressed: () async {
            final options = _options.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
            if (_questionController.text.trim().isEmpty || options.length < 2) {
              return;
            }

            await ref.read(pollsRepositoryProvider).createPoll(question: _questionController.text.trim(), options: options);
            _questionController.clear();
            for (final c in _options) {
              c.clear();
            }
          },
          child: const Text('Create poll'),
        ),
        const Divider(height: 28),
        Text('Existing polls', style: Theme.of(context).textTheme.titleMedium),
        pollsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
          error: (error, _) => Text('Error: $error'),
          data: (polls) => Column(
            children: polls
                .map(
                  (poll) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(poll.question),
                    subtitle: Text('Votes: ${poll.totalVotes}'),
                    trailing: TextButton(
                      onPressed: poll.isClosed ? null : () => ref.read(pollsRepositoryProvider).closePoll(poll.id),
                      child: Text(poll.isClosed ? 'Closed' : 'Close poll'),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

