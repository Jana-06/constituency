import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../data/candidate_repository.dart';
import '../models/candidate_profile.dart';

final candidateRepositoryProvider = Provider<CandidateRepository>((ref) {
  return CandidateRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  );
});

class CandidateSearchParams {
  const CandidateSearchParams({
    required this.district,
    required this.constituency,
    this.partyId,
  });

  final String district;
  final String constituency;
  final String? partyId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CandidateSearchParams &&
        other.district == district &&
        other.constituency == constituency &&
        other.partyId == partyId;
  }

  @override
  int get hashCode => Object.hash(district, constituency, partyId);
}

final candidatesProvider = FutureProvider.family<List<CandidateProfile>, CandidateSearchParams>((ref, params) {
  return ref.read(candidateRepositoryProvider).fetchLiveCandidates(
        district: params.district,
        constituency: params.constituency,
        partyId: params.partyId,
      );
});



