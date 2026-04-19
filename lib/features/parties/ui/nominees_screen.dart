import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/empty_state_illustration.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../providers/parties_provider.dart';

class NomineesScreen extends ConsumerStatefulWidget {
  const NomineesScreen({
    super.key,
    required this.partyId,
    required this.district,
    required this.constituency,
  });

  final String partyId;
  final String district;
  final String constituency;

  @override
  ConsumerState<NomineesScreen> createState() => _NomineesScreenState();
}

class _NomineesScreenState extends ConsumerState<NomineesScreen> {
  final _messageController = TextEditingController();
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _loadingEarlier = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String get _roomId => '${widget.district}_${widget.constituency}'.replaceAll(' ', '_').toLowerCase();

  @override
  Widget build(BuildContext context) {
    final partyAsync = ref.watch(partyByIdProvider(widget.partyId));
    final nomineeService = ref.watch(nomineeServiceProvider);
    final msgAsync = ref.watch(constituencyMessagesProvider(_roomId));

    return Scaffold(
      appBar: AppBar(
        title: partyAsync.maybeWhen(
          data: (party) => Text('${party?.shortName ?? 'Party'} - ${widget.constituency}'),
          orElse: () => Text(widget.constituency),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                partyAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: ShimmerBox(height: 26, width: 220),
                  ),
                  error: (error, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Unable to load party info: $error'),
                    ),
                  ),
                  data: (party) {
                    if (party == null) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Party details not found.'),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${party.shortName} candidates in ${widget.constituency}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder(
                          future: nomineeService.fetchNominees(
                            party: party.englishName,
                            constituency: widget.constituency,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState != ConnectionState.done) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShimmerBox(height: 24, width: 220),
                                    SizedBox(height: 12),
                                    Text('Fetching candidates from the web...'),
                                  ],
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('No nominee data found - check back later'),
                                      const SizedBox(height: 8),
                                      OutlinedButton(onPressed: () => setState(() {}), child: const Text('Retry')),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final nominees = snapshot.data ?? [];
                            if (nominees.isEmpty) {
                              return const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('No candidates listed yet for this constituency.'),
                                ),
                              );
                            }

                            return Column(
                              children: nominees
                                  .map(
                                    (nominee) => Card(
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage:
                                              nominee.thumbnail == null ? null : CachedNetworkImageProvider(nominee.thumbnail!),
                                          child: nominee.thumbnail == null ? const Icon(Icons.person) : null,
                                        ),
                                        title: Text(nominee.name),
                                        subtitle: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            Chip(label: Text(nominee.party)),
                                            Chip(label: Text(nominee.constituency)),
                                          ],
                                        ),
                                        trailing: TextButton(
                                          onPressed: () => context.push('/webview', extra: {'title': nominee.name, 'url': nominee.link}),
                                          child: const Text('View profile'),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Constituency Message Board'),
                  subtitle: Text('${widget.district} · ${widget.constituency}'),
                ),
                msgAsync.when(
                      data: (snapshot) {
                        final docs = snapshot.docs.where((d) => (d.data()['isDeleted'] as bool?) != true).toList();
                        if (docs.isNotEmpty) {
                          _lastDoc = docs.last;
                        }
                        if (docs.isEmpty) {
                          return const SizedBox(
                            height: 180,
                            child: EmptyStateIllustration(
                              title: 'No messages yet',
                              subtitle: 'Start the conversation in your constituency.',
                            ),
                          );
                        }

                        return Column(
                          children: [
                            if (_lastDoc != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _loadingEarlier ? null : () => _loadEarlier(context),
                                  child: const Text('Load earlier'),
                                ),
                              ),
                            ...docs.reversed.map((doc) {
                              final data = doc.data();
                              final mine = data['uid'] == FirebaseAuth.instance.currentUser?.uid;
                              final bubbleColor = mine ? AppTheme.saffron : Theme.of(context).colorScheme.surfaceContainerHigh;
                              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

                              return Align(
                                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  constraints: const BoxConstraints(maxWidth: 300),
                                  decoration: BoxDecoration(
                                    color: bubbleColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['text'] as String? ?? ''),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${data['userName'] ?? 'Citizen'} · ${timestamp?.toLocal().toString().substring(0, 16) ?? ''}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: ShimmerBox(height: 120),
                      ),
                      error: (error, _) => Text('Failed to load messages: $error'),
                    ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(hintText: 'Write a message...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _messageController.text.trim().isEmpty
                        ? null
                        : () => _sendMessage(context),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(BuildContext context) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = ref.read(firebaseAuthProvider);
    final firestore = ref.read(firestoreProvider);
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await firestore.collection(AppConstants.firestoreUsers).doc(uid).get();
      final userData = userDoc.data();

      await firestore
          .collection(AppConstants.firestoreMessages)
          .doc(_roomId)
          .collection('items')
          .add({
        'uid': uid,
        'userName': userData?['name'] ?? auth.currentUser?.displayName ?? 'Citizen',
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'district': widget.district,
        'constituency': widget.constituency,
      });

      await ref.read(analyticsProvider).logEvent(
        name: 'message_sent',
        parameters: {
          'district': widget.district,
          'constituency': widget.constituency,
        },
      );

      _messageController.clear();
      setState(() {});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message failed: $e')),
        );
      }
    }
  }

  Future<void> _loadEarlier(BuildContext context) async {
    if (_lastDoc == null) return;
    setState(() => _loadingEarlier = true);

    final query = await ref
        .read(firestoreProvider)
        .collection(AppConstants.firestoreMessages)
        .doc(_roomId)
        .collection('items')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(100)
        .get();

    if (query.docs.isNotEmpty) {
      _lastDoc = query.docs.last;
    }

    setState(() => _loadingEarlier = false);
  }
}


