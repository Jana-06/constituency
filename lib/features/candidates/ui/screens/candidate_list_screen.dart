import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/firebase/firebase_providers.dart';
import '../../../../../core/theme.dart';
import '../../../../../shared/widgets/empty_state_illustration.dart';
import '../../../../../shared/widgets/shimmer_box.dart';
import '../../../../../features/auth/providers/auth_provider.dart';
import '../../../parties/providers/parties_provider.dart';
import '../../models/candidate_profile.dart';
import '../../providers/candidate_providers.dart';

class CandidateListScreen extends ConsumerStatefulWidget {
  const CandidateListScreen({
    super.key,
    required this.district,
    required this.constituency,
    this.partyId,
  });

  final String district;
  final String constituency;
  final String? partyId;

  @override
  ConsumerState<CandidateListScreen> createState() => _CandidateListScreenState();
}

class _CandidateListScreenState extends ConsumerState<CandidateListScreen> {
  static const String _affidavitRedirectUrl = 'https://www.myneta.info/TamilNadu2026/';
  final TextEditingController _messageController = TextEditingController();
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _loadingEarlier = false;

  String get _roomId => '${widget.district}_${widget.constituency}'.replaceAll(' ', '_').toLowerCase();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = CandidateSearchParams(
      district: widget.district,
      constituency: widget.constituency,
      partyId: widget.partyId,
    );
    final candidatesAsync = ref.watch(
      candidatesProvider(params),
    );
    final messagesAsync = ref.watch(constituencyMessagesProvider(_roomId));
    final party = widget.partyId == null ? null : ref.watch(partyByIdProvider(widget.partyId!)).value;
    final authUser = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          party == null
              ? '${widget.constituency} candidates'
              : '${party.shortName} candidates in ${widget.constituency}',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh candidates',
            onPressed: () => ref.invalidate(candidatesProvider(params)),
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.constituency, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(widget.district, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 10),
                        Text(
                            'Loaded from live Tamil Nadu candidate records in Firestore.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 10),
                candidatesAsync.when(
                  loading: () => const _CandidateLoading(),
                  error: (error, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('No data found — check back later'),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: () => ref.invalidate(candidatesProvider(params)),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (candidates) {
                    if (candidates.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const EmptyStateIllustration(
                                title: 'No candidates yet',
                                subtitle: 'We will keep this constituency in sync with live data.',
                              ),
                              const SizedBox(height: 12),
                              FilledButton.tonal(
                                onPressed: () => ref.invalidate(candidatesProvider(params)),
                                child: const Text('Reload'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tamil Nadu 2026 candidate list (database)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7EF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(width: 44, child: Text('S.No', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black))),
                              Expanded(child: Text('Name of candidate', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black))),
                              SizedBox(width: 92, child: Text('Symbol', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...candidates.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 220 + (entry.key * 20)),
                              curve: Curves.easeOut,
                              child: _CandidateCard(
                                serialNumber: entry.key + 1,
                                candidate: entry.value,
                                onTap: () => _openExternalLink(_affidavitRedirectUrl),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Constituency message board'),
                  subtitle: Text('${widget.district} · ${widget.constituency}'),
                ),
                messagesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: ShimmerBox(height: 140),
                  ),
                  error: (error, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Failed to load messages: $error'),
                    ),
                  ),
                  data: (snapshot) {
                    final docs = snapshot.docs.where((doc) => (doc.data()['isDeleted'] as bool?) != true).toList();
                    if (docs.isNotEmpty) {
                      _lastDoc = docs.last;
                    }

                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: EmptyStateIllustration(
                          title: 'No messages yet',
                          subtitle: 'Be the first citizen to start the conversation.',
                        ),
                      );
                    }

                    return Column(
                      children: [
                        if (_lastDoc != null)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: _loadingEarlier ? null : () => _loadEarlier(),
                              child: Text(_loadingEarlier ? 'Loading…' : 'Load earlier'),
                            ),
                          ),
                        ...docs.reversed.map((doc) {
                          final data = doc.data();
                          final mine = data['uid'] == FirebaseAuth.instance.currentUser?.uid;
                          final bubbleColor = mine ? AppTheme.saffron.withValues(alpha: 0.22) : Theme.of(context).colorScheme.surfaceContainerHighest;
                          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

                          return Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(maxWidth: 320),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['text'] as String? ?? '', style: const TextStyle(color: Colors.black)),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${data['userName'] ?? 'Citizen'} · ${timestamp == null ? '' : '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}'}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 88),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Write a message…',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _messageController.text.trim().isEmpty ? null : () => _sendMessage(authUser),
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


  Future<void> _sendMessage(User? authUser) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || authUser == null) return;

    final firestore = ref.read(firestoreProvider);
    try {
      final userDoc = await firestore.collection(AppConstants.firestoreUsers).doc(authUser.uid).get();
      final userData = userDoc.data();

      await firestore.collection(AppConstants.firestoreMessages).doc(_roomId).collection('items').add({
        'uid': authUser.uid,
        'userName': userData?['name'] ?? authUser.displayName ?? 'Citizen',
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
      if (mounted) setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message failed: $error')));
    }
  }

  Future<void> _loadEarlier() async {
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

    if (mounted) {
      setState(() => _loadingEarlier = false);
    }
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.serialNumber,
    required this.candidate,
    required this.onTap,
  });

  final int serialNumber;
  final CandidateProfile candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '$serialNumber',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      candidate.partyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text('Affidavit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: Center(
                  child: _CandidateSymbol(candidate: candidate),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateSymbol extends StatelessWidget {
  const _CandidateSymbol({required this.candidate});

  final CandidateProfile candidate;

  @override
  Widget build(BuildContext context) {
    final symbolAssetPath = candidate.symbolAssetPath;
    if (symbolAssetPath != null && symbolAssetPath.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              symbolAssetPath,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, size: 20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            candidate.symbolName ?? 'Symbol',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Colors.black87,
                ),
          ),
        ],
      );
    }

    if (candidate.partyFlagUrl != null && candidate.partyFlagUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: CachedNetworkImage(
          imageUrl: candidate.partyFlagUrl!,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => const Icon(Icons.flag, size: 18),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.flag, size: 18),
        const SizedBox(height: 4),
        Text(
          candidate.symbolName ?? 'Symbol pending',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.black87,
              ),
        ),
      ],
    );
  }
}

extension on _CandidateListScreenState {
  Future<void> _openExternalLink(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid candidate source URL')));
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Chrome link')));
    }
  }
}

class _CandidateLoading extends StatelessWidget {
  const _CandidateLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ShimmerBox(height: 120),
        SizedBox(height: 12),
        ShimmerBox(height: 120),
        SizedBox(height: 12),
        ShimmerBox(height: 120),
      ],
    );
  }
}


