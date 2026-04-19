import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/models/party.dart';
import '../data/nominee_search_service.dart';
import '../data/party_repository.dart';

final partyRepositoryProvider = Provider<PartyRepository>((ref) => const PartyRepository());
final nomineeServiceProvider = Provider<NomineeSearchService>((ref) => NomineeSearchService());

final partiesProvider = FutureProvider<List<Party>>((ref) async {
  final repository = ref.watch(partyRepositoryProvider);
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(storageProvider);
  return repository.getParties(firestore: firestore, storage: storage);
});

final partyByIdProvider = Provider.family<AsyncValue<Party?>, String>((ref, partyId) {
  final partiesAsync = ref.watch(partiesProvider);
  return partiesAsync.whenData((parties) {
    for (final party in parties) {
      if (party.id == partyId) return party;
    }
    return null;
  });
});

final constituencyMessagesProvider = StreamProvider.family
    .autoDispose<QuerySnapshot<Map<String, dynamic>>, String>((ref, roomId) {
  return ref
      .watch(firestoreProvider)
      .collection(AppConstants.firestoreMessages)
      .doc(roomId)
      .collection('items')
      .orderBy('timestamp', descending: true)
      .limit(100)
      .snapshots();
});

