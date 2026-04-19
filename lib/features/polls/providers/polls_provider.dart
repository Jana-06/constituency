import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/models/poll.dart';
import '../data/polls_repository.dart';

final pollsRepositoryProvider = Provider<PollsRepository>((ref) {
  return PollsRepository(ref.watch(firestoreProvider));
});

final pollsProvider = StreamProvider<List<Poll>>((ref) {
  return ref.watch(pollsRepositoryProvider).watchPolls();
});

